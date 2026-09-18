/* ========================================================================
 * ACPEDIT.H  -  Edit window (source buffer) and Message window (assembler
 *               output / error list) for ACPIDE.
 * ====================================================================== */
#ifndef ACPIDE_ACPEDIT_H
#define ACPIDE_ACPEDIT_H

/* ---- screen layout ------------------------------------------------------
 * row 1        menu bar (drawn by menu_bar() itself)
 * rows 2-18    Edit window   (17 rows: border + 15 text rows + border) --
 *              or rows 2-24 (full height) when the message window is
 *              toggled off; see ed_bottom()/ed_rows() below.
 * rows 19-24   Message window (6 rows: border + 4 text rows + border) --
 *              entirely absent when show_msgwin is 0.
 * row 25       status line                                              */
#define ED_X1 1
#define ED_Y1 2
#define ED_X2 80
#define ED_Y2_SPLIT 16    /* edit window bottom when message window shown  */
#define ED_Y2_FULL  24    /* edit window bottom when message window hidden */
#define ED_GUTTER 5                       /* line-number column width     */
#define ED_LISTW  19                      /* "NNNN CCCCCCCCCCCC  " prefix
                                            * width for the listing view   */

#define MSG_X1 1
#define MSG_Y1 17
#define MSG_X2 80
#define MSG_Y2 24
#define MSG_ROWS (MSG_Y2 - MSG_Y1 - 1)

#define STATUS_Y 25

#define FOCUS_EDIT 0
#define FOCUS_MSG  1

#define COMPILE_UNKNOWN 0   /* never assembled, or edited since            */
#define COMPILE_OK      1
#define COMPILE_ERR     2

extern int   ed_dirty;               /* 1 if buffer has unsaved changes    */
extern char  ed_filename[LINELEN];   /* "" if the buffer has never been named */
extern int   ide_focus;              /* FOCUS_EDIT or FOCUS_MSG            */
extern int   show_gutter;            /* 1 = show line numbers (default on) */
extern int   show_listing;           /* 1 = show ADDR/CODE columns too     */
extern int   listing_valid;          /* 1 if show_listing's data matches
                                       * the current buffer (see acp_assemble
                                       * in ACPMAIN.C / mark_dirty() below) */
extern int   show_msgwin;            /* 1 = message window visible (default on) */
extern int   compile_status;         /* COMPILE_UNKNOWN/OK/ERR, for the title
                                       * bar colour and status-line badge   */
extern int   last_err_count;         /* error count from the last assemble,
                                       * shown in the status-line badge     */

int  ed_bottom(void);                        /* current edit-window bottom row */
int  ed_rows(void);                          /* current edit-window interior rows */

void editor_new(void);                       /* clear buffer, one blank line */
int  editor_load(const char *name);          /* 0 ok, -1 not found            */
int  editor_save(const char *name);          /* 0 ok, -1 write error          */
void editor_draw(void);                      /* redraws edit + status         */
void editor_key(int k);                      /* handle one keypress           */
void editor_goto_line(int dispno);           /* used for error navigation     */

void msg_init(void);                         /* one-time heap allocation      */
void msg_clear(void);
void msg_add(const char *text, int dispno);  /* dispno 0 = not a source ref  */
void msg_draw(void);
void msg_key(int k);                         /* handle one keypress           */
int  msg_first_err_dispno(void);             /* 0 if no message has a dispno   */
void msg_scroll_to_first_error(void);        /* show errors, not the tail      */

void status_draw(void);                      /* bottom status line             */

/* installed with acp_set_err_hook() so pass1/pass2 errors land here       */
void editor_err_hook(int dispno, const char *msg, const char *what);

#endif /* ACPIDE_ACPEDIT_H */
