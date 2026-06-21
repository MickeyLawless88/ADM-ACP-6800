/* ========================================================================
 * acp6800.c  -  ADM-style program development system, retargeted to the
 *               Motorola 6800.
 *
 * A faithful recreation of the Lear Siegler ADM-2 MICOS development
 * environment described in Section 5 of the ADM-2 microprogramming manual:
 *
 *     ACP      - Assembly Control Program (the top-level menu shell)
 *     ASSEDIT  - the line-oriented source file editor
 *     ASM      - the two-pass assembler
 *
 * The ADM-2 microcode instruction set has been REPLACED by the standard
 * Motorola 6800 assembly language.  The shell, editor and two-pass
 * assembler workflow / listing / label-list / error-message behaviour are
 * preserved from the manual; only the target ISA differs.
 *
 * Portable ANSI C (C89).  Builds unchanged under Turbo C (DOS) and GCC.
 * Pure stdio: runs on a console or piped over a tty / serial line.
 *
 *     cc -o acp6800 acp6800.c              (GCC: add -ansi -pedantic)
 *     tcc acp6800.c                        (Turbo C, large model suggested)
 * ====================================================================== */
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>

/* getcwd lives in different headers per toolchain; used only to tell the
 * user where output files were written */
#if defined(__TURBOC__) || defined(__BORLANDC__)
#  include <dir.h>
#  define HAVE_GETCWD 1
#elif defined(__unix__) || defined(__APPLE__) || defined(__linux__)
#  include <unistd.h>
#  define HAVE_GETCWD 1
#endif

/* ---- portable types -------------------------------------------------- */
typedef unsigned char  BYTE;
typedef unsigned int   WORD;     /* 16 bits is enough; masked to 0xFFFF   */

/* ---- limits ---------------------------------------------------------- */
#define ACP_VERSION "1.3"        /* bump on every change so stale binaries  */
                                 /* are identifiable from the banner        */

#define MAXLINES  3000           /* records per source file               */
#define LINELEN   128            /* characters per source line            */
#define NAMELEN   16
#define MAXSYM    2000
#define OBJMAX    64             /* max object bytes a single line can emit */

/* The large tables are heap-allocated at start-up rather than declared as
 * static arrays.  Turbo C (16-bit) forbids any single static/auto array
 * larger than 64 KB; allocating keeps each request comfortably under that
 * limit and behaves identically under GCC. */

/* ====================================================================== */
/*  small portable helpers                                                */
/* ====================================================================== */

static char *xstrdup(const char *s)
{
    char *p = (char *)malloc(strlen(s) + 1);
    if (p) strcpy(p, s);
    return p;
}

static void rstrip(char *s)
{
    int n = (int)strlen(s);
    while (n > 0 && (s[n-1] == '\n' || s[n-1] == '\r' ||
                     s[n-1] == ' '  || s[n-1] == '\t')) {
        s[--n] = '\0';
    }
}

static void upcase(char *s)
{
    for (; *s; s++) *s = (char)toupper((unsigned char)*s);
}

/* read one line from the terminal; returns 0 on EOF */
static int getline_p(const char *prompt, char *buf, int size)
{
    if (prompt) { fputs(prompt, stdout); fflush(stdout); }
    if (fgets(buf, size, stdin) == NULL) { buf[0] = '\0'; return 0; }
    rstrip(buf);
    return 1;
}

/* ====================================================================== */
/*  source file buffer (shared by editor and assembler)                   */
/*                                                                        */
/*  Record 1 is reserved for the system and is never displayed, exactly   */
/*  as in the manual.  User text begins at line 2.  Internally lines[0]   */
/*  holds the reserved record; lines[1] displays as line 2, and so on.    */
/* ====================================================================== */

static char **gl_lines;          /* malloc'd: MAXLINES char* slots         */
static int   gl_count;           /* number of slots used incl. reserved   */

static void buf_clear(void)
{
    int i;
    for (i = 0; i < gl_count; i++) {
        if (gl_lines[i]) { free(gl_lines[i]); gl_lines[i] = NULL; }
    }
    gl_count = 1;                /* reserve record 1                       */
    gl_lines[0] = xstrdup("");
}

/* display-line number n (>=2) -> internal index, or -1 if out of range   */
static int idx_of(int dispno)
{
    int i = dispno - 1;          /* line 2 -> index 1                      */
    if (i < 1 || i >= gl_count) return -1;
    return i;
}

static int last_dispno(void) { return gl_count; } /* highest display no.  */

/* load file <name> into the buffer; returns record count (user lines) or
 * -1 if the file does not exist                                          */
static int buf_load(const char *name)
{
    FILE *f = fopen(name, "r");
    char tmp[LINELEN];
    buf_clear();
    if (!f) return -1;
    while (fgets(tmp, sizeof(tmp), f)) {
        rstrip(tmp);
        if (gl_count >= MAXLINES) break;
        gl_lines[gl_count++] = xstrdup(tmp);
    }
    fclose(f);
    return gl_count - 1;
}

static int buf_save(const char *name)
{
    FILE *f = fopen(name, "w");
    int i;
    if (!f) return -1;
    for (i = 1; i < gl_count; i++) {
        fputs(gl_lines[i] ? gl_lines[i] : "", f);
        fputc('\n', f);
    }
    fclose(f);
    return 0;
}

/* append text as a new last line */
static int buf_append(const char *text)
{
    if (gl_count >= MAXLINES) return -1;
    gl_lines[gl_count++] = xstrdup(text);
    return 0;
}

/* replace the text of display line dispno */
static int buf_replace(int dispno, const char *text)
{
    int i = idx_of(dispno);
    if (i < 0) return -1;
    free(gl_lines[i]);
    gl_lines[i] = xstrdup(text);
    return 0;
}

/* insert one line before display line dispno (existing line slides down) */
static int buf_insert(int dispno, const char *text)
{
    int i = dispno - 1;
    int k;
    if (gl_count >= MAXLINES) return -1;
    if (i < 1) i = 1;
    if (i > gl_count) i = gl_count;
    for (k = gl_count; k > i; k--) gl_lines[k] = gl_lines[k-1];
    gl_lines[i] = xstrdup(text);
    gl_count++;
    return 0;
}

/* delete display lines first..last inclusive; returns count deleted */
static int buf_delete(int first, int last)
{
    int fi = first - 1, li = last - 1;
    int n, k;
    if (fi < 1) fi = 1;
    if (li >= gl_count) li = gl_count - 1;
    if (li < fi) return 0;
    n = li - fi + 1;
    for (k = fi; k <= li; k++) if (gl_lines[k]) free(gl_lines[k]);
    for (k = li + 1; k < gl_count; k++) gl_lines[k - n] = gl_lines[k];
    gl_count -= n;
    return n;
}

/* ====================================================================== */
/*  ASSEDIT - the source file editor                                      */
/* ====================================================================== */

static int valid_filename(const char *s)
{
    const char *base, *ext, *p;
    int baselen, extlen, i;

    if (!s || !*s) return 0;

    /* Strip off any drive or directory prefix; validate only the final component. */
    base = s;
    for (p = s + strlen(s) - 1; p >= s; p--) {
        if (*p == ':' || *p == '\\' || *p == '/') {
            base = p + 1;
            break;
        }
    }

    /* Find an optional extension separator in the final component. */
    ext = NULL;
    for (p = base; *p; p++) {
        if (*p == '.') {
            if (ext) return 0;           /* more than one dot in final component */
            ext = p + 1;
        }
    }
    if (ext && *ext == '\0') return 0;  /* trailing dot not allowed */

    /* Validate the base name part (1-8 chars, starts with letter, alphanumeric). */
    for (p = base; *p && *p != '.'; p++) { }
    baselen = (int)(p - base);
    if (baselen < 1 || baselen > 8) return 0;
    if (!isalpha((unsigned char)base[0])) return 0;
    for (i = 0; i < baselen; i++)
        if (!isalnum((unsigned char)base[i])) return 0;

    /* Validate the optional extension (1-3 alphanumeric chars). */
    if (ext) {
        extlen = 0;
        for (p = ext; *p; p++) {
            if (!isalnum((unsigned char)*p)) return 0;
            extlen++;
        }
        if (extlen < 1 || extlen > 3) return 0;
    }

    return 1;
}

/* enter source lines starting at display line `start`, terminated by "//" */
static void enter_lines(int start)
{
    char in[LINELEN];
    int  no = start;
    char prompt[16];
    for (;;) {
        sprintf(prompt, "%5d   ", no);
        if (!getline_p(prompt, in, sizeof(in))) break;
        if (strncmp(in, "//", 2) == 0) break;
        if (buf_append(in) < 0) {
            printf("FILE FULL\n");
            break;
        }
        no++;
    }
}

static void edit_list(int from, int to)
{
    int i;
    if (to > last_dispno()) to = last_dispno();
    for (i = from; i <= to; i++) {
        int x = idx_of(i);
        if (x < 0) continue;
        printf("%5d   %s\n", i, gl_lines[x]);
    }
    if (to >= last_dispno()) printf("END OF FILE\n");
}

static void edit_change(int dispno)
{
    char in[LINELEN], prompt[16];
    int x = idx_of(dispno);
    if (x < 0) { printf("NO SUCH LINE\n"); return; }
    printf("%5d   %s\n", dispno, gl_lines[x]);
    sprintf(prompt, "%5d   ", dispno);
    if (!getline_p(prompt, in, sizeof(in))) return;
    if (strncmp(in, "//", 2) == 0) return;
    buf_replace(dispno, in);
}

static void edit_insert(int nlines, int before)
{
    char in[LINELEN], prompt[16];
    int  at = before, made = 0;
    printf("OPENING THE FILE FOR INSERTION OF %d LINES\n", nlines);
    printf("READY FOR INSERTION\n");
    while (made < nlines) {
        sprintf(prompt, "%5d   ", at);
        if (!getline_p(prompt, in, sizeof(in))) break;
        if (strncmp(in, "//", 2) == 0) break;
        buf_insert(at, in);
        at++; made++;
    }
}

static void edit_delete(int first, int last)
{
    char in[LINELEN];
    int  i, n;
    printf("ARE THESE THE CORRECT LINE(S)   (Y/N)?\n");
    for (i = first; i <= last; i++) {
        int x = idx_of(i);
        if (x >= 0) printf("%5d   %s\n", i, gl_lines[x]);
    }
    if (!getline_p("...", in, sizeof(in))) return;
    upcase(in);
    if (in[0] != 'Y') { printf("DELETE IGNORED\n"); return; }
    n = buf_delete(first, last);
    printf("DELETING %d LINES\n", n);
    printf("DELETE COMPLETE\n");
}

static void edit_search(const char *str)
{
    int i, hits = 0;
    for (i = 2; i <= last_dispno(); i++) {
        int x = idx_of(i);
        if (x >= 0 && strstr(gl_lines[x], str)) {
            printf("%5d   %s\n", i, gl_lines[x]);
            hits++;
        }
    }
    if (!hits) printf("STRING NOT FOUND\n");
}

static void edit_menu(void)
{
    printf("\n           READY FOR EDITING\n");
    printf("A    APPEND TO FILE\n");
    printf("C    CHANGE LINE\n");
    printf("D    DELETE LINE\n");
    printf("I    INSERT LINE BEFORE\n");
    printf("L    DISPLAY LINE(S)\n");
    printf("S    SEARCH FOR STRING BETWEEN LINES\n");
    printf("T    DISPLAY FILE\n");
    printf("X    EXIT FROM EDITOR\n");
}

/* edit-mode command loop on the file already loaded as `name` */
static void edit_mode(const char *name)
{
    char in[LINELEN], arg[LINELEN];
    int  a, b, n;
    edit_menu();
    for (;;) {
        if (!getline_p("...", in, sizeof(in))) break;
        if (in[0] == '\0') continue;
        switch (toupper((unsigned char)in[0])) {
        case 'A':
            printf("%s READY FOR INPUT\n", name);
            enter_lines(last_dispno() + 1);
            break;
        case 'C':
            { char *p = strchr(in, '#');
              if (p) a = atoi(p + 1);
              else { getline_p("# LINE-NO. ", arg, sizeof(arg)); a = atoi(arg); }
              edit_change(a); }
            break;
        case 'D':
            getline_p("FROM LINE, TO LINE ", arg, sizeof(arg));
            if (sscanf(arg, "%d ,%d", &a, &b) < 2 &&
                sscanf(arg, "%d,%d", &a, &b) < 2) { a = b = atoi(arg); }
            edit_delete(a, b);
            break;
        case 'I':
            getline_p("# OF LINES TO INSERT BEFORE LINE # n,line ", arg, sizeof(arg));
            if (sscanf(arg, "%d,%d", &n, &a) < 2 &&
                sscanf(arg, "%d ,%d", &n, &a) < 2) { n = 1; a = atoi(arg); }
            edit_insert(n, a);
            break;
        case 'L':
            getline_p("FROM LINE, TO LINE ", arg, sizeof(arg));
            if (sscanf(arg, "%d,%d", &a, &b) < 2 &&
                sscanf(arg, "%d ,%d", &a, &b) < 2) { a = atoi(arg); b = a; }
            edit_list(a, b);
            break;
        case 'S':
            getline_p("STR ", arg, sizeof(arg));
            edit_search(arg);
            break;
        case 'T':
            edit_list(2, last_dispno());
            break;
        case 'X':
            buf_save(name);
            printf("%s SAVED\n", name);
            return;
        case '?':
            edit_menu();
            break;
        default:
            printf("CMD ERR -- TYPE ? FOR LIST\n");
            break;
        }
    }
    buf_save(name);
}

/* ASSEDIT command-mode menu */
static void assedit_menu(void)
{
    printf("\n'ASSEDIT' HERE -- WHAT DO YOU WANT TO DO?\n");
    printf("C    CREATE A NEW SOURCE FILE.\n");
    printf("A    APPEND TO AN EXISTING SOURCE FILE.\n");
    printf("E    EDIT AN EXISTING SOURCE FILE.\n");
    printf("D    DUPLICATE A SOURCE FILE.\n");
    printf("S    SHRINK/EXPAND A SOURCE FILE\n");
    printf("M    MERGE TWO FILES\n");
    printf("(CR) EXIT FROM EDITOR.\n");
}

static void cmd_create(void)
{
    char name[LINELEN];
    printf("NAME THE NEW ADM SOURCE FILE\n");
    if (!getline_p("", name, sizeof(name))) return;
    upcase(name);
    if (!valid_filename(name)) {
        printf("NAME MUST BE 1-8 ALPHANUMERIC, BEGIN WITH A LETTER\n");
        return;
    }
    buf_clear();
    printf("%s READY FOR INPUT\n", name);
    enter_lines(2);
    buf_save(name);
    printf("%s SAVED\n", name);
}

static void cmd_append(void)
{
    char name[LINELEN];
    printf("WHAT IS THE NAME OF THE FILE TO WHICH YOU WISH TO APPEND?\n");
    if (!getline_p("", name, sizeof(name))) return;
    upcase(name);
    if (buf_load(name) < 0) { printf("FILE NOT FOUND\n"); return; }
    printf("%s READY FOR INPUT\n", name);
    enter_lines(last_dispno() + 1);
    buf_save(name);
    printf("%s SAVED\n", name);
}

static void cmd_edit(void)
{
    char name[LINELEN];
    int  recs;
    if (!getline_p("EDIT WHAT FILE ? ", name, sizeof(name))) return;
    upcase(name);
    recs = buf_load(name);
    if (recs < 0) { printf("FILE NOT FOUND\n"); return; }
    printf("%d RECORDS ON FILE %s\n", recs, name);
    edit_mode(name);
}

static void cmd_duplicate(void)
{
    char nw[LINELEN], old[LINELEN];
    int  recs;
    getline_p("NEW FILE NAME  ? ", nw, sizeof(nw));   upcase(nw);
    getline_p("OLD FILE NAME  ? ", old, sizeof(old)); upcase(old);
    recs = buf_load(old);
    if (recs < 0) { printf("FILE NOT FOUND\n"); return; }
    buf_save(nw);
    printf("DUPLICATING %s TO %s   RECORD COUNT = %d\n", old, nw, recs);
}

static void cmd_shrink(void)
{
    char name[LINELEN];
    if (!getline_p("FILE NAME ? ", name, sizeof(name))) return;
    upcase(name);
    if (buf_load(name) < 0) { printf("FILE NOT FOUND\n"); return; }
    printf("THERE ARE %d RECORDS ON FILE %s\n", last_dispno() - 1, name);
    printf("FILE %s HAS BEEN COMPACTED\n", name);
    buf_save(name);
}

/* merge lines L1..L2 of file1 into file2 after a given line */
static void cmd_merge(void)
{
    char file1[LINELEN], file2[LINELEN], arg[LINELEN];
    char **seg;
    int  l1, l2, after, i, segn = 0, recs2, segcap;

    getline_p("SOURCE VOLUME 'XXXX' ? ", file1, sizeof(file1)); upcase(file1);
    if (buf_load(file1) < 0) { printf("FILE NOT FOUND\n"); return; }
    getline_p("TAKE DATA BETWEEN LINES 'L1' & 'L2' (L1,L2) ? ", arg, sizeof(arg));
    if (sscanf(arg, "%d,%d", &l1, &l2) < 2) { printf("BAD RANGE\n"); return; }
    segcap = (l2 >= l1) ? (l2 - l1 + 1) : 1;
    seg = (char **)malloc((unsigned)segcap * sizeof(char *));
    if (!seg) { printf("OUT OF MEMORY\n"); return; }
    for (i = l1; i <= l2; i++) {
        int x = idx_of(i);
        if (x >= 0) seg[segn++] = xstrdup(gl_lines[x]);
    }

    getline_p("DESTINATION FILE ? ", file2, sizeof(file2)); upcase(file2);
    recs2 = buf_load(file2);
    if (recs2 < 0) { printf("FILE NOT FOUND\n"); free(seg); return; }
    getline_p("MERGE AFTER LINE 'L' ? ", arg, sizeof(arg));
    after = atoi(arg);
    printf("FILE %s CONTAINS %d RECORDS\n", file2, recs2);
    printf("WRITING DATA INTO FILE %s\n", file2);
    for (i = 0; i < segn; i++) {
        buf_insert(after + 1 + i, seg[i]);
        free(seg[i]);
    }
    free(seg);
    buf_save(file2);
    printf("MERGE COMPLETE\n");
    printf("FILE %s NOW CONTAINS %d RECORDS\n", file2, last_dispno() - 1);
}

static void assedit(void)
{
    char in[LINELEN];
    assedit_menu();
    for (;;) {
        if (!getline_p("? ", in, sizeof(in))) return;
        if (in[0] == '\0') return;                 /* CR -> exit            */
        switch (toupper((unsigned char)in[0])) {
        case 'C': cmd_create();    break;
        case 'A': cmd_append();    break;
        case 'E': cmd_edit();      break;
        case 'D': cmd_duplicate(); break;
        case 'S': cmd_shrink();    break;
        case 'M': cmd_merge();     break;
        default:  printf("CMD ERR -- TYPE A LISTED COMMAND\n"); break;
        }
        assedit_menu();
    }
}

/* ====================================================================== */
/*  6800 ASSEMBLER                                                        */
/* ====================================================================== */

#define M_NONE 0
#define M_INH  1                 /* inherent / accumulator, 1 byte         */
#define M_IMM  2                 /* immediate                              */
#define M_DIR  3                 /* direct (zero page)                     */
#define M_IND  4                 /* indexed  n,X                           */
#define M_EXT  5                 /* extended                               */
#define M_REL  6                 /* relative branch                        */

#define NOOP   (-1)
#define F_IMM16 1                /* immediate operand is 16 bits           */

typedef struct {
    char  mnem[6];
    short inh, imm, dir, ind, ext, rel;
    short flags;
} OPC;

/* Standard MC6800 opcode table (opcodes in hex).  -1 = mode unavailable. */
static OPC optab[] = {
 /* mnem   inh   imm   dir   ind   ext   rel  flags */
 {"ABA", 0x1B, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"ADCA",NOOP, 0x89, 0x99, 0xA9, 0xB9, NOOP, 0},
 {"ADCB",NOOP, 0xC9, 0xD9, 0xE9, 0xF9, NOOP, 0},
 {"ADDA",NOOP, 0x8B, 0x9B, 0xAB, 0xBB, NOOP, 0},
 {"ADDB",NOOP, 0xCB, 0xDB, 0xEB, 0xFB, NOOP, 0},
 {"ANDA",NOOP, 0x84, 0x94, 0xA4, 0xB4, NOOP, 0},
 {"ANDB",NOOP, 0xC4, 0xD4, 0xE4, 0xF4, NOOP, 0},
 {"ASL", NOOP, NOOP, NOOP, 0x68, 0x78, NOOP, 0},
 {"ASLA",0x48, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"ASLB",0x58, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"ASR", NOOP, NOOP, NOOP, 0x67, 0x77, NOOP, 0},
 {"ASRA",0x47, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"ASRB",0x57, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"BCC", NOOP, NOOP, NOOP, NOOP, NOOP, 0x24, 0},
 {"BCS", NOOP, NOOP, NOOP, NOOP, NOOP, 0x25, 0},
 {"BEQ", NOOP, NOOP, NOOP, NOOP, NOOP, 0x27, 0},
 {"BGE", NOOP, NOOP, NOOP, NOOP, NOOP, 0x2C, 0},
 {"BGT", NOOP, NOOP, NOOP, NOOP, NOOP, 0x2E, 0},
 {"BHI", NOOP, NOOP, NOOP, NOOP, NOOP, 0x22, 0},
 {"BITA",NOOP, 0x85, 0x95, 0xA5, 0xB5, NOOP, 0},
 {"BITB",NOOP, 0xC5, 0xD5, 0xE5, 0xF5, NOOP, 0},
 {"BLE", NOOP, NOOP, NOOP, NOOP, NOOP, 0x2F, 0},
 {"BLS", NOOP, NOOP, NOOP, NOOP, NOOP, 0x23, 0},
 {"BLT", NOOP, NOOP, NOOP, NOOP, NOOP, 0x2D, 0},
 {"BMI", NOOP, NOOP, NOOP, NOOP, NOOP, 0x2B, 0},
 {"BNE", NOOP, NOOP, NOOP, NOOP, NOOP, 0x26, 0},
 {"BPL", NOOP, NOOP, NOOP, NOOP, NOOP, 0x2A, 0},
 {"BRA", NOOP, NOOP, NOOP, NOOP, NOOP, 0x20, 0},
 {"BSR", NOOP, NOOP, NOOP, NOOP, NOOP, 0x8D, 0},
 {"BVC", NOOP, NOOP, NOOP, NOOP, NOOP, 0x28, 0},
 {"BVS", NOOP, NOOP, NOOP, NOOP, NOOP, 0x29, 0},
 {"CBA", 0x11, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"CLC", 0x0C, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"CLI", 0x0E, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"CLR", NOOP, NOOP, NOOP, 0x6F, 0x7F, NOOP, 0},
 {"CLRA",0x4F, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"CLRB",0x5F, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"CLV", 0x0A, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"CMPA",NOOP, 0x81, 0x91, 0xA1, 0xB1, NOOP, 0},
 {"CMPB",NOOP, 0xC1, 0xD1, 0xE1, 0xF1, NOOP, 0},
 {"COM", NOOP, NOOP, NOOP, 0x63, 0x73, NOOP, 0},
 {"COMA",0x43, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"COMB",0x53, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"CPX", NOOP, 0x8C, 0x9C, 0xAC, 0xBC, NOOP, F_IMM16},
 {"DAA", 0x19, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"DEC", NOOP, NOOP, NOOP, 0x6A, 0x7A, NOOP, 0},
 {"DECA",0x4A, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"DECB",0x5A, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"DES", 0x34, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"DEX", 0x09, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"EORA",NOOP, 0x88, 0x98, 0xA8, 0xB8, NOOP, 0},
 {"EORB",NOOP, 0xC8, 0xD8, 0xE8, 0xF8, NOOP, 0},
 {"INC", NOOP, NOOP, NOOP, 0x6C, 0x7C, NOOP, 0},
 {"INCA",0x4C, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"INCB",0x5C, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"INS", 0x31, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"INX", 0x08, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"JMP", NOOP, NOOP, NOOP, 0x6E, 0x7E, NOOP, 0},
 {"JSR", NOOP, NOOP, NOOP, 0xAD, 0xBD, NOOP, 0},
 {"LDAA",NOOP, 0x86, 0x96, 0xA6, 0xB6, NOOP, 0},
 {"LDAB",NOOP, 0xC6, 0xD6, 0xE6, 0xF6, NOOP, 0},
 {"LDS", NOOP, 0x8E, 0x9E, 0xAE, 0xBE, NOOP, F_IMM16},
 {"LDX", NOOP, 0xCE, 0xDE, 0xEE, 0xFE, NOOP, F_IMM16},
 {"LSR", NOOP, NOOP, NOOP, 0x64, 0x74, NOOP, 0},
 {"LSRA",0x44, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"LSRB",0x54, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 /* LSL / LSLA / LSLB are synonyms for ASL / ASLA / ASLB */
 {"LSL", NOOP, NOOP, NOOP, 0x68, 0x78, NOOP, 0},
 {"LSLA",0x48, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"LSLB",0x58, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"NEG", NOOP, NOOP, NOOP, 0x60, 0x70, NOOP, 0},
 {"NEGA",0x40, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"NEGB",0x50, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"NOP", 0x01, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"ORAA",NOOP, 0x8A, 0x9A, 0xAA, 0xBA, NOOP, 0},
 {"ORAB",NOOP, 0xCA, 0xDA, 0xEA, 0xFA, NOOP, 0},
 {"PSHA",0x36, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"PSHB",0x37, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"PULA",0x32, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"PULB",0x33, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"ROL", NOOP, NOOP, NOOP, 0x69, 0x79, NOOP, 0},
 {"ROLA",0x49, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"ROLB",0x59, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"ROR", NOOP, NOOP, NOOP, 0x66, 0x76, NOOP, 0},
 {"RORA",0x46, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"RORB",0x56, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"RTI", 0x3B, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"RTS", 0x39, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"SBA", 0x10, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"SBCA",NOOP, 0x82, 0x92, 0xA2, 0xB2, NOOP, 0},
 {"SBCB",NOOP, 0xC2, 0xD2, 0xE2, 0xF2, NOOP, 0},
 {"SEC", 0x0D, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"SEI", 0x0F, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"SEV", 0x0B, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"STAA",NOOP, NOOP, 0x97, 0xA7, 0xB7, NOOP, 0},
 {"STAB",NOOP, NOOP, 0xD7, 0xE7, 0xF7, NOOP, 0},
 {"STS", NOOP, NOOP, 0x9F, 0xAF, 0xBF, NOOP, 0},
 {"STX", NOOP, NOOP, 0xDF, 0xEF, 0xFF, NOOP, 0},
 {"SUBA",NOOP, 0x80, 0x90, 0xA0, 0xB0, NOOP, 0},
 {"SUBB",NOOP, 0xC0, 0xD0, 0xE0, 0xF0, NOOP, 0},
 {"SWI", 0x3F, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"TAB", 0x16, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"TAP", 0x06, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"TBA", 0x17, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"TPA", 0x07, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"TST", NOOP, NOOP, NOOP, 0x6D, 0x7D, NOOP, 0},
 {"TSTA",0x4D, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"TSTB",0x5D, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"TSX", 0x30, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"TXS", 0x35, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"WAI", 0x3E, NOOP, NOOP, NOOP, NOOP, NOOP, 0},
 {"",    NOOP, NOOP, NOOP, NOOP, NOOP, NOOP, 0}
};

static OPC *find_opc(const char *m)
{
    int i;
    for (i = 0; optab[i].mnem[0]; i++)
        if (strcmp(optab[i].mnem, m) == 0) return &optab[i];
    return NULL;
}

/* ---- symbol table ---------------------------------------------------- */
typedef struct { char name[NAMELEN]; long val; int defined; } SYM;
static SYM *symtab;              /* malloc'd: MAXSYM entries               */
static int nsym;

static SYM *sym_find(const char *name)
{
    int i;
    for (i = 0; i < nsym; i++)
        if (strcmp(symtab[i].name, name) == 0) return &symtab[i];
    return NULL;
}

static int sym_define(const char *name, long val)
{
    SYM *s = sym_find(name);
    if (s) {
        if (s->defined) return -1;     /* already exists */
        s->val = val; s->defined = 1;
        return 0;
    }
    if (nsym >= MAXSYM) return -2;
    strncpy(symtab[nsym].name, name, NAMELEN - 1);
    symtab[nsym].name[NAMELEN - 1] = '\0';
    symtab[nsym].val = val;
    symtab[nsym].defined = 1;
    nsym++;
    return 0;
}

/* ---- expression evaluator -------------------------------------------- *
 * Supports: $hex  %binary  'c char  decimal  symbol  *(=loc counter)
 *           binary + and - between terms, left to right, optional sign.   *
 * Returns 1 if fully resolved, 0 if an undefined symbol was referenced.   */
static int eval(const char *s, WORD loc, long *out)
{
    long acc = 0, term;
    int  op = '+', resolved = 1, any = 0;
    char tok[NAMELEN];
    const char *p = s;

    while (*p) {
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '+' || *p == '-') { op = *p++; continue; }
        if (*p == '\0') break;
        term = 0;
        any = 1;
        if (*p == '*') {
            term = (long)loc; p++;
        } else if (*p == '$') {
            p++;
            while (isxdigit((unsigned char)*p)) {
                int d = isdigit((unsigned char)*p) ? *p - '0'
                        : (toupper((unsigned char)*p) - 'A' + 10);
                term = term * 16 + d; p++;
            }
        } else if (*p == '%') {
            p++;
            while (*p == '0' || *p == '1') { term = term * 2 + (*p - '0'); p++; }
        } else if (*p == '\'') {
            p++;
            if (*p) { term = (unsigned char)*p; p++; }
        } else if (isdigit((unsigned char)*p)) {
            while (isdigit((unsigned char)*p)) { term = term * 10 + (*p - '0'); p++; }
        } else if (isalpha((unsigned char)*p) || *p == '_' || *p == '.') {
            int n = 0;
            while ((isalnum((unsigned char)*p) || *p == '_' || *p == '.') &&
                   n < NAMELEN - 1) tok[n++] = (char)toupper((unsigned char)*p++);
            tok[n] = '\0';
            { SYM *sy = sym_find(tok);
              if (sy && sy->defined) term = sy->val;
              else resolved = 0; }
        } else {
            p++;             /* skip stray character */
            continue;
        }
        if (op == '+') acc += term; else acc -= term;
    }
    if (!any) resolved = 0;
    *out = acc & 0xFFFFL;
    return resolved;
}

/* ---- parse a source line into label / mnemonic / operand ------------- *
 * Column 1 non-blank, non-'*' => label.  '*' in column 1 => comment.      */
static void parse_line(const char *src, char *lab, char *mn, char *opnd)
{
    const char *p = src;
    int n;
    lab[0] = mn[0] = opnd[0] = '\0';
    if (*p == '*' || *p == ';') return;            /* full-line comment    */

    if (*p && *p != ' ' && *p != '\t') {           /* label in column 1    */
        n = 0;
        while (*p && *p != ' ' && *p != '\t' && n < NAMELEN - 1)
            lab[n++] = (char)toupper((unsigned char)*p++);
        lab[n] = '\0';
        if (n > 0 && lab[n-1] == ':') lab[n-1] = '\0';  /* allow trailing : */
    }
    while (*p == ' ' || *p == '\t') p++;
    n = 0;                                          /* mnemonic             */
    while (*p && *p != ' ' && *p != '\t' && n < NAMELEN - 1)
        mn[n++] = (char)toupper((unsigned char)*p++);
    mn[n] = '\0';
    while (*p == ' ' || *p == '\t') p++;
    n = 0;                                          /* operand field        */
    /* Data directives (FCC and the byte/word lists FCB/DB, FDB/DW) may
     * contain quoted strings with embedded spaces, so for these we keep
     * the rest of the line verbatim instead of stopping at the first space.
     * A trailing comment introduced by an unquoted ';' is dropped. */
    if (strcmp(mn, "FCC") == 0 || strcmp(mn, "FCB") == 0 ||
        strcmp(mn, "DB")  == 0 || strcmp(mn, "FDB") == 0 ||
        strcmp(mn, "DW")  == 0) {
        int in_quote = 0; char q = 0;
        while (*p && n < LINELEN - 1) {
            if (in_quote) {
                if (*p == q) in_quote = 0;
            } else {
                if (*p == '"' || *p == '\'') { in_quote = 1; q = *p; }
                else if (*p == ';') break;          /* start of comment    */
            }
            opnd[n++] = *p++;
        }
        /* strip trailing whitespace left before a dropped comment */
        while (n > 0 && (opnd[n-1] == ' ' || opnd[n-1] == '\t')) n--;
    } else {
        while (*p && *p != ' ' && *p != '\t' && n < LINELEN - 1)
            opnd[n++] = *p++;
    }
    opnd[n] = '\0';
}

/* Count the bytes an FCB/DB (or, *2, FDB/DW) operand list will emit.
 * This MUST agree byte-for-byte with the pass-2 emitter below, including
 * backslash escape collapsing inside quoted strings, or every following
 * address will be wrong.  Items are comma-separated; a quoted "..." or
 * '...' contributes one byte per (post-escape) character, a bare term
 * contributes one byte. */
static int count_items(const char *s)
{
    int  n = 0;
    const char *p = s;

    while (*p == ' ' || *p == '\t') p++;
    if (*p == '\0') return 0;

    for (;;) {
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '"' || *p == '\'') {        /* quoted string item        */
            char delim = *p++;
            while (*p && *p != delim) {
                if (*p == '\\' && *(p+1)) p++; /* escape -> one byte        */
                n++; p++;
            }
            if (*p == delim) p++;
            while (*p && *p != ',') p++;        /* skip to separator         */
        } else {                                /* bare numeric/label item   */
            while (*p && *p != ',') p++;
            n++;
        }
        if (*p == ',') { p++; continue; }
        break;
    }
    return n;
}

/* split an indexed operand "expr,X" -> returns 1 and copies expr; else 0 */
static int is_indexed(const char *opnd, char *expr)
{
    int n = (int)strlen(opnd);
    if (n >= 2 && (opnd[n-1] == 'X' || opnd[n-1] == 'x') && opnd[n-2] == ',') {
        strncpy(expr, opnd, n - 2);
        expr[n - 2] = '\0';
        return 1;
    }
    return 0;
}

/* assembled-line record produced by pass 1 (kept small: no text copies,
 * pass 2 re-parses the source line from the buffer) */
typedef struct {
    int           dispno;
    WORD          addr;
    unsigned char mode;          /* M_* */
    unsigned char is_dir;        /* DIR_* */
    short         size;          /* object bytes */
    OPC          *op;
} ALINE;

#define DIR_NONE 0
#define DIR_ORG  1
#define DIR_EQU  2
#define DIR_FCB  3
#define DIR_FDB  4
#define DIR_FCC  5
#define DIR_RMB  6
#define DIR_END  7

static int directive_of(const char *mn)
{
    if (!strcmp(mn, "ORG")) return DIR_ORG;
    if (!strcmp(mn, "EQU")) return DIR_EQU;
    if (!strcmp(mn, "FCB")) return DIR_FCB;
    if (!strcmp(mn, "DB"))  return DIR_FCB;   /* DB = define byte  (FCB)  */
    if (!strcmp(mn, "FDB")) return DIR_FDB;
    if (!strcmp(mn, "DW"))  return DIR_FDB;   /* DW = define word  (FDB)  */
    if (!strcmp(mn, "FCC")) return DIR_FCC;
    if (!strcmp(mn, "RMB")) return DIR_RMB;
    if (!strcmp(mn, "END")) return DIR_END;
    return DIR_NONE;
}

static int fcc_len(const char *opnd)
{
    char delim;
    const char *p = opnd;
    int n = 0;
    if (!*p) return 0;
    delim = *p++;
    while (*p && *p != delim) { n++; p++; }
    return n;
}

/* ---- the two passes -------------------------------------------------- */

static ALINE *prog;              /* malloc'd: MAXLINES entries             */
static int   nprog;
static int   err_count;
static WORD  start_addr;
static int   have_start;

static void emit_err(FILE *lst, int dispno, const char *msg, const char *what)
{
    char line[160];
    int x = idx_of(dispno);
    const char *src = (x >= 0) ? gl_lines[x] : "";
    
    if (what && *what) sprintf(line, "*** ERROR (LINE %d): %s - %s", dispno, msg, what);
    else               sprintf(line, "*** ERROR (LINE %d): %s", dispno, msg);
    
    printf("%s\n", line);
    if (lst) {
        fprintf(lst, "%s\n", line);
        fprintf(lst, "    SOURCE: %s\n", src);
        fprintf(lst, "\n");
    }
    err_count++;
}

/* PASS 1: build symbol table and size every line */
static void pass1(void)
{
    char lab[NAMELEN], mn[NAMELEN], opnd[LINELEN], ex[LINELEN];
    int  i, dir;
    long v;
    WORD loc = 0;
    OPC *op;

    nprog = 0; nsym = 0; err_count = 0; have_start = 0;

    for (i = 2; i <= last_dispno(); i++) {
        int x = idx_of(i);
        ALINE *a;
        const char *src = (x >= 0) ? gl_lines[x] : "";

        if (nprog >= MAXLINES) break;
        a = &prog[nprog++];
        a->dispno = i; a->addr = loc; a->mode = M_NONE; a->size = 0;
        a->op = NULL; a->is_dir = DIR_NONE;

        parse_line(src, lab, mn, opnd);

        if (mn[0] == '\0') {                 /* blank / comment / label only */
            if (lab[0]) {
                if (sym_define(lab, (long)loc) == -1)
                    emit_err(NULL, i, "LABEL ALREADY EXISTS", lab);
            }
            continue;
        }

        dir = directive_of(mn);

        /* EQU defines its label from the operand, not from loc */
        if (dir == DIR_EQU) {
            a->is_dir = DIR_EQU;
            if (!eval(opnd, loc, &v))
                emit_err(NULL, i, "OPERAND NOT FOUND", opnd);
            if (lab[0] && sym_define(lab, v) == -1)
                emit_err(NULL, i, "LABEL ALREADY EXISTS", lab);
            continue;
        }

        /* every other line: a leading label takes the current address */
        if (lab[0]) {
            if (sym_define(lab, (long)loc) == -1)
                emit_err(NULL, i, "LABEL ALREADY EXISTS", lab);
        }

        if (dir != DIR_NONE) {
            a->is_dir = dir;
            switch (dir) {
            case DIR_ORG:
                if (!eval(opnd, loc, &v))
                    emit_err(NULL, i, "OPERAND NOT FOUND", opnd);
                loc = (WORD)(v & 0xFFFF);
                a->addr = loc;
                if (!have_start) { start_addr = loc; have_start = 1; }
                break;
            case DIR_FCB: a->size = count_items(opnd);       break;
            case DIR_FDB: a->size = count_items(opnd) * 2;   break;
            case DIR_FCC: a->size = fcc_len(opnd);           break;
            case DIR_RMB:
                if (!eval(opnd, loc, &v))
                    emit_err(NULL, i, "OPERAND NOT FOUND", opnd);
                a->size = (int)v;
                break;
            case DIR_END: a->size = 0;                       break;
            default: break;
            }
            loc = (WORD)((loc + a->size) & 0xFFFF);
            continue;
        }

        /* a machine instruction */
        op = find_opc(mn);
        if (!op) { emit_err(NULL, i, "INSTRUCTION NOT FOUND", mn); a->size = 1; loc++; continue; }
        a->op = op;

        if (op->rel != NOOP) {                    /* branch                */
            a->mode = M_REL; a->size = 2;
        } else if (op->inh != NOOP) {             /* inherent: ignore any   */
            a->mode = M_INH; a->size = 1;         /* trailing comment text  */
        } else if (opnd[0] == '\0') {             /* needs an operand        */
            emit_err(NULL, i, "OPERAND MISSING IN SOURCE STATEMENT", mn);
            a->mode = M_INH; a->size = 1;
        } else if (opnd[0] == '#') {              /* immediate             */
            a->mode = M_IMM; a->size = (op->flags & F_IMM16) ? 3 : 2;
        } else if (is_indexed(opnd, ex)) {        /* indexed n,X           */
            a->mode = M_IND; a->size = 2;
        } else {                                  /* direct or extended    */
            int resolved = eval(opnd, loc, &v);
            if (op->dir != NOOP && resolved && v >= 0 && v <= 0xFF) {
                a->mode = M_DIR; a->size = 2;
            } else {
                a->mode = M_EXT; a->size = 3;     /* fwd ref defaults EXT  */
            }
        }
        if (!have_start) { start_addr = loc; have_start = 1; }
        loc = (WORD)((loc + a->size) & 0xFFFF);
    }
}

/* S-record output state */
static FILE *srec;
static BYTE  srbuf[32];
static int   srn;
static WORD  sraddr;

/* Binary output state.
 * The buffer is indexed by OFFSET from the program origin, not by absolute
 * address.  This keeps the buffer small enough for Turbo C (no >64K static
 * array) yet still captures high ROM addresses such as the ADM-31 plugin
 * slot at $E000-$E7FF.  A 32K window covers any single 6800 ROM image. */
static FILE *binfile;
static BYTE  binbuf[32768];     /* 32K window, indexed by (addr - bin_base) */
static long  bin_base;          /* absolute address that maps to binbuf[0] */
static long  bin_min_addr;      /* long: addresses exceed 16-bit signed int */
static long  bin_max_addr;

static void srec_flush(void)
{
    int i, sum, cnt;
    if (!srec || srn == 0) return;
    cnt = srn + 3;                       /* addr(2) + data + checksum(1)   */
    fprintf(srec, "S1%02X%04X", cnt, sraddr & 0xFFFF);
    sum = cnt + ((sraddr >> 8) & 0xFF) + (sraddr & 0xFF);
    for (i = 0; i < srn; i++) { fprintf(srec, "%02X", srbuf[i]); sum += srbuf[i]; }
    fprintf(srec, "%02X\n", (~sum) & 0xFF);
    srn = 0;
}

static void srec_byte(WORD addr, BYTE b)
{
    if (!srec) return;
    if (srn > 0 && (sraddr + srn) != addr) srec_flush();
    if (srn == 0) sraddr = addr;
    if (srn >= 16) { srec_flush(); sraddr = addr; }
    srbuf[srn++] = b;
}

static void srec_end(WORD start)
{
    int sum;
    srec_flush();
    if (!srec) return;
    sum = 3 + ((start >> 8) & 0xFF) + (start & 0xFF);
    fprintf(srec, "S903%04X%02X\n", start & 0xFFFF, (~sum) & 0xFF);
}

/* Binary output: collect bytes during assembly.
 * Stored at binbuf[addr - bin_base], so absolute addresses anywhere in the
 * 64K space are captured as long as the whole image fits in a 32K window. */
static void bin_byte(WORD addr, BYTE b)
{
    long off;
    if (!binfile) return;
    off = (long)addr - bin_base;
    if (off < 0 || off >= 32768L) return;   /* outside the 32K window */
    binbuf[off] = b;
    if (bin_min_addr > (long)addr) bin_min_addr = (long)addr;
    if (bin_max_addr < (long)addr) bin_max_addr = (long)addr;
}

/* Binary output: write collected bytes to file */
static void bin_flush(void)
{
    long i;
    if (!binfile || bin_min_addr > bin_max_addr) return;

    /* Write from min to max address, indexed by offset from base */
    for (i = bin_min_addr; i <= bin_max_addr; i++) {
        fputc(binbuf[i - bin_base], binfile);
    }
}

/* format up to 4 object bytes for the listing CODE column */
static void code_str(char *dst, BYTE *b, int n)
{
    int i, k = 0;
    dst[0] = '\0';
    for (i = 0; i < n && i < 4; i++) { sprintf(dst + k, "%02X ", b[i]); k += 3; }
    while (k < 12) dst[k++] = ' ';
    dst[k] = '\0';
}

/* PASS 2: generate object code and the assembly listing */
static void pass2(FILE *lst)
{
    int  i, j;
    long v;
    char code[16];
    BYTE ob[OBJMAX];
    int  nb;

    for (i = 0; i < nprog; i++) {
        ALINE *a = &prog[i];
        OPC *op = a->op;
        WORD here = a->addr;
        char ex[LINELEN];
        int  x = idx_of(a->dispno);
        const char *src = (x >= 0) ? gl_lines[x] : "";
        char lab[NAMELEN], mn[NAMELEN], opbuf[LINELEN];
        const char *opnd;

        parse_line(src, lab, mn, opbuf);
        opnd = opbuf;
        nb = 0;

        if (a->is_dir == DIR_EQU || a->is_dir == DIR_ORG ||
            a->is_dir == DIR_END || (a->op == NULL && a->is_dir == DIR_NONE)) {
            /* no object bytes (comment, label-only, EQU, ORG, END) */
            code_str(code, ob, 0);
            if (a->is_dir == DIR_EQU) {
                eval(opnd, here, &v);
                sprintf(code, "=%04lX     ", v & 0xFFFF);
            }
            printf("%04X  %s%5d  %s\n", here, code, a->dispno, src);
            if (lst) fprintf(lst, "%04X  %s%5d  %s\n", here, code, a->dispno, src);
            if (a->is_dir == DIR_END) break;
            continue;
        }

        if (a->is_dir == DIR_FCB) {
            char tmp[LINELEN]; const char *p = opnd; int k = 0;
            while (*p && nb < OBJMAX) {
                char *q = tmp; k = 0;
                
                /* Check for quoted string */
                if (*p == '"' || *p == '\'') {
                    char delim = *p++;
                    while (*p && *p != delim && nb < OBJMAX) {
                        if (*p == '\\' && *(p+1)) {
                            p++;
                            switch (*p) {
                            case 'n': ob[nb++] = 0x0A; break;
                            case 'r': ob[nb++] = 0x0D; break;
                            case 't': ob[nb++] = 0x09; break;
                            case '\\': ob[nb++] = 0x5C; break;
                            case '"': ob[nb++] = 0x22; break;
                            case '\'': ob[nb++] = 0x27; break;
                            default: ob[nb++] = (BYTE)*p; break;
                            }
                            p++;
                        } else {
                            ob[nb++] = (BYTE)*p++;
                        }
                    }
                    if (*p == delim) p++;
                    /* Skip to next comma or end */
                    while (*p && *p != ',') p++;
                    if (*p == ',') p++;
                } else {
                    /* Regular number/label operand */
                    while (*p && *p != ',') { tmp[k++] = *p++; }
                    tmp[k] = '\0'; if (*p == ',') p++;
                    if (!eval(tmp, here, &v)) emit_err(lst, a->dispno, "OPERAND NOT FOUND", tmp);
                    ob[nb++] = (BYTE)(v & 0xFF);
                }
                (void)q;
            }
        } else if (a->is_dir == DIR_FDB) {
            char tmp[LINELEN]; const char *p = opnd; int k;
            while (*p && nb < OBJMAX) {
                k = 0;
                while (*p && *p != ',') { tmp[k++] = *p++; }
                tmp[k] = '\0'; if (*p == ',') p++;
                if (!eval(tmp, here, &v)) emit_err(lst, a->dispno, "OPERAND NOT FOUND", tmp);
                ob[nb++] = (BYTE)((v >> 8) & 0xFF);
                ob[nb++] = (BYTE)(v & 0xFF);
            }
        } else if (a->is_dir == DIR_FCC) {
            const char *p = opnd; char delim;
            if (*p) { delim = *p++; while (*p && *p != delim && nb < OBJMAX) ob[nb++] = (BYTE)*p++; }
        } else if (a->is_dir == DIR_RMB) {
            /* reserve: emit no object, just advance the listing address */
            code_str(code, ob, 0);
            printf("%04X  %s%5d  %s\n", here, code, a->dispno, src);
            if (lst) fprintf(lst, "%04X  %s%5d  %s\n", here, code, a->dispno, src);
            continue;
        } else if (op) {
            /* machine instruction */
            switch (a->mode) {
            case M_INH:
                ob[nb++] = (BYTE)op->inh;
                break;
            case M_IMM:
                ob[nb++] = (BYTE)op->imm;
                if (!eval(opnd + 1, here, &v)) emit_err(lst, a->dispno, "OPERAND NOT FOUND", opnd+1);
                if (op->flags & F_IMM16) { ob[nb++] = (BYTE)((v>>8)&0xFF); ob[nb++] = (BYTE)(v&0xFF); }
                else { if (v < 0 || v > 0xFF) emit_err(lst, a->dispno, "VALUE OUT OF BOUNDS", opnd+1);
                       ob[nb++] = (BYTE)(v & 0xFF); }
                break;
            case M_DIR:
                ob[nb++] = (BYTE)op->dir;
                if (!eval(opnd, here, &v)) emit_err(lst, a->dispno, "OPERAND NOT FOUND", opnd);
                ob[nb++] = (BYTE)(v & 0xFF);
                break;
            case M_IND:
                ob[nb++] = (BYTE)op->ind;
                is_indexed(opnd, ex);
                if (ex[0] == '\0') v = 0;
                else if (!eval(ex, here, &v)) emit_err(lst, a->dispno, "OPERAND NOT FOUND", ex);
                ob[nb++] = (BYTE)(v & 0xFF);
                break;
            case M_EXT:
                if (op->ext == NOOP) { emit_err(lst, a->dispno, "OPERAND MISSING IN SOURCE STATEMENT", ""); break; }
                ob[nb++] = (BYTE)op->ext;
                if (!eval(opnd, here, &v)) emit_err(lst, a->dispno, "OPERAND NOT FOUND", opnd);
                ob[nb++] = (BYTE)((v >> 8) & 0xFF);
                ob[nb++] = (BYTE)(v & 0xFF);
                break;
            case M_REL: {
                long target, off;
                ob[nb++] = (BYTE)op->rel;
                if (opnd[0] == '\0') { emit_err(lst, a->dispno, "OPERAND MISSING IN SOURCE STATEMENT", ""); break; }
                if (!eval(opnd, here, &target)) emit_err(lst, a->dispno, "OPERAND NOT FOUND", opnd);
                off = target - ((long)here + 2);
                if (off < -128 || off > 127)
                    emit_err(lst, a->dispno, "BRANCH OUT OF RANGE", opnd);
                ob[nb++] = (BYTE)(off & 0xFF);
                break; }
            default: break;
            }
        }

        for (j = 0; j < nb; j++) {
            srec_byte((WORD)(here + j), ob[j]);
            bin_byte((WORD)(here + j), ob[j]);
        }
        code_str(code, ob, nb);
        printf("%04X  %s%5d  %s\n", here, code, a->dispno, src);
        if (lst) fprintf(lst, "%04X  %s%5d  %s\n", here, code, a->dispno, src);
    }
}

static void print_labels(FILE *lst)
{
    int i;
    printf("\nSYMBOL TABLE\n");
    if (lst) fprintf(lst, "\nSYMBOL TABLE\n");
    for (i = 0; i < nsym; i++) {
        printf("  %-8s %04lX\n", symtab[i].name, symtab[i].val & 0xFFFF);
        if (lst) fprintf(lst, "  %-8s %04lX\n", symtab[i].name, symtab[i].val & 0xFFFF);
    }
}

static char last_listing[LINELEN] = "";

/* ACP option 2: assemble a program (TURBO C FIX) */
static void do_assemble(void)
{
    char name[LINELEN], base[12], lst_name[LINELEN], obj_name[LINELEN], bin_name[LINELEN], ans[128];
    FILE *lst;

    if (!getline_p("SOURCE FILE NAME ? ", name, sizeof(name))) return;
    upcase(name);
    if (buf_load(name) < 0) { printf("FILE NOT FOUND\n"); return; }

    /* Derive an 8.3-safe output base from the source name: drop any drive
     * or directory prefix and any extension, keep at most 8 chars.  This
     * keeps the output as e.g. SINE.LST / SINE.S19 even when the source was
     * entered as SINE.ASM or C:\SRC\SINE.ASM, so the DOS file create works. */
    {
        int s, k = 0;
        for (s = 0; name[s]; s++)
            if (name[s] == ':' || name[s] == '\\' || name[s] == '/') k = s + 1;
        s = k; k = 0;
        while (name[s] && name[s] != '.' && k < 8) base[k++] = name[s++];
        base[k] = '\0';
    }
    if (base[0] == '\0') strcpy(base, "OUT");
    sprintf(lst_name, "%s.LST", base);
    sprintf(obj_name, "%s.S19", base);
    sprintf(bin_name, "%s.BIN", base);

    printf("\nASSEMBLY PASS 1\n");
    pass1();
    printf("PASS 1 COMPLETE\n");
    printf("LAST ADDRESS USED IS %04X\n",
           nprog ? (WORD)(prog[nprog-1].addr + prog[nprog-1].size) : 0);
    printf("ERROR COUNT = %d\n", err_count);

    getline_p("PRINT LABEL LIST (Y) ? ", ans, 128);
    upcase(ans);

    printf("\nCONTINUE WITH ASSEMBLY (Y) ? ");
    if (!getline_p("", ans, 128)) return;
    upcase(ans);
    if (ans[0] == 'N') { printf("ASSEMBLY ABORTED\n"); return; }

    lst  = fopen(lst_name, "w");
    if (!lst)  printf("*** CANNOT CREATE LISTING FILE %s (%s)\n",
                      lst_name, strerror(errno));
    srec = fopen(obj_name, "w");
    if (!srec) printf("*** CANNOT CREATE OBJECT FILE %s (%s)\n",
                      obj_name, strerror(errno));
    binfile = fopen(bin_name, "wb");
    if (!binfile) printf("*** CANNOT CREATE BINARY FILE %s (%s)\n",
                      bin_name, strerror(errno));
    srn = 0;
    bin_min_addr = 0xFFFFL;
    bin_max_addr = 0L;
    bin_base = have_start ? (long)start_addr : 0L;  /* binbuf[0] = origin */

    printf("\nINSTRUCTION CODE GENERATOR FOR 6800 ASSEMBLER\n\n");
    if (lst) {
        fprintf(lst, "ASSEMBLY LISTING - SOURCE FILE %s\n\n", name);
        fprintf(lst, "ADDR  CODE        LINE  SOURCE STATEMENT\n");
        fprintf(lst, "----  ----------  ----  ----------------\n");
    }
    printf("ADDR  CODE        LINE  SOURCE STATEMENT\n");
    printf("----  ----------  ----  ----------------\n");

    pass2(lst);
    print_labels(lst);

    printf("\n****** END OF ASSEMBLY ******\n");
    printf("ERROR COUNT = %d\n", err_count);

    if (lst) {
        fprintf(lst, "\n");
        fprintf(lst, "====================================================================\n");
        fprintf(lst, "ASSEMBLY SUMMARY\n");
        fprintf(lst, "====================================================================\n");
        fprintf(lst, "TOTAL ERRORS: %d\n", err_count);
        if (err_count == 0) {
            fprintf(lst, "STATUS: ASSEMBLY SUCCESSFUL - NO ERRORS\n");
        } else {
            fprintf(lst, "STATUS: ASSEMBLY FAILED - %d ERROR(S) FOUND\n", err_count);
            fprintf(lst, "\nNote: Review error messages above (marked with ***).\n");
            fprintf(lst, "Each error shows:\n");
            fprintf(lst, "  - Error type and details\n");
            fprintf(lst, "  - Line number\n");
            fprintf(lst, "  - Source statement that caused the error\n");
        }
        fprintf(lst, "====================================================================\n");
        fclose(lst);
        strcpy(last_listing, lst_name);
        printf("LISTING WRITTEN TO %s\n", lst_name);
    } else {
        printf("LISTING NOT WRITTEN\n");
    }
    if (srec) {
        srec_end(have_start ? start_addr : 0);
        fclose(srec); srec = NULL;
        printf("OBJECT (S-RECORD) WRITTEN TO %s\n", obj_name);
    } else {
        printf("OBJECT NOT WRITTEN\n");
    }
    if (binfile) {
        bin_flush();
        fclose(binfile); binfile = NULL;
        if (bin_min_addr <= bin_max_addr) {
            int actual_size = (int)(bin_max_addr - bin_min_addr + 1);
            printf("BINARY %04lX-%04lX WRITTEN TO %s (%d bytes)\n",
                   bin_min_addr & 0xFFFFL, bin_max_addr & 0xFFFFL,
                   bin_name, actual_size);
            
            /* Ask for padding (TURBO C FIX) */
            printf("\nPAD BINARY TO SIZE (0=none, 2048=2K ROM, other): ");
            if (getline_p("", ans, 128)) {
                int pad_size = atoi(ans);
                if (pad_size > 0 && pad_size > actual_size) {
                    FILE *padfile = fopen(bin_name, "wb");
                    if (padfile) {
                        long a;
                        int j;
                        /* Write original code (offset-indexed) */
                        for (a = bin_min_addr; a <= bin_max_addr; a++) {
                            fputc(binbuf[a - bin_base], padfile);
                        }
                        /* Pad with 0xFF */
                        for (j = actual_size; j < pad_size; j++) {
                            fputc(0xFF, padfile);
                        }
                        fclose(padfile);
                        printf("PADDED BINARY WRITTEN TO %s (%d bytes, padded to %d)\n",
                               bin_name, actual_size, pad_size);
                    }
                }
            }
        } else {
            printf("BINARY NOT WRITTEN (no code)\n");
        }
    } else {
        printf("BINARY NOT WRITTEN\n");
    }
#ifdef HAVE_GETCWD
    {
        char cwd[96];
        if (getcwd(cwd, sizeof(cwd)) != NULL)
            printf("(IN DIRECTORY %s)\n", cwd);
    }
#endif
}

/* ACP option 3: show the last assembler output file on the terminal */
static void show_listing(void)
{
    char name[LINELEN], line[LINELEN];
    FILE *f;
    if (last_listing[0]) strcpy(name, last_listing);
    else { if (!getline_p("LISTING FILE ? ", name, sizeof(name))) return; upcase(name); }
    f = fopen(name, "r");
    if (!f) { printf("FILE NOT FOUND\n"); return; }
    while (fgets(line, sizeof(line), f)) fputs(line, stdout);
    fclose(f);
}

/* ====================================================================== */
/*  ACP - Assembly Control Program (top-level shell)                      */
/* ====================================================================== */

static void acp_menu(void)
{
   printf("\n'ACP' AT YOUR SERVICE - CHOOSE YOUR OPTION.\n");
   printf("=============================================================\n");
   printf("1    SOURCE FILE EDITOR.\n");
   printf("2    ASSEMBLE PROGRAM.\n");
   printf("3    SHOW THE ASSEMBLER OUTPUT FILE ON THE TERMINAL\n");
   printf("4    END\n");
}

int main(void)
{
    char in[LINELEN];

    gl_lines = (char **)malloc((unsigned)MAXLINES * sizeof(char *));
    prog     = (ALINE *)malloc((unsigned)MAXLINES * sizeof(ALINE));
    symtab   = (SYM  *)malloc((unsigned)MAXSYM   * sizeof(SYM));
    if (!gl_lines || !prog || !symtab) {
        printf("OUT OF MEMORY - CANNOT START\n");
        return 1;
    }

    gl_count = 1;
    gl_lines[0] = xstrdup("");

{
        time_t      now = time(NULL);
        struct tm  *lt  = localtime(&now);
        char        datebuf[32];

        strftime(datebuf, sizeof datebuf, "%m/%d/%y", lt);   /* e.g. 06/20/26 */

        printf("\n");
        printf("\n");
        printf("ACCOUNT-ID: LSI01\n");
        printf("PASSWORD: XXXXX  %s \n", datebuf);
        printf("       GOOD DAY USER 4100  PORT 7\n");
        printf("           WELCOME TO THE WONDERFUL WORLD OF 'MICOS'\n");
        printf("*************************************************************\n");
        printf("BELIEVE NOTHING YOU HEAR, AND ONLY ONE HALF THAT YOU SEE\n");
        printf("*************************************************************\n");
        printf("##\n");
        printf("RUN'ACP'\n");
        printf("(ADM-ACP / ASSEDIT, MOTOROLA 6800 ASM)  V%s\n", ACP_VERSION);
        printf("=============================================================\n");
        printf("ENTER \"BYE\" AT THE ACP PROMPT TO DISCONNECT.\n");
    }

    for (;;) {
        acp_menu();
        if (!getline_p("...? ", in, sizeof(in))) break;
        rstrip(in);
        if (in[0] == '\0') continue;

        { char up[LINELEN]; strcpy(up, in); upcase(up);
          if (strcmp(up, "BYE") == 0) { printf("BYE: IDLE\n"); break; } }

        switch (in[0]) {
        case '1': assedit();      break;
        case '2': do_assemble();  break;
        case '3': show_listing(); break;
        case '4': printf("##\n"); printf("SIGNED OFF.\n"); return 0;
        default:  printf("INVALID OPTION - ENTER 1, 2, 3 OR 4\n"); break;
        }
    }
    return 0;
}
