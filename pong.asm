0 ; =============================================================================
1 ; PONG  --  ADM-31 plugin ROM A ($E000-$E7FF, 2716), 2048 bytes
2 ;
3 ; One-player Pong for the Lear Siegler ADM-31.  You are the LEFT paddle,
4 ; the computer is the RIGHT paddle.  First to 7 wins.
5 ;
6 ;   UP / DOWN cursor keys  (or W / S, or the LEFT / RIGHT cursor keys the
7 ;                           way Rubout used them)   move your paddle
8 ;   SPACE                   serve / start a new game
9 ;   P                       pause / resume
10 ;
11 ; Paddle / collision logic is taken from Rubout (David Menard's Breakout
12 ; for this terminal), turned 90 degrees because Pong's paddles are
13 ; vertical.  What was kept, and where it came from in RUBOUT.ASM:
14 ;
15 ;   * Paddle = a run of identical characters ('#' here, '-' in Rubout)
16 ;     that SLIDES: one end is written, the other end is blanked.  The
17 ;     paddle is never redrawn as a whole while it moves.
18 ;     (RESET_07C / RESET_0AE)
19 ;   * Paddle input = direct PIA1 scan-code polling: write the scan code
20 ;     to $7800, bit 7 of the read-back = key is down.  Held keys keep
21 ;     moving the paddle, no key-repeat involved.  (same two routines)
22 ;   * Ball move = BALLCOL then BALLROW, then CALCADR turns (row,col) into
23 ;     a CRTRAM address.  (BALLMOV / BALLCOL / BALLROW / CALCADR)
24 ;   * Collision = HALT-strobe READ-BACK of the cell the ball is about to
25 ;     enter, then branch on the character found there.  Blank = move on,
26 ;     paddle char = bounce, anything else = wall.  The screen itself is
27 ;     the collision map.  (BALLMOV: TSTB / CMPB #$2D)
28 ;   * Direction flags are sign bytes toggled with COM, exactly like
29 ;     Rubout's $F4/$F5 (COM flips $80 <-> $7F).
30 ;   * After a bounce the ball is stepped back out and the cell is
31 ;     re-tested (Rubout's BRA BALLMOV_003 loop), so a ball that bounces
32 ;     into a corner is handled by the same code path.
33 ;   * Ball erase = only blank the previous cell if it still holds the ball
34 ;     glyph, so a paddle that has slid over it is never damaged.
35 ;   * Where the ball strikes the paddle picks the return direction
36 ;     (Rubout peeks 2 cells along the paddle with TST 2,X; here the hit
37 ;     cell's offset from the paddle's top picks one of 5 angles).
38 ;   * BEEP = PIA1 CRB bit 3 pulse, verbatim.
39 ;   * Cursor is hidden and PIA1B bit 2 cleared exactly as RESET_011 does.
40 ;
41 ; Computer player: tracks the ball's row (plus a random aim error that
42 ; changes every time you return the ball, sometimes big enough to miss),
43 ; moves one row every OTHER tick (half your speed) and drifts back to centre while the ball is going away.
44 ; Hit the ball with the ends of your paddle to make steep shots it cannot
45 ; keep up with.  The ball speeds up through a rally.
46 ;
47 ; Layout (80x24):  row 0 scores, row 1 and 22 walls, rows 2-21 court,
48 ; row 23 messages.  Paddles are 5 rows tall at col 4 (you) and col 75 (CPU).
49 ; =============================================================================
50 
51 HALT            EQU     $7000           ; VSYNC strobe (write before CRTRAM access)
52 PIA1            EQU     $7800           ; keyboard scan / strobe (bit7 = key down)
53 PIA1B           EQU     $7802
54 PIA1CRB         EQU     $7803           ; bit 3 = bell
55 CRTRAM          EQU     $8000
56 CRTC6           EQU     $7F06
57 CURCOL          EQU     $7F0C           ; cursor column register
58 
59 CH_PAD          EQU     $23             ; '#'  paddle
60 CH_WALL         EQU     $3D             ; '='  top / bottom wall
61 CH_NET          EQU     $3A             ; ':'  centre line
62 CH_BALL         EQU     $4F             ; 'O'  ball
63 
64 WINSC           EQU     7               ; points to win
65 DLYSTART        EQU     6400            ; tick delay at serve (DEX/BNE = 8 clocks)
66 
67 ; ---- RAM ($0100-$03FF is free; stack is at $03FF, same as the other games) --
68 HPAD            EQU     $0100           ; human paddle: +0 top row, +1 column
69 CPAD            EQU     $0102           ; computer paddle
70 BROW            EQU     $0104           ; ball row
71 BCOL            EQU     $0105           ; ball column
72 BHDIR           EQU     $0106           ; bit7 set = moving right
73 BVDIR           EQU     $0107           ; bit7 set = moving down
74 BVRATE          EQU     $0108           ; vertical step every N ticks (0 = flat)
75 BVCNT           EQU     $0109
76 CURADR          EQU     $010A           ; 2 bytes, ball's CRTRAM address
77 OLDADR          EQU     $010C           ; 2 bytes, previous ball address
78 OLDCOL          EQU     $010E
79 SCOREH          EQU     $010F
80 SCOREC          EQU     $0110
81 TICK            EQU     $0111
82 AIMOFF          EQU     $0112           ; computer's aim error, -3..+3
83 POINT           EQU     $0113           ; 0 none, 1 human scored, 2 CPU scored
84 LOSER           EQU     $0114           ; $80 serve toward CPU, $7F toward human
85 DLYCNT          EQU     $0115           ; 2 bytes, tick delay
86 SEED            EQU     $0117           ; 2 bytes, LFSR state
87 TRIES           EQU     $0119           ; bounce-retest limiter
88 ROWARG          EQU     $011A
89 COLARG          EQU     $011B
90 ADRPTR          EQU     $011C           ; 2 bytes
91 TMPA            EQU     $011E
92 TMPB            EQU     $011F
93 TMPX            EQU     $0120           ; 2 bytes
94 KPTR            EQU     $0122           ; 2 bytes
95 PSRC            EQU     $0124           ; 2 bytes
96 MPDIR           EQU     $0126
97 
98 ; =============================================================================
99         ORG     $E000
100         FCB     $54,$4A                 ; "TJ" plugin signature
101 KEYENTRY
102         RTS                             ; $E002: stock IRQ may call this; we SEI and poll
103 
104         ORG     $E03C
105         JMP     RESET                   ; ROM C jumps here after the "TJ" check
106 
107 ; Fixed-address callbacks stock ROMs B/C may JSR into (see ASTEROID.ASM).
108         ORG     $E07D
109 PLUGCB2 RTS
110         ORG     $E08A
111 ESCCB   RTS
112         ORG     $E0CA
113 PLUGCB3 RTS
114 
115 ; =============================================================================
116 ; RESET -- one-time init (same hardware setup as Rubout's RESET / RESET_011)
117 ; =============================================================================
118         ORG     $E100
119 RESET
120         SEI                             ; own the machine, we poll the keys
121         LDS     #$03FF
122         LDAA    #$17
123         STAA    CRTC6
124         COMA
125         STAA    CURCOL                  ; $E8 = cursor parked off screen
126         LDAA    PIA1B
127         ANDA    #$FB
128         STAA    PIA1B
129         LDX     #$ACE1
130         STX     SEED
131         CLR     TICK
132         CLR     AIMOFF
133 NEWMATCH
134         JSR     CLRSCR
135         CLR     SCOREH
136         CLR     SCOREC
137         LDAA    #$80
138         STAA    LOSER                   ; first serve goes toward the computer
139         JSR     DRAWFLD
140 SERVEPT
141         JSR     MSGCLR
142         LDAA    #23
143         STAA    ROWARG
144         LDAA    #15
145         STAA    COLARG
146         LDX     #SSERVE
147         JSR     PUTSTR
148         JSR     WAITSP
149         JSR     MSGCLR
150         JSR     SERVE
151 
152 ; ---- main game loop: one tick = poll, computer, ball, delay ---------------
153 GAME
154         JSR     POLLHUM
155         JSR     CPUAI
156         JSR     BALLMOV
157         LDX     DLYCNT
158 GDLY    DEX
159         BNE     GDLY
160         INC     TICK
161         TST     POINT
162         BEQ     GAME
163 
164 ; ---- somebody scored -------------------------------------------------------
165         JSR     BEEP
166         LDAA    POINT
167         CMPA    #1
168         BNE     GP_CPU
169         INC     SCOREH
170         LDAA    #$80
171         STAA    LOSER                   ; computer lost the point: serve to it
172         BRA     GP_SHOW
173 GP_CPU  INC     SCOREC
174         LDAA    #$7F
175         STAA    LOSER                   ; you lost the point: serve to you
176 GP_SHOW JSR     SHOWSC
177         LDAA    SCOREH
178         CMPA    #WINSC
179         BNE     GP_N1
180         LDX     #SWIN
181         BRA     ENDGAME
182 GP_N1   LDAA    SCOREC
183         CMPA    #WINSC
184         BNE     GP_NEXT
185         LDX     #SLOSE
186         BRA     ENDGAME
187 GP_NEXT JMP     SERVEPT
188 
189 ENDGAME
190         STX     KPTR
191         JSR     MSGCLR
192         LDAA    #23
193         STAA    ROWARG
194         LDAA    #22
195         STAA    COLARG
196         LDX     KPTR
197         JSR     PUTSTR
198         JSR     WAITSP
199         JMP     NEWMATCH
200 
201 ; =============================================================================
202 ; SERVE -- ball to the centre line at a random row, random angle
203 ; =============================================================================
204 SERVE
205         LDAA    #40
206         STAA    BCOL
207         JSR     RAND
208         ANDA    #$0F
209         ADDA    #4
210         STAA    BROW                    ; rows 4-19
211         LDAA    LOSER
212         STAA    BHDIR
213         JSR     RAND
214         STAA    BVDIR                   ; bit 7 = random up / down
215         JSR     RAND
216         ANDA    #1
217         INCA
218         STAA    BVRATE                  ; 1 = steep, 2 = shallow
219         STAA    BVCNT
220         LDX     #DLYSTART
221         STX     DLYCNT
222         CLR     POINT
223         LDAA    BROW
224         STAA    ROWARG
225         LDAA    BCOL
226         STAA    COLARG
227         STAA    OLDCOL
228         JSR     CALCADR
229         STX     CURADR
230         STX     OLDADR
231         LDAA    #CH_BALL
232         STAA    HALT
233         NOP
234         STAA    0,X
235         LDX     #0                      ; ~0.5 s breather so the ball can be seen
236 SV_DLY  DEX
237         BNE     SV_DLY
238         RTS
239 
240 ; =============================================================================
241 ; BALLMOV -- Rubout's BALLMOV: advance column, advance row, read back the
242 ; destination cell, branch on what is there.
243 ; =============================================================================
244 BALLMOV
245         LDX     CURADR
246         STX     OLDADR
247         LDAA    BCOL
248         STAA    OLDCOL
249         LDAA    #6
250         STAA    TRIES
251         JSR     BALLCOL
252         JSR     BALLROW
253 BM_EVAL
254         LDAA    BROW
255         STAA    ROWARG
256         LDAA    BCOL
257         STAA    COLARG
258         JSR     CALCADR
259         STX     CURADR
260         STAA    HALT                    ; sync to the CRT, then READ the cell
261         NOP
262         LDAB    0,X
263         DEC     TRIES
264         BEQ     BM_FREE                 ; safety valve: stop re-testing
265         TSTB
266         BEQ     BM_FREE                 ; blank
267         CMPB    #CH_NET
268         BEQ     BM_FREE                 ; centre line is passable
269         CMPB    #CH_PAD
270         BEQ     BM_PAD                  ; paddle
271         CMPB    #CH_WALL
272         BNE     BM_FREE
273         COM     BVDIR                   ; wall: flip vertical direction ...
274         JSR     BR_STEP                 ; ... step back out, re-test the cell
275         BRA     BM_EVAL
276 BM_PAD
277         JSR     PADHIT                  ; flip horizontal, pick the angle
278         JSR     BALLCOL                 ; step back out of the paddle column
279         BRA     BM_EVAL
280 
281 BM_FREE
282         LDAA    BCOL
283         CMPA    #2
284         BCS     BM_HMISS                ; got past your paddle
285         CMPA    #78
286         BCC     BM_CMISS                ; got past the computer's paddle
287         LDX     CURADR
288         LDAA    #CH_BALL
289         STAA    HALT
290         NOP
291         STAA    0,X
292 BM_ERASE
293         LDX     OLDADR
294         CPX     CURADR                  ; bounced straight back into the same cell?
295         BEQ     BM_DONE                 ; then the ball we just drew is the one there
296         STAA    HALT
297         NOP
298         LDAA    0,X
299         CMPA    #CH_BALL                ; only blank it if it is still the ball
300         BNE     BM_DONE
301         LDAA    OLDCOL
302         CMPA    #40
303         BEQ     BM_NET
304         CLRA
305         BRA     BM_WR
306 BM_NET  LDAA    #CH_NET                 ; restore the centre line
307 BM_WR   STAA    HALT
308         NOP
309         STAA    0,X
310 BM_DONE RTS
311 BM_HMISS
312         LDAA    #2
313         STAA    POINT                   ; computer scores
314         BRA     BM_ERASE
315 BM_CMISS
316         LDAA    #1
317         STAA    POINT                   ; you score
318         BRA     BM_ERASE
319 
320 ; BALLCOL -- Rubout's BALLCOL: step column by the sign flag.
321 BALLCOL
322         TST     BHDIR
323         BMI     BC_R
324         DEC     BCOL
325         RTS
326 BC_R    INC     BCOL
327         RTS
328 
329 ; BALLROW -- Rubout's BALLROW, with a tick divider so shallow shots move
330 ; one row every second tick.
331 BALLROW
332         LDAA    BVRATE
333         BEQ     BR_X                    ; flat shot
334         DEC     BVCNT
335         BNE     BR_X
336         STAA    BVCNT
337 BR_STEP TST     BVDIR
338         BMI     BR_D
339         DEC     BROW
340         RTS
341 BR_D    INC     BROW
342 BR_X    RTS
343 
344 ; PADHIT -- the ball has entered a paddle cell.  Reverse horizontal
345 ; direction, choose the angle from where on the paddle it landed, beep,
346 ; speed the rally up, and (when you hit it) re-roll the computer's aim.
347 ;   cell 0 up steep | 1 up shallow | 2 flat | 3 down shallow | 4 down steep
348 PADHIT
349         COM     BHDIR
350         LDX     #HPAD
351         LDAA    BCOL
352         CMPA    #40
353         BCS     PH_REC
354         LDX     #CPAD
355 PH_REC  LDAB    BROW
356         SUBB    0,X                     ; B = 0..4, offset from paddle top
357         BNE     PH_1
358         CLR     BVDIR
359         LDAA    #1
360         BRA     PH_SET
361 PH_1    DECB
362         BNE     PH_2
363         CLR     BVDIR
364         LDAA    #2
365         BRA     PH_SET
366 PH_2    DECB
367         BNE     PH_3
368         CLRA
369         BRA     PH_SET
370 PH_3    DECB
371         BNE     PH_4
372         LDAA    #$80
373         STAA    BVDIR
374         LDAA    #2
375         BRA     PH_SET
376 PH_4    LDAA    #$80
377         STAA    BVDIR
378         LDAA    #1
379 PH_SET  STAA    BVRATE
380         STAA    BVCNT
381         JSR     BEEP
382         LDAA    DLYCNT                  ; speed up: -200 per hit, floor ~3600
383         CMPA    #$0E
384         BCS     PH_AIM
385         LDAA    DLYCNT+1
386         SUBA    #200
387         STAA    DLYCNT+1
388         LDAA    DLYCNT
389         SBCA    #0
390         STAA    DLYCNT
391 PH_AIM  LDAA    BCOL
392         CMPA    #40
393         BCC     PH_X                    ; computer's hit: nothing more
394         JSR     RAND                    ; AIMOFF = -3..+3, bell-shaped (sum of two
395         STAA    TMPA                    ; 0-3 rolls, minus 3).  +-3 is outside the
396         ANDA    #3                      ; paddle: the computer misjudges ~1 in 8.
397         STAA    TMPB
398         LDAA    TMPA
399         LSRA
400         LSRA
401         ANDA    #3
402         ADDA    TMPB
403         SUBA    #3
404         STAA    AIMOFF
405 PH_X    RTS
406 
407 ; =============================================================================
408 ; POLLHUM -- scan the human's keys; first one found moves the paddle 1 row
409 ; =============================================================================
410 POLLHUM
411         LDAA    #$28                    ; P
412         STAA    PIA1
413         LDAA    PIA1
414         BPL     PK_NP
415         JSR     PAUSE
416 PK_NP   LDX     #KEYTAB
417 PK_LP   LDAA    0,X
418         BEQ     PK_END
419         STAA    PIA1
420         LDAA    PIA1
421         BMI     PK_HIT
422         INX
423         INX
424         BRA     PK_LP
425 PK_HIT  LDAA    1,X
426         LDX     #HPAD
427         JSR     MOVPAD
428 PK_END  RTS
429 
430 ; scan code, direction.   $53 up   $52 down  (cursor keys, ^K / ^J in KBDTAB)
431 ;                         $20 W    $31 S     $54 left $55 right (Rubout's keys)
432 KEYTAB  FCB     $53,$FF,$20,$FF,$54,$FF
433         FCB     $52,$01,$31,$01,$55,$01
434         FCB     0
435 
436 ; MOVPAD -- X = paddle record, A = $FF (up) or $01 (down).  Slides the
437 ; paddle one row: writes the new leading end, blanks the old trailing end.
438 ; Top row is limited to 2..17 (court rows 2-21).
439 MOVPAD
440         STAA    MPDIR
441         LDAB    0,X
442         ADDB    MPDIR
443         CMPB    #2
444         BCS     MP_X
445         CMPB    #18
446         BCC     MP_X
447         STAB    0,X
448         STAB    TMPB
449         LDAA    1,X
450         STAA    COLARG
451         TST     MPDIR
452         BMI     MP_UP
453         LDAA    TMPB                    ; down: draw top+4, blank top-1
454         ADDA    #4
455         STAA    ROWARG
456         LDAA    #CH_PAD
457         JSR     PUTAT
458         LDAA    TMPB
459         DECA
460         STAA    ROWARG
461         CLRA
462         JMP     PUTAT
463 MP_UP   LDAA    TMPB                    ; up: draw top, blank top+5
464         STAA    ROWARG
465         LDAA    #CH_PAD
466         JSR     PUTAT
467         LDAA    TMPB
468         ADDA    #5
469         STAA    ROWARG
470         CLRA
471         JMP     PUTAT
472 MP_X    RTS
473 
474 ; =============================================================================
475 ; CPUAI -- the computer player.  Moves every other tick.  Aims its paddle
476 ; centre at (ball row + AIMOFF) while the ball is coming at it, otherwise
477 ; drifts back to row 11.
478 ; =============================================================================
479 CPUAI
480         LDAA    TICK
481         ANDA    #1
482         BNE     CA_X
483         LDAA    #11
484         TST     BHDIR
485         BPL     CA_TGT                  ; ball going away
486         LDAA    BROW
487         ADDA    AIMOFF
488 CA_TGT  STAA    TMPA
489         LDAA    CPAD
490         ADDA    #2                      ; centre row of the paddle
491         CMPA    TMPA
492         BEQ     CA_X
493         BGT     CA_UP                   ; signed: target can be -1 near the top
494         LDAA    #1
495         BRA     CA_MV
496 CA_UP   LDAA    #$FF
497 CA_MV   LDX     #CPAD
498         JSR     MOVPAD
499 CA_X    RTS
500 
501 ; =============================================================================
502 ; PAUSE / WAITSP -- keyboard waits
503 ; =============================================================================
504 PAUSE
505         JSR     PZREL                   ; wait for P to be released
506         LDAA    #23
507         STAA    ROWARG
508         LDAA    #37
509         STAA    COLARG
510         LDX     #SPAUSE
511         JSR     PUTSTR
512 PZW     LDAA    #$28
513         STAA    PIA1
514         LDAA    PIA1
515         BPL     PZW                     ; wait for P to be pressed again
516         JSR     PZREL                   ; and released
517         JMP     MSGCLR
518 PZREL   LDAA    #$28
519         STAA    PIA1
520         LDAA    PIA1
521         BMI     PZREL
522         RTS
523 
524 ; WAITSP -- wait for SPACE (spinning the random generator while we wait,
525 ; which is what seeds each serve), then wait for it to be released.
526 WAITSP
527         JSR     RAND
528         LDAA    #$4B
529         STAA    PIA1
530         LDAA    PIA1
531         BPL     WAITSP
532 WSREL   LDAA    #$4B
533         STAA    PIA1
534         LDAA    PIA1
535         BMI     WSREL
536         RTS
537 
538 ; =============================================================================
539 ; SCREEN HELPERS
540 ; =============================================================================
541 ; PUTAT -- write A at (ROWARG,COLARG)
542 PUTAT
543         STAA    TMPA
544         JSR     CALCADR
545         LDAA    TMPA
546         STAA    HALT
547         NOP
548         STAA    0,X
549         RTS
550 
551 ; PUTSTR -- zero-terminated string at X, written from (ROWARG,COLARG)
552 PUTSTR
553         STX     PSRC
554 PS_LP   LDX     PSRC
555         LDAA    0,X
556         BEQ     PS_X
557         INX
558         STX     PSRC
559         JSR     PUTAT
560         INC     COLARG
561         BRA     PS_LP
562 PS_X    RTS
563 
564 ; HLINE -- A = char, B = count, X = first CRTRAM address
565 HLINE
566         STAA    HALT
567         NOP
568         STAA    0,X
569         INX
570         DECB
571         BNE     HLINE
572         RTS
573 
574 CLRSCR
575         LDX     #CRTRAM
576         CLRA
577 CS_LP   STAA    HALT
578         NOP
579         STAA    0,X
580         INX
581         CPX     #CRTRAM+1920
582         BNE     CS_LP
583         RTS
584 
585 MSGCLR
586         LDX     #CRTRAM+1840            ; row 23
587         LDAB    #80
588         CLRA
589         JMP     HLINE
590 
591 ; SHOWSC -- redraw both score digits
592 SHOWSC
593         CLR     ROWARG
594         LDAA    #8
595         STAA    COLARG
596         LDAA    SCOREH
597         ADDA    #$30
598         JSR     PUTAT
599         LDAA    #74
600         STAA    COLARG
601         LDAA    SCOREC
602         ADDA    #$30
603         JMP     PUTAT
604 
605 ; DRAWPAD -- X = paddle record; draw all 5 cells
606 DRAWPAD
607         LDAA    1,X
608         STAA    COLARG
609         LDAA    0,X
610         STAA    ROWARG
611         LDAA    #5
612         STAA    TMPB
613 DP_LP   LDAA    #CH_PAD
614         JSR     PUTAT
615         INC     ROWARG
616         DEC     TMPB
617         BNE     DP_LP
618         RTS
619 
620 ; DRAWFLD -- walls, centre line, captions, scores, paddles
621 DRAWFLD
622         LDAA    #CH_WALL
623         LDX     #CRTRAM+80
624         LDAB    #80
625         JSR     HLINE
626         LDAA    #CH_WALL
627         LDX     #CRTRAM+1760
628         LDAB    #80
629         JSR     HLINE
630         LDAA    #2
631         STAA    ROWARG
632         LDAA    #40
633         STAA    COLARG
634 DF_NET  LDAA    #CH_NET
635         JSR     PUTAT
636         INC     ROWARG
637         LDAA    ROWARG
638         CMPA    #22
639         BNE     DF_NET
640         CLR     ROWARG
641         LDAA    #4
642         STAA    COLARG
643         LDX     #SYOU
644         JSR     PUTSTR
645         CLR     ROWARG
646         LDAA    #34
647         STAA    COLARG
648         LDX     #STITLE
649         JSR     PUTSTR
650         CLR     ROWARG
651         LDAA    #70
652         STAA    COLARG
653         LDX     #SCPU
654         JSR     PUTSTR
655         JSR     SHOWSC
656         LDAA    #9
657         STAA    HPAD
658         STAA    CPAD
659         LDAA    #4
660         STAA    HPAD+1
661         LDAA    #75
662         STAA    CPAD+1
663         LDX     #HPAD
664         JSR     DRAWPAD
665         LDX     #CPAD
666         JMP     DRAWPAD
667 
668 ; CALCADR -- (ROWARG,COLARG) -> X = CRTRAM + row*80 + col  (as ASTEROID.ASM)
669 CALCADR
670         CLR     ADRPTR
671         LDAA    ROWARG
672         STAA    ADRPTR+1
673         ASL     ADRPTR+1
674         ROL     ADRPTR
675         ASL     ADRPTR+1
676         ROL     ADRPTR
677         ASL     ADRPTR+1
678         ROL     ADRPTR
679         ASL     ADRPTR+1
680         ROL     ADRPTR                  ; row*16
681         LDAA    ADRPTR
682         LDAB    ADRPTR+1
683         PSHA
684         PSHB
685         ASL     ADRPTR+1
686         ROL     ADRPTR
687         ASL     ADRPTR+1
688         ROL     ADRPTR                  ; row*64
689         PULB
690         ADDB    ADRPTR+1
691         STAB    ADRPTR+1
692         PULA
693         ADCA    ADRPTR
694         STAA    ADRPTR                  ; row*80
695         LDAA    COLARG
696         ADDA    ADRPTR+1
697         STAA    ADRPTR+1
698         LDAA    ADRPTR
699         ADCA    #0
700         ADDA    #$80                    ; + CRTRAM ($8000)
701         STAA    ADRPTR
702         LDX     ADRPTR
703         RTS
704 
705 ; RAND -- 16-bit Galois LFSR (taps $B400), returns A = low byte
706 RAND
707         LDAA    SEED+1
708         ANDA    #1
709         STAA    TMPA
710         LSR     SEED
711         ROR     SEED+1
712         TST     TMPA
713         BEQ     RND_X
714         LDAA    SEED
715         EORA    #$B4
716         STAA    SEED
717 RND_X   LDAA    SEED+1
718         RTS
719 
720 ; BEEP -- Rubout's BEEP: pulse PIA1 CRB bit 3
721 BEEP
722         LDAA    PIA1CRB
723         ANDA    #$F7
724         STAA    PIA1CRB
725         ORAA    #$08
726         STAA    PIA1CRB
727         RTS
728 
729 ; =============================================================================
730 ; TEXT (plain ASCII, stock character generator)
731 ; =============================================================================
732 SYOU    FCC     "YOU"
733         FCB     0
734 SCPU    FCC     "CPU"
735         FCB     0
736 STITLE  FCC     "ADM-31 PONG"
737         FCB     0
738 SSERVE  FCC     "SPACE=SERVE  UP/DOWN OR W/S=MOVE  P=PAUSE"
739         FCB     0
740 SPAUSE  FCC     "PAUSED"
741         FCB     0
742 SWIN    FCC     "YOU WIN!  SPACE = NEW GAME"
743         FCB     0
744 SLOSE   FCC     "CPU WINS  SPACE = NEW GAME"
745         FCB     0
746 
747         ORG     $E7FF
748         FCB     $FF                     ; end-of-bank marker
749 
750         END
751 