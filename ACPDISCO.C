/* ========================================================================
 * ACPDISCO.C  -  shared 6800 disassembly engine.  See ACPDISCO.H.
 *
 * This is the exact same logic originally verified as the standalone
 * ACPDIS.C tool (full real-Turbo-C, real-DOSBox round-trip tests against
 * a real 2KB game ROM, with and without /data ranges, plus the org-
 * independence and org-guessing verification) -- only the plumbing
 * changed: output goes through a caller-supplied line callback instead
 * of always being fprintf() to a FILE*, so the exact same engine can
 * populate ACPIDE's live editor buffer instead of (or in addition to) a
 * file on disk.
 * ====================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ACPDISCO.H"

#if defined(__TURBOC__) || defined(__BORLANDC__)
# include <alloc.h>          /* farmalloc */
# define DIS_FAR huge   /* NOT far: a plain far pointer's arithmetic does
                          * not carry into the segment when the offset
                          * wraps past 0xFFFF, and farmalloc() gives no
                          * guarantee its returned offset is 0 -- with a
                          * full 64K array and a nonzero base offset, the
                          * top of the array silently wraps around and
                          * aliases low addresses in the same segment.
                          * huge pointers normalize on every access, which
                          * costs some speed but is the only correct way
                          * to safely index a full 64K block by an
                          * arbitrary 16-bit value here (confirmed by a
                          * real, reproduced bug during development). */
#else
# define DIS_FAR
#endif

#define MEMSZ 0x10000UL

#define FL_LOADED 0x01
#define FL_DATA   0x02
#define FL_TARGET 0x04
#define FL_BOUND  0x08

#if defined(__TURBOC__) || defined(__BORLANDC__)
static BYTE DIS_FAR *mem;
static BYTE DIS_FAR *flg;
#else
static BYTE mem[0x10000];
static BYTE flg[0x10000];
#endif

const WORD ACPDISCO_ADM31_SOCKETS[4] = { 0xE000, 0xE800, 0xF000, 0xF800 };

static void (*progress_hook)(long done, long total) = NULL;

void acpdisco_set_progress_hook(void (*hook)(long done, long total))
{
    progress_hook = hook;
}

/* Appends spaces to s (which already holds text) until it reaches at
 * least `width` characters, always adding at least one -- lays out the
 * label/mnemonic/operand columns with plain spaces instead of tab
 * characters. Deliberately not tabs: ACPEDIT.C's screen renderer writes
 * buffer bytes straight to video memory with no tab expansion, so a
 * literal tab character (0x09) displays as code page 437's glyph for
 * that byte -- a hollow circle, easily misread as a lowercase "o" on
 * screen -- rather than a blank gap. Plain spaces render correctly and
 * match this project's own hand-written .ASM house style besides. */
static void pad_field(char *s, int width)
{
    int n = width - (int)strlen(s);
    if (n < 1) n = 1;
    while (n-- > 0) strcat(s, " ");
}

void acpdisco_init(void)
{
#if defined(__TURBOC__) || defined(__BORLANDC__)
    if (mem) return;   /* idempotent: called once per program run in CLI
                         * mode, but the GUI's "Disassemble Binary..."
                         * command may invoke it again on a second use in
                         * the same session -- farmalloc()ing twice would
                         * leak the first block. */
    mem = (BYTE huge *)farmalloc(MEMSZ);
    flg = (BYTE huge *)farmalloc(MEMSZ);
    if (!mem || !flg) { fprintf(stderr, "out of memory\n"); exit(1); }
#endif
    {
        long i;
        for (i = 0; i < (long)MEMSZ; i++) { mem[i] = 0; flg[i] = 0; }
    }
}

void acpdisco_mark_data(WORD lo, WORD hi)
{
    long k;
    for (k = lo; k <= (long)hi && k <= 0xFFFF; k++) flg[(WORD)k] |= FL_DATA;
}

void acpdisco_clear_data(void)
{
    long i;
    for (i = 0; i < (long)MEMSZ; i++) flg[i] &= (BYTE)~FL_DATA;
}

long acpdisco_load(const char *img_file, WORD org)
{
    FILE *f = fopen(img_file, "rb");
    WORD addr;
    long i, n = 0;
    int c;
    if (!f) { fprintf(stderr, "cannot open %s\n", img_file); return 0; }
    for (i = 0; i < (long)MEMSZ; i++) flg[i] &= FL_DATA;   /* clear all but FL_DATA */
    addr = org;
    for (;;) {
        c = fgetc(f);
        if (c == EOF) break;
        mem[addr] = (BYTE)c;
        flg[addr] |= FL_LOADED;
        n++;
        if (addr == 0xFFFF) break;   /* stop at the top of the address space */
        addr++;
    }
    fclose(f);
    return n;
}

/* Reads up to 3 bytes starting at addr from mem[], stopping at `end`
 * (exclusive) so a decode never reads past the loaded image. */
static int peek3(WORD addr, WORD end, BYTE *buf)
{
    int n = 0;
    while (n < 3 && (WORD)(addr + n) != end) { buf[n] = mem[(WORD)(addr + n)]; n++; }
    return n;
}

int acpdisco_try_org(WORD base, long loaded_len)
{
    WORD end = (WORD)(base + loaded_len);
    int score = 0;
    WORD addr;

    /* pass 0: boundary discovery */
    addr = base;
    while (addr != end) {
        if (progress_hook) progress_hook((long)(addr - base), loaded_len);
        flg[addr] |= FL_BOUND;
        if (flg[addr] & FL_DATA) { addr++; continue; }
        {
            BYTE buf[3];
            int navail = peek3(addr, end, buf);
            ACP_DECODED d;
            if (acp_decode(addr, buf, navail, &d)) addr = (WORD)(addr + d.size);
            else addr++;
        }
    }

    /* pass 1: target marking + scoring */
    addr = base;
    while (addr != end) {
        if (progress_hook) progress_hook((long)(addr - base), loaded_len);
        if (flg[addr] & FL_DATA) { addr++; continue; }
        {
            BYTE buf[3];
            int navail = peek3(addr, end, buf);
            ACP_DECODED d;
            if (acp_decode(addr, buf, navail, &d)) {
                if ((d.mode == ACP_M_EXT || d.mode == ACP_M_REL) &&
                    d.operand >= base && d.operand < (long)base + loaded_len &&
                    (flg[(WORD)d.operand] & FL_BOUND) &&
                    !(flg[(WORD)d.operand] & FL_TARGET)) {
                    /* Only the FIRST reference to a given address counts
                     * toward the score -- otherwise a long run of
                     * repeated raw-data bytes that happens to decode
                     * into many instructions all referencing the SAME
                     * coincidental address can inflate a wrong
                     * candidate's score past a correct one that
                     * references many DIFFERENT real addresses once or
                     * twice each (confirmed on a real file: a long run
                     * of $FF sprite data outscored the true origin
                     * roughly 3 to 1 before this fix). */
                    score++;
                }
                if ((d.mode == ACP_M_EXT || d.mode == ACP_M_REL) &&
                    d.operand >= base && d.operand < (long)base + loaded_len &&
                    (flg[(WORD)d.operand] & FL_BOUND))
                    flg[(WORD)d.operand] |= FL_TARGET;
                addr = (WORD)(addr + d.size);
            } else {
                addr++;
            }
        }
    }
    return score;
}

WORD acpdisco_guess_org(const char *img_file, const WORD *candidates, int ncand,
                         int *out_scores, long *out_len)
{
    int i, best = -1, best_score = -1;
    long best_len = 0;

    for (i = 0; i < ncand; i++) {
        long n = acpdisco_load(img_file, candidates[i]);
        int score;
        if (n == 0) { if (out_scores) out_scores[i] = -1; continue; }
        score = acpdisco_try_org(candidates[i], n);
        if (out_scores) out_scores[i] = score;
        if (score > best_score) { best_score = score; best = i; best_len = n; }
    }
    if (best < 0) return 0xFFFF;

    /* make the winner the "current" load again, since the loop above may
     * have left a different (losing) candidate loaded last */
    acpdisco_load(img_file, candidates[best]);
    acpdisco_try_org(candidates[best], best_len);
    if (out_len) *out_len = best_len;
    return candidates[best];
}

void acpdisco_emit(WORD base, long loaded_len, const char *img_file,
                    int include_header,
                    void (*emit_line)(void *ctx, const char *line), void *ctx)
{
    WORD end = (WORD)(base + loaded_len);
    char line[160];

    if (include_header) {
        sprintf(line, "; Disassembled by ACPDIS from %s", img_file ? img_file : "");
        emit_line(ctx, line);
        sprintf(line, "; Range: $%04X-$%04X (%ld bytes)", base,
                (WORD)(base + loaded_len - 1), loaded_len);
        emit_line(ctx, line);
        emit_line(ctx, "");
    }
    strcpy(line, "");
    pad_field(line, 8);
    strcat(line, "ORG");
    pad_field(line, 12);
    { char tmp[8]; sprintf(tmp, "$%04X", base); strcat(line, tmp); }
    emit_line(ctx, line);

    {
        WORD addr = base;
        while (addr != end) {
            char lbl[10];
            lbl[0] = '\0';
            if (progress_hook) progress_hook((long)(addr - base), loaded_len);
            if (flg[addr] & FL_TARGET) sprintf(lbl, "L_%04X", addr);

            if (flg[addr] & FL_DATA) {
                int n2 = 0;
                char tmp[16];
                strcpy(line, lbl);
                pad_field(line, 8);
                strcat(line, "DB");
                pad_field(line, 12);
                while (addr != end && (flg[addr] & FL_DATA) && n2 < 8) {
                    /* Stop this line (without consuming the byte) if it's
                     * itself a label target -- otherwise that address
                     * never gets its FL_TARGET check at the top of the
                     * outer loop, same boundary problem as instruction
                     * alignment, just for data runs. */
                    if (n2 > 0 && (flg[addr] & FL_TARGET)) break;
                    sprintf(tmp, "%s$%02X", n2 ? "," : "", mem[addr]);
                    strcat(line, tmp);
                    addr++; n2++;
                }
                emit_line(ctx, line);
                continue;
            }

            {
                BYTE buf[3];
                int navail = peek3(addr, end, buf);
                ACP_DECODED d;
                if (acp_decode(addr, buf, navail, &d)) {
                    char opnd[24];
                    opnd[0] = '\0';
                    switch (d.mode) {
                    case ACP_M_INH:
                        break;
                    case ACP_M_IMM:
                        if (d.size == 2) sprintf(opnd, "#$%02lX", d.operand);
                        else              sprintf(opnd, "#$%04lX", d.operand);
                        break;
                    case ACP_M_DIR:
                        sprintf(opnd, "$%02lX", d.operand);
                        break;
                    case ACP_M_IND:
                        sprintf(opnd, "$%02lX,X", d.operand);
                        break;
                    case ACP_M_EXT:
                        if (flg[(WORD)d.operand] & FL_TARGET)
                            sprintf(opnd, "L_%04lX", d.operand);
                        else
                            sprintf(opnd, "$%04lX", d.operand);
                        break;
                    case ACP_M_REL:
                        if (flg[(WORD)d.operand] & FL_TARGET)
                            sprintf(opnd, "L_%04lX", d.operand);
                        else
                            sprintf(opnd, "$%04lX", d.operand);
                        break;
                    default:
                        break;
                    }
                    strcpy(line, lbl);
                    pad_field(line, 8);
                    strcat(line, d.mnem);
                    if (opnd[0]) { pad_field(line, 12); strcat(line, opnd); }
                    emit_line(ctx, line);
                    addr = (WORD)(addr + d.size);
                } else {
                    char tmp[8];
                    strcpy(line, lbl);
                    pad_field(line, 8);
                    strcat(line, "DB");
                    pad_field(line, 12);
                    sprintf(tmp, "$%02X", mem[addr]);
                    strcat(line, tmp);
                    emit_line(ctx, line);
                    addr++;
                }
            }
        }
    }

    strcpy(line, "");
    pad_field(line, 8);
    strcat(line, "END");
    emit_line(ctx, line);
    if (progress_hook) progress_hook(loaded_len, loaded_len);
}
