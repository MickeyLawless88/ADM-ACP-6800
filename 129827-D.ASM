; 129827-147.bin -- ROM D ($F800-$FFFF)
; VERIFIED BYTE-EXACT: reassembled through acp6800, diffed identical to original.
;
; Holds the hardware vector table at $FFF8-$FFFF:
;   IRQ = NMI = $FA87 (IRQ_HANDLER, in this same ROM)
;   SWI = RESET = $E900 (RESET, in ROM B -- see ROM129827_B.ASM)
;
; IRQ_HANDLER polls ACIA1 then PRNTER (same pattern as the DataMaxx
; firmware's own interrupt handler). Also contains screen-position
; calculation routines (SCRN_CALC, SCRN_PUTC, SCRN_SETUP) and buffer
; initialization (BUF_INIT, BUF_INIT2).
;
; LABELS: see ROM129827_A.ASM's header for the naming scheme.
; Traced coverage: 319 instructions, 665/2048 bytes (32.5%).
;
        ORG     $F800
        FCB     $B6,$7E,$80,$84,$0F,$BD,$EE,$9C
        FCB     $A6,$00,$BD,$F9,$A4,$96,$83,$84
        FCB     $9F,$8A,$40,$97,$83,$B7,$7A,$00
        FCB     $CE,$00,$00,$BD,$F9,$92,$CE,$00
        FCB     $02,$BD,$F9,$92,$7E,$F9,$99
BUF_INIT
        LDX     #$0100
        STX     $8D
        STX     $8B
        FCB     $7F,$00,$8F
        RTS
        FCB     $AC,$73,$58,$40,$3A,$1D,$0F,$08
        FCB     $05,$05,$04,$03,$02,$02,$02,$01
BUF_INIT_01B
        FCB     $7D,$00,$8F
        BEQ     BUF_INIT_03A
        LDX     $8B
        LDAA    $00,X
        ANDA    #$7F
        ORAA    $92
        STAA    $7A01
        FCB     $7A,$00,$8F
        INX
        CPX     #$010C
        BNE     BUF_INIT_037
        LDX     #$0100
BUF_INIT_037
        STX     $8B
        RTS
BUF_INIT_03A
        LDAA    $83
        ANDA    #$9F
        STAA    $83
        STAA    $7A00
        RTS
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$8F
BUF_INIT_0A9
        LDX     #$00B3
        LDAA    #$80
        LDAB    #$08
        BSR     BUF_INIT_0FD
        LDX     #$00BB
        LDAB    #$08
        CLRA
        BSR     BUF_INIT_0FD
        LDX     #$ECEC
        STX     $93
        LDX     #$F7E4
        STX     $A1
        LDAA    $00
        BNE     BUF_INIT_0E3
        LDX     #$ED87
        STX     $95
        LDX     #$F9DD
        STX     $97
        LDX     #$FA20
        STX     $99
        LDX     #$F4A6
        STX     $9B
        LDX     #$E6C5
        STX     $9D
        BRA     BUF_INIT_0E6
BUF_INIT_0E3
        JSR     $E0C3
BUF_INIT_0E6
        LDX     #$0000
        STX     $CB
        STX     $CD
        LDX     #$0000
        JSR     CLR_HIBIT
        LDX     #$0002
        JSR     CLR_HIBIT
        CLI
        JMP     BUF_INIT_104
BUF_INIT_0FD
        STAA    $00,X
        INX
        DECB
        BGT     BUF_INIT_0FD
        RTS
BUF_INIT_104
        LDX     $CB
BUF_INIT_106
        LDAA    $B3,X
        BPL     BUF_INIT_13D
BUF_INIT_10A
        INX
        CPX     #$0008
        BNE     BUF_INIT_106
        FCB     $7F,$00,$CC
        LDAB    $7802
        BITB    #$02
        BNE     BUF_INIT_104
        LDAB    #$34
        STAB    $7801
        LDAB    #$3C
        STAB    $7801
        LDX     #$0000
BUF_INIT_127
        LDAA    $BB,X
        BEQ     BUF_INIT_135
        DEC     $BB,X
        BNE     BUF_INIT_135
        LDAA    $B3,X
        ANDA    #$7F
        STAA    $B3,X
BUF_INIT_135
        INX
        CPX     #$0008
        BNE     BUF_INIT_127
        BRA     BUF_INIT_104
BUF_INIT_13D
        STX     $CB
        STX     $CD
        TAB
        ANDA    #$7C
        STAA    $B3,X
        LDAA    $C3,X
        FCB     $78,$00,$CE
        LDX     $CD
        BITB    #$01
        BEQ     BUF_INIT_15F
        BITB    #$02
        BEQ     BUF_INIT_15B
        PSHA
        BSR     CLR_HIBIT_007
        PULA
        LDX     $CD
BUF_INIT_15B
        LDX     $A3,X
        BRA     BUF_INIT_161
BUF_INIT_15F
        LDX     $93,X
BUF_INIT_161
        ANDB    #$30
        JSR     $00,X
        LDX     $CB
        BRA     BUF_INIT_10A
        STAA    $C3,X
CLR_HIBIT
        LDAA    $B3,X
        ANDA    #$7F
        STAA    $B3,X
        RTS
CLR_HIBIT_007
        LDX     $CB
        LDAA    $B3,X
        ORAA    #$80
        STAA    $B3,X
        CLR     $BB,X
        RTS
        FCB     $DE,$CB,$E6,$B3,$CA,$81,$A7,$BB
        FCB     $26,$02,$C4,$7F,$E7,$B3,$32,$33
        FCB     $DF,$CD,$78,$00,$CE,$DE,$CD,$A7
        FCB     $A3,$E7,$A4,$39,$DE,$CB,$E6,$B3
        FCB     $CA,$83,$20,$E8,$DE,$CB,$36,$A6
        FCB     $B3,$84,$CF,$C4,$30,$1B,$A7,$B3
        FCB     $32,$39,$DE,$CB,$E6,$B3,$C4,$30
        FCB     $39,$BD,$FA,$63,$5D,$2B,$3C,$CE
        FCB     $00,$03,$4D,$2A,$0E,$D6,$5C,$27
        FCB     $08,$E6,$B3,$C4,$FE,$E7,$B3,$20
        FCB     $02,$84,$7F,$7E,$F9,$90,$A6,$00
        FCB     $16,$D8,$0F,$D7,$0F,$08,$8C,$03
        FCB     $80,$26,$03,$CE,$01,$10,$4D,$2A
        FCB     $0D,$E6,$00,$D7,$D3,$08,$8C,$03
        FCB     $80,$26,$03,$CE,$01,$10,$DF,$CF
        FCB     $7F,$00,$D4,$39,$36,$BD,$F9,$99
        FCB     $32,$4D,$2A,$1B,$84,$7F,$D6,$D3
        FCB     $C5,$10,$26,$EF,$C5,$60,$27,$0C
        FCB     $D6,$5C,$27,$08,$37,$BD,$FB,$8B
        FCB     $32,$7E,$EF,$2D,$7E,$EE,$F5,$C6
        FCB     $50,$D7,$D6,$85,$60,$27,$F5,$91
        FCB     $55,$27,$F1,$BD,$EE,$F5,$7A,$00
        FCB     $D6,$27,$C8,$BD,$FA,$63,$5D,$2B
        FCB     $C2,$4D,$2A,$E7,$7E,$FA,$28,$DE
        FCB     $CF,$9C,$D1,$27,$13,$BD,$F9,$FA
        FCB     $7D,$00,$15,$2F,$09,$BD,$E8,$6F
        FCB     $D6,$15,$C5,$02,$27,$02,$5F,$39
        FCB     $C6,$80,$39
BUF_INIT2
        LDX     #$0110
        STX     $D1
        STX     $CF
        RTS
IRQ_HANDLER
        LDAB    $7A00
        BPL     IRQ_HANDLER_007
        BSR     IRQ_HANDLER_017
IRQ_HANDLER_007
        LDAB    $7C00
        BPL     IRQ_HANDLER_016
        LDAB    $E670
        CMPB    #$AA
        BNE     IRQ_HANDLER_016
        JSR     $E8AE
IRQ_HANDLER_016
        RTI
IRQ_HANDLER_017
        BITB    #$01
        BEQ     IRQ_HANDLER_073
        LDAA    $7A01
        ANDA    #$7F
        ANDB    #$70
        BEQ     IRQ_HANDLER_02D
        BITB    #$10
        BEQ     IRQ_HANDLER_02B
        STAB    $D7
        RTS
IRQ_HANDLER_02B
        ORAA    #$80
IRQ_HANDLER_02D
        FCB     $7D,$00,$D7
        BEQ     IRQ_HANDLER_036
        FCB     $7F,$00,$D7
        RTS
IRQ_HANDLER_036
        FCB     $7D,$00,$D4
        BMI     IRQ_HANDLER_06C
        LDX     $D1
        STAA    $00,X
        INX
        CPX     #$0380
        BNE     IRQ_HANDLER_048
        LDX     #$0110
IRQ_HANDLER_048
        STX     $D1
        TSTA
        BPL     IRQ_HANDLER_05A
        STAB    $00,X
        INX
        CPX     #$0380
        BNE     IRQ_HANDLER_058
        LDX     #$0110
IRQ_HANDLER_058
        STX     $D1
IRQ_HANDLER_05A
        INX
        CPX     #$0380
        BNE     IRQ_HANDLER_063
        LDX     #$0110
IRQ_HANDLER_063
        CPX     $CF
        BNE     IRQ_HANDLER_06B
        LDAA    #$80
        STAA    $D4
IRQ_HANDLER_06B
        RTS
IRQ_HANDLER_06C
        LDAA    #$80
        STAA    $D5
        JMP     KBD_DISP_027
IRQ_HANDLER_073
        BITB    #$02
        BEQ     IRQ_HANDLER_082
        LDAA    $83
        ANDA    #$60
        CMPA    #$20
        BNE     IRQ_HANDLER_082
        JMP     BUF_INIT_01B
IRQ_HANDLER_082
        BITB    #$04
        BEQ     IRQ_HANDLER_089
        LDAA    $7A01
IRQ_HANDLER_089
        RTS
        FCB     $86,$80,$97,$28,$96,$64,$85,$10
        FCB     $27,$03,$7E,$EF,$B0,$7E,$EF,$D0
        FCB     $7F,$00,$28,$39,$86,$80,$97,$29
        FCB     $39
CLR_FLAG29
        FCB     $7F,$00,$29
        RTS
        FCB     $96,$51,$84,$BF,$20,$04,$96,$51
        FCB     $8A,$40,$97,$51,$39,$BD,$F9,$C0
        FCB     $81,$46,$26,$06,$96,$51,$84,$7F
        FCB     $20,$F0,$81,$48,$26,$EE,$96,$51
        FCB     $8A,$80,$20,$E6,$86,$80,$97,$2A
        FCB     $39,$7F,$00,$2A,$39,$86,$80,$97
        FCB     $2D,$39,$7F,$00,$2D,$39
KBD_DISP
        FCB     $7D,$00,$52
        BNE     KBD_DISP_019
        FCB     $7D,$00,$15
        BNE     KBD_DISP_019
        LDAA    $60
        BITA    #$20
        BNE     KBD_DISP_019
        LDAA    $7802
        ANDA    #$04
        ORAA    #$80
        STAA    $52
KBD_DISP_019
        RTS
        FCB     $7F,$00,$52,$39,$86,$02,$97,$2E
        FCB     $39,$7F,$00,$2E,$39
KBD_DISP_027
        LDAA    $7803
        ANDA    #$F7
        STAA    $7803
        ORAA    #$08
        STAA    $7803
        RTS
        FCB     $BD,$F9,$C0,$BD,$F3,$5E,$8A,$90
        FCB     $7E,$EF,$2D,$D6,$CC,$C1,$01,$26
        FCB     $04,$D6,$63,$2B,$4D,$BD,$F9,$C0
        FCB     $7F,$00,$74,$81,$2E,$26,$07,$86
        FCB     $10,$97,$74,$BD,$F9,$C0,$BD,$F3
        FCB     $5E,$25,$38,$9B,$74,$97,$74,$BD
        FCB     $F9,$C0,$BD,$F3,$5E,$48,$48,$48
        FCB     $48,$97,$73,$BD,$F9,$C0,$BD,$F3
        FCB     $5E,$25,$20,$CE,$00,$55,$DF,$CD
        FCB     $D6,$74,$DB,$CE,$D7,$CE,$D6,$CD
        FCB     $C9,$00,$D7,$CD,$DE,$CD,$D6,$73
        FCB     $1B,$A7,$00
KBD_COND
        LDAB    $00
        BEQ     KBD_COND_007
        JSR     $E094
KBD_COND_007
        RTS
        FCB     $7E,$FB,$8B,$BD,$F9,$C0,$36,$BD
        FCB     $FD,$AA,$32,$81,$21,$26,$03,$7E
        FCB     $E9,$00,$81,$30,$2D,$61,$26,$02
        FCB     $8D,$0D,$81,$39,$26,$02,$8D,$2E
        FCB     $81,$38,$26,$02,$8D,$3B,$39,$DE
        FCB     $53,$C6,$10,$8D,$58,$DF,$D8,$8D
        FCB     $51,$CE,$00,$55,$C6,$10,$8D,$4D
        FCB     $8D,$48,$8D,$46,$DE,$D8,$C6,$0E
        FCB     $8D,$43,$8D,$3E,$CE,$00,$65,$C6
        FCB     $0E,$8D,$3A,$8D,$35,$39,$CE,$EB
        FCB     $C7,$C6,$02,$8D,$30,$8D,$2B,$CE
        FCB     $EB,$19,$C6,$02,$8D,$27,$8D,$22
        FCB     $39,$B6,$7E,$00,$8D,$3F,$8D,$1A
        FCB     $B6,$79,$00,$8D,$38,$8D,$13,$B6
        FCB     $7D,$00,$8D,$31,$8D,$0C,$39,$8D
        FCB     $AE,$8D,$07,$8D,$D1,$8D,$03,$8D
        FCB     $E0,$39,$7E,$F0,$6A
CHR_PROC
        STX     $CD
        PSHB
        LDAA    $00,X
        PSHA
        JSR     $F379
        JSR     $EF2D
        PULA
        JSR     $F37D
        JSR     $EF2D
        JSR     $F047
        PULB
        LDX     $CD
        INX
        STX     $CD
        DECB
        BNE     CHR_PROC
        RTS
        FCB     $97,$D8,$C6,$08,$D7,$D9,$BD,$F0
        FCB     $47,$74,$00,$D8,$24,$04,$86,$46
        FCB     $20,$02,$86,$4E,$BD,$EF,$2D,$7A
        FCB     $00,$D9,$26,$EA,$39,$86,$01,$20
        FCB     $06,$86,$80,$20,$02,$86,$11,$F6
        FCB     $E6,$70,$C1,$AA,$26,$1B,$F6,$79
        FCB     $00,$C5,$80,$26,$14,$7E,$E6,$71
        FCB     $F6,$E6,$70,$C1,$AA,$26,$0A,$F6
        FCB     $79,$00,$C5,$80,$26,$03,$7E,$E8
        FCB     $22,$39,$FE,$E0,$00,$8C,$54,$4A
        FCB     $26,$F7,$7E,$E0,$3E,$86,$02,$7E
        FCB     $EF,$2D,$86,$03,$20,$F9,$BD,$F9
        FCB     $C0,$80,$20,$97,$73,$BD,$F9,$C0
        FCB     $91,$55,$27,$0A,$36,$BD,$EF,$16
        FCB     $32,$7A,$00,$73,$2E,$F6,$39,$86
        FCB     $20,$D6,$65,$C5,$80,$27,$05,$96
        FCB     $5D,$20,$01,$4F,$D6,$65,$C5,$02
        FCB     $27,$03,$7F,$00,$29,$9A,$29,$36
        FCB     $BD,$EE,$AB,$96,$52,$2A,$35,$84
        FCB     $04,$F6,$78,$02,$C4,$04,$11,$26
        FCB     $2B,$32,$D6,$23,$37,$D6,$24,$37
        FCB     $D6,$26,$37,$D6,$27,$37,$36,$BD
        FCB     $F3,$B5,$BD,$FD,$D3,$BD,$F3,$B5
        FCB     $32,$33,$F7,$7F,$0C,$D7,$27,$33
        FCB     $F7,$7F,$0D,$D7,$26,$33,$D7,$24
        FCB     $33,$D7,$23,$36,$BD,$FD,$D6,$31
        FCB     $7E,$EF,$D0,$D6,$65,$C5,$04,$27
        FCB     $30,$4F,$36,$20,$33,$8D,$0F,$36
        FCB     $20,$2E,$D6,$65,$C5,$04,$27,$F5
        FCB     $8D,$0F,$8D,$02,$20,$1E,$86,$20
        FCB     $D6,$65,$C5,$40,$27,$02,$96,$5D
        FCB     $39,$96,$2F,$2A,$07,$96,$62,$2A
        FCB     $03,$BD,$F2,$58,$39,$86,$A0,$20
        FCB     $03,$8D,$EE,$4F,$36,$7F,$00,$28
        FCB     $7F,$00,$29,$BD,$EE,$AB,$96,$52
        FCB     $27,$12,$84,$04,$F6,$78,$02,$C4
        FCB     $04,$11,$26,$03,$BD,$F3,$B5,$8D
        FCB     $09,$BD,$F3,$B5,$8D,$04,$31,$7E
        FCB     $EF,$D0
SCRN_SETUP
        JSR     $F026
        LDAB    $21
        ADDB    #$07
        LDAA    #$7F
        STAB    $D8
        STAA    $D9
        LDAA    $25
        JSR     $F341
        ADDA    #$4F
        ADCB    $21
        STAB    $DA
        STAA    $DB
        TSX
        LDAB    $02,X
        LDX     $23
SCRN_SETUP_01F
        LDAA    $28
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
        CPX     $DA
        BEQ     SCRN_SETUP_042
        CPX     $D8
        BEQ     SCRN_SETUP_03C
        INX
        BRA     SCRN_SETUP_01F
SCRN_SETUP_03C
        LDX     $21
        STX     $23
        BRA     SCRN_SETUP_01F
SCRN_SETUP_042
        JMP     $F34F
        FCB     $86,$20,$D6,$65,$C5,$80,$27,$02
        FCB     $96,$5D,$BD,$EE,$AB
SCRN_SETUP_052
        LDAB    $65
        BITB    #$01
        BEQ     SCRN_SETUP_05B
        FCB     $7F,$00,$29
SCRN_SETUP_05B
        ORAA    $29
        LDAB    #$50
        SUBB    $27
        STAB    $DB
        LDX     $23
SCRN_SETUP_065
        LDAB    $28
        BPL     SCRN_SETUP_071
        STAA    $7000
        NOP
        LDAB    $00,X
        BMI     SCRN_SETUP_07D
SCRN_SETUP_071
        STAA    $7000
        NOP
        STAA    $00,X
        INX
        FCB     $7A,$00,$DB
        BNE     SCRN_SETUP_065
SCRN_SETUP_07D
        LDX     $23
        STAA    $7000
        NOP
        LDAA    $00,X
        BITA    $28
        BEQ     SCRN_SETUP_08C
        JSR     $F151
SCRN_SETUP_08C
        RTS
        FCB     $4F,$20,$BF
LOAD_5D
        LDAA    $5D
        BRA     SCRN_SETUP_052
        JSR     CLR_FLAG29
SCRN_CALC
        LDX     $23
        LDAA    #$50
        SUBA    $27
        STAA    $DB
        LDAB    #$20
SCRN_CALC_00A
        STAA    $7000
        NOP
        LDAA    $00,X
        BITA    $28
        BNE     SCRN_CALC_021
        STAA    $7000
        NOP
        STAB    $00,X
        TAB
        INX
        FCB     $7A,$00,$DB
        BNE     SCRN_CALC_00A
SCRN_CALC_021
        LDX     $23
        RTS
        FCB     $BD,$FB,$2A,$DE,$23,$C6,$4F,$F0
        FCB     $7F,$09,$27,$14,$B7,$70,$00,$01
        FCB     $A6,$01,$95,$28,$26,$0A,$B7,$70
        FCB     $00,$01,$A7,$00,$08,$5A,$20,$EA
        FCB     $96,$5D,$B7,$70,$00,$01,$A7,$00
        FCB     $39,$7D,$00,$28,$27,$01,$39,$7F
        FCB     $00,$29,$BD,$F0,$3C,$DE,$23,$DF
        FCB     $DC,$96,$52,$2A,$3D,$F6,$78,$02
        FCB     $84,$04,$C4,$04,$11,$26,$33,$C6
        FCB     $87,$4D,$26,$02,$CB,$08,$86,$D0
        FCB     $D7,$DC,$97,$DD,$DE,$DC,$A6,$04
        FCB     $36,$4A,$2A,$02,$86,$17,$A7,$04
        FCB     $32,$BD,$F3,$41,$EB,$00,$D7,$7D
        FCB     $97,$7E,$96,$25,$BD,$F3,$41,$DB
        FCB     $21,$D7,$7F,$97,$80,$C6,$50,$BD
        FCB     $F4,$12,$96,$25,$91,$26,$27,$42
        FCB     $4D,$27,$24,$4A,$97,$DA,$BD,$F3
        FCB     $41,$DB,$21,$D7,$D8,$97,$D9,$DE
        FCB     $D8,$C6,$50,$B7,$70,$00,$01,$A6
        FCB     $00,$B7,$70,$00,$01,$A7,$50,$08
        FCB     $5A,$26,$F0,$96,$DA,$20,$D5,$DE
        FCB     $21,$DF,$7D,$96,$7E,$8B,$30,$97
        FCB     $80,$96,$7D,$89,$07,$97,$7F,$C6
        FCB     $50,$BD,$F4,$12,$86,$17,$97,$DA
        FCB     $20,$BA,$96,$5D,$7E,$FE,$25,$7D
        FCB     $00,$28,$27,$01,$39,$7F,$00,$29
        FCB     $BD,$F0,$3C,$96,$26,$91,$25,$27
        FCB     $3C,$81,$17,$26,$16,$D6,$21,$CB
        FCB     $07,$86,$30,$D7,$7D,$97,$7E,$DE
        FCB     $21,$DF,$7F,$C6,$50,$BD,$F4,$12
        FCB     $4F,$20,$E2,$36,$BD,$F3,$41,$DB
        FCB     $21,$D7,$D8,$97,$D9,$DE,$D8,$C6
        FCB     $50,$B7,$70,$00,$01,$A6,$50,$B7
        FCB     $70,$00,$01,$A7,$00,$08,$5A,$26
        FCB     $F0,$32,$4C,$20,$C0,$BD,$F3,$41
        FCB     $DB,$21,$D7,$7D,$D7,$D8,$97,$7E
        FCB     $97,$D9,$96,$52,$27,$33,$F6,$78
        FCB     $02,$C4,$04,$84,$04,$11,$26,$29
        FCB     $88,$04,$48,$8B,$87,$C6,$D0,$97
        FCB     $7F,$D7,$80,$DE,$7F,$A6,$04,$4C
        FCB     $81,$17,$2F,$01,$4F,$A7,$04,$BD
        FCB     $F3,$41,$EB,$00,$D7,$7F,$97,$80
        FCB     $DE,$7F,$DF,$D8,$C6,$50,$BD,$F4
        FCB     $12,$DE,$D8,$C6,$50,$96,$5D,$B7
        FCB     $70,$00,$01,$A7,$00,$08,$5A,$26
        FCB     $F6,$39,$FA,$87,$E9,$00,$FA,$87
        FCB     $E9,$00

        END