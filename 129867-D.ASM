; 129867-65.bin -- ROM D ($F800-$FFFF)
; VERIFIED BYTE-EXACT: reassembled through acp6800, diffed identical to original.
;
; Holds the hardware vector table at $FFF8-$FFFF:
;   IRQ = $ED83 (IRQ_HANDLER, in ROM B -- see R867B.ASM)
;   SWI = NMI = RESET = $E800 (RESET, in ROM B -- see R867B.ASM)
;
; Low traced coverage here (94 instructions, 192/2048 bytes, 9.4%) -- most
; of this ROM's own routines (screen output, buffer init) are reached from
; ROM B/C, not called directly from either vector, so little of this
; specific ROM's content falls within the traced call graph.
;
; LABELS: see R867B.ASM's header for the naming scheme.
;
        ORG     $F800
        FCB     $0C
CODE_F801
        STAA    $7000
        NOP
        STAA    $00,X
        INX
        FCB     $7A,$00,$BA
        BNE     $F7F5
CODE_F80D
        LDX     $13
        STAA    $7000
        NOP
        LDAA    $00,X
        BITA    $18
        BEQ     CODE_F81C
        JSR     $F3FA
CODE_F81C
        RTS
        FCB     $4F,$20,$BF
LOAD_4D
        LDAA    $4D
        BRA     $F7E2
        JSR     $F079
SCRN_CALC
        LDX     $13
        LDAA    #$50
        SUBA    $17
        STAA    $BA
        LDAB    #$20
SCRN_CALC_00A
        STAA    $7000
        NOP
        LDAA    $00,X
        BITA    $18
        BNE     SCRN_CALC_021
        STAA    $7000
        NOP
        STAB    $00,X
        TAB
        INX
        FCB     $7A,$00,$BA
        BNE     SCRN_CALC_00A
SCRN_CALC_021
        LDX     $13
        RTS
        FCB     $BD,$F0,$79,$DE,$13,$C6,$4F,$F0
        FCB     $7F,$09,$27,$14,$B7,$70,$00,$01
        FCB     $A6,$01,$95,$18,$26,$0A,$B7,$70
        FCB     $00,$01,$A7,$00,$08,$5A,$20,$EA
        FCB     $96,$4D,$B7,$70,$00,$01,$A7,$00
        FCB     $39,$7D,$00,$18,$27,$01,$39,$7F
        FCB     $00,$19,$BD,$F2,$E5,$DE,$13,$DF
        FCB     $BB,$96,$42,$2A,$3D,$F6,$78,$02
        FCB     $84,$04,$C4,$04,$11,$26,$33,$C6
        FCB     $87,$4D,$26,$02,$CB,$08,$86,$D0
        FCB     $D7,$BB,$97,$BC,$DE,$BB,$A6,$04
        FCB     $36,$4A,$2A,$02,$86,$17,$A7,$04
        FCB     $32,$BD,$F5,$EA,$EB,$00,$D7,$B1
        FCB     $97,$B2,$96,$15,$BD,$F5,$EA,$DB
        FCB     $11,$D7,$B3,$97,$B4,$C6,$50,$BD
        FCB     $F6,$BB,$96,$15,$91,$16,$27,$42
        FCB     $4D,$27,$24,$4A,$97,$B9,$BD,$F5
        FCB     $EA,$DB,$11,$D7,$B7,$97,$B8,$DE
        FCB     $B7,$C6,$50,$B7,$70,$00,$01,$A6
        FCB     $00,$B7,$70,$00,$01,$A7,$50,$08
        FCB     $5A,$26,$F0,$96,$B9,$20,$D5,$DE
        FCB     $11,$DF,$B1,$96,$B2,$8B,$30,$97
        FCB     $B4,$96,$B1,$89,$07,$97,$B3,$C6
        FCB     $50,$BD,$F6,$BB,$86,$17,$97,$B9
        FCB     $20,$BA,$96,$4D,$7E,$F7,$E2,$7D
        FCB     $00,$18,$27,$01,$39,$7F,$00,$19
        FCB     $BD,$F2,$E5,$96,$16,$91,$15,$27
        FCB     $3C,$81,$17,$26,$16,$D6,$11,$CB
        FCB     $07,$86,$30,$D7,$B1,$97,$B2,$DE
        FCB     $11,$DF,$B3,$C6,$50,$BD,$F6,$BB
        FCB     $4F,$20,$E2,$36,$BD,$F5,$EA,$DB
        FCB     $11,$D7,$B7,$97,$B8,$DE,$B7,$C6
        FCB     $50,$B7,$70,$00,$01,$A6,$50,$B7
        FCB     $70,$00,$01,$A7,$00,$08,$5A,$26
        FCB     $F0,$32,$4C,$20,$C0,$BD,$F5,$EA
        FCB     $DB,$11,$D7,$B1,$D7,$B7,$97,$B2
        FCB     $97,$B8,$96,$42,$27,$33,$F6,$78
        FCB     $02,$C4,$04,$84,$04,$11,$26,$29
        FCB     $88,$04,$48,$8B,$87,$C6,$D0,$97
        FCB     $B3,$D7,$B4,$DE,$B3,$A6,$04,$4C
        FCB     $81,$17,$2F,$01,$4F,$A7,$04,$BD
        FCB     $F5,$EA,$EB,$00,$D7,$B3,$97,$B4
        FCB     $DE,$B3,$DF,$B7,$C6,$50,$BD,$F6
        FCB     $BB,$DE,$B7,$C6,$50,$96,$4D,$B7
        FCB     $70,$00,$01,$A7,$00,$08,$5A,$26
        FCB     $F6,$39,$86,$02,$20,$21,$86,$03
        FCB     $20,$1D,$86,$04,$20,$19,$86,$05
        FCB     $20,$15,$86,$06,$20,$11,$86,$07
        FCB     $20,$0D,$86,$08,$20,$09,$86,$09
        FCB     $20,$05,$86,$0A,$20,$01,$43,$97
        FCB     $C5,$BD,$EF,$BC,$7F,$00,$AE,$4F
        FCB     $CE,$00,$04,$BD,$EC,$B8,$CE,$00
        FCB     $00,$BD,$EC,$C3,$CE,$00,$02,$7E
        FCB     $EC,$C3,$BD,$FC,$DD,$96,$C5,$2A
        FCB     $05,$CE,$FA,$77,$20,$0F,$D6,$55
        FCB     $C4,$20,$D7,$CD,$CE,$FA,$32,$48
        FCB     $BD,$EF,$AD,$EE,$00,$AD,$00,$96
        FCB     $C5,$81,$0A,$27,$0E,$96,$46,$27
        FCB     $0A,$BD,$FC,$F5,$96,$47,$27,$03
        FCB     $BD,$FC,$F5,$BD,$FB,$2F,$CE,$00
        FCB     $07,$BD,$EC,$BA,$7E,$EC,$C1,$FA
        FCB     $48,$FA,$48,$FA,$A5,$FA,$A5,$FA
        FCB     $AD,$FA,$AD,$FC,$0B,$FC,$05,$FA
        FCB     $62,$FA,$49,$FA,$82,$39,$B6,$78
        FCB     $02,$D6,$42,$27,$02,$98,$42,$84
        FCB     $04,$44,$44,$8A,$30,$D6,$54,$C5
        FCB     $40,$26,$01,$4C,$BD,$FC,$F5,$96
        FCB     $16,$4A,$90,$15,$2C,$02,$8B,$18
        FCB     $8B,$20,$BD,$FC,$F5,$96,$17,$8B
        FCB     $20,$7E,$FC,$F5,$96,$4B,$BD,$FC
        FCB     $F5,$96,$C5,$43,$7E,$FC,$F5,$CE
        FCB     $7B,$80,$DF,$B7,$A6,$1E,$81,$0D
        FCB     $26,$17,$A6,$1F,$81,$8A,$26,$11
        FCB     $84,$7F,$97,$C5,$DE,$B7,$A6,$00
        FCB     $08,$DF,$B7,$BD,$FC,$F5,$4D,$2A
        FCB     $F3,$39,$BD,$FB,$26,$BD,$F2,$E5
        FCB     $20,$17,$BD,$FB,$26,$96,$42,$27
        FCB     $0D,$F6,$78,$02,$84,$04,$C4,$04
        FCB     $11,$27,$03,$BD,$F6,$5E,$BD,$F2
        FCB     $CF,$4F,$B7,$00,$1E,$97,$C6,$BD
        FCB     $EF,$8B,$7D,$00,$AE,$2B,$2D,$BD
        FCB     $FB,$57,$D6,$50,$2A,$04,$81,$03
        FCB     $27,$22,$C5,$10,$27,$06,$DE,$13
        FCB     $9C,$C1,$27,$18,$4D,$27,$03,$BD
        FCB     $FC,$F5,$DE,$13,$9C,$C1,$27,$0C
        FCB     $BD,$FB,$4C,$7D,$00,$17,$26,$CF
        FCB     $8D,$03,$20,$CB,$39,$96,$55,$85
        FCB     $10,$27,$04,$96,$18,$2B,$1B,$96
        FCB     $48,$27,$17,$BD,$FC,$F5,$96,$49
        FCB     $27,$10,$7E,$FC,$F5,$36,$96,$CD
        FCB     $26,$07,$96,$4A,$27,$03,$BD,$FC
        FCB     $F5,$32,$39,$DE,$16,$DF,$C3,$DE
        FCB     $13,$DF,$C1,$39,$96,$18,$26,$15
        FCB     $96,$C5,$81,$02,$2D,$0F,$81,$06
        FCB     $2E,$0B,$2D,$06,$D6,$54,$C5,$20
        FCB     $27,$03,$BD,$F2,$9A,$7F,$00,$C5
        FCB     $39,$BD,$F2,$F0,$7D,$00,$B5,$27
        FCB     $1E,$7E,$F3,$13,$DE,$13,$B7,$70
        FCB     $00,$01,$A6,$00,$7D,$00,$18,$26
        FCB     $0F,$16,$C4,$F0,$C1,$90,$26,$02
        FCB     $86,$20,$84,$7F,$7F,$00,$CD,$39
        FCB     $D6,$C5,$C5,$01,$26,$3D,$D6,$C6
        FCB     $4D,$2B,$0B,$C1,$01,$26,$F0,$7F
        FCB     $00,$C6,$8D,$91,$20,$E4,$81,$E0
        FCB     $27,$18,$C1,$02,$27,$DC,$C6,$01
        FCB     $D7,$C6,$9C,$C1,$27,$1B,$BD,$FB
        FCB     $4C,$D6,$17,$26,$B7,$BD,$FB,$00
        FCB     $20,$B2,$C1,$02,$27,$E8,$C1,$01
        FCB     $26,$03,$BD,$FB,$18,$C6,$02,$20
        FCB     $DF,$4F,$39,$4D,$2B,$16,$7D,$00
        FCB     $C6,$27,$AF,$36,$96,$45,$BD,$FC
        FCB     $F5,$86,$28,$BD,$FC,$F5,$7F,$00
        FCB     $C6,$32,$20,$9E,$16,$C4,$F0,$C1
        FCB     $90,$26,$17,$36,$96,$45,$BD,$FC
        FCB     $F5,$86,$47,$BD,$FC,$F5,$32,$84
        FCB     $0F,$BD,$F6,$26,$BD,$FC,$F5,$7E
        FCB     $FB,$99,$7D,$00,$C6,$26,$10,$36
        FCB     $96,$45,$BD,$FC,$F5,$86,$29,$BD
        FCB     $FC,$F5,$86,$01,$97,$C6,$32,$7E
        FCB     $FB,$6D,$96,$54,$85,$20,$26,$F7
        FCB     $BD,$FB,$26,$7F,$00,$BB,$7F,$00
        FCB     $BC,$F6,$78,$02,$C4,$04,$D7,$BD
        FCB     $96,$54,$85,$20,$27,$0E,$86,$1C
        FCB     $97,$B9,$97,$BA,$B7,$70,$00,$01
        FCB     $A7,$00,$20,$23,$86,$02,$97,$B9
        FCB     $86,$03,$97,$BA,$96,$42,$27,$08
        FCB     $84,$04,$11,$26,$03,$BD,$F6,$5E
        FCB     $96,$15,$BD,$F5,$EA,$DB,$11,$8B
        FCB     $4F,$C9,$00,$D7,$BB,$97,$BC,$96
        FCB     $42,$27,$0D,$84,$04,$F6,$78,$02
        FCB     $C4,$04,$11,$27,$03,$BD,$F6,$5E
        FCB     $96,$15,$80,$17,$2C,$02,$8B,$18
        FCB     $BD,$F5,$EA,$DB,$11,$D7,$B7,$97
        FCB     $B8,$F6,$78,$02,$C4,$04,$D1,$BD
        FCB     $27,$03,$BD,$F6,$5E,$DE,$13,$9C
        FCB     $B7,$27,$27,$BD,$F3,$6F,$B7,$70
        FCB     $00,$01,$A6,$00,$91,$B9,$27,$06
        FCB     $9C,$B7,$26,$EF,$20,$14,$D6,$54
        FCB     $C5,$20,$27,$06,$D6,$16,$D1,$C3
        FCB     $26,$05,$BD,$FB,$4C,$20,$03,$BD
        FCB     $F3,$13,$DE,$BB,$DF,$C1,$BD,$EF
        FCB     $8B,$7D,$00,$AE,$2B,$20,$BD,$FB
        FCB     $57,$4D,$27,$07,$91,$BA,$27,$16
        FCB     $BD,$FC,$F5,$DE,$13,$9C,$C1,$27
        FCB     $0E,$BD,$FB,$4C,$7D,$00,$17,$26
        FCB     $DD,$BD,$FB,$00,$20,$D8,$39,$7E
        FCB     $F2,$8F,$D6,$CC,$CA,$01,$D7,$CC
        FCB     $36,$F6,$7E,$00,$C4,$1C,$96,$BF
        FCB     $84,$83,$1B,$97,$BF,$B7,$7A,$00
        FCB     $32,$39,$36,$7D,$00,$CC,$26,$02
        FCB     $8D,$E0,$D6,$CB,$C1,$0C,$27,$FA
        FCB     $DE,$C9,$32,$A7,$00,$16,$D8,$0E
        FCB     $D7,$0E,$7C,$00,$CB,$08,$8C,$01
        FCB     $0C,$26,$03,$CE,$01,$00,$DF,$C9
        FCB     $D6,$BF,$C4,$9F,$CA,$20,$D7,$BF
        FCB     $F7,$7A,$00,$39,$7F,$00,$CC,$96
        FCB     $CB,$27,$07,$86,$01,$BD,$EC,$CC
        FCB     $20,$F5,$B6,$7A,$00,$85,$02,$27
        FCB     $EE,$96,$4F,$26,$0D,$CE,$FD,$75
        FCB     $B6,$7E,$80,$84,$0F,$BD,$EF,$AD
        FCB     $A6,$00,$BD,$EC,$CC,$96,$BF,$84
        FCB     $9F,$8A,$40,$97,$BF,$B7,$7A,$00
        FCB     $CE,$00,$00,$BD,$EC,$BA,$CE,$00
        FCB     $02,$BD,$EC,$BA,$7E,$EC,$C1
BUF_INIT
        LDX     #$0100
        STX     $C9
        STX     $C7
        FCB     $7F,$00,$CB
        RTS
        FCB     $AC,$73,$58,$40,$3A,$1D,$0F,$08
        FCB     $05,$05,$04,$03,$02,$02,$02,$01
BUF_INIT_01B
        FCB     $7D,$00,$CB
        BEQ     BUF_INIT_03A
        LDX     $C7
        LDAA    $00,X
        ANDA    #$7F
        ORAA    $CE
        STAA    $7A01
        FCB     $7A,$00,$CB
        INX
        CPX     #$010C
        BNE     BUF_INIT_037
        LDX     #$0100
BUF_INIT_037
        STX     $C7
        RTS
BUF_INIT_03A
        LDAA    $BF
        ANDA    #$9F
        STAA    $BF
        STAA    $7A00
        RTS
        FCB     $AA,$D6,$53,$C5,$04,$26,$4B,$D6
        FCB     $D1,$26,$47,$CA,$80,$D7,$D1,$97
        FCB     $D0,$BD,$EF,$BC,$7F,$00,$AE,$96
        FCB     $D0,$2B,$10,$DE,$13,$96,$DB,$B7
        FCB     $70,$00,$01,$A7,$00,$BD,$F2,$59
        FCB     $BD,$F2,$CF,$96,$9E,$97,$CF,$CE
        FCB     $00,$00,$DF,$B7,$B6,$79,$00,$84
        FCB     $1C,$8A,$01,$97,$C0,$B7,$7C,$00
        FCB     $CE,$00,$05,$BD,$EC,$BA,$CE,$00
        FCB     $00,$BD,$EC,$C3,$CE,$00,$02,$7E
        FCB     $EC,$C3,$7E,$F0,$DA,$8D,$40,$7D
        FCB     $00,$D0,$27,$01,$39,$96,$CF,$81
        FCB     $03,$26,$25,$86,$01,$BD,$F9,$DA
        FCB     $7E,$EC,$C1,$CE,$00,$02,$BD,$EC
        FCB     $BA,$B6,$00,$01,$81,$02,$27,$02
        FCB     $8D,$1D,$7D,$00,$D0,$27,$09,$86
        FCB     $01,$BD,$EC,$CC,$20,$EB,$27,$56
        FCB     $CE,$00,$02,$BD,$EC,$BA,$CE,$00
        FCB     $00,$BD,$EC,$BA,$7E,$EC,$C1,$BD
        FCB     $EF,$8B,$F6,$7C,$00,$C4,$0A,$C1
        FCB     $02,$27,$06,$7D,$00,$AE,$2B,$78
        FCB     $39,$D6,$D0,$2B,$73,$C4,$0F,$5A
        FCB     $27,$1F,$5A,$27,$29,$5A,$27,$22
        FCB     $5A,$27,$3B,$5A,$27,$62,$5A,$27
        FCB     $10,$5A,$27,$1A,$5A,$27,$13,$5A
        FCB     $27,$14,$5A,$27,$14,$5F,$D7,$D0
        FCB     $39,$86,$0D,$7C,$00,$D0,$B7,$7C
        FCB     $01,$39,$86,$0A,$20,$F5,$4F,$20
        FCB     $F2,$7F,$00,$D0,$96,$D1,$84,$7F
        FCB     $97,$D1,$96,$C0,$84,$9F,$8A,$40
        FCB     $97,$C0,$B7,$7C,$00,$39,$8D,$E6
        FCB     $DE,$13,$DF,$B7,$96,$B8,$8B,$50
        FCB     $97,$B8,$96,$B7,$89,$00,$97,$B7
        FCB     $DE,$B7,$09,$9C,$13,$27,$0E,$B7
        FCB     $70,$00,$01,$A6,$00,$84,$7F,$27
        FCB     $F1,$81,$20,$27,$ED,$DF,$B7,$39
        FCB     $DE,$13,$B7,$70,$00,$01,$A6,$00
        FCB     $16,$D1,$DB,$27,$4A,$7D,$00,$AE
        FCB     $2B,$1E,$7D,$00,$D0,$2B,$12,$D5
        FCB     $18,$27,$08,$D6,$D0,$C5,$10,$27
        FCB     $02,$86,$20,$84,$7F,$26,$02,$86
        FCB     $20,$B7,$7C,$01,$9C,$B7,$27,$1D
        FCB     $96,$17,$81,$4F,$26,$14,$96,$16
        FCB     $91,$15,$26,$0E,$96,$42,$27,$81
        FCB     $F6,$78,$02,$84,$02,$C4,$04,$11
        FCB     $26,$1E,$7E,$F2,$F0,$96,$D0,$84
        FCB     $F0,$4C,$97,$D0,$7E,$F3,$13,$86
        FCB     $20,$B7,$70,$00,$01,$A7,$00,$7D
        FCB     $00,$AE,$2B,$04,$96,$D0,$2A,$03
        FCB     $7E,$FE,$8F,$84,$F0,$8A,$06,$97
        FCB     $D0,$39,$BD,$EC,$E8,$84,$03,$27
        FCB     $33,$81,$03,$27,$36,$0E,$7D,$00
        FCB     $D2,$26,$26,$97,$D2,$7F,$00,$42
        FCB     $96,$11,$85,$08,$27,$05,$CE,$80
        FCB     $00,$20,$03,$CE,$88,$00,$DF,$D3
        FCB     $DF,$D7,$DF,$D9,$96,$D3,$8B,$07
        FCB     $97,$D5,$86,$CF,$97,$D6,$7E,$FD
        FCB     $E2,$97,$D2,$39,$7D,$00,$D2,$27
        FCB     $02,$20,$07,$39,$84,$7F,$81,$14
        FCB     $26,$06,$86,$80,$97,$D2,$20,$11
        FCB     $DE,$D7,$B7,$70,$00,$01,$A7,$00
        FCB     $08,$9C,$D5,$26,$02,$DE,$D3,$DF
        FCB     $D7,$D6,$C0,$C4,$9F,$CA,$20,$D7
        FCB     $C0,$F7,$7C,$00,$39
SCRN_OUTQ
        LDX     $D9
        CPX     $D7
        BEQ     SCRN_OUTQ_019
        STAA    $7000
        NOP
        LDAA    $00,X
        STAA    $7C01
        INX
        CPX     $D5
        BNE     SCRN_OUTQ_016
        LDX     $D3
SCRN_OUTQ_016
        STX     $D9
        RTS
SCRN_OUTQ_019
        LDAA    $C0
        ANDA    #$9F
        LDAB    $D1
        CMPB    #$01
        BEQ     SCRN_OUTQ_027
        LDAB    $D2
        BPL     SCRN_OUTQ_035
SCRN_OUTQ_027
        LDAB    $D2
        BITB    #$08
        BEQ     SCRN_OUTQ_03B
        FCB     $7F,$00,$D2
        ORAA    #$40
        FCB     $7F,$00,$D1
SCRN_OUTQ_035
        STAA    $C0
        STAA    $7C00
        RTS
SCRN_OUTQ_03B
        CLRA
        STAA    $7C01
        LDAA    #$88
        STAA    $D2
        RTS
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $72,$ED,$83,$E8,$00,$E8,$00,$E8
        FCB     $00

        END