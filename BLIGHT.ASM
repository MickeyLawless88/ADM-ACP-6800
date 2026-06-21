; =============================================================================
; B L I G H T   --  ADM-31 plugin ROM ($E000-$E7FF)
; By: Mickey White Lawless
; PREMISE:
;   Ark-ship MERIDIAN, grow-deck 4.  A spore-blight is loose in the crop
;   trays and creeps to the next crops every cycle.  You pilot containment
;   drone B-7.  Moving onto a tray SCORCHES it to bare deck -- a firebreak
;   the blight cannot cross.  Burn lines, starve the blight, save the harvest.
;
;   Cells:  Y crop (fuel)   * blight   x dead tray   . bare deck   @ drone
;   Each cycle the blight spreads one tray in each direction into adjacent
;   crops; spent blight burns out to dead (x).  Game ends when no blight
;   remains.  Score = crops still standing.
;
; Build/run:  assemble with acp6800 (pad 2048), load as --romA in adm31emu.
; =============================================================================

HALT            EQU     $7000           ; VSYNC strobe (write before CRTRAM)
PIA1            EQU     $7800           ; keyboard scan / strobe (bit7)
PIA1B           EQU     $7802           ; SHIFT(bit7)/CTRL(bit6)
CRTRAM          EQU     $8000           ; 80x24 display RAM
KBDTAB          EQU     $EA1A           ; firmware keycode table {unsh,sh}

; ---- zero page state ----
       
SCRNPTR         RMB     2               ; CRTRAM write cursor
CELLPTR         RMB     2               ; grid cell pointer
KPTR            RMB     2               ; keytable pointer
PSRC            RMB     2               ; PUTSTR source pointer
SEED            RMB     2               ; LFSR rng state
PX              RMB     1               ; drone column 0..7
PY              RMB     1               ; drone row 0..7
CYCLE           RMB     1
TREES           RMB     1               ; living crops
BURNED          RMB     1               ; dead trays
FIRES           RMB     1               ; active blight cells
CUTS            RMB     1               ; scorched (firebreaks burned)
ROWV            RMB     1
COLV            RMB     1
NROW            RMB     1
NCOL            RMB     1
KSCAN           RMB     1
KCHAR           RMB     1
TMPA            RMB     1
TMPB            RMB     1
IDX             RMB     1
QUITF           RMB     1
MSGCODE         RMB     1
DXX             RMB     1               ; move delta col (signed)
DYY             RMB     1               ; move delta row (signed)

GRID            EQU     $0100           ; 64 bytes, page-aligned ($0100-$013F)

; cell codes: 0 bare  1 crop  2 blight  3 dead  4 ignite(temp)

; =============================================================================
        ORG     $E000
        FCB     $54,$4A                 ; "TJ" plugin signature

        ORG     $E03C
        JMP     START

; =============================================================================
START
        SEI                             ; own the machine
        LDS     #$03FF
        JSR     TITLE                   ; premise screen + seed rng
NEWGAME
        JSR     INITGRID
        CLR     QUITF
        CLR     MSGCODE
GLOOP
        JSR     DRAW
        JSR     GETCMD                  ; move/scorch, or set QUITF
        LDAA    QUITF
        BNE     GOVER
        JSR     SPREAD                  ; blight creeps one ring
        INC     CYCLE
        LDAA    FIRES
        BNE     GLOOP                   ; blight remains -> keep playing
GOVER
        JSR     DRAW                    ; final board
        JSR     ENDSCREEN
        JMP     NEWGAME

; =============================================================================
; INITGRID - scatter crops via LFSR, seed blight at centre, place drone.
; =============================================================================
INITGRID
        CLR     IDX
IG1
        JSR     RAND                    ; A = pseudo-random byte
        ANDA    #3
        BNE     IGCROP                  ; 3/4 crop, 1/4 bare
        CLRA
        BRA     IGSET
IGCROP
        LDAA    #1
IGSET
        LDAB    #$01
        STAB    CELLPTR
        LDAB    IDX
        STAB    CELLPTR+1
        LDX     CELLPTR
        STAA    0,X
        INC     IDX
        LDAA    IDX
        CMPA    #64
        BNE     IG1
; seed blight 2x2 at centre (rows 3-4, cols 3-4 -> idx 27,28,35,36)
        LDAA    #2
        LDX     #GRID+27
        STAA    0,X
        LDX     #GRID+28
        STAA    0,X
        LDX     #GRID+35
        STAA    0,X
        LDX     #GRID+36
        STAA    0,X
; drone at (1,1); clear that tray
        LDAA    #1
        STAA    PX
        STAA    PY
        LDX     #GRID+9
        CLR     0,X
; counters
        CLR     CYCLE
        CLR     BURNED
        CLR     CUTS
        JSR     RECNT                   ; set TREES, FIRES
        RTS

; =============================================================================
; RAND - 16-bit Galois LFSR (taps $B400).  Returns A=low byte. Clobbers A,TMPA.
; =============================================================================
RAND
        LDAA    SEED+1
        ANDA    #1
        STAA    TMPA                    ; out bit
        LSR     SEED
        ROR     SEED+1
        TST     TMPA
        BEQ     RNDX
        LDAA    SEED
        EORA    #$B4
        STAA    SEED
RNDX
        LDAA    SEED+1
        RTS

; =============================================================================
; RECNT - recount FIRES (blight) and TREES (crops) across the grid.
; =============================================================================
RECNT
        CLR     FIRES
        CLR     TREES
        LDAB    #0
RC1
        LDAA    #$01
        STAA    CELLPTR
        STAB    CELLPTR+1
        LDX     CELLPTR
        LDAA    0,X
        CMPA    #2
        BNE     RC2
        INC     FIRES
        BRA     RCN
RC2
        CMPA    #1
        BNE     RCN
        INC     TREES
RCN
        INCB
        CMPB    #64
        BNE     RC1
        RTS

; =============================================================================
; SPREAD - blight creeps one ring; spent blight burns out.
;   Phase A: every blight(2) marks adjacent crop(1) as ignite(4).
;   Phase B: blight(2)->dead(3), ignite(4)->blight(2).  Then recount.
; =============================================================================
SPREAD
        LDAB    #0                      ; B = index, preserved across IGNB
SPA
        LDAA    #$01
        STAA    CELLPTR
        STAB    CELLPTR+1
        LDX     CELLPTR
        LDAA    0,X
        CMPA    #2
        BNE     SPAN
; compute row/col of this blight cell
        TBA
        ANDA    #7
        STAA    COLV
        TBA
        LSRA
        LSRA
        LSRA
        STAA    ROWV
; up
        TST     ROWV
        BEQ     SPADN
        PSHB
        SUBB    #8
        JSR     IGNB
        PULB
SPADN
        LDAA    ROWV
        CMPA    #7
        BEQ     SPALF
        PSHB
        ADDB    #8
        JSR     IGNB
        PULB
SPALF
        TST     COLV
        BEQ     SPART
        PSHB
        DECB
        JSR     IGNB
        PULB
SPART
        LDAA    COLV
        CMPA    #7
        BEQ     SPAN
        PSHB
        INCB
        JSR     IGNB
        PULB
SPAN
        INCB
        CMPB    #64
        BNE     SPA
; phase B
        LDAB    #0
SPB
        LDAA    #$01
        STAA    CELLPTR
        STAB    CELLPTR+1
        LDX     CELLPTR
        LDAA    0,X
        CMPA    #2
        BNE     SPB1
        LDAA    #3
        STAA    0,X
        INC     BURNED
        BRA     SPBN
SPB1
        CMPA    #4
        BNE     SPBN
        LDAA    #2
        STAA    0,X
SPBN
        INCB
        CMPB    #64
        BNE     SPB
        JSR     RECNT
        RTS

; IGNB - if GRID[B]==crop(1) set it to ignite(4).  Clobbers A,X,CELLPTR.
IGNB
        LDAA    #$01
        STAA    CELLPTR
        STAB    CELLPTR+1
        LDX     CELLPTR
        LDAA    0,X
        CMPA    #1
        BNE     IGNBX
        LDAA    #4
        STAA    0,X
IGNBX
        RTS

; =============================================================================
; GETCMD - read a command; move/scorch the drone, pass, or quit.
; =============================================================================
GETCMD
GCRD
        JSR     GETC                    ; A = ascii of pressed key
        TAB                             ; keep raw in B (for space test)
        ANDA    #$DF                    ; fold letters to upper (n->N)
        CMPA    #'Q
        BNE     GCNQ
        JMP     GCQUIT
GCNQ
        CMPB    #$20                    ; space = wait
        BEQ     GCPASS
        CMPA    #'P
        BEQ     GCPASS
        CMPA    #'N
        BNE     GCS
        CLR     DXX
        LDAA    #$FF
        STAA    DYY
        BRA     GCTRY
GCS
        CMPA    #'S
        BNE     GCE
        CLR     DXX
        LDAA    #1
        STAA    DYY
        BRA     GCTRY
GCE
        CMPA    #'E
        BNE     GCW
        LDAA    #1
        STAA    DXX
        CLR     DYY
        BRA     GCTRY
GCW
        CMPA    #'W
        BNE     GCRD                    ; unknown key -> re-read
        LDAA    #$FF
        STAA    DXX
        CLR     DYY
GCTRY
        LDAA    PY
        ADDA    DYY
        CMPA    #8
        BCC     GCBLK                   ; >=8 (or $FF) off-grid
        STAA    NROW
        LDAA    PX
        ADDA    DXX
        CMPA    #8
        BCC     GCBLK
        STAA    NCOL
        LDAA    NROW
        STAA    ROWV
        LDAA    NCOL
        STAA    COLV
        JSR     CELLADDR
        LDAA    0,X
        CMPA    #2                       ; blight -> can't enter
        BEQ     GCBLK
        CMPA    #3                       ; dead -> can't enter
        BEQ     GCBLK
        CMPA    #1                       ; crop -> scorch costs a crop
        BNE     GCMOVE
        DEC     TREES
        INC     CUTS
GCMOVE
        CLRA
        STAA    0,X                      ; scorch tray to bare deck
        LDAA    NROW
        STAA    PY
        LDAA    NCOL
        STAA    PX
        CLR     MSGCODE
        RTS
GCBLK
        LDAA    #1
        STAA    MSGCODE
        JMP     GCRD                     ; blocked -> re-read (no wasted cycle)
GCPASS
        LDAA    #2
        STAA    MSGCODE
        RTS
GCQUIT
        LDAA    #1
        STAA    QUITF
        RTS

; =============================================================================
; DRAW - clear screen, draw title/grid/status/prompt.
; =============================================================================
DRAW
        JSR     CLRSCRN
        LDAA    #0
        LDAB    #25
        JSR     GOTOXY
        LDX     #SBANNER
        JSR     PUTSTR
        LDAA    #2
        LDAB    #4
        JSR     GOTOXY
        LDX     #SHDR
        JSR     PUTSTR
        CLR     ROWV
DR1
        LDAA    ROWV
        ADDA    #3
        LDAB    #2
        JSR     GOTOXY
        LDAA    ROWV
        ADDA    #'1
        JSR     PUTC                     ; row label digit
        CLR     COLV
DR2
        LDAA    #$20
        JSR     PUTC                     ; column gap
        LDAA    PY
        CMPA    ROWV
        BNE     DRCELL
        LDAA    PX
        CMPA    COLV
        BNE     DRCELL
        LDAA    #'@
        JSR     PUTC                     ; drone here
        BRA     DRNX
DRCELL
        JSR     CELLADDR
        LDAA    0,X
        JSR     GLYPH
        JSR     PUTC
DRNX
        INC     COLV
        LDAA    COLV
        CMPA    #8
        BNE     DR2
        INC     ROWV
        LDAA    ROWV
        CMPA    #8
        BNE     DR1
        JSR     DRAWSTAT
        JSR     DRAWMSG
        RTS

; GLYPH - cell code in A -> display char in A.
GLYPH
        CMPA    #1
        BNE     GL2
        LDAA    #'Y
        RTS
GL2
        CMPA    #2
        BNE     GL3
        LDAA    #'*
        RTS
GL3
        CMPA    #3
        BNE     GL0
        LDAA    #'x
        RTS
GL0
        LDAA    #'.
        RTS

; DRAWSTAT - the right-hand status panel.
DRAWSTAT
        LDAA    #3
        LDAB    #40
        JSR     GOTOXY
        LDX     #SLCYC
        JSR     PUTSTR
        LDAA    CYCLE
        JSR     PRDEC2
        LDAA    #4
        LDAB    #40
        JSR     GOTOXY
        LDX     #SLCROP
        JSR     PUTSTR
        LDAA    TREES
        JSR     PRDEC2
        LDAA    #5
        LDAB    #40
        JSR     GOTOXY
        LDX     #SLLOST
        JSR     PUTSTR
        LDAA    BURNED
        JSR     PRDEC2
        LDAA    #6
        LDAB    #40
        JSR     GOTOXY
        LDX     #SLBL
        JSR     PUTSTR
        LDAA    FIRES
        JSR     PRDEC2
        LDAA    #7
        LDAB    #40
        JSR     GOTOXY
        LDX     #SLSC
        JSR     PUTSTR
        LDAA    CUTS
        JSR     PRDEC2
        RTS

; DRAWMSG - flavour line, event line, command prompt.
DRAWMSG
        LDAA    #11
        LDAB    #2
        JSR     GOTOXY
        LDX     #SFLAV
        JSR     PUTSTR
        LDAA    #12
        LDAB    #2
        JSR     GOTOXY
        LDAA    MSGCODE
        CMPA    #2
        BNE     DMP
        LDX     #SHOLD
        JSR     PUTSTR
DMP
        LDAA    #14
        LDAB    #2
        JSR     GOTOXY
        LDX     #SPROMPT
        JSR     PUTSTR
        RTS

; =============================================================================
; ENDSCREEN - result + score + rank, wait for key.
; =============================================================================
ENDSCREEN
        LDAA    #16
        LDAB    #2
        JSR     GOTOXY
        LDAA    QUITF
        BNE     ESAB
        LDX     #SCONTN
        JSR     PUTSTR
        BRA     ESSC
ESAB
        LDX     #SABORT
        JSR     PUTSTR
ESSC
        LDAA    #17
        LDAB    #2
        JSR     GOTOXY
        LDX     #SCROPSV
        JSR     PUTSTR
        LDAA    TREES
        JSR     PRDEC2
        LDAA    #18
        LDAB    #2
        JSR     GOTOXY
        LDAA    TREES
        CMPA    #30
        BCS     ESR2
        LDX     #SRANK1
        BRA     ESPR
ESR2
        CMPA    #15
        BCS     ESR3
        LDX     #SRANK2
        BRA     ESPR
ESR3
        LDX     #SRANK3
ESPR
        JSR     PUTSTR
        LDAA    #20
        LDAB    #2
        JSR     GOTOXY
        LDX     #SAGAIN
        JSR     PUTSTR
        JSR     GETC
        RTS

; =============================================================================
; TITLE - premise screen; seed the rng from how long the operator waits.
; =============================================================================
TITLE
        JSR     CLRSCRN
        LDAA    #1
        LDAB    #28
        JSR     GOTOXY
        LDX     #STITLE
        JSR     PUTSTR
        LDAA    #4
        LDAB    #4
        JSR     GOTOXY
        LDX     #SP1
        JSR     PUTSTR
        LDAA    #6
        LDAB    #4
        JSR     GOTOXY
        LDX     #SP2
        JSR     PUTSTR
        LDAA    #7
        LDAB    #4
        JSR     GOTOXY
        LDX     #SP3
        JSR     PUTSTR
        LDAA    #9
        LDAB    #4
        JSR     GOTOXY
        LDX     #SP4
        JSR     PUTSTR
        LDAA    #10
        LDAB    #4
        JSR     GOTOXY
        LDX     #SP5
        JSR     PUTSTR
        LDAA    #12
        LDAB    #4
        JSR     GOTOXY
        LDX     #SP6
        JSR     PUTSTR
        LDAA    #14
        LDAB    #4
        JSR     GOTOXY
        LDX     #SLEGEND
        JSR     PUTSTR
        LDAA    #17
        LDAB    #4
        JSR     GOTOXY
        LDX     #SPK
        JSR     PUTSTR
; seed loop
        LDX     #$ACE1
        STX     SEED
TWAIT
        INC     SEED+1
        BNE     TW2
        INC     SEED
TW2
        JSR     ANYKEY
        TSTA
        BEQ     TWAIT
        JSR     GETC                    ; consume + debounce-release
        RTS

; =============================================================================
; CELLADDR - in: ROWV,COLV ; out: X = GRID + ROWV*8 + COLV. Clobbers A.
; =============================================================================
CELLADDR
        LDAA    ROWV
        ASLA
        ASLA
        ASLA
        ADDA    COLV
        STAA    CELLPTR+1
        LDAA    #$01
        STAA    CELLPTR
        LDX     CELLPTR
        RTS

; =============================================================================
; PRDEC2 - print A (0..99) as two decimal digits.
; =============================================================================
PRDEC2
        LDAB    #0
P2A
        CMPA    #10
        BCS     P2B
        SUBA    #10
        INCB
        BRA     P2A
P2B
        PSHA
        TBA
        ADDA    #'0
        JSR     PUTC
        PULA
        ADDA    #'0
        JSR     PUTC
        RTS

; =============================================================================
; SCREEN I/O
; =============================================================================
; GOTOXY - A=row B=col -> SCRNPTR. Clobbers A,B,X,TMPA.
GOTOXY
        STAB    TMPA
        LDX     #CRTRAM
        STX     SCRNPTR
GXY1
        TSTA
        BEQ     GXY2
        LDAB    SCRNPTR+1
        ADDB    #80
        STAB    SCRNPTR+1
        LDAB    SCRNPTR
        ADCB    #0
        STAB    SCRNPTR
        DECA
        BRA     GXY1
GXY2
        LDAB    SCRNPTR+1
        ADDB    TMPA
        STAB    SCRNPTR+1
        LDAB    SCRNPTR
        ADCB    #0
        STAB    SCRNPTR
        RTS

; PUTC - write char A to SCRNPTR, advance. Clobbers A,X,TMPB.
PUTC
        STAA    TMPB
        STAA    HALT
        NOP
        LDX     SCRNPTR
        LDAA    TMPB
        STAA    0,X
        INX
        STX     SCRNPTR
        RTS

; PUTSTR - print null-terminated string at X.
PUTSTR
        STX     PSRC
PS1
        LDX     PSRC
        LDAA    0,X
        BEQ     PSX
        INX
        STX     PSRC
        JSR     PUTC
        BRA     PS1
PSX
        RTS

; CLRSCRN - blank the visible 80x24.
CLRSCRN
        LDX     #CRTRAM
CLS1
        LDAA    #$20
        STAA    HALT
        NOP
        STAA    0,X
        INX
        CPX     #CRTRAM+1920
        BNE     CLS1
        RTS

; =============================================================================
; KEYBOARD ($EA1A decode + release wait)
; =============================================================================
; GETC - block until a key, return ascii in A.
GETC
GC0
        CLRB
GC1
        STAB    PIA1
        LDAA    PIA1
        BMI     GCHIT
        INCB
        CMPB    #$58
        BNE     GC1
        BRA     GC0
GCHIT
        STAB    KSCAN
        ASLB
        LDAA    PIA1B
        BPL     GCNS
        INCB
GCNS
        LDX     #KBDTAB
        STX     KPTR
        ADDB    KPTR+1
        STAB    KPTR+1
        LDAA    KPTR
        ADCA    #0
        STAA    KPTR
        LDX     KPTR
        LDAA    0,X
        STAA    KCHAR
        LDAB    KSCAN
GCRL
        STAB    PIA1
        LDAA    PIA1
        BMI     GCRL
        LDAA    KCHAR
        RTS

; ANYKEY - A=$FF if any key is down, else 0.
ANYKEY
        CLRB
AK1
        STAB    PIA1
        LDAA    PIA1
        BMI     AKYES
        INCB
        CMPB    #$58
        BNE     AK1
        CLRA
        RTS
AKYES
        LDAA    #$FF
        RTS

; =============================================================================
; TEXT
; =============================================================================
STITLE   FCC     "*   B L I G H T   *"
         FCB     0
SBANNER  FCC     "B L I G H T   ::   MERIDIAN GROW-DECK 4"
         FCB     0
SP1      FCC     "ARK-SHIP MERIDIAN  --  GROW-DECK 4"
         FCB     0
SP2      FCC     "A SPORE-BLIGHT IS LOOSE IN THE CROP TRAYS."
         FCB     0
SP3      FCC     "EVERY CYCLE IT CREEPS TO THE NEXT CROPS."
         FCB     0
SP4      FCC     "PILOT DRONE B-7.  MOVE ONTO A TRAY TO SCORCH"
         FCB     0
SP5      FCC     "IT TO BARE DECK -- A LINE THE BLIGHT CANT CROSS."
         FCB     0
SP6      FCC     "SPEND A FEW CROPS TO SAVE THE HARVEST."
         FCB     0
SLEGEND  FCC     "Y=CROP  *=BLIGHT  x=DEAD  .=DECK  @=DRONE"
         FCB     0
SPK      FCC     "PRESS ANY KEY TO BEGIN"
         FCB     0
SHDR     FCC     "1 2 3 4 5 6 7 8"
         FCB     0
SLCYC    FCC     "CYCLE:  "
         FCB     0
SLCROP   FCC     "CROPS:  "
         FCB     0
SLLOST   FCC     "LOST:   "
         FCB     0
SLBL     FCC     "BLIGHT: "
         FCB     0
SLSC     FCC     "SCORCH: "
         FCB     0
SFLAV    FCC     "GROW-DECK 4  ::  CONTAINMENT ACTIVE"
         FCB     0
SHOLD    FCC     "DRONE HOLDS POSITION."
         FCB     0
SPROMPT  FCC     "MOVE N/E/S/W   SPC=WAIT   Q=ABORT ? "
         FCB     0
SCONTN   FCC     "*** BLIGHT CONTAINED ***"
         FCB     0
SABORT   FCC     "*** MISSION ABORTED ***"
         FCB     0
SCROPSV  FCC     "CROPS SAVED: "
         FCB     0
SRANK1   FCC     "HARVEST SECURED -- WELL FLOWN, B-7."
         FCB     0
SRANK2   FCC     "PARTIAL HARVEST -- THE DECK WILL RECOVER."
         FCB     0
SRANK3   FCC     "GROW-DECK LOST -- RATIONS ON HALF."
         FCB     0
SAGAIN   FCC     "PRESS ANY KEY TO REPLANT."
         FCB     0

        ORG     $E7FF
        FCB     $FF

		END
