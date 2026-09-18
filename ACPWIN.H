/* ========================================================================
 * ACPWIN.H  -  Borland-style text-mode window manager for ACPIDE.
 *
 * Direct video-segment writes (no BIOS calls per character), used the same
 * way as the VidPoke technique in Mickey's TE-86 editor.  80x25 text mode
 * is assumed throughout; ACPIDE does not attempt other modes/resolutions.
 * ====================================================================== */
#ifndef ACPIDE_ACPWIN_H
#define ACPIDE_ACPWIN_H

#include <stdio.h>

#define SCR_W 80
#define SCR_H 25

/* ---- colour scheme (retheme here) -------------------------------------
 * Attribute byte: bit7=blink, bits6-4=background, bits3-0=foreground.    */
#define ATTR_DESKTOP    0x17      /* white on blue  -- empty desktop        */
#define ATTR_BORDER     0x1F      /* bright white on blue -- window frame   */
#define ATTR_TITLE      0x1E      /* yellow on blue -- window title text    */
#define ATTR_TEXT       0x1F      /* bright white on blue -- window body    */
#define ATTR_TEXT_DIM   0x17      /* white on blue  -- non-focused body     */
#define ATTR_MENUBAR    0x70      /* black on light gray -- menu bar        */
#define ATTR_MENUSEL    0x07      /* light gray on black -- selected item   */
#define ATTR_MENUHOT    0x74      /* red on light gray -- hotkey letter     */
#define ATTR_STATUS     0x70      /* black on light gray -- status line     */
#define ATTR_STATUS_OK  0x2F      /* bright white on green -- status badge  */
#define ATTR_STATUS_ERR 0x4F      /* bright white on red -- status badge    */
#define ATTR_ERRLINE    0x4F      /* bright white on red -- active error    */
#define ATTR_DIALOG     0x4E      /* yellow on red  -- popup dialog body    */
#define ATTR_DIALOG_BD  0x4F      /* bright white on red -- popup border    */
#define ATTR_SHADOW     0x08      /* black-on-black dim, used for shadows   */
#define ATTR_TITLE_OK   0x2E      /* yellow on green -- title bar, last
                                    * compile had 0 errors                  */
#define ATTR_TITLE_ERR  0x4E      /* yellow on red -- title bar, last
                                    * compile had errors                    */

/* ---- video/keyboard primitives (ACPWIN.C) ----------------------------- */
void vid_init(void);                       /* clear screen, hide cursor     */
void vid_done(void);                       /* restore cursor before exit()  */
void vid_putc(int x, int y, int ch, int attr);
void vid_puts(int x, int y, const char *s, int attr);
void vid_fill(int x1, int y1, int x2, int y2, int ch, int attr);
long vid_bufsz(int x1, int y1, int x2, int y2);
void vid_save(int x1, int y1, int x2, int y2, void far *buf);
void vid_restore(int x1, int y1, int x2, int y2, void far *buf);
void draw_box(int x1, int y1, int x2, int y2, int attr, const char *title,
              int double_line);
/* Same as draw_box() but never blanks the interior first -- use this from
 * anything that repaints every interior cell itself on each call (the
 * edit and message windows do); draw_box() still blanks for dialogs and
 * other callers that write sparse content over whatever was there. */
void draw_box_border(int x1, int y1, int x2, int y2, int attr,
                      const char *title, int double_line);
void draw_shadow(int x1, int y1, int x2, int y2);   /* call AFTER draw_box */
void cursor_at(int x, int y);              /* text-mode cursor position     */
void cursor_hide(void);
void cursor_show(void);

/* ---- keyboard ----------------------------------------------------------
 * get_key() returns a plain ASCII code (1-255) for ordinary keys, or
 * (0x100 | scancode) for the extended (0-prefixed) keys below.           */
int  key_hit(void);
int  get_key(void);
void vid_dump_ascii(FILE *out);   /* debug aid, not used by ACPIDE itself   */

#define K_UP       0x148
#define K_DOWN     0x150
#define K_LEFT     0x14B
#define K_RIGHT    0x14D
#define K_HOME     0x147
#define K_END      0x14F
#define K_PGUP     0x149
#define K_PGDN     0x151
#define K_DEL      0x153
#define K_INS      0x152
#define K_CTRL_HOME 0x177
#define K_CTRL_END  0x175
#define K_F1       0x13B
#define K_F2       0x13C
#define K_F3       0x13D
#define K_F4       0x13E
#define K_F5       0x13F
#define K_F6       0x140
#define K_F7       0x141
#define K_F8       0x142
#define K_F9       0x143
#define K_F10      0x144
#define K_ALT_X    0x12D
#define K_CTRL_F9  0x186   /* NOTE: verify against your keyboard/DOSBox --
                             * BIOS extended scan codes for Ctrl-Fn vary a
                             * little across machines/emulators.  The Run
                             * menu's Emulate item always works regardless. */
#define K_TAB      9
#define K_BACKSPACE 8
#define K_ENTER    13
#define K_ESC      27

/* ---- pull-down menu bar -------------------------------------------------
 * A generic Borland-style menu engine.  The caller owns the id numbering;
 * menu_bar() just returns which item's id was chosen. id 0 is reserved
 * for a separator row (label ignored) and is never selectable. */
typedef struct {
    const char *label;     /* top bar name, e.g. "File"                    */
    char        hotkey;    /* uppercase letter, e.g. 'F' (Alt+letter)      */
} MENU_TOP;

typedef struct {
    const char *label;     /* item text, e.g. "Save"; NULL/"" = separator  */
    const char *keytag;    /* right-aligned hint, e.g. "F2"; "" for none   */
    char        hotkey;    /* uppercase letter (should occur in label)     */
    int         id;        /* returned to caller; 0 = separator/disabled   */
} MENU_ITEM;

/* Draws just the top-level bar (no dropdown, nothing highlighted) -- call
 * this each time through the main loop so row 1 stays populated between
 * F10 activations. */
void menu_strip_draw(const MENU_TOP *tops, int ntops);

/* Runs the menu bar interactively (F10 or Alt+hotkey to enter it from the
 * caller's main loop -- the caller decides when to invoke this).  Returns
 * the chosen item's id, or 0 if the user backed out with Esc. */
int menu_bar(const MENU_TOP *tops, int ntops,
             const MENU_ITEM *const items[], const int nitems[]);

/* ---- simple modal dialogs (built on the primitives above) ------------- */
/* Centered message box with an [ OK ] prompt.  Blocks until a key/click. */
void dlg_message(const char *title, const char *msg);

/* Yes/No/Cancel.  Returns 'Y', 'N', or 27 (Esc == Cancel).                */
int  dlg_confirm(const char *title, const char *msg);

/* Single-line text input.  buf must hold at least maxlen+1 bytes and may
 * contain an initial value.  Returns 1 on Enter, 0 on Esc (buf unchanged
 * on Esc). */
int  dlg_input(const char *title, const char *prompt, char *buf, int maxlen);

/* Scrollable pick-list of nitems strings.  Returns the chosen index, or
 * -1 on Esc. */
int  dlg_pick(const char *title, const char *const *items, int nitems);

/* Large, near-full-screen READ-ONLY scrollable viewer -- for content too
 * big/wide for dlg_pick's compact box (symbol tables, cross-reference
 * listings). Esc or Enter dismisses; no selection is returned. */
void text_view(const char *title, const char *const *lines, int nlines);

/* Directory browser built on dlg_pick(): lists the current directory
 * (subdirectories bracketed, ".." included unless at the root), lets the
 * user navigate in and out with Enter, and returns a chosen regular file.
 * out_name must hold at least maxlen+1 bytes. Returns 1 with out_name set
 * to the chosen file (bare name, current directory becomes the file's
 * directory as a side effect of navigating), or 0 if the user cancelled
 * (current directory may still have changed if they navigated before
 * cancelling). */
int  dlg_file_browse(char *out_name, int maxlen);

#endif /* ACPIDE_ACPWIN_H */
