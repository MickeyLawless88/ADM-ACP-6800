/* ========================================================================
 * ACPEDIT.C  -  Edit window and Message window behaviour for ACPIDE.
 *
 * The editor operates directly on ACPCORE's gl_lines[]/gl_count buffer via
 * buf_load/buf_save/buf_replace/buf_insert/buf_delete -- there is no
 * separate in-memory copy, so "Assemble" always sees exactly what's on
 * screen, saved or not (a deliberate difference from the original
 * interactive ACP, which re-read the file from disk each time).
 * ====================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "ACP.H"
#include "ACPWIN.H"
#include "ACPEDIT.H"

int  ed_dirty = 0;
char ed_filename[LINELEN] = "";
int  ide_focus = FOCUS_EDIT;
int  show_gutter = 1;
int  show_listing = 0;
int  listing_valid = 0;
int  show_msgwin = 1;
int  compile_status = COMPILE_UNKNOWN;
int  last_err_count = 0;

static int cur_line = 2;     /* display line number (>=2)                 */
static int cur_col  = 0;     /* 0-based character offset in that line     */
static int top_line = 2;     /* display line shown in the top text row    */

int ed_bottom(void) { return show_msgwin ? ED_Y2_SPLIT : ED_Y2_FULL; }
int ed_rows(void)   { return ed_bottom() - ED_Y1 - 1; }

#define MSG_MAXLINES 200
#define MSG_LINEMAX  160    /* bytes per allocated message row (see msg_init()) */
/* heap-allocated (see msg_init()), not static arrays -- 200*160 bytes of
 * static data here plus ACPCORE.C's binbuf overflows the 64K near data
 * segment under 16-bit Turbo C even in the large model (memory models
 * change how code/pointers are addressed, not where plain static globals
 * live -- those still share one fixed-size near segment). */
static char **msg_text;
static int   *msg_dispno;
static int  nmsg = 0;
static int  msg_top = 0;
static int  msg_sel = 0;

/* ---- helpers ------------------------------------------------------------ */

/* Any edit invalidates the listing-view data (addresses/hex bytes shown
 * only make sense for what was last actually assembled) and the compile-
 * status badge (it no longer describes the current buffer), so route
 * every buffer mutation through here instead of setting ed_dirty directly. */
static void mark_dirty(void)
{
    ed_dirty = 1;
    listing_valid = 0;
    compile_status = COMPILE_UNKNOWN;
}

static void clamp_col(void)
{
    int idx = idx_of(cur_line);
    int len = (idx >= 0 && gl_lines[idx]) ? (int)strlen(gl_lines[idx]) : 0;
    if (cur_col > len) cur_col = len;
    if (cur_col < 0) cur_col = 0;
}

static void scroll_to_cursor(void)
{
    int rows = ed_rows();
    if (cur_line < top_line) top_line = cur_line;
    if (cur_line > top_line + rows - 1) top_line = cur_line - rows + 1;
    if (top_line < 2) top_line = 2;
}

/* ---- edit window --------------------------------------------------------*/

void editor_new(void)
{
    buf_clear();
    buf_append("");
    cur_line = 2; cur_col = 0; top_line = 2;
    ed_dirty = 0;
    listing_valid = 0;
    compile_status = COMPILE_UNKNOWN;
    ed_filename[0] = '\0';
}

int editor_load(const char *name)
{
    if (buf_load(name) < 0) return -1;
    if (last_dispno() < 2) buf_append("");     /* guarantee one editable line */
    cur_line = 2; cur_col = 0; top_line = 2;
    strncpy(ed_filename, name, LINELEN - 1);
    ed_filename[LINELEN - 1] = '\0';
    ed_dirty = 0;
    listing_valid = 0;
    compile_status = COMPILE_UNKNOWN;
    return 0;
}

int editor_save(const char *name)
{
    if (buf_save(name) < 0) return -1;
    strncpy(ed_filename, name, LINELEN - 1);
    ed_filename[LINELEN - 1] = '\0';
    ed_dirty = 0;
    return 0;
}

void editor_draw(void)
{
    char title[LINELEN + 2];
    int focused = (ide_focus == FOCUS_EDIT);
    int r;
    int bottom = ed_bottom();
    int rows = ed_rows();
    int prefix = (show_listing ? ED_LISTW : 0) + (show_gutter ? ED_GUTTER : 0);
    int iw = (ED_X2 - ED_X1 - 1) - prefix;   /* text columns available   */
    if (iw < 1) iw = 1;

    sprintf(title, "%s%s", ed_filename[0] ? ed_filename : "(unnamed)",
            ed_dirty ? "*" : "");
    draw_box_border(ED_X1, ED_Y1, ED_X2, bottom, focused ? ATTR_BORDER : ATTR_TEXT_DIM,
              title, 1);

    for (r = 0; r < rows; r++) {
        int dispno = top_line + r;
        int y = ED_Y1 + 1 + r;
        int battr = focused ? ATTR_TEXT : ATTR_TEXT_DIM;
        int x = ED_X1 + 1;
        int have_line = (dispno <= last_dispno());

        if (show_listing) {
            char seg[ED_LISTW + 1];
            WORD addr; char code[13];
            if (have_line && listing_valid && acp_line_info(dispno, &addr, code)) {
                sprintf(seg, "%04X %-12s  ", addr, code);
            } else {
                memset(seg, ' ', ED_LISTW); seg[ED_LISTW] = '\0';
            }
            vid_puts(x, y, seg, battr);
            x += ED_LISTW;
        }

        if (show_gutter) {
            if (have_line) {
                char gutter[16];
                sprintf(gutter, "%*d ", ED_GUTTER - 1, dispno - 1);
                vid_puts(x, y, gutter, battr);
            } else {
                vid_fill(x, y, x + ED_GUTTER - 1, y, ' ', battr);
            }
            x += ED_GUTTER;
        }

        if (have_line) {
            int idx = idx_of(dispno);
            const char *text = (idx >= 0 && gl_lines[idx]) ? gl_lines[idx] : "";
            char shown[LINELEN];
            int n = (int)strlen(text);
            if (n > iw) n = iw;
            memcpy(shown, text, n);
            if (n < iw) memset(shown + n, ' ', iw - n);   /* pad in the same
                                    * buffer instead of a separate fill pass
                                    * that double-writes the text cells    */
            shown[iw] = '\0';
            vid_puts(x, y, shown, battr);
        } else {
            vid_fill(x, y, ED_X2 - 1, y, ' ', battr);
        }
    }

    if (focused) {
        int text_x = ED_X1 + 1 + prefix;
        int sx = text_x + cur_col;
        int sy = ED_Y1 + 1 + (cur_line - top_line);
        int last_col = ED_X2 - 1;
        if (sx > last_col) sx = last_col;      /* clamp on screen -- no
                                                 * horizontal scroll yet   */
        cursor_at(sx, sy);
        cursor_show();
    } else {
        cursor_hide();
    }
}

void editor_key(int k)
{
    int idx = idx_of(cur_line);
    char line[LINELEN];
    int len;

    strcpy(line, (idx >= 0 && gl_lines[idx]) ? gl_lines[idx] : "");
    len = (int)strlen(line);

    switch (k) {
    case K_LEFT:
        if (cur_col > 0) cur_col--;
        else if (cur_line > 2) { cur_line--; cur_col = 999; clamp_col(); }
        break;
    case K_RIGHT:
        if (cur_col < len) cur_col++;
        else if (cur_line < last_dispno()) { cur_line++; cur_col = 0; }
        break;
    case K_UP:
        if (cur_line > 2) { cur_line--; clamp_col(); }
        break;
    case K_DOWN:
        if (cur_line < last_dispno()) { cur_line++; clamp_col(); }
        break;
    case K_HOME: cur_col = 0; break;
    case K_END:  cur_col = len; break;
    case K_PGUP:
        cur_line -= ed_rows(); if (cur_line < 2) cur_line = 2;
        clamp_col();
        break;
    case K_PGDN:
        cur_line += ed_rows(); if (cur_line > last_dispno()) cur_line = last_dispno();
        clamp_col();
        break;
    case K_CTRL_HOME: cur_line = 2; cur_col = 0; break;
    case K_CTRL_END:  cur_line = last_dispno(); clamp_col(); cur_col = len; break;

    case K_ENTER: {
        char left[LINELEN], right[LINELEN];
        strncpy(left, line, cur_col); left[cur_col] = '\0';
        strcpy(right, line + cur_col);
        buf_replace(cur_line, left);
        buf_insert(cur_line + 1, right);
        cur_line++; cur_col = 0; mark_dirty();
        break; }

    case K_BACKSPACE:
        if (cur_col > 0) {
            memmove(line + cur_col - 1, line + cur_col, len - cur_col + 1);
            buf_replace(cur_line, line);
            cur_col--; mark_dirty();
        } else if (cur_line > 2) {
            int pidx = idx_of(cur_line - 1);
            const char *prev = (pidx >= 0 && gl_lines[pidx]) ? gl_lines[pidx] : "";
            char joined[LINELEN];
            if ((int)strlen(prev) + len < LINELEN - 1) {
                sprintf(joined, "%s%s", prev, line);
                buf_replace(cur_line - 1, joined);
                buf_delete(cur_line, cur_line);
                cur_col = (int)strlen(prev);
                cur_line--; mark_dirty();
            }
        }
        break;

    case K_DEL:
        if (cur_col < len) {
            memmove(line + cur_col, line + cur_col + 1, len - cur_col);
            buf_replace(cur_line, line);
            mark_dirty();
        } else if (cur_line < last_dispno()) {
            int nidx = idx_of(cur_line + 1);
            const char *next = (nidx >= 0 && gl_lines[nidx]) ? gl_lines[nidx] : "";
            char joined[LINELEN];
            if (len + (int)strlen(next) < LINELEN - 1) {
                sprintf(joined, "%s%s", line, next);
                buf_replace(cur_line, joined);
                buf_delete(cur_line + 1, cur_line + 1);
                mark_dirty();
            }
        }
        break;

    case 25:                          /* Ctrl-Y: delete current line       */
        buf_delete(cur_line, cur_line);
        if (last_dispno() < 2) buf_append("");
        if (cur_line > last_dispno()) cur_line = last_dispno();
        cur_col = 0; mark_dirty();
        break;

    case K_TAB: {
        int spaces = 8 - (cur_col % 8), i;
        if (len + spaces < LINELEN - 1) {
            memmove(line + cur_col + spaces, line + cur_col, len - cur_col + 1);
            for (i = 0; i < spaces; i++) line[cur_col + i] = ' ';
            buf_replace(cur_line, line);
            cur_col += spaces; mark_dirty();
        }
        break; }

    default:
        if (k >= 32 && k < 127 && len < LINELEN - 1) {
            memmove(line + cur_col + 1, line + cur_col, len - cur_col + 1);
            line[cur_col] = (char)k;
            buf_replace(cur_line, line);
            cur_col++; mark_dirty();
        }
        break;
    }

    scroll_to_cursor();
}

void editor_goto_line(int dispno)
{
    if (dispno < 2) dispno = 2;
    if (dispno > last_dispno()) dispno = last_dispno();
    cur_line = dispno; cur_col = 0;
    scroll_to_cursor();
    ide_focus = FOCUS_EDIT;
}

/* ---- message window ------------------------------------------------------*/

void msg_init(void)
{
    int i;
    msg_text   = (char **)malloc((unsigned)MSG_MAXLINES * sizeof(char *));
    msg_dispno = (int *)malloc((unsigned)MSG_MAXLINES * sizeof(int));
    if (!msg_text || !msg_dispno) {
        fprintf(stderr, "OUT OF MEMORY - CANNOT START ACPIDE\n");
        exit(1);
    }
    for (i = 0; i < MSG_MAXLINES; i++) {
        msg_text[i] = (char *)malloc(MSG_LINEMAX);
        if (!msg_text[i]) { fprintf(stderr, "OUT OF MEMORY - CANNOT START ACPIDE\n"); exit(1); }
    }
}

void msg_clear(void) { nmsg = 0; msg_top = 0; msg_sel = 0; }

void msg_add(const char *text, int dispno)
{
    if (nmsg >= MSG_MAXLINES) return;   /* oldest messages simply stop scrolling in;
                                          * a session rarely produces 200 lines of
                                          * assembler output before Clear Messages. */
    strncpy(msg_text[nmsg], text, MSG_LINEMAX - 1);
    msg_text[nmsg][MSG_LINEMAX - 1] = '\0';
    msg_dispno[nmsg] = dispno;
    nmsg++;
    msg_sel = nmsg - 1;
    if (msg_sel >= msg_top + MSG_ROWS) msg_top = msg_sel - MSG_ROWS + 1;
}

void msg_draw(void)
{
    int focused = (ide_focus == FOCUS_MSG);
    int iw = MSG_X2 - MSG_X1 - 1;
    int r;

    if (!show_msgwin) return;   /* the edit window has expanded to cover
                                  * this screen area -- drawing here would
                                  * clobber it */

    draw_box_border(MSG_X1, MSG_Y1, MSG_X2, MSG_Y2, focused ? ATTR_BORDER : ATTR_TEXT_DIM,
              "Message", 1);

    for (r = 0; r < MSG_ROWS; r++) {
        int idx = msg_top + r;
        int y = MSG_Y1 + 1 + r;
        if (idx < nmsg) {
            int attr;
            char shown[160];
            int n = (int)strlen(msg_text[idx]);
            if (n > iw) n = iw;
            memcpy(shown, msg_text[idx], n);
            if (n < iw) memset(shown + n, ' ', iw - n);
            shown[iw] = '\0';
            if (focused && idx == msg_sel) attr = ATTR_MENUSEL;
            else attr = msg_dispno[idx] ? ATTR_TEXT : ATTR_TEXT_DIM;
            vid_puts(MSG_X1 + 1, y, shown, attr);
        } else {
            vid_fill(MSG_X1 + 1, y, MSG_X2 - 1, y, ' ',
                      focused ? ATTR_TEXT : ATTR_TEXT_DIM);
        }
    }
    cursor_hide();
}

void msg_key(int k)
{
    switch (k) {
    case K_UP:   if (msg_sel > 0) msg_sel--; break;
    case K_DOWN: if (msg_sel < nmsg - 1) msg_sel++; break;
    case K_PGUP: msg_sel -= MSG_ROWS; if (msg_sel < 0) msg_sel = 0; break;
    case K_PGDN: msg_sel += MSG_ROWS; if (msg_sel > nmsg - 1) msg_sel = nmsg - 1; break;
    case K_HOME: msg_sel = 0; break;
    case K_END:  msg_sel = nmsg - 1; break;
    case K_ENTER:
        if (nmsg > 0 && msg_dispno[msg_sel] != 0)
            editor_goto_line(msg_dispno[msg_sel]);
        break;
    default: break;
    }
    if (msg_sel < 0) msg_sel = 0;
    if (msg_sel < msg_top) msg_top = msg_sel;
    if (msg_sel >= msg_top + MSG_ROWS) msg_top = msg_sel - MSG_ROWS + 1;
}

void editor_err_hook(int dispno, const char *msg, const char *what)
{
    char line[200];
    int shown = dispno - 1;   /* dispno is ACPCORE's internal numbering
                                * (line 1 is a reserved record per the
                                * original ADM-2 ASSEDIT convention, so
                                * the first user line is dispno 2) -- the
                                * editor displays ordinary 1-based line
                                * numbers, so shift to match what's on
                                * screen. */
    if (what && *what) sprintf(line, "LINE %d: %s - %s", shown, msg, what);
    else               sprintf(line, "LINE %d: %s", shown, msg);
    msg_add(line, dispno);
}

int msg_first_err_dispno(void)
{
    int i;
    for (i = 0; i < nmsg; i++)
        if (msg_dispno[i] != 0) return msg_dispno[i];
    return 0;
}

/* msg_add() always scrolls to show the newest line, which is right for a
 * clean assemble ("Wrote X / 0 error(s)") but wrong when there are errors
 * above the trailing "Wrote"/count lines -- the useful part scrolls out
 * of view and nothing indicates more is above.  Call this right after an
 * Assemble that produced errors to scroll back up to them instead. */
void msg_scroll_to_first_error(void)
{
    int i;
    for (i = 0; i < nmsg; i++) {
        if (msg_dispno[i] != 0) {
            msg_sel = i;
            msg_top = i;
            return;
        }
    }
}

/* ---- status line -----------------------------------------------------*/

void status_draw(void)
{
    char left[LINELEN + 48], hints[64], line[81], badge[16];
    int llen, hlen, badge_attr = ATTR_STATUS;

    sprintf(left, " %s%s  Ln %d Col %d",
            ed_filename[0] ? ed_filename : "(unnamed)",
            ed_dirty ? "*" : "", cur_line - 1, cur_col + 1);
    strcpy(hints, "F1=Help F2=Save F3=Open F9=Asm F10=Menu Alt-X=Exit ");

    llen = (int)strlen(left);
    hlen = (int)strlen(hints);
    memset(line, ' ', 80); line[80] = '\0';
    if (llen > 80) llen = 80;
    memcpy(line, left, llen);
    if (hlen <= 80) memcpy(line + (80 - hlen), hints, hlen);

    vid_puts(1, STATUS_Y, line, ATTR_STATUS);

    /* Graphical (colour-coded) compile-status badge, right after the
     * Ln/Col text -- green for a clean assemble, red with the error
     * count otherwise. Nothing shown until the buffer's been assembled
     * at least once, or after it's edited (see mark_dirty()). */
    badge[0] = '\0';
    if (compile_status == COMPILE_OK) {
        strcpy(badge, " OK ");
        badge_attr = ATTR_STATUS_OK;
    } else if (compile_status == COMPILE_ERR) {
        sprintf(badge, " %d ERR ", last_err_count);
        badge_attr = ATTR_STATUS_ERR;
    }
    if (badge[0]) {
        int bx = 2 + llen;
        int blen = (int)strlen(badge);
        if (bx + blen > 80) bx = 80 - blen;
        if (bx < 1) bx = 1;
        vid_puts(bx, STATUS_Y, badge, badge_attr);
    }
}
