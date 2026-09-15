; 129827-148.bin -- ROM C ($F000-$F7FF)
; VERIFIED BYTE-EXACT: reassembled through acp6800, diffed identical to original.
;
; Contains a cluster of cursor row/column management routines
; (ROW_RESET, ROW_CLR, ROW_DEC, ROW_BOUND, COL_SET, COL_DEC, COL_BOUND,
; ROW_DISP) all sharing VTAC hardware registers $7F0C/$7F0D and zero-page
; shadow variables $25/$26/$27, plus the NIB2ASC hex-digit routine (same
; pattern as this project's own NIB2ASC in ISIS68.ASM) and keyboard
; setup/toggle routines.
;
; LABELS: see ROM129827_A.ASM's header for the naming scheme.
; Traced coverage: 250 instructions, 488/2048 bytes (23.8%).
;
        ORG     $F000
        BITB    #$40
        BEQ     CODE_F007
        JSR     $FE63
CODE_F007
        JSR     ROW_CLR
        LDAB    $63
        BITB    #$20
        BEQ     CODE_F013
        JSR     ROW_BOUND
CODE_F013
        BSR     CODE_F017
        BRA     $EFC6
CODE_F017
        LDAA    $28
        BPL     CODE_F023
        STAA    $7000
        NOP
        LDAA    $00,X
        BMI     CODE_F025
CODE_F023
        INS
        INS
CODE_F025
        RTS
ROW_RESET
        CLRB
        STAB    $7F0C
        STAB    $27
        LDAA    $25
ROW_RESET_008
        SUBA    #$17
        BGE     COL_SET
        ADDA    #$18
COL_SET
        STAA    $7F0D
        STAA    $26
        JMP     CALC_OFS_00E
ROW_CLR
        CLRB
        STAB    $7F0C
        STAB    $27
        STAB    $81
        JMP     CALC_OFS_00E
COL_BOUND
        LDAA    $27
        CMPA    #$4F
        BEQ     COL_BOUND_015
        FCB     $7F,$00,$81
        INCA
        STAA    $7F0C
        STAA    $27
        LDX     $23
        INX
        STX     $23
        RTS
COL_BOUND_015
        LDAB    $28
        BMI     CLR_CALL
        LDAB    $63
        BITB    #$10
        BEQ     CLR_CALL
        FCB     $7C,$00,$81
        RTS
CLR_CALL
        BSR     ROW_CLR
        BRA     ROW_BOUND
ROW_BOUND
        LDAA    $26
        CMPA    $25
        BEQ     ROW_BOUND_010
        CMPA    #$17
        BNE     ROW_BOUND_00C
        LDAA    #$FF
ROW_BOUND_00C
        INCA
ROW_BOUND_00D
        JMP     COL_SET
ROW_BOUND_010
        FCB     $7D,$00,$52
        BNE     ROW_BOUND_04B
        FCB     $7D,$00,$28
        BEQ     ROW_BOUND_01D
ROW_BOUND_01A
        JMP     ROW_RESET_008
ROW_BOUND_01D
        LDAB    $65
        BITB    #$08
        BNE     ROW_BOUND_01A
        INCA
        CMPA    #$18
        BLT     ROW_BOUND_029
        CLRA
ROW_BOUND_029
        STAA    $25
        STAA    $7F06
        JSR     COL_SET
        SUBA    $27
        SBCB    #$00
        STAB    $D8
        STAA    $D9
        LDX     $D8
        LDAB    #$50
        CLRA
ROW_BOUND_03E
        STAA    $7000
        NOP
        STAA    $00,X
        INX
        DECB
        BNE     ROW_BOUND_03E
        LDX     $23
        RTS
ROW_BOUND_04B
        JSR     KBD_TOGGLE
        LDAA    $25
        SUBA    #$17
        BPL     ROW_BOUND_056
        ADDA    #$18
ROW_BOUND_056
        BRA     ROW_BOUND_00D
ROW_DEC
        LDAA    $27
        BEQ     ROW_DEC_010
        DECA
        STAA    $7F0C
        STAA    $27
        LDX     $23
        DEX
        STX     $23
        RTS
ROW_DEC_010
        LDAA    #$4F
        STAA    $7F0C
        STAA    $27
        BRA     COL_DEC
COL_DEC
        LDAA    $26
        BNE     COL_DEC_006
        LDAA    #$18
COL_DEC_006
        DECA
        STAA    $7F0D
        STAA    $26
        CMPA    $25
        BNE     COL_DEC_01F
        FCB     $7D,$00,$52
        BEQ     COL_DEC_01F
        JSR     KBD_TOGGLE
        LDAA    $25
        STAA    $7F0D
        STAA    $26
COL_DEC_01F
        JMP     CALC_OFS_00E
        FCB     $7D,$00,$28,$27,$5B,$BD,$F1,$F2
        FCB     $96,$27,$DE,$23,$DF,$D8,$20,$04
        FCB     $9C,$DC,$27,$26,$81,$4F,$27,$2A
        FCB     $08,$4C,$9C,$D8,$27,$1C,$B7,$70
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
        CPX     $D8
        BEQ     ROW_DISP_006
        BRA     COL_DEC_048
COL_DEC_05C
        STAA    $7F0C
        STAA    $27
        STX     $23
        RTS
        FCB     $BD,$F0,$6A,$96,$27,$20,$D1
COL_DEC_06B
        JSR     CLR_CALL
        LDAA    $27
        BRA     COL_DEC_04E
ROW_DISP
        LDAA    $27
        STX     $D8
        BRA     COL_DEC_048
ROW_DISP_006
        JSR     ROW_RESET
        JSR     ROW_DEC
        CLRA
        STAA    $00,X
        RTS
        FCB     $7D,$00,$2F,$27,$2D,$2B,$2C,$4F
        FCB     $D6,$27,$9B,$2F,$81,$4F,$22,$05
        FCB     $11,$2E,$05,$20,$F5,$7E,$F0,$6A
        FCB     $36,$D6,$23,$96,$24,$90,$27,$C2
        FCB     $00,$30,$AB,$00,$C9,$00,$D7,$23
        FCB     $97,$24,$32,$B7,$7F,$0C,$97,$27
        FCB     $DE,$23,$39,$96,$27,$81,$4F,$27
        FCB     $12,$7C,$00,$27,$BD,$F2,$92,$E5
        FCB     $00,$27,$F0,$96,$27,$B7,$7F,$0C
        FCB     $7E,$F3,$4F,$7E,$F0,$6A,$7D,$00
        FCB     $28,$27,$7A,$8D,$3C,$96,$27,$DE
        FCB     $23,$DF,$D8,$8D,$1F,$2B,$13,$9C
        FCB     $D8,$27,$16,$9C,$DC,$27,$12,$8D
        FCB     $13,$2A,$F4,$DF,$23,$97,$27,$7E
        FCB     $F0,$47,$BD,$F1,$DD,$2B,$FB,$20
        FCB     $E6,$7E,$F1,$3B,$4D,$27,$09,$4A
        FCB     $09,$B7,$70,$00,$01,$E6,$00,$39
        FCB     $DF,$23,$BD,$F0,$D6,$96,$27,$20
        FCB     $F0,$96,$25,$97,$DD,$4F,$D6,$52
        FCB     $27,$1D,$C4,$04,$F8,$78,$02,$C5
        FCB     $04,$27,$14,$86,$08,$98,$21,$8B
        FCB     $07,$97,$DA,$C6,$D4,$D7,$DB,$DE
        FCB     $DA,$A6,$00,$97,$DD,$86,$08,$98
        FCB     $21,$97,$DC,$96,$DD,$80,$17,$2C
        FCB     $02,$8B,$18,$BD,$F3,$41,$DB,$DC
        FCB     $D7,$DC,$97,$DD,$39,$7D,$00,$2F
        FCB     $27,$24,$2B,$14,$D6,$27,$26,$05
        FCB     $BD,$F0,$C6,$D6,$27,$4F,$9B,$2F
        FCB     $11,$2B,$FB,$90,$2F,$7E,$F1,$79
        FCB     $BD,$F0,$C6,$96,$27,$27,$07,$BD
        FCB     $F2,$92,$E5,$00,$27,$F2,$39,$CE
        FCB     $00,$30,$C6,$0A,$4F,$A7,$00,$08
        FCB     $5A,$26,$FA,$20,$21,$8D,$2A,$EA
        FCB     $00,$E7,$00,$D6,$2F,$CA,$80,$20
        FCB     $1D,$8D,$1E,$53,$E4,$00,$E7,$00
        FCB     $CE,$00,$30,$C6,$0A,$4F,$A1,$00
        FCB     $26,$0E,$08,$5A,$26,$F8,$D6,$2F
        FCB     $C1,$D0,$27,$04,$C4,$7F,$D7,$2F
        FCB     $39,$CE,$00,$30,$96,$27,$44,$44
        FCB     $44,$BD,$EE,$9C,$C6,$01,$96,$27
        FCB     $84,$07,$27,$04,$58,$4A,$26,$FC
        FCB     $39,$BD,$F9,$C0
CHR_CLASS
        ANDA    #$7F
        SUBA    #$20
        BMI     CHR_CLASS_010
        CMPA    #$50
        BLT     CHR_CLASS_00E
        BGT     CHR_CLASS_010
        LDAA    #$D0
CHR_CLASS_00E
        STAA    $2F
CHR_CLASS_010
        RTS
        FCB     $BD,$F9,$C0,$D6,$64,$C5,$40,$26
        FCB     $01,$4A,$81,$30,$2C,$02,$86,$30
        FCB     $81,$31,$2F,$02,$86,$31,$84,$01
        FCB     $D6,$52,$26,$0F,$48,$48,$F6,$78
        FCB     $02,$C4,$04,$11,$27,$1D,$BD,$F3
        FCB     $88,$20,$18,$36,$C4,$04,$B6,$78
        FCB     $02,$84,$04,$11,$26,$06,$33,$5D
        FCB     $27,$09,$20,$04,$33,$5D,$26,$03
        FCB     $BD,$F3,$88,$BD,$F9,$C0,$8D,$33
        FCB     $81,$18,$2D,$02,$86,$17,$9B,$25
        FCB     $4C,$81,$18,$2D,$02,$80,$18,$B7
        FCB     $7F,$0D,$97,$26,$BD,$F9,$C0,$8D
        FCB     $1A,$81,$50,$2D,$02,$86,$4F,$B7
        FCB     $7F,$0C,$97,$27,$BD,$F3,$4F,$96
        FCB     $63,$85,$02,$27,$0D,$BD,$F0,$17
        FCB     $7E,$F1,$51,$84,$7F,$80,$20,$2C
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
        LDAA    $26
        BSR     CALC_OFS
        ADDA    $27
        ADCB    $21
        STAB    $23
        STAA    $24
        LDX     $23
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
        FCB     $7D,$00,$15,$26,$3B,$96,$60,$85
        FCB     $20,$26,$35,$C6,$07,$8D,$20,$B7
        FCB     $70,$00,$01,$A6,$00,$95,$28,$27
        FCB     $27,$96,$52,$27,$0D,$84,$04,$F6
        FCB     $78,$02,$C4,$04,$11,$27,$03,$7E
        FCB     $EF,$E3,$7E,$F1,$51
KBD_TOGGLE
        LDAB    #$06
        STAB    $82
        JSR     KBD_SETUP
        LDAA    $7802
        EORA    #$04
        STAA    $7802
        BSR     KBD_SETUP_013
        LDX     $23
        RTS
KBD_SETUP
        LDAA    $21
        ADDA    #$07
        STAA    $7D
        LDAA    #$D0
        STAA    $7E
        LDX     #$0021
        STX     $7F
        LDAB    #$30
        BRA     SCRN_PUTC
KBD_SETUP_013
        LDX     #$0021
        STX     $7D
        LDAA    $7802
        ANDA    #$04
        ASLA
        ADDA    #$80
        STAA    $21
        ADDA    #$07
        STAA    $7F
        LDAA    #$D0
        STAA    $80
        FCB     $7D,$00,$52
        BEQ     KBD_SETUP_033
        LDAB    $82
        BRA     KBD_SETUP_035
KBD_SETUP_033
        LDAB    #$30
KBD_SETUP_035
        BSR     SCRN_PUTC
        LDAA    $25
        STAA    $7F06
        LDAA    $26
        STAA    $7F0D
        LDAA    $27
        STAA    $7F0C
        JMP     CALC_OFS_00E
SCRN_PUTC
        LDX     $7F
        STAA    $7000
        NOP
        LDAA    $00,X
        INX
        STX     $7F
        LDX     $7D
        STAA    $7000
        NOP
        STAA    $00,X
        INX
        STX     $7D
        DECB
        BNE     SCRN_PUTC
        RTS
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$86,$02,$20,$27
        FCB     $86,$03,$20,$23,$86,$04,$20,$1F
        FCB     $86,$05,$20,$1B,$86,$06,$20,$17
        FCB     $96,$64,$85,$20,$26,$69,$86,$07
        FCB     $20,$0D,$86,$08,$20,$09,$86,$09
        FCB     $20,$05,$86,$0A,$20,$01,$43,$97
        FCB     $89,$BD,$EE,$AB,$7F,$00,$7A,$4F
        FCB     $CE,$00,$04,$BD,$F9,$90,$CE,$00
        FCB     $00,$BD,$F9,$9B,$CE,$00,$02,$7E
        FCB     $F9,$9B,$BD,$F7,$9A,$96,$89,$2A
        FCB     $05,$CE,$F5,$28,$20,$0F,$D6,$65
        FCB     $C4,$20,$D7,$91,$CE,$F4,$E4,$48
        FCB     $BD,$EE,$9C,$EE,$00,$AD,$00,$96
        FCB     $89,$81,$0A,$27,$0E,$96,$56,$27
        FCB     $0A,$BD,$F7,$B2,$96,$57,$27,$03
        FCB     $BD,$F7,$B2,$BD,$F5,$E1,$CE,$00
        FCB     $07,$BD,$F9,$92,$7E,$F9,$99,$39
        FCB     $F4,$E3,$F4,$E3,$F5,$57,$F5,$57
        FCB     $F5,$5F,$F5,$5F,$F6,$C5,$F6,$C5
        FCB     $F5,$13,$F4,$FA,$F5,$34,$B6,$78
        FCB     $02,$D6,$52,$27,$02,$98,$52,$84
        FCB     $04,$44,$44,$8A,$30,$D6,$64,$C5
        FCB     $40,$26,$01,$4C,$BD,$F7,$B2,$96
        FCB     $26,$4A,$90,$25,$2C,$02,$8B,$18
        FCB     $8B,$20,$BD,$F7,$B2,$96,$27,$8B
        FCB     $20,$7E,$F7,$B2,$B6,$00,$5B,$BD
        FCB     $F7,$B2,$96,$89,$43,$7E,$F7,$B2
        FCB     $CE,$7B,$80,$DF,$D8,$A6,$1E,$81
        FCB     $0D,$26,$17,$A6,$1F,$81,$8A,$26
        FCB     $11,$84,$7F,$97,$89,$DE,$D8,$A6
        FCB     $00,$08,$DF,$D8,$BD,$F7,$B2,$4D
        FCB     $2A,$F3,$39,$BD,$F5,$D8,$BD,$F0
        FCB     $3C,$20,$17,$BD,$F5,$D8,$96,$52
        FCB     $27,$0D,$F6,$78,$02,$84,$04,$C4
        FCB     $04,$11,$27,$03,$BD,$F3,$B5,$BD
        FCB     $F0,$26,$4F,$B7,$00,$2E,$97,$8A
        FCB     $BD,$EE,$7A,$7D,$00,$7A,$2B,$2D
        FCB     $BD,$F6,$09,$D6,$60,$2A,$04,$81
        FCB     $03,$27,$22,$C5,$10,$27,$06,$DE
        FCB     $23,$9C,$85,$27,$18,$4D,$27,$03
        FCB     $BD,$F7,$B2,$DE,$23,$9C,$85,$27
        FCB     $0C,$BD,$F5,$FE,$7D,$00,$27,$26
        FCB     $CF,$8D,$03,$20,$CB,$39,$96,$65
        FCB     $85,$10,$27,$04,$96,$28,$2B,$1B
        FCB     $96,$58,$27,$17,$BD,$F7,$B2,$96
        FCB     $59,$27,$10,$7E,$F7,$B2,$36,$96
        FCB     $91,$26,$07,$96,$5A,$27,$03,$BD
        FCB     $F7,$B2,$32,$39,$DE,$26,$DF,$87
        FCB     $DE,$23,$DF,$85,$39,$96,$28,$26
        FCB     $15,$96,$89,$81,$02,$2D,$0F,$81
        FCB     $06,$2E,$0B,$2D,$06,$D6,$64,$C5
        FCB     $20,$27,$03,$BD,$EF,$F1,$7F,$00
        FCB     $89,$39,$BD,$F0,$47,$7D,$00,$81
        FCB     $27,$1E,$7E,$F0,$6A,$DE,$23,$B7
        FCB     $70,$00,$01,$A6,$00,$7D,$00,$28
        FCB     $26,$0F,$16,$C4,$F0,$C1,$90,$26
        FCB     $02,$86,$20,$84,$7F,$7F,$00,$91
        FCB     $39,$D6,$89,$C5,$01,$26,$4B,$D6
        FCB     $8A,$4D,$2B,$0B,$C1,$01,$26,$F0
        FCB     $7F,$00,$8A,$8D,$91,$20,$E4,$81
        FCB     $E0,$27,$26,$C1,$02,$27,$DC,$C6
        FCB     $01,$D7,$8A,$9C,$85,$27,$29,$84
        FCB     $7F,$91,$DB,$26,$08,$D6,$89,$C4
        FCB     $06,$C1,$06,$27,$1C,$BD,$F5,$FE
        FCB     $D6,$27,$26,$A9,$BD,$F5,$B2,$20
        FCB     $A4,$C1,$02,$27,$DA,$C1,$01,$26
        FCB     $03,$BD,$F5,$CA,$C6,$02,$20,$D1
        FCB     $4F,$39,$4D,$2B,$16,$7D,$00,$8A
        FCB     $27,$A1,$36,$96,$55,$BD,$F7,$B2
        FCB     $86,$28,$BD,$F7,$B2,$7F,$00,$8A
        FCB     $32,$20,$90,$16,$C4,$F0,$C1,$90
        FCB     $26,$17,$36,$96,$55,$BD,$F7,$B2
        FCB     $86,$47,$BD,$F7,$B2,$32,$84,$0F
        FCB     $BD,$F3,$7D,$BD,$F7,$B2,$7E,$F6
        FCB     $59,$7D,$00,$8A,$26,$10,$36,$96
        FCB     $55,$BD,$F7,$B2,$86,$29,$BD,$F7
        FCB     $B2,$86,$01,$97,$8A,$32,$7E,$F6
        FCB     $1F,$BD,$F5,$D8,$5F,$D7,$DC,$D7
        FCB     $DD,$D7,$8A,$F6,$78,$02,$C4,$04
        FCB     $D7,$DE,$96,$64,$85,$20,$27,$0E
        FCB     $86,$1C,$97,$DA,$97,$DB,$B7,$70
        FCB     $00,$01,$A7,$00,$20,$23,$86,$02
        FCB     $97,$DA,$86,$03,$97,$DB,$96,$52
        FCB     $27,$08,$84,$04,$11,$26,$03,$BD
        FCB     $F3,$B5,$96,$25,$BD,$F3,$41,$DB
        FCB     $21,$8B,$4F,$C9,$00,$D7,$DC,$97
        FCB     $DD,$96,$52,$27,$0D,$84,$04,$F6
        FCB     $78,$02,$C4,$04,$11,$27,$03,$BD
        FCB     $F3,$B5,$96,$25,$80,$17,$2C,$02
        FCB     $8B,$18,$BD,$F3,$41,$DB,$21,$D7
        FCB     $D8,$97,$D9,$F6,$78,$02,$C4,$04
        FCB     $D1,$DE,$27,$03,$BD,$F3,$B5,$DE
        FCB     $23,$9C,$D8,$27,$29,$BD,$F0,$C6
        FCB     $B7,$70,$00,$01,$A6,$00,$84,$7F
        FCB     $91,$DA,$27,$06,$9C,$D8,$26,$ED
        FCB     $20,$14,$D6,$64,$C5,$20,$27,$06
        FCB     $D6,$26,$D1,$87,$26,$05,$BD,$F5
        FCB     $FE,$20,$03,$BD,$F0,$6A,$DE,$DC
        FCB     $DF,$85,$BD,$EE,$7A,$7D,$00,$7A
        FCB     $2B,$20,$BD,$F6,$09,$4D,$27,$07
        FCB     $91,$DB,$27,$17,$BD,$F7,$B2,$DE
        FCB     $23,$9C,$85,$27,$0E,$BD,$F5,$FE
        FCB     $7D,$00,$27,$26,$DD,$BD,$F5,$B2
        FCB     $20,$D8,$39,$7E,$EF,$E6,$D6,$90
        FCB     $CA,$01,$D7,$90,$36,$F6,$7E,$00
        FCB     $C4,$1C,$96,$83,$84,$83,$1B,$97
        FCB     $83,$B7,$7A,$00,$32,$39,$36,$7D
        FCB     $00,$90,$26,$02,$8D,$E0,$D6,$8F
        FCB     $C1,$0C,$27,$FA,$DE,$8D,$32,$A7
        FCB     $00,$16,$D8,$0F,$D7,$0F,$7C,$00
        FCB     $8F,$08,$8C,$01,$0C,$26,$03,$CE
        FCB     $01,$00,$DF,$8D,$D6,$83,$C4,$9F
        FCB     $CA,$20,$D7,$83,$F7,$7A,$00,$39
        FCB     $7F,$00,$90,$96,$8F,$27,$07,$86
        FCB     $01,$BD,$F9,$A4,$20,$F5,$B6,$7A
        FCB     $00,$85,$02,$27,$EE,$96,$5F,$26
        FCB     $0D,$CE,$F8,$32

        END