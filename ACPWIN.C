/* ========================================================================
 * ACPWIN.C  -  video/keyboard primitives and modal dialogs for ACPIDE.
 *
 * Text mode only (80x25), direct writes to the video segment (0xB800 for
 * color, 0xB000 for mono -- detected once at vid_init() via the BIOS data
 * area current-video-mode byte at 0040:0049h).  Build LARGE model (see
 * ACP.H) so plain malloc() pointers are already far and can be handed to
 * vid_save()/vid_restore() directly.
 * ====================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dos.h>
#include <conio.h>
#include <mem.h>
#include <dir.h>

#include "ACPWIN.H"

static unsigned char far *vmem;    /* points at the base of text video RAM */

/* ---- low-level video --------------------------------------------------*/

static void detect_video(void)
{
    unsigned char mode = peekb(0x0040, 0x0049);
    vmem = (mode == 7) ? (unsigned char far *)MK_FP(0xB000, 0)
                        : (unsigned char far *)MK_FP(0xB800, 0);
}

void vid_init(void)
{
    detect_video();
    cursor_hide();
    vid_fill(1, 1, SCR_W, SCR_H, ' ', ATTR_DESKTOP);
}

void vid_done(void)
{
    cursor_show();
    clrscr();               /* leave a plain screen behind on exit          */
    gotoxy(1, 1);
}

void vid_putc(int x, int y, int ch, int attr)
{
    long off;
    if (x < 1 || x > SCR_W || y < 1 || y > SCR_H) return;
    off = ((long)(y - 1) * SCR_W + (x - 1)) * 2;
    vmem[off]     = (unsigned char)ch;
    vmem[off + 1] = (unsigned char)attr;
}

void vid_puts(int x, int y, const char *s, int attr)
{
    int cx = x;
    while (*s && cx <= SCR_W) { vid_putc(cx, y, (unsigned char)*s, attr); cx++; s++; }
}

void vid_fill(int x1, int y1, int x2, int y2, int ch, int attr)
{
    int x, y;
    for (y = y1; y <= y2; y++)
        for (x = x1; x <= x2; x++)
            vid_putc(x, y, ch, attr);
}

long vid_bufsz(int x1, int y1, int x2, int y2)
{
    return (long)(x2 - x1 + 1) * (y2 - y1 + 1) * 2L;
}

/* Plain byte-at-a-time far copies -- deliberately not using _fmemcpy/
 * movedata so this doesn't depend on which runtime library a given Turbo
 * C / Turbo C++ version ships; a handful of extra loop iterations per
 * dialog redraw is not a speed concern here. */
void vid_save(int x1, int y1, int x2, int y2, void far *buf)
{
    unsigned char far *dst = (unsigned char far *)buf;
    int x, y, w = x2 - x1 + 1;
    for (y = y1; y <= y2; y++) {
        long off = ((long)(y - 1) * SCR_W + (x1 - 1)) * 2;
        for (x = 0; x < w * 2; x++) *dst++ = vmem[off + x];
    }
}

void vid_restore(int x1, int y1, int x2, int y2, void far *buf)
{
    unsigned char far *src = (unsigned char far *)buf;
    int x, y, w = x2 - x1 + 1;
    for (y = y1; y <= y2; y++) {
        long off = ((long)(y - 1) * SCR_W + (x1 - 1)) * 2;
        for (x = 0; x < w * 2; x++) vmem[off + x] = *src++;
    }
}

/* ---- box drawing -------------------------------------------------------
 * Single-line box chars: 196 ─, 179 │, 218 ┌, 191 ┐, 192 └, 217 ┘
 * Double-line box chars: 205 ═, 186 ║, 201 ╔, 187 ╗, 200 ╚, 188 ╝        */
void draw_box_border(int x1, int y1, int x2, int y2, int attr,
                      const char *title, int double_line)
{
    int x, y;
    int hbar = double_line ? 205 : 196;
    int vbar = double_line ? 186 : 179;
    int tl   = double_line ? 201 : 218;
    int tr   = double_line ? 187 : 191;
    int bl   = double_line ? 200 : 192;
    int br   = double_line ? 188 : 217;

    vid_putc(x1, y1, tl, attr);
    vid_putc(x2, y1, tr, attr);
    vid_putc(x1, y2, bl, attr);
    vid_putc(x2, y2, br, attr);
    for (x = x1 + 1; x < x2; x++) { vid_putc(x, y1, hbar, attr); vid_putc(x, y2, hbar, attr); }
    for (y = y1 + 1; y < y2; y++) { vid_putc(x1, y, vbar, attr); vid_putc(x2, y, vbar, attr); }

    if (title && *title) {
        int len = (int)strlen(title) + 2;      /* padding space each side  */
        int tx  = x1 + ((x2 - x1 + 1) - len) / 2;
        vid_putc(tx, y1, ' ', attr);
        vid_puts(tx + 1, y1, title, attr);
        vid_putc(tx + 1 + (int)strlen(title), y1, ' ', attr);
    }
}

void draw_box(int x1, int y1, int x2, int y2, int attr, const char *title,
              int double_line)
{
    /* Interior blank-then-redraw is exactly the flicker pattern fixed in
     * redraw_all() -- but dialogs (unlike the edit/message windows) don't
     * necessarily overwrite every interior cell themselves afterward, so
     * they still need it. draw_box_border() is the flicker-free path for
     * callers that repaint their whole interior every time regardless. */
    vid_fill(x1 + 1, y1 + 1, x2 - 1, y2 - 1, ' ', attr);
    draw_box_border(x1, y1, x2, y2, attr, title, double_line);
}

void draw_shadow(int x1, int y1, int x2, int y2)
{
    /* two columns to the right, one row below -- classic Borland shadow;
     * darkens whatever's already there without changing the character. */
    int x, y;
    for (y = y1 + 1; y <= y2 + 1; y++)
        for (x = x2 + 1; x <= x2 + 2; x++) {
            long off = ((long)(y - 1) * SCR_W + (x - 1)) * 2;
            if (x < 1 || x > SCR_W || y < 1 || y > SCR_H) continue;
            vmem[off + 1] = ATTR_SHADOW;
        }
    for (x = x1 + 2; x <= x2; x++) {
        int y2s = y2 + 1;
        long off = ((long)(y2s - 1) * SCR_W + (x - 1)) * 2;
        if (y2s > SCR_H) continue;
        vmem[off + 1] = ATTR_SHADOW;
    }
}

void cursor_at(int x, int y) { gotoxy(x, y); }
void cursor_hide(void)
{
    _setcursortype(_NOCURSOR);
}

void cursor_show(void)
{
    /* Turbo C++ 1.00's runtime has _setcursortype() but no matching
     * _getcursortype() to round-trip the original shape, so this just
     * restores the ordinary block/underline cursor rather than whatever
     * shape happened to be active before vid_init(). */
    _setcursortype(_NORMALCURSOR);
}

/* ---- keyboard ----------------------------------------------------------
 * Turbo C's getch(): ordinary keys return their ASCII code directly;
 * function/cursor/Alt keys return 0 followed by a second getch() with the
 * BIOS scan code.  We fold that into a single int: (0x100 | scancode).   */
int key_hit(void) { return kbhit(); }

/* Not used by ACPIDE itself -- a small debug aid for dumping the current
 * screen (characters only, no attributes) to stdout/a log file.  Handy
 * when bringing this up under a new emulator/terminal for the first
 * time. */
void vid_dump_ascii(FILE *out)
{
    int x, y;
    for (y = 1; y <= SCR_H; y++) {
        for (x = 1; x <= SCR_W; x++) {
            long off = ((long)(y - 1) * SCR_W + (x - 1)) * 2;
            int ch = vmem[off];
            fputc((ch >= 32 && ch < 127) ? ch : '.', out);
        }
        fputc('\n', out);
    }
}

int get_key(void)
{
    int c = getch();
    if (c == 0) {
        int sc = getch();
        return 0x100 | sc;
    }
    return c;
}

/* ========================================================================
 *  pull-down menu bar
 * ====================================================================== */

/* x (1-based) where each top-level label starts, computed fresh each call
 * since labels/ntops are supplied by the caller each time. */
static void top_positions(const MENU_TOP *tops, int ntops, int *xpos)
{
    int x = 2, i;
    for (i = 0; i < ntops; i++) {
        xpos[i] = x;
        x += (int)strlen(tops[i].label) + 3;   /* label + 2 gap + 1 pad    */
    }
}

static void draw_top_bar(const MENU_TOP *tops, int ntops, const int *xpos, int active)
{
    int i;
    if (active < 0) {
        /* Idle steady-state: menu_strip_draw() calls this on every single
         * keystroke even though the bar never changes between keypresses.
         * Build the whole row in one uniform-attribute buffer instead of
         * blanking then overwriting each label's cells a second time. */
        char row[SCR_W + 1];
        int p;
        memset(row, ' ', SCR_W); row[SCR_W] = '\0';
        for (i = 0; i < ntops; i++) {
            int x = xpos[i] - 1;
            const char *lbl = tops[i].label;
            for (p = 0; lbl[p] && x + p < SCR_W; p++) row[x + p] = lbl[p];
        }
        vid_puts(1, 1, row, ATTR_MENUBAR);
        return;
    }
    vid_fill(1, 1, SCR_W, 1, ' ', ATTR_MENUBAR);
    for (i = 0; i < ntops; i++) {
        int attr = (i == active) ? ATTR_MENUSEL : ATTR_MENUBAR;
        vid_puts(xpos[i], 1, tops[i].label, attr);
    }
}

void menu_strip_draw(const MENU_TOP *tops, int ntops)
{
    int xpos[16];
    if (ntops > 16) ntops = 16;
    top_positions(tops, ntops, xpos);
    draw_top_bar(tops, ntops, xpos, -1);
}

/* highlight the single hotkey character within a label, if present */
static void puts_hot(int x, int y, const char *label, char hotkey, int attr, int hotattr)
{
    int i;
    vid_puts(x, y, label, attr);
    for (i = 0; label[i]; i++) {
        if (toupper((unsigned char)label[i]) == toupper((unsigned char)hotkey)) {
            vid_putc(x + i, y, (unsigned char)label[i], hotattr);
            break;
        }
    }
}

/* returns index of the first selectable (id != 0) item at/after `from`,
 * wrapping around; -1 if the dropdown has no selectable items at all */
static int next_selectable(const MENU_ITEM *const items, int nitems, int from, int dir)
{
    int i, n = nitems;
    if (n <= 0) return -1;
    i = from;
    do {
        i = (i + dir + n) % n;
        if (items[i].id != 0) return i;
    } while (i != from);
    return (items[from].id != 0) ? from : -1;
}

static int drop_width(const MENU_ITEM *items, int nitems)
{
    int i, w = 12;
    for (i = 0; i < nitems; i++) {
        int l = (int)strlen(items[i].label ? items[i].label : "")
              + (int)strlen(items[i].keytag ? items[i].keytag : "") + 6;
        if (l > w) w = l;
    }
    return w;
}

int menu_bar(const MENU_TOP *tops, int ntops,
             const MENU_ITEM *const items[], const int nitems[])
{
    int xpos[16];
    int active = 0;
    int sel;
    int result = 0;
    int running = 1;

    if (ntops > 16) ntops = 16;
    top_positions(tops, ntops, xpos);

    while (running) {
        int dx1 = xpos[active] - 1, dw = drop_width(items[active], nitems[active]);
        int dy1 = 2, dy2 = dy1 + nitems[active] + 1;
        int dx2 = dx1 + dw - 1;
        void far *bg;
        int r;

        if (dx2 > SCR_W) { dx1 -= (dx2 - SCR_W); dx2 = SCR_W; }

        draw_top_bar(tops, ntops, xpos, active);

        bg = malloc((size_t)vid_bufsz(dx1, dy1, dx2 + 2, dy2 + 1));
        if (bg) vid_save(dx1, dy1, dx2 + 2, dy2 + 1, bg);
        draw_box(dx1, dy1, dx2, dy2, ATTR_MENUBAR, NULL, 0);
        draw_shadow(dx1, dy1, dx2, dy2);

        sel = next_selectable(items[active], nitems[active], -1, 1);

        for (;;) {
            for (r = 0; r < nitems[active]; r++) {
                const MENU_ITEM *it = &items[active][r];
                int y = dy1 + 1 + r;
                int is_sep = (it->id == 0 && (it->label == NULL || it->label[0] == '\0'));
                int attr = (r == sel) ? ATTR_MENUSEL : ATTR_MENUBAR;
                if (is_sep) {
                    int x;
                    for (x = dx1 + 1; x < dx2; x++) vid_putc(x, y, 196, ATTR_MENUBAR);
                } else {
                    vid_fill(dx1 + 1, y, dx2 - 1, y, ' ', attr);
                    puts_hot(dx1 + 2, y, it->label, it->hotkey, attr,
                             (r == sel) ? attr : ATTR_MENUHOT);
                    if (it->keytag && it->keytag[0]) {
                        int kx = dx2 - 1 - (int)strlen(it->keytag);
                        vid_puts(kx, y, it->keytag, attr);
                    }
                }
            }

            {
                int k = get_key();
                if (k == K_RIGHT) {
                    active = (active + 1) % ntops;
                    if (bg) { vid_restore(dx1, dy1, dx2 + 2, dy2 + 1, bg); free(bg); }
                    goto redraw_top;
                } else if (k == K_LEFT) {
                    active = (active - 1 + ntops) % ntops;
                    if (bg) { vid_restore(dx1, dy1, dx2 + 2, dy2 + 1, bg); free(bg); }
                    goto redraw_top;
                } else if (k == K_DOWN) {
                    sel = next_selectable(items[active], nitems[active], sel, 1);
                } else if (k == K_UP) {
                    sel = next_selectable(items[active], nitems[active], sel, -1);
                } else if (k == K_ENTER) {
                    result = (sel >= 0) ? items[active][sel].id : 0;
                    running = 0;
                    break;
                } else if (k == K_ESC) {
                    result = 0; running = 0; break;
                } else if (k >= 32 && k < 256) {
                    /* jump to an item whose hotkey matches, if any */
                    int r2;
                    for (r2 = 0; r2 < nitems[active]; r2++) {
                        if (items[active][r2].id != 0 &&
                            toupper((unsigned char)items[active][r2].hotkey) == toupper((unsigned char)k)) {
                            result = items[active][r2].id; running = 0; break;
                        }
                    }
                    if (!running) break;
                }
            }
        }
        if (bg) { vid_restore(dx1, dy1, dx2 + 2, dy2 + 1, bg); free(bg); }
        break;
redraw_top:
        continue;
    }
    return result;
}

/* ========================================================================
 *  modal dialogs
 * ====================================================================== */

/* centers a WxH box on screen and returns its top-left corner */
static void center_box(int w, int h, int *x1, int *y1)
{
    *x1 = (SCR_W - w) / 2 + 1;
    *y1 = (SCR_H - h) / 2 + 1;
    if (*x1 < 1) *x1 = 1;
    if (*y1 < 1) *y1 = 1;
}

void dlg_message(const char *title, const char *msg)
{
    int w = (int)strlen(msg) + 8;
    int h = 5;
    int x1, y1, x2, y2;
    void far *bg;
    if (w > SCR_W - 4) w = SCR_W - 4;
    if (w < (int)strlen(title) + 6) w = (int)strlen(title) + 6;
    center_box(w, h, &x1, &y1);
    x2 = x1 + w - 1; y2 = y1 + h - 1;

    bg = malloc((size_t)vid_bufsz(x1, y1, x2 + 2, y2 + 1));
    if (bg) vid_save(x1, y1, x2 + 2, y2 + 1, bg);

    draw_box(x1, y1, x2, y2, ATTR_DIALOG_BD, title, 1);
    draw_shadow(x1, y1, x2, y2);
    vid_puts(x1 + (w - (int)strlen(msg)) / 2, y1 + 2, msg, ATTR_DIALOG);
    {
        const char *ok = "[ OK ]";
        vid_puts(x1 + (w - (int)strlen(ok)) / 2, y2 - 1, ok, ATTR_MENUSEL);
    }
    for (;;) {
        int k = get_key();
        if (k == K_ENTER || k == K_ESC || k == ' ') break;
    }
    if (bg) { vid_restore(x1, y1, x2 + 2, y2 + 1, bg); free(bg); }
}

int dlg_confirm(const char *title, const char *msg)
{
    int w = (int)strlen(msg) + 8, h = 5;
    int x1, y1, x2, y2, sel = 0;
    void far *bg;
    if (w > SCR_W - 4) w = SCR_W - 4;
    center_box(w, h, &x1, &y1);
    x2 = x1 + w - 1; y2 = y1 + h - 1;

    bg = malloc((size_t)vid_bufsz(x1, y1, x2 + 2, y2 + 1));
    if (bg) vid_save(x1, y1, x2 + 2, y2 + 1, bg);
    draw_box(x1, y1, x2, y2, ATTR_DIALOG_BD, title, 1);
    draw_shadow(x1, y1, x2, y2);
    vid_puts(x1 + (w - (int)strlen(msg)) / 2, y1 + 2, msg, ATTR_DIALOG);

    for (;;) {
        int bx1 = x1 + w / 2 - 9, bx2 = x1 + w / 2 + 1;
        vid_puts(bx1, y2 - 1, " Yes ", sel == 0 ? ATTR_MENUSEL : ATTR_DIALOG);
        vid_puts(bx2, y2 - 1, " No  ", sel == 1 ? ATTR_MENUSEL : ATTR_DIALOG);
        {
            int k = get_key();
            if (k == K_LEFT || k == K_RIGHT || k == K_TAB) sel = !sel;
            else if (k == K_ENTER) { sel = sel ? 'N' : 'Y'; break; }
            else if (k == 'y' || k == 'Y') { sel = 'Y'; break; }
            else if (k == 'n' || k == 'N') { sel = 'N'; break; }
            else if (k == K_ESC) { sel = K_ESC; break; }
        }
    }
    if (bg) { vid_restore(x1, y1, x2 + 2, y2 + 1, bg); free(bg); }
    return sel;
}

#define DLG_BUFMAX 128

int dlg_input(const char *title, const char *prompt, char *buf, int maxlen)
{
    int w = maxlen + 8, h = 6;
    int x1, y1, x2, y2;
    void far *bg;
    char work[DLG_BUFMAX];
    int len, pos, k;

    if (maxlen > DLG_BUFMAX - 1) maxlen = DLG_BUFMAX - 1;

    if (w > SCR_W - 4) w = SCR_W - 4;
    if (w < (int)strlen(prompt) + 4) w = (int)strlen(prompt) + 4;
    if (w < (int)strlen(title) + 6) w = (int)strlen(title) + 6;
    center_box(w, h, &x1, &y1);
    x2 = x1 + w - 1; y2 = y1 + h - 1;

    bg = malloc((size_t)vid_bufsz(x1, y1, x2 + 2, y2 + 1));
    if (bg) vid_save(x1, y1, x2 + 2, y2 + 1, bg);
    draw_box(x1, y1, x2, y2, ATTR_DIALOG_BD, title, 1);
    draw_shadow(x1, y1, x2, y2);
    vid_puts(x1 + 2, y1 + 2, prompt, ATTR_DIALOG);

    strncpy(work, buf, sizeof(work) - 1); work[sizeof(work) - 1] = '\0';
    if ((int)strlen(work) > maxlen) work[maxlen] = '\0';
    len = (int)strlen(work);
    pos = len;

    for (;;) {
        int fx = x1 + 2, fy = y1 + 3, fw = w - 4;
        vid_fill(fx, fy, fx + fw - 1, fy, ' ', ATTR_MENUSEL);
        vid_puts(fx, fy, work, ATTR_MENUSEL);
        cursor_at(fx + pos, fy);
        cursor_show();
        k = get_key();
        if (k == K_ENTER) { strcpy(buf, work); cursor_hide();
            if (bg) { vid_restore(x1, y1, x2 + 2, y2 + 1, bg); free(bg); }
            return 1; }
        if (k == K_ESC) { cursor_hide();
            if (bg) { vid_restore(x1, y1, x2 + 2, y2 + 1, bg); free(bg); }
            return 0; }
        if (k == K_BACKSPACE) {
            if (pos > 0) { memmove(work + pos - 1, work + pos, len - pos + 1); pos--; len--; }
        } else if (k == K_DEL) {
            if (pos < len) { memmove(work + pos, work + pos + 1, len - pos); len--; }
        } else if (k == K_LEFT) { if (pos > 0) pos--; }
        else if (k == K_RIGHT) { if (pos < len) pos++; }
        else if (k == K_HOME) { pos = 0; }
        else if (k == K_END)  { pos = len; }
        else if (k >= 32 && k < 256 && len < maxlen) {
            memmove(work + pos + 1, work + pos, len - pos + 1);
            work[pos] = (char)k; pos++; len++;
        }
    }
}

int dlg_pick(const char *title, const char *const *items, int nitems)
{
    int w = 20, h, i, top = 0, sel = 0, maxrows;
    int x1, y1, x2, y2;
    void far *bg;

    for (i = 0; i < nitems; i++) {
        int l = (int)strlen(items[i]) + 4;
        if (l > w) w = l;
    }
    if (w > SCR_W - 4) w = SCR_W - 4;
    maxrows = nitems < 14 ? (nitems < 1 ? 1 : nitems) : 14;
    h = maxrows + 4;
    center_box(w, h, &x1, &y1);
    x2 = x1 + w - 1; y2 = y1 + h - 1;

    bg = malloc((size_t)vid_bufsz(x1, y1, x2 + 2, y2 + 1));
    if (bg) vid_save(x1, y1, x2 + 2, y2 + 1, bg);
    draw_box(x1, y1, x2, y2, ATTR_DIALOG_BD, title, 1);
    draw_shadow(x1, y1, x2, y2);

    if (nitems == 0) {
        vid_puts(x1 + 2, y1 + 2, "(nothing to show)", ATTR_DIALOG);
        get_key();
        if (bg) { vid_restore(x1, y1, x2 + 2, y2 + 1, bg); free(bg); }
        return -1;
    }

    for (;;) {
        int r;
        if (sel < top) top = sel;
        if (sel >= top + maxrows) top = sel - maxrows + 1;
        for (r = 0; r < maxrows; r++) {
            int idx = top + r;
            int attr = (idx == sel) ? ATTR_MENUSEL : ATTR_DIALOG;
            vid_fill(x1 + 1, y1 + 2 + r, x2 - 1, y1 + 2 + r, ' ', attr);
            if (idx < nitems) vid_puts(x1 + 2, y1 + 2 + r, items[idx], attr);
        }
        {
            int k = get_key();
            if (k == K_UP)   { if (sel > 0) sel--; }
            else if (k == K_DOWN) { if (sel < nitems - 1) sel++; }
            else if (k == K_PGUP) { sel -= maxrows; if (sel < 0) sel = 0; }
            else if (k == K_PGDN) { sel += maxrows; if (sel > nitems-1) sel = nitems-1; }
            else if (k == K_HOME) { sel = 0; }
            else if (k == K_END)  { sel = nitems - 1; }
            else if (k == K_ENTER) {
                if (bg) { vid_restore(x1, y1, x2 + 2, y2 + 1, bg); free(bg); }
                return sel;
            } else if (k == K_ESC) {
                if (bg) { vid_restore(x1, y1, x2 + 2, y2 + 1, bg); free(bg); }
                return -1;
            }
        }
    }
}

/* ========================================================================
 *  compile progress popup (Turbo-C-style "Compiling..." box)
 * ====================================================================== */
static int  cp_x1, cp_y1, cp_x2, cp_y2;
static void far *cp_bg;
static int  cp_open = 0;

#define CP_BARW 36   /* width of the progress gauge between its brackets */

void compile_progress_open(const char *filename)
{
    int w = 46, h = 9;
    char title[64];

    cp_x1 = (SCR_W - w) / 2 + 1;
    cp_y1 = (SCR_H - h) / 2 + 1;
    cp_x2 = cp_x1 + w - 1;
    cp_y2 = cp_y1 + h - 1;

    cp_bg = malloc((size_t)vid_bufsz(cp_x1, cp_y1, cp_x2 + 2, cp_y2 + 1));
    if (cp_bg) vid_save(cp_x1, cp_y1, cp_x2 + 2, cp_y2 + 1, cp_bg);

    sprintf(title, "Compiling %.30s", filename && *filename ? filename : "(unnamed)");
    draw_box(cp_x1, cp_y1, cp_x2, cp_y2, ATTR_DIALOG_BD, title, 1);

    vid_puts(cp_x1 + 3, cp_y1 + 2, "Pass:", ATTR_DIALOG);
    vid_puts(cp_x1 + 3, cp_y1 + 3, "Statements:", ATTR_DIALOG);
    vid_puts(cp_x1 + 3, cp_y1 + 4, "Errors:", ATTR_DIALOG);
    vid_putc(cp_x1 + 3, cp_y1 + 6, '[', ATTR_DIALOG);
    vid_putc(cp_x1 + 4 + CP_BARW, cp_y1 + 6, ']', ATTR_DIALOG);
    vid_fill(cp_x1 + 4, cp_y1 + 6, cp_x1 + 3 + CP_BARW, cp_y1 + 6, ' ', ATTR_DIALOG);

    cp_open = 1;
}

void compile_progress_update(int pass, int line_no, int total_lines, int err_count)
{
    char buf[40];
    int filled, i;

    if (!cp_open) return;

    sprintf(buf, "%d of 2  ", pass);
    vid_puts(cp_x1 + 16, cp_y1 + 2, buf, ATTR_DIALOG);

    sprintf(buf, "%5d / %-5d", line_no, total_lines);
    vid_puts(cp_x1 + 16, cp_y1 + 3, buf, ATTR_DIALOG);

    sprintf(buf, "%-5d", err_count);
    vid_puts(cp_x1 + 16, cp_y1 + 4, buf, ATTR_DIALOG);

    filled = (total_lines > 0) ? (int)((long)CP_BARW * line_no / total_lines) : 0;
    if (filled > CP_BARW) filled = CP_BARW;
    for (i = 0; i < CP_BARW; i++)
        vid_putc(cp_x1 + 4 + i, cp_y1 + 6, i < filled ? 219 : ' ', ATTR_DIALOG);
}

void compile_progress_close(void)
{
    if (!cp_open) return;
    if (cp_bg) { vid_restore(cp_x1, cp_y1, cp_x2 + 2, cp_y2 + 1, cp_bg); free(cp_bg); cp_bg = NULL; }
    cp_open = 0;
}

/* ========================================================================
 *  disassembly progress popup (same idea as the compile one above, but
 *  simpler -- disassembly has no "pass 1/2" or error count concept, just
 *  a byte offset moving through the loaded image) -- see ACPDCMD.C
 * ====================================================================== */
static int  dp_x1, dp_y1, dp_x2, dp_y2;
static void far *dp_bg;
static int  dp_open = 0;

#define DP_BARW 36

void disasm_progress_open(const char *filename)
{
    int w = 46, h = 7;
    char title[64];

    dp_x1 = (SCR_W - w) / 2 + 1;
    dp_y1 = (SCR_H - h) / 2 + 1;
    dp_x2 = dp_x1 + w - 1;
    dp_y2 = dp_y1 + h - 1;

    dp_bg = malloc((size_t)vid_bufsz(dp_x1, dp_y1, dp_x2 + 2, dp_y2 + 1));
    if (dp_bg) vid_save(dp_x1, dp_y1, dp_x2 + 2, dp_y2 + 1, dp_bg);

    sprintf(title, "Disassembling %.30s", filename && *filename ? filename : "(unnamed)");
    draw_box(dp_x1, dp_y1, dp_x2, dp_y2, ATTR_DIALOG_BD, title, 1);

    vid_puts(dp_x1 + 3, dp_y1 + 2, "Bytes:", ATTR_DIALOG);
    vid_putc(dp_x1 + 3, dp_y1 + 4, '[', ATTR_DIALOG);
    vid_putc(dp_x1 + 4 + DP_BARW, dp_y1 + 4, ']', ATTR_DIALOG);
    vid_fill(dp_x1 + 4, dp_y1 + 4, dp_x1 + 3 + DP_BARW, dp_y1 + 4, ' ', ATTR_DIALOG);

    dp_open = 1;
}

void disasm_progress_update(long done, long total)
{
    char buf[24];
    int filled, i;

    if (!dp_open) return;

    sprintf(buf, "%5ld / %-5ld", done, total);
    vid_puts(dp_x1 + 12, dp_y1 + 2, buf, ATTR_DIALOG);

    filled = (total > 0) ? (int)((long)DP_BARW * done / total) : 0;
    if (filled > DP_BARW) filled = DP_BARW;
    for (i = 0; i < DP_BARW; i++)
        vid_putc(dp_x1 + 4 + i, dp_y1 + 4, i < filled ? 219 : ' ', ATTR_DIALOG);
}

void disasm_progress_close(void)
{
    if (!dp_open) return;
    if (dp_bg) { vid_restore(dp_x1, dp_y1, dp_x2 + 2, dp_y2 + 1, dp_bg); free(dp_bg); dp_bg = NULL; }
    dp_open = 0;
}

/* ========================================================================
 *  text_view -- large read-only scrollable viewer (symbol/xref tables,
 *  and anything else too big for dlg_pick's compact box)
 * ====================================================================== */
void text_view(const char *title, const char *const *lines, int nlines)
{
    int x1 = 2, y1 = 2, x2 = 79, y2 = 23;
    int rows = y2 - y1 - 1;
    int iw = x2 - 1 - (x1 + 1) + 1;
    int top = 0;
    void far *bg;

    bg = malloc((size_t)vid_bufsz(x1, y1, x2 + 2, y2 + 1));
    if (bg) vid_save(x1, y1, x2 + 2, y2 + 1, bg);
    draw_box(x1, y1, x2, y2, ATTR_DIALOG_BD, title, 1);
    draw_shadow(x1, y1, x2, y2);

    if (nlines <= 0) {
        vid_puts(x1 + 2, y1 + 2, "(nothing to show)", ATTR_DIALOG);
        get_key();
    } else {
        for (;;) {
            int r;
            if (top > nlines - rows) top = nlines - rows;
            if (top < 0) top = 0;
            for (r = 0; r < rows; r++) {
                int idx = top + r;
                int y = y1 + 1 + r;
                vid_fill(x1 + 1, y, x2 - 1, y, ' ', ATTR_DIALOG);
                if (idx < nlines) {
                    char shown[100];
                    int n = (int)strlen(lines[idx]);
                    if (n > iw) n = iw;
                    if (n > (int)sizeof(shown) - 1) n = (int)sizeof(shown) - 1;
                    memcpy(shown, lines[idx], n); shown[n] = '\0';
                    vid_puts(x1 + 1, y, shown, ATTR_DIALOG);
                }
            }
            {
                int k = get_key();
                if (k == K_UP) top--;
                else if (k == K_DOWN) top++;
                else if (k == K_PGUP) top -= rows;
                else if (k == K_PGDN) top += rows;
                else if (k == K_HOME) top = 0;
                else if (k == K_END) top = nlines - rows;
                else if (k == K_ENTER || k == K_ESC) break;
            }
        }
    }
    if (bg) { vid_restore(x1, y1, x2 + 2, y2 + 1, bg); free(bg); }
}

/* ========================================================================
 *  dlg_file_browse -- directory browser built on dlg_pick()
 * ====================================================================== */
#define FB_MAXFILES 150
#define FB_NAMEW    16
static char **fb_names;

static void fb_ensure_init(void)
{
    int i;
    if (fb_names) return;
    fb_names = (char **)malloc((unsigned)FB_MAXFILES * sizeof(char *));
    if (!fb_names) return;
    for (i = 0; i < FB_MAXFILES; i++) fb_names[i] = (char *)malloc(FB_NAMEW);
}

int dlg_file_browse(char *out_name, int maxlen)
{
    fb_ensure_init();
    if (!fb_names) return 0;   /* out of memory -- nothing sensible to do */

    for (;;) {
        char cwd[80];
        int n = 0;
        struct ffblk ff;
        int done;
        int idx;
        int at_root;

        if (getcwd(cwd, sizeof(cwd)) == NULL) strcpy(cwd, "?");
        at_root = ((int)strlen(cwd) <= 3);   /* "C:\" or bare "\" */

        if (!at_root && n < FB_MAXFILES) { strcpy(fb_names[n], ".."); n++; }

        done = findfirst("*.*", &ff, FA_DIREC);
        while (!done && n < FB_MAXFILES) {
            if (strcmp(ff.ff_name, ".") != 0 && strcmp(ff.ff_name, "..") != 0) {
                if (ff.ff_attrib & FA_DIREC)
                    sprintf(fb_names[n], "[%.12s]", ff.ff_name);
                else
                    strncpy(fb_names[n], ff.ff_name, FB_NAMEW - 1);
                fb_names[n][FB_NAMEW - 1] = '\0';
                n++;
            }
            done = findnext(&ff);
        }

        idx = dlg_pick(cwd, (const char *const *)fb_names, n);
        if (idx < 0) return 0;

        if (strcmp(fb_names[idx], "..") == 0) {
            chdir("..");
            continue;
        }
        if (fb_names[idx][0] == '[') {
            char dname[FB_NAMEW];
            int len = (int)strlen(fb_names[idx]) - 2;   /* strip [ and ] */
            if (len > FB_NAMEW - 1) len = FB_NAMEW - 1;
            strncpy(dname, fb_names[idx] + 1, len); dname[len] = '\0';
            chdir(dname);
            continue;
        }

        strncpy(out_name, fb_names[idx], maxlen);
        out_name[maxlen] = '\0';
        return 1;
    }
}
