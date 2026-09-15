; 129867-66.bin -- ROM C ($F000-$F7FF)
; VERIFIED BYTE-EXACT: reassembled through acp6800, diffed identical to original.
;
; Same cursor row/column management cluster as 129827-148.bin (ROW_RESET,
; ROW_CLR, ROW_DEC, ROW_BOUND, COL_SET, COL_DEC, COL_BOUND, ROW_DISP),
; plus NIB2ASC. Routine names match the 129827 set's equivalents directly.
;
; One real edge case handled here: one traced instruction's encoding
; genuinely crosses this ROM's own $F7FF/$F800 boundary into the next
; physical chip's address range (the 6800 sees one flat address space, so
; this is valid on real hardware) -- it's emitted as raw FCB bytes here
; rather than a mnemonic, since a single output file can't represent an
; instruction whose bytes span two separate ROM chips.
;
; LABELS: see R867B.ASM's header for the naming scheme.
; Traced coverage: 377 instructions, 752/2048 bytes (36.7%).
;
        ORG     $F000
        FCB     $20,$C6,$20,$7E,$EC,$F0,$5F,$BD
        FCB     $EC,$F0,$81,$58,$27,$04,$81,$75
        FCB     $26,$03,$7E,$F0,$A6,$85,$60,$27
        FCB     $21,$F6,$00,$1A,$26,$33,$7E,$EF
        FCB     $31,$85,$60,$27,$0A,$81,$7F,$26
        FCB     $11,$F6,$00,$1A,$26,$0C,$39,$F6
        FCB     $00,$1A,$26,$06,$CE,$EB,$AA,$7E
        FCB     $EF,$3A
SCRDISP
        FCB     $7D,$00,$1E
        BEQ     SCRDISP_00A
        PSHA
        JSR     $F827
        PULA
SCRDISP_00A
        ORAA    $19
        LDX     $13
        STAA    $7000
        NOP
        STAA    $00,X
        JMP     CHR_PROC_0A2
        FCB     $36,$86,$1B,$8D,$E4,$32,$20,$E1
        FCB     $00,$00,$00,$00,$00,$00,$BF,$86
        FCB     $80,$97,$18,$96,$54,$85,$10,$27
        FCB     $03,$7E,$F2,$59,$7E,$F2,$79,$7F
        FCB     $00,$18,$39,$86,$80,$97,$19,$39
CLR_FLAG
        FCB     $7F,$00,$19
        RTS
        FCB     $96,$41,$84,$BF,$20,$04,$96,$41
        FCB     $8A,$40,$97,$41,$39,$BD,$EC,$E8
        FCB     $81,$46,$26,$06,$96,$41,$84,$7F
        FCB     $20,$F0,$81,$48,$26,$EE,$96,$41
        FCB     $8A,$80,$20,$E6,$86,$80,$97,$1A
        FCB     $39,$7F,$00,$1A,$39,$86,$80,$97
        FCB     $1D,$39,$7F,$00,$1D,$39
KBD_DISP
        FCB     $7D,$00,$42
        BNE     KBD_DISP_019
        FCB     $7D,$00,$D2
        BNE     KBD_DISP_019
        LDAA    $50
        BITA    #$20
        BNE     KBD_DISP_019
        LDAA    $7802
        ANDA    #$04
        ORAA    #$80
        STAA    $42
KBD_DISP_019
        RTS
        FCB     $7F,$00,$42,$39,$86,$02,$97,$1E
        FCB     $39,$7F,$00,$1E,$39
KBD_DISP_027
        LDAA    $7803
        ANDA    #$F7
        STAA    $7803
        ORAA    #$08
        STAA    $7803
        RTS
        FCB     $BD,$EC,$E8,$BD,$F6,$07,$8A,$90
        FCB     $7E,$F0,$3A,$D6,$9E,$C1,$01,$26
        FCB     $04,$D6,$53,$2B,$4D,$BD,$EC,$E8
        FCB     $7F,$00,$64,$81,$2E,$26,$07,$86
        FCB     $10,$97,$64,$BD,$EC,$E8,$BD,$F6
        FCB     $07,$25,$38,$9B,$64,$97,$64,$BD
        FCB     $EC,$E8,$BD,$F6,$07,$48,$48,$48
        FCB     $48,$97,$63,$BD,$EC,$E8,$BD,$F6
        FCB     $07,$25,$20,$CE,$00,$45,$DF,$9F
        FCB     $D6,$64,$DB,$A0,$D7,$A0,$D6,$9F
        FCB     $C9,$00,$D7,$9F,$DE,$9F,$D6,$63
        FCB     $1B,$A7,$00
KBD_COND
        LDAB    $00
        BEQ     KBD_COND_007
        JSR     $E08A
KBD_COND_007
        RTS
        FCB     $7E,$F0,$DA,$BD,$EC,$E8,$36,$BD
        FCB     $F7,$67,$32,$81,$21,$26,$03,$7E
        FCB     $E8,$00,$81,$30,$2D,$61,$26,$02
        FCB     $8D,$0D,$81,$39,$26,$02,$8D,$2E
        FCB     $81,$38,$26,$02,$8D,$3B,$39,$DE
        FCB     $43,$C6,$10,$8D,$58,$DF,$B7,$8D
        FCB     $51,$CE,$00,$45,$C6,$10,$8D,$4D
        FCB     $8D,$48,$8D,$46,$DE,$B7,$C6,$0E
        FCB     $8D,$43,$8D,$3E,$CE,$00,$55,$C6
        FCB     $0E,$8D,$3A,$8D,$35,$39,$CE,$EA
        FCB     $C6,$C6,$02,$8D,$30,$8D,$2B,$CE
        FCB     $EA,$18,$C6,$02,$8D,$27,$8D,$22
        FCB     $39,$B6,$7E,$00,$8D,$3F,$8D,$1A
        FCB     $B6,$79,$00,$8D,$38,$8D,$13,$B6
        FCB     $7D,$00,$8D,$31,$8D,$0C,$39,$8D
        FCB     $AE,$8D,$07,$8D,$D1,$8D,$03,$8D
        FCB     $E0,$39,$7E,$F3,$13
CHR_PROC
        STX     $9F
        PSHB
        LDAA    $00,X
        PSHA
        JSR     HINIB2ASC
        JSR     SCRDISP
        PULA
        JSR     NIB2ASC
        JSR     SCRDISP
        JSR     COL_BOUND
        PULB
        LDX     $9F
        INX
        STX     $9F
        DECB
        BNE     CHR_PROC
        RTS
        FCB     $97,$B7,$C6,$08,$D7,$B8,$BD,$F2
        FCB     $F0,$74,$00,$B7,$24,$04,$86,$46
        FCB     $20,$02,$86,$4E,$BD,$F0,$3A,$7A
        FCB     $00,$B8,$26,$EA,$39,$86,$01,$20
        FCB     $06,$86,$80,$20,$02,$86,$11,$F6
        FCB     $79,$00,$C5,$80,$26,$0D,$7E,$FD
        FCB     $AF,$F6,$79,$00,$C5,$80,$26,$03
        FCB     $7E,$FF,$40,$39,$FE,$E0,$00,$8C
        FCB     $54,$4A,$26,$F7,$7E,$E0,$3C,$86
        FCB     $02,$7E,$F0,$3A,$86,$03,$20,$F9
        FCB     $BD,$EC,$E8,$80,$20,$97,$63,$BD
        FCB     $EC,$E8,$91,$45,$27,$0A,$36,$BD
        FCB     $F0,$21,$32,$7A,$00,$63,$2E,$F6
        FCB     $39,$96,$42,$2A,$0D,$84,$04,$F6
        FCB     $78,$02,$C4,$04,$11,$27,$03,$BD
        FCB     $F6,$5E,$BD,$F2,$CF,$8D,$51
CHR_PROC_09F
        JMP     ROW_DISP
CHR_PROC_0A2
        JSR     COL_BOUND
CHR_PROC_0A5
        BSR     CHR_PROC_0F0
        BRA     CHR_PROC_09F
        LDX     $13
        BRA     CHR_PROC_0A5
        LDAB    $18
        BEQ     CHR_PROC_0B5
        LDAB    $54
        BMI     CHR_PROC_0CA
CHR_PROC_0B5
        JSR     ROW_BOUND
        BSR     CHR_PROC_0F0
        BRA     CHR_PROC_09F
CHR_PROC_0BC
        JSR     ROW_DEC
        BSR     CHR_PROC_0F0
        BRA     CHR_PROC_0BC
        JSR     COL_DEC
        BSR     CHR_PROC_0F0
        BRA     CHR_PROC_0BC
CHR_PROC_0CA
        JSR     CLR_CALL
        BSR     CHR_PROC_0F0
        BRA     CHR_PROC_09F
        LDAB    $18
        ORAB    $B5
        BNE     CHR_PROC_0E0
        LDAB    $53
        BITB    #$40
        BEQ     CHR_PROC_0E0
        JSR     $F820
CHR_PROC_0E0
        JSR     ROW_CLR
        LDAB    $53
        BITB    #$20
        BEQ     CHR_PROC_0EC
        JSR     ROW_BOUND
CHR_PROC_0EC
        BSR     CHR_PROC_0F0
        BRA     CHR_PROC_09F
CHR_PROC_0F0
        LDAA    $18
        BPL     CHR_PROC_0FC
        STAA    $7000
        NOP
        LDAA    $00,X
        BMI     CHR_PROC_0FE
CHR_PROC_0FC
        INS
        INS
CHR_PROC_0FE
        RTS
ROW_RESET
        CLRB
        STAB    $7F0C
        STAB    $17
        LDAA    $15
ROW_RESET_008
        SUBA    #$17
        BGE     COL_SET
        ADDA    #$18
COL_SET
        STAA    $7F0D
        STAA    $16
        JMP     CALC_OFS_00E
ROW_CLR
        CLRB
        STAB    $7F0C
        STAB    $17
        STAB    $B5
        JMP     CALC_OFS_00E
COL_BOUND
        LDAA    $17
        CMPA    #$4F
        BEQ     COL_BOUND_015
        FCB     $7F,$00,$B5
        INCA
        STAA    $7F0C
        STAA    $17
        LDX     $13
        INX
        STX     $13
        RTS
COL_BOUND_015
        LDAB    $18
        BMI     CLR_CALL
        LDAB    $53
        BITB    #$10
        BEQ     CLR_CALL
        FCB     $7C,$00,$B5
        RTS
CLR_CALL
        BSR     ROW_CLR
        BRA     ROW_BOUND
ROW_BOUND
        LDAA    $16
        CMPA    $15
        BEQ     ROW_BOUND_010
        CMPA    #$17
        BNE     ROW_BOUND_00C
        LDAA    #$FF
ROW_BOUND_00C
        INCA
ROW_BOUND_00D
        JMP     COL_SET
ROW_BOUND_010
        FCB     $7D,$00,$42
        BNE     ROW_BOUND_04B
        FCB     $7D,$00,$18
        BEQ     ROW_BOUND_01D
ROW_BOUND_01A
        JMP     ROW_RESET_008
ROW_BOUND_01D
        LDAB    $55
        BITB    #$08
        BNE     ROW_BOUND_01A
        INCA
        CMPA    #$18
        BLT     ROW_BOUND_029
        CLRA
ROW_BOUND_029
        STAA    $15
        STAA    $7F06
        JSR     COL_SET
        SUBA    $17
        SBCB    #$00
        STAB    $B7
        STAA    $B8
        LDX     $B7
        LDAB    #$50
        CLRA
ROW_BOUND_03E
        STAA    $7000
        NOP
        STAA    $00,X
        INX
        DECB
        BNE     ROW_BOUND_03E
        LDX     $13
        RTS
ROW_BOUND_04B
        JSR     KBD_TOGGLE
        LDAA    $15
        SUBA    #$17
        BPL     ROW_BOUND_056
        ADDA    #$18
ROW_BOUND_056
        BRA     ROW_BOUND_00D
ROW_DEC
        LDAA    $17
        BEQ     ROW_DEC_010
        DECA
        STAA    $7F0C
        STAA    $17
        LDX     $13
        DEX
        STX     $13
        RTS
ROW_DEC_010
        LDAA    #$4F
        STAA    $7F0C
        STAA    $17
        BRA     COL_DEC
COL_DEC
        LDAA    $16
        BNE     COL_DEC_006
        LDAA    #$18
COL_DEC_006
        DECA
        STAA    $7F0D
        STAA    $16
        CMPA    $15
        BNE     COL_DEC_01F
        FCB     $7D,$00,$42
        BEQ     COL_DEC_01F
        JSR     KBD_TOGGLE
        LDAA    $15
        STAA    $7F0D
        STAA    $16
COL_DEC_01F
        JMP     CALC_OFS_00E
        FCB     $7D,$00,$18,$27,$5B,$BD,$F4,$9B
        FCB     $96,$17,$DE,$13,$DF,$B7,$20,$04
        FCB     $9C,$BB,$27,$26,$81,$4F,$27,$2A
        FCB     $08,$4C,$9C,$B7,$27,$1C,$B7,$70
        FCB     $00,$01,$E6,$00,$2A,$EA
COL_DEC_048
        CMPA    #$4F
        BEQ     COL_DEC_06B
        INX
        INCA
COL_DEC_04E
        STAA    $7000
        NOP
        LDAB    $00,X
        BPL     COL_DEC_05C
        CPX     $B7
        BEQ     ROW_DISP_006
        BRA     COL_DEC_048
COL_DEC_05C
        STAA    $7F0C
        STAA    $17
        STX     $13
        RTS
        FCB     $BD,$F3,$13,$96,$17,$20,$D1
COL_DEC_06B
        JSR     CLR_CALL
        LDAA    $17
        BRA     COL_DEC_04E
ROW_DISP
        LDAA    $17
        STX     $B7
        BRA     COL_DEC_048
ROW_DISP_006
        JSR     ROW_RESET
        JSR     ROW_DEC
        CLRA
        STAA    $00,X
        RTS
        FCB     $7D,$00,$1F,$27,$2D,$2B,$2C,$4F
        FCB     $D6,$17,$9B,$1F,$81,$4F,$22,$05
        FCB     $11,$2E,$05,$20,$F5,$7E,$F3,$13
        FCB     $36,$D6,$13,$96,$14,$90,$17,$C2
        FCB     $00,$30,$AB,$00,$C9,$00,$D7,$13
        FCB     $97,$14,$32,$B7,$7F,$0C,$97,$17
        FCB     $DE,$13,$39,$96,$17,$81,$4F,$27
        FCB     $12,$7C,$00,$17,$BD,$F5,$3B,$E5
        FCB     $00,$27,$F0,$96,$17,$B7,$7F,$0C
        FCB     $7E,$F5,$F8,$7E,$F3,$13,$7D,$00
        FCB     $18,$27,$7A,$8D,$3C,$96,$17,$DE
        FCB     $13,$DF,$B7,$8D,$1F,$2B,$13,$9C
        FCB     $B7,$27,$16,$9C,$BB,$27,$12,$8D
        FCB     $13,$2A,$F4,$DF,$13,$97,$17,$7E
        FCB     $F2,$F0,$BD,$F4,$86,$2B,$FB,$20
        FCB     $E6,$7E,$F3,$E4,$4D,$27,$09,$4A
        FCB     $09,$B7,$70,$00,$01,$E6,$00,$39
        FCB     $DF,$13,$BD,$F3,$7F,$96,$17,$20
        FCB     $F0,$96,$15,$97,$BC,$4F,$D6,$42
        FCB     $27,$1D,$C4,$04,$F8,$78,$02,$C5
        FCB     $04,$27,$14,$86,$08,$98,$11,$8B
        FCB     $07,$97,$B9,$C6,$D4,$D7,$BA,$DE
        FCB     $B9,$A6,$00,$97,$BC,$86,$08,$98
        FCB     $11,$97,$BB,$96,$BC,$80,$17,$2C
        FCB     $02,$8B,$18,$BD,$F5,$EA,$DB,$BB
        FCB     $D7,$BB,$97,$BC,$39,$7D,$00,$1F
        FCB     $27,$24,$2B,$14,$D6,$17,$26,$05
        FCB     $BD,$F3,$6F,$D6,$17,$4F,$9B,$1F
        FCB     $11,$2B,$FB,$90,$1F,$7E,$F4,$22
        FCB     $BD,$F3,$6F,$96,$17,$27,$07,$BD
        FCB     $F5,$3B,$E5,$00,$27,$F2,$39,$CE
        FCB     $00,$20,$C6,$0A,$4F,$A7,$00,$08
        FCB     $5A,$26,$FA,$20,$21,$8D,$2A,$EA
        FCB     $00,$E7,$00,$D6,$1F,$CA,$80,$20
        FCB     $1D,$8D,$1E,$53,$E4,$00,$E7,$00
        FCB     $CE,$00,$20,$C6,$0A,$4F,$A1,$00
        FCB     $26,$0E,$08,$5A,$26,$F8,$D6,$1F
        FCB     $C1,$D0,$27,$04,$C4,$7F,$D7,$1F
        FCB     $39,$CE,$00,$20,$96,$17,$44,$44
        FCB     $44,$BD,$EF,$AD,$C6,$01,$96,$17
        FCB     $84,$07,$27,$04,$58,$4A,$26,$FC
        FCB     $39,$BD,$EC,$E8
CHR_CLASS
        ANDA    #$7F
        SUBA    #$20
        BMI     CHR_CLASS_010
        CMPA    #$50
        BLT     CHR_CLASS_00E
        BGT     CHR_CLASS_010
        LDAA    #$D0
CHR_CLASS_00E
        STAA    $1F
CHR_CLASS_010
        RTS
        FCB     $BD,$EC,$E8,$D6,$54,$C5,$40,$26
        FCB     $01,$4A,$81,$30,$2C,$02,$86,$30
        FCB     $81,$31,$2F,$02,$86,$31,$84,$01
        FCB     $D6,$42,$26,$0F,$48,$48,$F6,$78
        FCB     $02,$C4,$04,$11,$27,$1D,$BD,$F6
        FCB     $31,$20,$18,$36,$C4,$04,$B6,$78
        FCB     $02,$84,$04,$11,$26,$06,$33,$5D
        FCB     $27,$09,$20,$04,$33,$5D,$26,$03
        FCB     $BD,$F6,$31,$BD,$EC,$E8,$8D,$33
        FCB     $81,$18,$2D,$02,$86,$17,$9B,$15
        FCB     $4C,$81,$18,$2D,$02,$80,$18,$B7
        FCB     $7F,$0D,$97,$16,$BD,$EC,$E8,$8D
        FCB     $1A,$81,$50,$2D,$02,$86,$4F,$B7
        FCB     $7F,$0C,$97,$17,$BD,$F5,$F8,$96
        FCB     $53,$85,$02,$27,$0D,$BD,$F2,$C0
        FCB     $7E,$F3,$FA,$84,$7F,$80,$20,$2C
        FCB     $01,$4F,$39
CALC_OFS
        TAB
        ASLA
        ASLA
        ABA
        CLRB
        ASLA
        ROLB
        ASLA
        ROLB
        ASLA
        ROLB
        ASLA
        ROLB
        RTS
CALC_OFS_00E
        LDAA    $16
        BSR     CALC_OFS
        ADDA    $17
        ADCB    $11
        STAB    $13
        STAA    $14
        LDX     $13
        RTS
        FCB     $81,$30,$2B,$14,$81,$39,$2F,$0C
        FCB     $84,$DF,$81,$41,$2B,$0A,$81,$46
        FCB     $2E,$06,$80,$07,$84,$0F,$0C,$39
        FCB     $4F,$0D,$39
HINIB2ASC
        LSRA
        LSRA
        LSRA
        LSRA
NIB2ASC
        ANDA    #$0F
        CMPA    #$0A
        BLT     NIB2ASC_008
        ADDA    #$07
NIB2ASC_008
        ADDA    #$30
        RTS
        FCB     $7D,$00,$D2,$26,$3B,$96,$50,$85
        FCB     $20,$26,$35,$C6,$07,$8D,$20,$B7
        FCB     $70,$00,$01,$A6,$00,$95,$18,$27
        FCB     $27,$96,$42,$27,$0D,$84,$04,$F6
        FCB     $78,$02,$C4,$04,$11,$27,$03,$7E
        FCB     $F2,$8C,$7E,$F3,$FA
KBD_TOGGLE
        LDAB    #$06
        STAB    $B6
        JSR     KBD_SETUP
        LDAA    $7802
        EORA    #$04
        STAA    $7802
        BSR     KBD_SETUP_013
        LDX     $13
        RTS
KBD_SETUP
        LDAA    $11
        ADDA    #$07
        STAA    $B1
        LDAA    #$D0
        STAA    $B2
        LDX     #$0011
        STX     $B3
        LDAB    #$30
        BRA     SCRN_PUTC
KBD_SETUP_013
        LDX     #$0011
        STX     $B1
        LDAA    $7802
        ANDA    #$04
        ASLA
        ADDA    #$80
        STAA    $11
        ADDA    #$07
        STAA    $B3
        LDAA    #$D0
        STAA    $B4
        FCB     $7D,$00,$42
        BEQ     KBD_SETUP_033
        LDAB    $B6
        BRA     KBD_SETUP_035
KBD_SETUP_033
        LDAB    #$30
KBD_SETUP_035
        BSR     SCRN_PUTC
        LDAA    $15
        STAA    $7F06
        LDAA    $16
        STAA    $7F0D
        LDAA    $17
        STAA    $7F0C
        JMP     CALC_OFS_00E
SCRN_PUTC
        LDX     $B3
        STAA    $7000
        NOP
        LDAA    $00,X
        INX
        STX     $B3
        LDX     $B1
        STAA    $7000
        NOP
        STAA    $00,X
        INX
        STX     $B1
        DECB
        BNE     SCRN_PUTC
        RTS
        FCB     $86,$20,$D6,$55,$C5,$80,$27,$05
        FCB     $96,$4D,$20,$01,$4F,$D6,$55,$C5
        FCB     $02,$27,$03,$7F,$00,$19,$9A,$19
        FCB     $36,$BD,$EF,$BC,$96,$42,$2A,$35
        FCB     $84,$04,$F6,$78,$02,$C4,$04,$11
        FCB     $26,$2B,$32,$D6,$13,$37,$D6,$14
        FCB     $37,$D6,$16,$37,$D6,$17,$37,$36
        FCB     $BD,$F6,$5E,$BD,$F7,$90,$BD,$F6
        FCB     $5E,$32,$33,$F7,$7F,$0C,$D7,$17
        FCB     $33,$F7,$7F,$0D,$D7,$16,$33,$D7
        FCB     $14,$33,$D7,$13,$36,$BD,$F7,$93
        FCB     $31,$7E,$F2,$79,$D6,$55,$C5,$04
        FCB     $27,$30,$4F,$36,$20,$33,$8D,$0F
        FCB     $36,$20,$2E,$D6,$55,$C5,$04,$27
        FCB     $F5,$8D,$0F,$8D,$02,$20,$1E,$86
        FCB     $20,$D6,$55,$C5,$40,$27,$02,$96
        FCB     $4D,$39,$96,$1F,$2A,$07,$96,$52
        FCB     $2A,$03,$BD,$F5,$01,$39,$86,$A0
        FCB     $20,$03,$8D,$EE,$4F,$36,$7F,$00
        FCB     $18,$7F,$00,$19,$BD,$EF,$BC,$96
        FCB     $42,$27,$12,$84,$04,$F6,$78,$02
        FCB     $C4,$04,$11,$26,$03,$BD,$F6,$5E
        FCB     $8D,$09,$BD,$F6,$5E,$8D,$04,$31
        FCB     $7E,$F2,$79
SCRN_SETUP
        JSR     ROW_RESET
        LDAB    $11
        ADDB    #$07
        LDAA    #$7F
        STAB    $B7
        STAA    $B8
        LDAA    $15
        JSR     CALC_OFS
        ADDA    #$4F
        ADCB    $11
        STAB    $B9
        STAA    $BA
        TSX
        LDAB    $02,X
        LDX     $13
SCRN_SETUP_01F
        LDAA    $18
        BPL     SCRN_SETUP_02B
        STAA    $7000
        NOP
        BITA    $00,X
        BNE     SCRN_SETUP_031
SCRN_SETUP_02B
        STAA    $7000
        NOP
        STAB    $00,X
SCRN_SETUP_031
        CPX     $B9
        BEQ     SCRN_SETUP_042
        CPX     $B7
        BEQ     SCRN_SETUP_03C
        INX
        BRA     SCRN_SETUP_01F
SCRN_SETUP_03C
        LDX     $11
        STX     $13
        BRA     SCRN_SETUP_01F
SCRN_SETUP_042
        JMP     CALC_OFS_00E
        FCB     $86,$20,$D6,$55,$C5,$80,$27,$02
        FCB     $96,$4D,$BD,$EF,$BC
SCRN_SETUP_052
        LDAB    $55
        BITB    #$01
        BEQ     SCRN_SETUP_05B
        FCB     $7F,$00,$19
SCRN_SETUP_05B
        ORAA    $19
        LDAB    #$50
        SUBB    $17
        STAB    $BA
        LDX     $13
SCRN_SETUP_065
        LDAB    $18
        BPL     $F801
        STAA    $7000
        NOP
        LDAB    $00,X
        FCB     $2B

        END