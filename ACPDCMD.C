/* ========================================================================
 * ACPDCMD.C  -  see ACPDCMD.H.  Turns a raw .BIN back into ACP6800
 * source, exactly like the standalone ACPDIS CLI mode (same acpdisco_*
 * engine -- see ACPDISCO.H/.C, verified byte-for-byte round-trip-correct
 * independent of what origin is chosen) but populates the live editor
 * buffer instead of writing a file, so the result is immediately
 * editable, assembleable (F9), and emulatable (Ctrl-F9) in the same
 * session. Only linked into ACPDIS.EXE -- see ACPDCMD.H.
 * ====================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ACP.H"
#include "ACPWIN.H"
#include "ACPEDIT.H"
#include "ACPCMDS.H"     /* EMU_NSOCK/emu_addr/emu_label, confirm_discard() */
#include "ACPDISCO.H"
#include "ACPDCMD.H"

/* Builds a suggested output name from the input name: strips any
 * extension and appends .ASM, truncating to keep the base within 8.3. */
static void suggest_asm_name(const char *img_name, char *out)
{
    char base[LINELEN];
    char *dot;
    strncpy(base, img_name, LINELEN - 1);
    base[LINELEN - 1] = '\0';
    dot = strrchr(base, '.');
    if (dot) *dot = '\0';
    if (strlen(base) > 8) base[8] = '\0';
    sprintf(out, "%s.ASM", base);
}

static void emit_to_buffer(void *ctx, const char *line)
{
    (void)ctx;
    buf_append(line);
}

void do_disassemble_binary(void)
{
    char img_name[LINELEN], org_buf[16], suggested[LINELEN];
    WORD org;
    long n;
    int pick;
    static const char *const choices[] = {
        "Enter origin address",
        "Guess origin (try ROM A/B/C/D sockets)"
    };

    if (!confirm_discard()) return;

    img_name[0] = '\0';
    if (!dlg_file_browse(img_name, LINELEN - 1)) return;   /* cancelled */
    upcase(img_name);

    acpdisco_init();

    pick = dlg_pick("Disassemble Binary", choices, 2);
    if (pick < 0) return;

    if (pick == 0) {
        org_buf[0] = '\0';
        if (!dlg_input("Disassemble Binary", "Origin address (hex):", org_buf, 8))
            return;
        org = (WORD)strtol(org_buf, NULL, 16);
        disasm_progress_open(img_name);
        acpdisco_set_progress_hook(disasm_progress_update);
        n = acpdisco_load(img_name, org);
        if (n == 0) {
            acpdisco_set_progress_hook(NULL);
            disasm_progress_close();
            dlg_message("Disassemble Binary", "Could not read that file.");
            return;
        }
        acpdisco_try_org(org, n);
        acpdisco_set_progress_hook(NULL);
        disasm_progress_close();
    } else {
        int scores[EMU_NSOCK];
        char lines[EMU_NSOCK + 1][48];
        const char *lineptrs[EMU_NSOCK + 1];
        int i;

        disasm_progress_open(img_name);
        acpdisco_set_progress_hook(disasm_progress_update);
        org = acpdisco_guess_org(img_name, emu_addr, EMU_NSOCK, scores, &n);
        acpdisco_set_progress_hook(NULL);
        disasm_progress_close();
        if (org == 0xFFFF) { dlg_message("Disassemble Binary", "Could not read that file."); return; }
        for (i = 0; i < EMU_NSOCK; i++) {
            sprintf(lines[i], "%-16s %3d resolved%s", emu_label[i], scores[i],
                    emu_addr[i] == org ? "   <- best" : "");
            lineptrs[i] = lines[i];
        }
        sprintf(lines[EMU_NSOCK], "Using $%04X (highest self-reference count).", org);
        lineptrs[EMU_NSOCK] = lines[EMU_NSOCK];
        text_view("Guessed Origin", lineptrs, EMU_NSOCK + 1);
    }

    disasm_progress_open(img_name);
    acpdisco_set_progress_hook(disasm_progress_update);
    buf_clear();
    acpdisco_emit(org, n, img_name, 1, emit_to_buffer, NULL);
    acpdisco_set_progress_hook(NULL);
    disasm_progress_close();

    if (last_dispno() < 2) buf_append("");   /* guarantee one editable line,
                                               * matching editor_load()     */
    editor_goto_line(2);
    suggest_asm_name(img_name, suggested);
    strncpy(ed_filename, suggested, LINELEN - 1);
    ed_filename[LINELEN - 1] = '\0';
    ed_dirty = 1;              /* fresh content, not yet saved under this name */
    listing_valid = 0;
    compile_status = COMPILE_UNKNOWN;
    msg_clear();
}
