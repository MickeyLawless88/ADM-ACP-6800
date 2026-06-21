; =============================================================================
; RT/68MX  --  ADM-31 / Lear Siegler adaptation  (crasm, 6800)
; ROM B plug-in slot, $E800-$EFFF (2KB, 2716)
;
; Assemble:  crasm -o rt68mx.srec rt68mx.asm
; Binary:    srec_cat rt68mx.srec -o rt68mx.bin -binary   (-> $E800-$EFFF, 2KB)
;
; Adapted from the Microware RT/68MX console monitor (c)1976,1977.
; This build is the MONITOR ONLY (no real-time multitasking executive):
;   - native console = ADM-31 keyboard (PIA1 scan/decode) + CRTRAM screen
;   - boots directly at reset (ADM-31 RST/SWI/NMI vectors -> $E800)
;   - keeps stock ROM C/D physically present (not called)
;
; DROPPED vs. the original:  RT executive (S cmd, task table, scheduler),
;   interrupt handlers, paper-tape LOAD/PUNCH (L/P), the PIA software-UART and
;   ACIA serial console paths.  Everything below is plain 6800 (no 6801 ops).
;
; COMMANDS:  M <,addr>  examine/change      D <,beg><,end>  dump
;            E <,addr>  execute (JMP)       G               go / resume (RTI)
;            B <,addr>  set breakpoint      R               register/stack dump
;            <ESC>      restart monitor
;
; Address entry is comma-led, MIKBUG style:  e.g.  D,0100,01FF<CR>
;
; BREAKPOINTS (B/G):  these use SWI ($3F).  The ADM-31's SWI vector lives in
;   ROM D and normally points at $E800.  To enable breakpoints, patch ROM D's
;   SWI_VEC to the RUNBKP address reported by crasm (see notes file).  Without
;   that patch, M/D/E/R and the console all work; only B/G need it.
; =============================================================================



; ----------------------------------------------------------------------------
; ADM-31 hardware (Table 4-1)
; ----------------------------------------------------------------------------
HALT            EQU     $7000       ; video-sync strobe (write anything)
PIA1            EQU     $7800       ; DA=$7800 CRA=$7801 DB=$7802 CRB=$7803
SW_BNK1         EQU     $7E00       ; strap/switch register
VTAC            EQU     $7F00       ; video timing controller base
CRTRAM          EQU     $8000       ; screen RAM

SCRSTRIDE       EQU     80          ; bytes per screen row (verified: $50)
SCRCOLS         EQU     80          ; visible columns
SCREND          EQU     $8780       ; one past last visible cell ($8000+24*80)
LASTROW         EQU     $8730       ; start of bottom row ($8000+23*80)
SCRCNT          EQU     1840        ; bytes to move on scroll (23*80)

; ----------------------------------------------------------------------------
; RAM layout  (ADM-31 has RAM only at $0000-$03FF; original used $A000)
;   monitor variables in page 0 (direct addressing); CPU stack high in page 1
; ----------------------------------------------------------------------------
BEGADR          EQU     $40         ; 2  dump start / current
ENDADR          EQU     $42         ; 2  dump end / BADDR result / M addr
SPTMP           EQU     $44         ; 2  saved user stack pointer
BKPADR          EQU     $46         ; 2  breakpoint address
BKPOP           EQU     $48         ; 1  breakpoint opcode/flag
RTMOD           EQU     $49         ; 1  run mode (monitor: 0)
ERRFLG          EQU     $4B         ; 1  error flag/code
CURPTR          EQU     $4C         ; 2  screen cursor CRTRAM address
CURCOL          EQU     $4E         ; 1  cursor column 0..79
KSCAN           EQU     $4F         ; 1  keyboard scan position
KMOD            EQU     $50         ; 1  keyboard modifier latch (PIA1_DB)
KCHAR           EQU     $51         ; 1  decoded key
KPTR            EQU     $52         ; 2  keyboard-table index scratch
MSRC            EQU     $54         ; 2  scroll source ptr
MDST            EQU     $56         ; 2  scroll dest ptr
MCNT            EQU     $58         ; 2  scroll counter
SAVEX           EQU     $5A         ; 2  X save (OUT1CH) - no PSHX on 6800
SAVEX2          EQU     $5C         ; 2  X save (IN1CHR)

STACK           EQU     $01FF       ; CPU stack top (grows down, page 1)

; =============================================================================
        ORG $E800
; =============================================================================
; RESET  --  ADM-31 reset/SWI/NMI vector to $E800; we own the machine.
;   Replicates the stock ROM B power-on bring-up (VTAC + PIA1) since the stock
;   ROM B no longer runs, then enters the monitor.
; =============================================================================
RESET
        SEI
        LDS     #STACK
; --- VTAC video init (stock ROM B $E80A-$E83D) ---
        CLRA
        LDX     #VTAC
        STAA    $0E,X               ; VTAC $7F0E = 0
        STAA    $0A,X               ; VTAC $7F0A = 0
        LDAA    #$65
        STAA    $00,X
        LDAA    #$44
        STAA    $01,X
        LDAA    #$5D
        STAA    $02,X
        LDAA    SW_BNK1
        ANDA    #$02
        BEQ     RVT1
        LDAA    #$20
        STAA    $04,X
        LDAA    #$14
        STAA    $05,X
        BRA     RVT2
RVT1
        LDAA    #$40
        STAA    $04,X
        LDAA    #$35
        STAA    $05,X
RVT2
        LDAA    #$17
        STAA    $03,X
        STAA    $06,X
        CLRA
        STAA    $0D,X
        STAA    $0C,X
        STAA    $0E,X
; --- PIA1 keyboard init (stock ROM B $E8D4-$E8EF) ---
        LDX     #PIA1
        CLR     $01,X
        CLR     $03,X
        LDAA    #$7F
        STAA    $00,X
        LDAA    #$1D
        STAA    $02,X
        LDAA    #$3C
        STAA    $01,X
        STAA    $03,X
        LDAA    #$01
        STAA    $00,X
        STAA    $02,X
; --- console state, clear screen, go ---
        STS     SPTMP
        LDAA    #$58
        STAA    KSCAN
        JSR     CLS
        JMP     BANNER

; =============================================================================
; CLS  --  clear visible screen, home cursor
; =============================================================================
CLS
        LDX     #CRTRAM
        STX     CURPTR
        CLR     CURCOL
        LDAA    #$20
CLS1
        STAA    $00,X
        INX
        CPX     #SCREND
        BNE     CLS1
        RTS

; =============================================================================
; SCROLL  --  move rows 1..23 up to 0..22, blank row 23, cursor to row 23
; =============================================================================
SCROLL
        LDX     #CRTRAM+SCRSTRIDE
        STX     MSRC
        LDX     #CRTRAM
        STX     MDST
        LDX     #SCRCNT
        STX     MCNT
SCR1
        LDX     MSRC
        LDAA    $00,X
        INX
        STX     MSRC
        LDX     MDST
        STAA    $00,X
        INX
        STX     MDST
        LDX     MCNT
        DEX
        STX     MCNT
        BNE     SCR1
        LDX     #LASTROW
        LDAA    #$20
SCR2
        STAA    $00,X
        INX
        CPX     #SCREND
        BNE     SCR2
        LDX     #LASTROW
        STX     CURPTR
        CLR     CURCOL
        RTS

; =============================================================================
; OUT1CH  --  print char in A to the ADM-31 screen at the cursor.
;   Preserves B and X (X via SAVEX, since 6800 has no PSHX).  CR = newline,
;   LF ignored, BS erases one cell.  Uses the verified HALT/NOP write pattern.
; =============================================================================
OUT1CH
        STX     SAVEX
        PSHB
        TAB                         ; B = char
        CMPB    #$0D
        BEQ     OC_CR
        CMPB    #$0A
        BEQ     OC_LF
        CMPB    #$08
        BEQ     OC_BS
        STAB    HALT                ; sync strobe
        NOP
        LDX     CURPTR
        STAB    $00,X
        INX
        STX     CURPTR
        INC     CURCOL
        LDAA    CURCOL
        CMPA    #SCRCOLS
        BNE     OC_RET
        JSR     OC_NL
        BRA     OC_RET
OC_CR
        JSR     OC_NL
        BRA     OC_RET
OC_LF
        BRA     OC_RET
OC_BS
        LDAA    CURCOL
        BEQ     OC_RET
        DEC     CURCOL
        LDX     CURPTR
        DEX
        STX     CURPTR
        LDAA    #$20
        STAA    HALT
        NOP
        STAA    $00,X
OC_RET
        PULB
        LDX     SAVEX
        RTS

; OC_NL -- advance cursor to start of next row; scroll if past bottom
OC_NL
        LDAA    CURCOL
        NEGA
        ADDA    #SCRSTRIDE          ; A = SCRSTRIDE - CURCOL
        ADDA    CURPTR+1
        STAA    CURPTR+1
        LDAA    CURPTR
        ADCA    #0
        STAA    CURPTR
        CLR     CURCOL
        LDX     CURPTR
        CPX     #SCREND
        BCS     OC_NLR              ; CURPTR < SCREND
        JSR     SCROLL
OC_NLR
        RTS

; =============================================================================
; IN1CHR  --  wait for a key, return ASCII in A.  Echoes to screen.
;   Native keyboard scan + decode (replicates stock ROM B $EE06 scan/decode
;   using the embedded KBTAB scancode table).  Preserves B and X.
; =============================================================================
IN1CHR
        STX     SAVEX2
        PSHB
INC_SCAN
        LDAA    KSCAN
        STAA    PIA1                ; select scan row (PIA1_DA)
        LDAA    PIA1                ; read back (bit7 = key down)
        BMI     INC_FOUND
        BNE     INC_DEC             ; readback nonzero -> advance position
        LDAA    #$58                ; readback 0 (pos wrapped) -> reload sentinel
INC_DEC
        DECA                        ; next position ($58 sentinel -> $57 first real)
        STAA    KSCAN
        BRA     INC_SCAN            ; block until a key is down
INC_FOUND
        LDAB    PIA1+2              ; PIA1_DB column/modifiers
        STAB    KMOD
        ASLB
        ROLA                        ; A = table index
        LDX     #KBTAB
        STX     KPTR
        ADDA    KPTR+1
        STAA    KPTR+1
        BCC     INC_NOCY
        INC     KPTR
INC_NOCY
        LDX     KPTR
        LDAA    $00,X               ; scancode table entry
        TSTA
        BMI     INC_STORE           ; bit7 set -> special key, use as-is
        LDAB    KMOD
        BITB    #$01                ; shift?
        BEQ     INC_CTRL
        CMPA    #$61
        BLT     INC_CTRL
        CMPA    #$7A
        BGT     INC_CTRL
        SUBA    #$20                ; lower -> upper
INC_CTRL
        LDAB    KMOD
        BITB    #$40                ; ctrl?
        BEQ     INC_STORE
        CMPA    #$40
        BLT     INC_STORE
        CMPA    #$7F
        BEQ     INC_STORE
        ANDA    #$1F                ; make control code
INC_STORE
        STAA    KCHAR
; debounce: wait for release at the same scan position
INC_REL
        LDAA    KSCAN
        STAA    PIA1
        LDAA    PIA1
        BMI     INC_REL
; echo and return char in A
        LDAA    KCHAR
        ANDA    #$7F
        STAA    KCHAR
        PSHA
        JSR     OUT1CH
        PULA
        PULB
        LDX     SAVEX2
        RTS

; --- console wrappers (preserve original RT/68 call structure) ---
OUTCH   JMP     OUT1CH
INCH    JMP     IN1CHR
OUTEEE  JMP     OUT1CH
INEEE   JMP     IN1CHR

; =============================================================================
; BANNER  --  startup banner, printed once at reset before monitor prompt.
;   Falls through into CONENT.
; =============================================================================
BANNER
        LDX     #BANSTR
        JSR     PDATA1
; =============================================================================
; Console monitor entry
; =============================================================================
CONENT
        CLR     BKPOP
        CLR     RTMOD
CONSOL
        CLR     ERRFLG
        LDS     #STACK
        JSR     CRLF
        LDAA    #'$'
        JSR     OUTEEE
        JSR     INEEE               ; command code -> A
        LDX     #CMDTBL-3
CMSRCH
        INX
        INX
        INX
        LDAB    $00,X               ; table code
        BEQ     CMDERR              ; 0 = end of table
        CBA                         ; typed (A) vs table (B)
        BNE     CMSRCH
        LDX     $01,X               ; handler address
        JSR     $00,X
TSTENT
        JSR     ERTEST
        JMP     CONSOL
CMDERR
        LDAB    #'6'
        JMP     ERROR

; =============================================================================
; Command handlers
; =============================================================================
; set/remove breakpoint (swap opcode with $3F via BKPOP)
SETBKP
        LDAA    BKPOP
        BEQ     SBRET
        LDX     BKPADR
        LDAB    $00,X
        STAA    $00,X
        STAB    BKPOP
SBRET
        RTS

; prepare to run user code (monitor-only: just (re)insert breakpoint)
SETRUN
        JSR     SETBKP
        RTS

; "E" execute at address (JMP)
EXCOM
        JSR     GETADR
        JSR     SETRUN
        LDX     ENDADR
        JMP     $00,X

; "G" go / resume from breakpoint (RTI off saved frame)
GOCOM
        LDS     SPTMP
        JSR     SETRUN
        RTI

; "B" set breakpoint
BKPCOM
        CLR     BKPOP
        JSR     GETADR
        STX     BKPADR
        LDAA    #$3F
        STAA    BKPOP
        RTS

; "D" dump memory
DMPCOM
        JSR     GET2AD
        JMP     DUMP

; "M" examine / change memory
MEMCOM
        JSR     GETADR
MEM1
        JSR     CRLF
MEM2
        LDAA    #$0D
        JSR     OUTEEE
        LDX     #ENDADR
        JSR     OUT4HS              ; print address
        LDX     ENDADR
        JSR     OUT2H               ; print contents (X advances)
        STX     ENDADR
        JSR     INEEE               ; delimiter
        CMPA    #$0A
        BEQ     MEM2                ; LF -> next location
        CMPA    #'/'
        BEQ     MEM3                ; '/' -> change
        RTS                         ; CR -> done
MEM3
        JSR     BYTE                ; new value -> A
        JSR     ERTEST
        DEX
        STAA    $00,X
        CMPA    $00,X
        BEQ     MEM1
        LDAB    #'5'
        JMP     ERROR

; read two comma-led addresses -> BEGADR (first), ENDADR/X (second)
GET2AD
        JSR     GETADR
        STX     BEGADR
GETADR
        JSR     INEEE
        CMPA    #$0D
        BEQ     GA_ABORT
        CMPA    #','
        BEQ     GA_C
        JMP     ERROR
GA_C
        JSR     BADDR
        BRA     ERTEST
GA_ABORT
        JMP     CONSOL

; error test / handler
ERTEST
        LDAB    ERRFLG
        BEQ     RETURN
ERROR
        LDX     #ERRMSG
        JSR     PDATA1
        TBA
        JSR     OUTEEE
        JMP     CONSOL
RETURN
        RTS

; =============================================================================
; DUMP  --  print 16 bytes/line from BEGADR until ENDADR reached
; =============================================================================
DUMP
        JSR     CRLF
        LDX     #BEGADR
        JSR     OUT4HS              ; line address
        LDAB    #16
        LDX     BEGADR
DUMP1
        JSR     OUT2HS              ; byte + space (X advances 1)
        DEX
        CPX     ENDADR
        BNE     DUMP2
        RTS
DUMP2
        INX
        DECB
        BNE     DUMP1
        STX     BEGADR
        BRA     DUMP

; =============================================================================
; "R" / breakpoint -- print saved stack:  SP CC B A XR PC
; =============================================================================
PRSTAK
        JSR     CRLF
        LDX     #SPTMP
        JSR     OUT4HS              ; SP
        LDX     SPTMP
PRSTK
        INX
        JSR     OUT2HS              ; CC
        JSR     OUT2HS              ; B
        JSR     OUT2HS              ; A
        JSR     OUT4HS              ; XR
        JMP     OUT4HS              ; PC (tail)

; =============================================================================
; SWI breakpoint service (RUNBKP).  Reached only if ROM D SWI_VEC is patched
; to point here.  Restores the breakpoint opcode and dumps the frame.
; =============================================================================
RUNBKP
        TSX
        JSR     ADJSTK              ; back PC up over the SWI
        LDX     $05,X               ; task PC from frame
        CPX     BKPADR
        BEQ     RUNBK2
        LDAB    #'7'
        STAB    ERRFLG
RUNBK2
        JSR     SETBKP              ; remove breakpoint opcode
        STS     SPTMP
        JSR     PRSTAK
        JMP     CONSOL
ADJSTK
        TST     $00,X
        BNE     ADSTK2
        DEC     $05,X
ADSTK2
        DEC     $06,X
        RTS

; =============================================================================
; Hex / ASCII I/O utilities (unchanged RT/68 logic, pure 6800)
; =============================================================================
OUTC2   JMP     OUT1CH              ; local trampoline (OUTCH out of branch range)
OUTHL
        LSRA
        LSRA
        LSRA
        LSRA
OUTHR
        ANDA    #$0F
        ADDA    #$30
        CMPA    #$39
        BLS     OUTC2
        ADDA    #$07
        BRA     OUTC2

OUT2H
        LDAA    $00,X
        JSR     OUTHL
        LDAA    $00,X
        INX
        BRA     OUTHR

OUT4HS
        JSR     OUT2H
OUT2HS
        JSR     OUT2H
OUTS
        LDAA    #$20
        JMP     OUTCH

PDATA2
        JSR     OUTCH
        INX
PDATA1
        LDAA    $00,X
        CMPA    #$04
        BNE     PDATA2
        RTS

CRLF
        LDX     #CRLSTR
        JMP     PDATA1

HBAD
        LDAA    #'3'
        STAA    ERRFLG
        RTS
INHEX
        JSR     INCH
        SUBA    #$30
        BCS     HBAD
        CMPA    #$09
        BLS     IHRET
        SUBA    #$07
        BCS     HBAD
        CMPA    #$0F
        BHI     HBAD
IHRET
        RTS

BYTE
        PSHB
        JSR     INHEX
        ASLA
        ASLA
        ASLA
        ASLA
        TAB
        JSR     INHEX
        ABA
        PULB
        PSHA
        ABA                         ; running checksum in B (harmless here)
        TAB
        PULA
        RTS

BADDR
        JSR     BYTE
        STAA    ENDADR
        JSR     BYTE
        STAA    ENDADR+1
        LDX     ENDADR
        RTS

; =============================================================================
; Keyboard scancode table  (copy of stock ROM B $EA1A-$EAC9)
; =============================================================================
KBTAB
        DB      $D1,$D1,$D7,$D7,$C5,$C5,$D2,$D2
        DB      $D4,$F4,$D9,$F9,$32,$22,$1B,$1B
        DB      $7F,$7F,$9E,$9F,$D0,$F0,$B4,$B6
        DB      $92,$93,$31,$21,$71,$51,$98,$98
        DB      $33,$23,$34,$24,$35,$25,$36,$26
        DB      $37,$27,$38,$28,$39,$29,$30,$5F
        DB      $2D,$3D,$5E,$7E,$5C,$7C,$09,$C9
        DB      $87,$87,$88,$88,$89,$89,$2D,$2D
        DB      $77,$57,$65,$45,$72,$52,$74,$54
        DB      $79,$59,$75,$55,$69,$49,$6F,$4F
        DB      $70,$50,$5B,$7B,$5D,$7D,$0D,$0D
        DB      $84,$84,$85,$85,$86,$86,$09,$09
        DB      $61,$41,$73,$53,$64,$44,$66,$46
        DB      $67,$47,$68,$48,$6A,$4A,$6B,$4B
        DB      $6C,$4C,$3B,$2B,$3A,$2A,$40,$60
        DB      $0A,$0A,$82,$82,$83,$83,$81,$81
        DB      $90,$91,$7A,$5A,$78,$58,$63,$43
        DB      $76,$56,$62,$42,$6E,$4E,$6D,$4D
        DB      $2C,$3C,$2E,$3E,$2F,$3F,$20,$20
        DB      $1F,$CA,$30,$30,$2E,$2E,$0D,$0D
        DB      $9D,$94,$1E,$1E,$0A,$0A,$0B,$0B
        DB      $08,$08,$0C,$0C,$E3,$00,$2C,$2C
        DB      $00,$00,$00,$00     ; guard: out-of-range indices read NUL

; =============================================================================
; Strings and command table
; =============================================================================
ERRMSG  DB      $20,'E','R','R','O','R',':',$20,$20,$04
CRLSTR  DB      $0D,$04
BANSTR  DB      $0D
        DB      'R','T','/','6','8','0','0'
        DB      $20,$20
        DB      'A','D','M','-','3','1'
        DB      $20,$20
        DB      'R','O','M','-','M','O','N','.'
        DB      $20,$20
        DB      'V','E','R',$20,'1','.','0'
        DB      $0D,$0D
        DB      $0D,$0D
        DB      $04
CMDTBL
        DB      'B'
        DW      BKPCOM
        DB      'D'
        DW      DMPCOM
        DB      'E'
        DW      EXCOM
        DB      'G'
        DW      GOCOM
        DB      'M'
        DW      MEMCOM
        DB      'R'
        DW      PRSTAK
        DB      $1B
        DW      RESET
        DB      0

; --- fill to top of the 2KB ROM B image ---

