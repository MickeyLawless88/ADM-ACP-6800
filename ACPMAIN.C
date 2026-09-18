/* ========================================================================
 * ACPMAIN.C  -  ACPIDE main program: menu bar, File/Search/Run/Options/
 *               Help commands, and the main event loop.
 *
 * ACPIDE at a glance:
 *   F1  Help        F2  Save        F3  Open        F9  Assemble
 *   F10 Menu        F6  Switch window (Edit <-> Message)
 *   Ctrl-F9 Assemble + Emulate         Alt-X Exit
 *   Ctrl-L Toggle line numbers         Ctrl-D Toggle listing view
 *   Ctrl-B Toggle message window
 *
 * The Edit window operates on ACPCORE's line buffer directly, so Assemble
 * always assembles what's on screen, saved or not.  Run|Emulate spawns
 * ADMEMU.EXE (see ADMEMU.C) on the assembled .BIN, the same way Turbo C's
 * own Run command hands the screen to your program and returns to the IDE
 * when it exits.
 * ====================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <process.h>
#include <conio.h>

#include "ACP.H"
#include "ACPWIN.H"
#include "ACPEDIT.H"

enum {
    ID_NEW = 1, ID_OPEN, ID_SAVE, ID_SAVEAS, ID_EXIT,
    ID_FINDLINE, ID_FINDTEXT,
    ID_ASSEMBLE, ID_ASSEMBLE_RUN, ID_EMULATE_LAST, ID_CLEARMSG, ID_EMU_CONFIG,
    ID_VIEW_TABLES,
    ID_LISTWIDTH, ID_ABOUT, ID_TOGGLE_GUTTER, ID_TOGGLE_LISTING,
    ID_TOGGLE_LST, ID_TOGGLE_MSGWIN
};

static MENU_TOP tops[] = {
    { "File",    'F' },
    { "Search",  'S' },
    { "Run",     'R' },
    { "Options", 'O' },
    { "Help",    'H' }
};

static MENU_ITEM file_items[] = {
    { "New",        "",      'N', ID_NEW },
    { "Open...",    "F3",    'O', ID_OPEN },
    { "Save",       "F2",    'S', ID_SAVE },
    { "Save As...", "",      'A', ID_SAVEAS },
    { NULL,         NULL,     0,  0 },        /* separator */
    { "Exit",       "Alt-X", 'X', ID_EXIT }
};
static MENU_ITEM search_items[] = {
    { "Find Line...", "", 'L', ID_FINDLINE },
    { "Find Text...", "", 'T', ID_FINDTEXT }
};
static MENU_ITEM run_items[] = {
    { "Assemble",           "F9",      'A', ID_ASSEMBLE },
    { "Assemble+Emulate",   "Ctrl-F9", 'E', ID_ASSEMBLE_RUN },
    { "Emulate Last Build", "",        'L', ID_EMULATE_LAST },
    { "Configure Emulator...", "",     'F', ID_EMU_CONFIG },
    { "View Symbol/Xref Table", "",    'V', ID_VIEW_TABLES },
    { "Clear Messages",     "",        'C', ID_CLEARMSG }
};
static MENU_ITEM opt_items[] = {
    { "List Width...",      "",      'W', ID_LISTWIDTH },
    { "Line Numbers",       "^L",    'L', ID_TOGGLE_GUTTER },
    { "Listing View",       "^D",    'D', ID_TOGGLE_LISTING },
    { "Message Window",     "^B",    'M', ID_TOGGLE_MSGWIN },
    { "Generate .LST File", "",      'G', ID_TOGGLE_LST }
};
static MENU_ITEM help_items[] = {
    { "About ACPIDE...", "", 'A', ID_ABOUT }
};

static const MENU_ITEM *const item_arrays[] = {
    file_items, search_items, run_items, opt_items, help_items
};
static const int item_counts[] = {
    sizeof(file_items)   / sizeof(file_items[0]),
    sizeof(search_items) / sizeof(search_items[0]),
    sizeof(run_items)    / sizeof(run_items[0]),
    sizeof(opt_items)    / sizeof(opt_items[0]),
    sizeof(help_items)   / sizeof(help_items[0])
};
#define NTOPS (sizeof(tops) / sizeof(tops[0]))

static ASM_RESULT last_asm;    /* result of the most recent acp_assemble() */
static int        have_last_asm = 0;
static int        gen_lst_file = 1;   /* 1 = keep the .LST after Assemble;
                                        * always generated internally either
                                        * way (View Symbol/Xref needs it),
                                        * just deleted afterward when off   */

/* ---- small helpers -----------------------------------------------------*/

/* case-insensitive substring search (Turbo C's runtime has no standard
 * strcasestr) */
static const char *ci_strstr(const char *hay, const char *needle)
{
    int nlen = (int)strlen(needle);
    if (nlen == 0) return hay;
    for (; *hay; hay++) {
        int i;
        for (i = 0; i < nlen && hay[i]; i++)
            if (toupper((unsigned char)hay[i]) != toupper((unsigned char)needle[i])) break;
        if (i == nlen) return hay;
    }
    return NULL;
}

static void redraw_all(void)
{
    /* No full-screen blank here: the menu bar, edit window, message
     * window, and status line between them already cover every row
     * (1 + 15 + 8 + 1 = 25), so clearing first only adds a visible
     * blank flash before the real content lands -- this was the cause
     * of the flicker when scrolling, since every keypress runs through
     * here. */
    menu_strip_draw(tops, NTOPS);
    editor_draw();
    msg_draw();
    status_draw();
}

/* jumps the editor to the first message that refers to a source line --
 * used right after an Assemble that produced errors. */
static void editor_err_jump_first(void)
{
    int d = msg_first_err_dispno();
    if (d > 0) editor_goto_line(d);
}

/* ---- File commands -------------------------------------------------------*/

static int do_save_as(void)
{
    char name[LINELEN];
    name[0] = '\0';
    if (!dlg_input("Save As", "File name (8.3):", name, LINELEN - 1)) return 0;
    upcase(name);
    if (!valid_filename(name)) {
        dlg_message("Save As", "Invalid name -- 1-8 letters/digits, optional .ext");
        return 0;
    }
    if (editor_save(name) < 0) {
        dlg_message("Save As", "Could not write that file.");
        return 0;
    }
    return 1;
}

static int do_save(void)
{
    if (ed_filename[0] == '\0') return do_save_as();
    if (editor_save(ed_filename) < 0) {
        dlg_message("Save", "Could not write that file.");
        return 0;
    }
    return 1;
}

/* returns 1 if it's OK to proceed (buffer wasn't dirty, or the user chose
 * to save/discard); 0 if the user cancelled */
static int confirm_discard(void)
{
    int r;
    if (!ed_dirty) return 1;
    r = dlg_confirm("Confirm", "Buffer modified.  Save changes first?");
    if (r == 'Y') return do_save();
    if (r == 'N') return 1;
    return 0;
}

static void do_new(void)
{
    if (!confirm_discard()) return;
    editor_new();
    msg_clear();
}

static void do_open(void)
{
    char name[LINELEN];
    if (!confirm_discard()) return;
    name[0] = '\0';
    if (!dlg_file_browse(name, LINELEN - 1)) return;   /* cancelled */
    upcase(name);
    if (editor_load(name) < 0) {
        dlg_message("Open", "File not found.");
        return;
    }
    msg_clear();
}

/* ---- Search commands ------------------------------------------------- */

static void do_find_line(void)
{
    char buf[16];
    int n;
    buf[0] = '\0';
    if (!dlg_input("Find Line", "Line number:", buf, 10)) return;
    n = atoi(buf);
    if (n < 1) n = 1;
    editor_goto_line(n + 1);   /* n is the on-screen (1-based) line number;
                                * editor_goto_line() wants ACPCORE's
                                * internal dispno, which is one higher. */
}

static void do_find_text(void)
{
    static char last[LINELEN] = "";
    int i, n;
    if (!dlg_input("Find Text", "Search for:", last, LINELEN - 1)) return;
    if (!last[0]) return;

    n = last_dispno();
    for (i = 2; i <= n; i++) {
        int idx = idx_of(i);
        if (idx >= 0 && gl_lines[idx] && ci_strstr(gl_lines[idx], last)) {
            editor_goto_line(i);
            return;
        }
    }
    dlg_message("Find Text", "Not found.");
}

/* ---- Run commands ------------------------------------------------------*/

/* ---- Emulator ROM-socket configuration -----------------------------------
 * The four ADM-31 plugin sockets ADMEMU understands, fixed by hardware:
 * A=$E000, B=$E800, C=$F000, D=$F800.  A blank filename means "nothing
 * fixed here" -- and whichever slot is blank when Run|Emulate fires is
 * where the just-assembled binary gets loaded (and, since there's no
 * guarantee of a valid reset vector without a full ROM set, where
 * execution starts directly). If more than one slot is blank, the first
 * in A/B/C/D order is used as the target and the rest are simply left
 * unloaded. */
#define EMU_NSOCK 4
static char emu_rom[EMU_NSOCK][LINELEN] = { "", "", "", "" };
static const char *emu_flag[EMU_NSOCK] = { "--romA", "--romB", "--romC", "--romD" };
static const char *emu_label[EMU_NSOCK] = { "ROM A ($E000)", "ROM B ($E800)",
                                             "ROM C ($F000)", "ROM D ($F800)" };
static const WORD emu_addr[EMU_NSOCK] = { 0xE000, 0xE800, 0xF000, 0xF800 };

static void do_configure_emulator(void)
{
    int i;
    char buf[LINELEN];
    char summary[4 * LINELEN + 32];

    for (i = 0; i < EMU_NSOCK; i++) {
        char prompt[64];
        sprintf(prompt, "%s file (blank = target for the assembled binary):",
                emu_label[i]);
        strcpy(buf, emu_rom[i]);
        if (dlg_input("Configure Emulator", prompt, buf, LINELEN - 1)) {
            upcase(buf);
            strcpy(emu_rom[i], buf);
        }
        /* Esc on a field just leaves it as it was and moves to the next. */
    }

    sprintf(summary, "A:%s  B:%s  C:%s  D:%s",
            emu_rom[0][0] ? emu_rom[0] : "(target)",
            emu_rom[1][0] ? emu_rom[1] : "(target)",
            emu_rom[2][0] ? emu_rom[2] : "(target)",
            emu_rom[3][0] ? emu_rom[3] : "(target)");
    dlg_message("Configure Emulator", summary);
}

static void do_emulate(const ASM_RESULT *res)
{
    int rc, i, target = -1;
    char *argvv[3 + 2 * EMU_NSOCK + 2 + 1];   /* exe + up to 4 "--romX file"
                                                * pairs + "--boot" addr + NULL */
    int argc = 0;
    char boot_arg[8];

    if (!res || !res->have_bin || !res->bin_name[0]) {
        dlg_message("Emulate", "No binary available -- assemble first.");
        return;
    }

    for (i = 0; i < EMU_NSOCK; i++) {
        if (emu_rom[i][0] == '\0') { target = i; break; }
    }
    if (target < 0) {
        dlg_message("Emulate",
            "All four ROM sockets are configured with fixed files.\n"
            "Leave one blank in Run|Configure Emulator to receive the\n"
            "assembled binary.");
        return;
    }

    vid_done();

    argvv[argc++] = "ADMEMU.EXE";
    for (i = 0; i < EMU_NSOCK; i++) {
        if (i == target) {
            argvv[argc++] = (char *)emu_flag[i];
            argvv[argc++] = (char *)res->bin_name;
        } else if (emu_rom[i][0]) {
            argvv[argc++] = (char *)emu_flag[i];
            argvv[argc++] = emu_rom[i];
        }
    }
    argvv[argc++] = "--boot";
    sprintf(boot_arg, "%04X", emu_addr[target]);
    argvv[argc++] = boot_arg;
    argvv[argc] = NULL;

    /* Print the exact command line about to run -- if the emulator ever
     * does something unexpected, this is the first thing to check: it
     * shows precisely what ACPIDE asked for, independent of whatever
     * ADMEMU itself does with it. ADMEMU clears the screen the instant
     * it starts, so pause here or this would never be readable. */
    printf("\nACPIDE: starting");
    for (i = 0; i < argc; i++) printf(" %s", argvv[i]);
    printf(" ...\npress any key to launch\n");
    getch();

    rc = spawnv(P_WAIT, "ADMEMU.EXE", argvv);
    if (rc == -1) {
        printf("\nCould not start ADMEMU.EXE (is it in the current directory "
               "or on PATH?)  Press any key...\n");
        getch();
    }
    vid_init();
    redraw_all();
}

/* ---- Symbol/Xref table cache ---------------------------------------------
 * Populated by reading the .LST file's own SYMBOL TABLE / CROSS-REFERENCE
 * TABLE section right after each Assemble (acp_assemble() always writes a
 * .LST internally so this works, whether or not "Generate .LST File" is
 * on -- see do_assemble()). View Symbol/Xref Table then just displays this
 * cache, no file needed at view time, so it still works even if the .LST
 * was deleted right after being read. */
#define TBL_MAXLINES 500
#define TBL_LINEW    92
static char **tbl_lines;
static int    tbl_nlines = 0;

static void tbl_ensure_init(void)
{
    int i;
    if (tbl_lines) return;
    tbl_lines = (char **)malloc((unsigned)TBL_MAXLINES * sizeof(char *));
    if (!tbl_lines) return;
    for (i = 0; i < TBL_MAXLINES; i++) tbl_lines[i] = (char *)malloc(TBL_LINEW);
}

/* Reads lst_name starting at its "SYMBOL TABLE" line through EOF into the
 * cache above (silently truncated at TBL_MAXLINES for pathological files).
 * Leaves the cache untouched (not cleared) if the file can't be opened or
 * that heading is never found, so a stale-but-present prior table isn't
 * wiped by an unrelated failure. */
static void tbl_load_from_lst(const char *lst_name)
{
    FILE *f = fopen(lst_name, "r");
    char line[TBL_LINEW];
    int found = 0;
    int n = 0;

    if (!f) return;
    tbl_ensure_init();
    if (!tbl_lines) { fclose(f); return; }

    while (fgets(line, sizeof(line), f)) {
        size_t ln = strlen(line);
        while (ln > 0 && (line[ln-1] == '\n' || line[ln-1] == '\r')) line[--ln] = '\0';
        if (!found) {
            if (strstr(line, "SYMBOL TABLE") != NULL) found = 1; else continue;
        }
        if (n < TBL_MAXLINES) { strcpy(tbl_lines[n], line); n++; }
    }
    fclose(f);
    if (found) tbl_nlines = n;   /* only replace the cache if we actually
                                  * found the section we were looking for */
}

static void do_assemble(int run_after)
{
    ASM_RESULT res;
    char line[400];

    msg_clear();
    acp_set_err_hook(editor_err_hook);
    /* want_lst is always 1 here regardless of gen_lst_file -- the table
     * cache above needs it every time.  If the user has "Generate .LST
     * File" off, the file gets deleted right after we've read it. */
    acp_assemble(ed_filename, 1, 1, 1, 0, &res);
    listing_valid = 1;   /* prog[] now reflects the current buffer -- the
                           * Listing View column can show it (see
                           * mark_dirty(), which clears this on any edit) */

    if (res.have_lst) {
        tbl_load_from_lst(res.lst_name);
        if (!gen_lst_file) remove(res.lst_name);
    }

    if ((res.have_lst && gen_lst_file) || res.have_obj || res.have_bin) {
        sprintf(line, "Wrote %s%s%s%s%s",
                (res.have_lst && gen_lst_file) ? res.lst_name : "",
                (res.have_lst && gen_lst_file) && (res.have_obj || res.have_bin) ? ", " : "",
                res.have_obj ? res.obj_name : "",
                res.have_obj && res.have_bin ? ", " : "",
                res.have_bin ? res.bin_name : "");
        msg_add(line, 0);
    }
    sprintf(line, "%d error(s).", res.err_count);
    msg_add(line, 0);

    last_asm = res; have_last_asm = 1;
    last_err_count = res.err_count;
    compile_status = (res.err_count == 0) ? COMPILE_OK : COMPILE_ERR;

    if (res.err_count > 0) {
        msg_scroll_to_first_error();   /* errors are the useful part --
                                         * show them, not the tail lines */
        editor_err_jump_first();
    } else if (run_after) {
        do_emulate(&res);
    }
}

/* ---- Options / Help -----------------------------------------------------*/

static void do_list_width(void)
{
    char buf[16];
    int w;
    sprintf(buf, "%d", list_width);
    if (!dlg_input("List Width", "72=TTY 80=CRT 132=printer 0=unlimited:", buf, 6))
        return;
    w = atoi(buf);
    if (w < 0) w = 0;
    if (w > 0 && w < 50) {
        dlg_message("List Width", "Too narrow -- minimum is 50 columns (or 0).");
        return;
    }
    list_width = w;
}

static void do_toggle_gutter(void) { show_gutter = !show_gutter; }
static void do_toggle_listing(void) { show_listing = !show_listing; }
static void do_toggle_lst(void) { gen_lst_file = !gen_lst_file; }

static void do_toggle_msgwin(void)
{
    show_msgwin = !show_msgwin;
    /* Nothing to explicitly blank either direction: editor_draw() and (if
     * shown) msg_draw() between them always repaint every row of whatever
     * the current geometry is, so the freed/reclaimed area is naturally
     * overwritten on the very next redraw_all(). Just make sure focus
     * isn't left pointing at a window that no longer exists. */
    if (!show_msgwin && ide_focus == FOCUS_MSG) ide_focus = FOCUS_EDIT;
}

static void do_view_tables(void)
{
    tbl_ensure_init();
    text_view("Symbol / Cross-Reference Table",
              (const char *const *)tbl_lines, tbl_nlines);
}

static void do_about(void)
{
    char msg[80];
    sprintf(msg, "ACPIDE %s  (ACP6800 engine v%s)", ACP_VERSION, ACP_ENGINE_VERSION);
    dlg_message("About ACPIDE", msg);
}

/* ---- dispatch ------------------------------------------------------------*/

static void dispatch(int id)
{
    switch (id) {
    case ID_NEW:            do_new();               break;
    case ID_OPEN:           do_open();              break;
    case ID_SAVE:           do_save();              break;
    case ID_SAVEAS:         do_save_as();           break;
    case ID_FINDLINE:       do_find_line();         break;
    case ID_FINDTEXT:       do_find_text();         break;
    case ID_ASSEMBLE:       do_assemble(0);         break;
    case ID_ASSEMBLE_RUN:   do_assemble(1);         break;
    case ID_EMULATE_LAST:   do_emulate(have_last_asm ? &last_asm : NULL); break;
    case ID_EMU_CONFIG:     do_configure_emulator(); break;
    case ID_VIEW_TABLES:    do_view_tables();       break;
    case ID_CLEARMSG:       msg_clear();            break;
    case ID_LISTWIDTH:      do_list_width();        break;
    case ID_TOGGLE_GUTTER:  do_toggle_gutter();     break;
    case ID_TOGGLE_LISTING: do_toggle_listing();    break;
    case ID_TOGGLE_LST:     do_toggle_lst();        break;
    case ID_TOGGLE_MSGWIN:  do_toggle_msgwin();     break;
    case ID_ABOUT:          do_about();             break;
    default: break;    /* ID_EXIT is handled by the main loop itself      */
    }
}

/* ---- main ----------------------------------------------------------------*/

int main(int argc, char **argv)
{
    int running = 1;

    acp_core_init();
    msg_init();
    editor_new();
    vid_init();

    if (argc > 1) {
        char name[LINELEN];
        strncpy(name, argv[1], LINELEN - 1); name[LINELEN - 1] = '\0';
        upcase(name);
        if (editor_load(name) < 0) {
            editor_new();
            strncpy(ed_filename, name, LINELEN - 1);   /* new file, that name */
        }
    }

    while (running) {
        redraw_all();
        {
            int k = get_key();
            if (k == K_F10) {
                int id = menu_bar(tops, NTOPS, item_arrays, item_counts);
                if (id == ID_EXIT) {
                    if (confirm_discard()) running = 0;
                } else if (id != 0) {
                    dispatch(id);
                }
            } else if (k == K_F6) {
                ide_focus = (ide_focus == FOCUS_EDIT) ? FOCUS_MSG : FOCUS_EDIT;
            } else if (k == K_F1) {
                do_about();
            } else if (k == K_F2) {
                do_save();
            } else if (k == K_F3) {
                do_open();
            } else if (k == K_F9) {
                do_assemble(0);
            } else if (k == K_CTRL_F9) {
                do_assemble(1);
            } else if (k == 12) {          /* Ctrl-L: toggle line numbers  */
                do_toggle_gutter();
            } else if (k == 4) {           /* Ctrl-D: toggle listing view  */
                do_toggle_listing();
            } else if (k == 2) {           /* Ctrl-B: toggle message window */
                do_toggle_msgwin();
            } else if (k == K_ALT_X) {
                if (confirm_discard()) running = 0;
            } else {
                if (ide_focus == FOCUS_EDIT) editor_key(k);
                else                          msg_key(k);
            }
        }
    }

    vid_done();
    return 0;
}
