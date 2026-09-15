; datamax socket 4.bin -- ROM D ($F800-$FFFF)
; MD5 97c7b2317943e5689fb0ee12af620dfd
;
; VERIFIED BYTE-EXACT: reassembled through the real acp6800 toolchain and
; diffed against the original .bin -- 0 errors, identical MD5.
;
; Holds the hardware vector table at $FFF8-$FFFF:
;   IRQ = SWI = $F713 (ROM C's IRQ_HANDLER, see DATAMAX3.ASM)
;   NMI = RESET = $E049 (ROM A's RESET, see DATAMAX1.ASM)
;
; LABELS: same scheme as DATAMAX1.ASM's header.
; Coverage: 296 instructions, 600/2048 bytes (29.3%).
;
        ORG     $F800
        FCB     $4D,$B7,$7C,$00,$DE,$29,$7E,$EB
        FCB     $6D,$DE,$29,$86,$50,$BD,$E7,$AB
        FCB     $97,$8F,$9C,$29,$27,$17,$9C,$B7
        FCB     $26,$04,$09,$DF,$B7,$08,$09,$B7
        FCB     $70,$00,$01,$A6,$00,$84,$7F,$27
        FCB     $E9,$81,$20,$27,$E5,$DF,$8F,$39
        FCB     $DE,$29,$B7,$70,$00,$01,$A6,$00
        FCB     $16,$C1,$1D,$27,$57,$7D,$00,$B3
        FCB     $2B,$36,$D5,$2F,$27,$08,$D6,$B3
        FCB     $C5,$10,$27,$02,$86,$20,$84,$7F
        FCB     $81,$20,$2C,$24,$81,$0C,$27,$20
        FCB     $D6,$0F,$C5,$20,$27,$18,$81,$08
        FCB     $27,$10,$81,$06,$27,$0C,$81,$05
        FCB     $27,$08,$81,$10,$26,$08,$96,$01
        FCB     $20,$06,$96,$00,$20,$02,$86,$20
        FCB     $B7,$7C,$01,$8D,$25,$9C,$B7,$27
        FCB     $13,$9C,$8F,$27,$04,$BD,$EC,$19
        FCB     $39,$96,$B3,$84,$F0,$4C,$97,$B3
        FCB     $BD,$EC,$31,$39,$96,$B3,$2A,$03
        FCB     $7E,$F7,$F6,$84,$F0,$8A,$05,$97
        FCB     $B3,$39,$81,$0D,$26,$04,$96,$13
        FCB     $97,$B4,$39
SCRN_OUTQ
        LDX     $AB
        CPX     $A9
        BEQ     SCRN_OUTQ_076
        LDAB    $B5
        BNE     SCRN_OUTQ_076
        STAA    $7000
        NOP
        LDAA    $00,X
        LDAB    $AD
        BEQ     SCRN_OUTQ_057
        BPL     SCRN_OUTQ_042
        FCB     $7F,$00,$AD
        CMPB    #$8B
        BEQ     SCRN_OUTQ_04B
        CMPA    #$61
        BEQ     SCRN_OUTQ_02F
        CMPA    #$62
        BEQ     SCRN_OUTQ_035
        CMPA    #$63
        BEQ     SCRN_OUTQ_03B
        LDAA    #$1B
SCRN_OUTQ_02B
        STAA    $7C01
        RTS
SCRN_OUTQ_02F
        STAA    $AE
        BSR     SCRN_OUTQ_06A
        BRA     SCRN_OUTQ
SCRN_OUTQ_035
        STAA    $B0
        BSR     SCRN_OUTQ_06A
        BRA     SCRN_OUTQ
SCRN_OUTQ_03B
        FCB     $7F,$00,$B0
        BSR     SCRN_OUTQ_06A
        BRA     SCRN_OUTQ
SCRN_OUTQ_042
        LDAA    #$20
        FCB     $7A,$00,$AD
        BNE     SCRN_OUTQ_02B
        BRA     SCRN_OUTQ_067
SCRN_OUTQ_04B
        SUBA    #$20
        BLS     SCRN_OUTQ_053
        STAA    $AD
        BRA     SCRN_OUTQ_042
SCRN_OUTQ_053
        LDAA    #$0B
        BRA     SCRN_OUTQ_02B
SCRN_OUTQ_057
        CMPA    #$1B
        BNE     SCRN_OUTQ_063
SCRN_OUTQ_05B
        ORAA    #$80
        STAA    $AD
        BSR     SCRN_OUTQ_06A
        BRA     SCRN_OUTQ
SCRN_OUTQ_063
        CMPA    #$0B
        BEQ     SCRN_OUTQ_05B
SCRN_OUTQ_067
        STAA    $7C01
SCRN_OUTQ_06A
        INX
        CPX     #$8FFE
        BNE     SCRN_OUTQ_073
        LDX     #$8800
SCRN_OUTQ_073
        STX     $AB
        RTS
SCRN_OUTQ_076
        LDAA    $4D
        ANDA    #$9F
        LDAB    $B1
        BPL     SCRN_OUTQ_08F
        LDAB    $B5
        BNE     SCRN_OUTQ_08F
        STAB    $B1
        LDAB    $AE
        ORAB    $AF
        STAB    $AF
        FCB     $7F,$00,$AE
        ORAA    #$40
SCRN_OUTQ_08F
        STAA    $4D
        STAA    $7C00
        RTS
        FCB     $96,$48,$27,$FB,$96,$B5,$88,$FF
        FCB     $97,$B5,$27,$2B,$7E,$E8,$D1,$84
        FCB     $7F,$81,$03,$27,$2D,$DE,$A9,$B7
        FCB     $70,$00,$01,$A7,$00,$08,$8C,$8F
        FCB     $FE,$26,$03,$CE,$88,$00,$9C,$AB
        FCB     $26,$05,$7C,$00,$CA,$20,$02,$DF
        FCB     $A9,$D6,$12,$C5,$01,$26,$0B,$D6
        FCB     $4D,$C4,$9F,$CA,$20,$D7,$4D,$F7
        FCB     $7C,$00,$39,$36,$BD,$E4,$F6,$32
        FCB     $D6,$BF,$2E,$47,$D6,$BC,$C5,$08
        FCB     $27,$06,$D6,$BD,$C1,$0C,$27,$3B
        FCB     $81,$90,$27,$15,$7D,$00,$B3,$26
        FCB     $32,$C1,$04,$27,$2F,$C5,$08,$26
        FCB     $2A,$D6,$0B,$C5,$02,$27,$24,$20
        FCB     $31,$7C,$00,$B6,$7D,$00,$B3,$26
        FCB     $1A,$BD,$EA,$E5,$D6,$BC,$37,$CA
        FCB     $04,$C4,$F7,$D7,$BC,$CE,$FB,$F9
        FCB     $BD,$FB,$88,$33,$C5,$08,$27,$03
        FCB     $BD,$EB,$6A,$39,$81,$9E,$26,$18
        FCB     $C4,$FB,$D7,$BC,$CE,$FB,$F9,$7E
        FCB     $FB,$8B,$D6,$BC,$CA,$04,$D7,$BC
        FCB     $CE,$FB,$F9,$36,$BD,$FB,$88,$32
        FCB     $4D,$2A,$03,$7E,$E5,$B4,$7E,$E7
        FCB     $04,$BD,$E5,$19,$81,$41,$27,$6D
        FCB     $D6,$73,$26,$60,$81,$4D,$26,$5D
        FCB     $96,$1F,$85,$01,$27,$03,$7E,$E8
        FCB     $D1,$BD,$F1,$00,$7F,$00,$CC,$DE
        FCB     $27,$DF,$CD,$D6,$48,$27,$0C,$86
        FCB     $C0,$97,$CE,$96,$CD,$8B,$03,$97
        FCB     $CD,$DE,$CD,$86,$20,$B7,$70,$00
        FCB     $01,$A7,$00,$86,$94,$B7,$70,$00
        FCB     $01,$A7,$50,$B7,$70,$00,$01,$A7
        FCB     $A0,$08,$DF,$D1,$86,$91,$B7,$70
        FCB     $00,$01,$A7,$00,$B7,$70,$00,$01
        FCB     $A7,$50,$B7,$70,$00,$01,$A7,$A0
        FCB     $DE,$44,$DF,$CF,$86,$4F,$97,$D3
        FCB     $86,$80,$97,$CC,$39,$81,$4E,$26
        FCB     $25,$7F,$00,$CC,$39,$BD,$F1,$00
        FCB     $96,$18,$BD,$E7,$15,$96,$19,$BD
        FCB     $E7,$15,$96,$48,$27,$0F,$86,$20
        FCB     $BD,$E7,$15,$96,$1A,$BD,$E7,$15
        FCB     $96,$1B,$BD,$E7,$15,$39,$81,$54
        FCB     $26,$0B,$BD,$E5,$19,$97,$18,$BD
        FCB     $E5,$19,$97,$19,$39,$81,$50,$26
        FCB     $0A,$BD,$E5,$19,$97,$1A,$BD,$E5
        FCB     $19,$97,$1B,$39,$7F,$00,$BC,$CE
        FCB     $FB,$F9,$BD,$FB,$B9,$20,$05
CLRV_BDC1
        CLRA
        STAA    $BD
        STAA    $BE
        CLRA
        STAA    $C0
        STAA    $C1
        LDAA    $BF
        BLE     CLRV_BDC1_014
        LDX     #$FBF9
        JSR     MSG_POS2
CLRV_BDC1_014
        FCB     $7F,$00,$BF
        RTS
        FCB     $CE,$FB,$FF,$BD,$FB,$B6,$86,$01
        FCB     $97,$BF,$39,$96,$CC,$27,$04,$88
        FCB     $01,$97,$CC,$39
SCRUPD_ALT
        LDAB    #$80
        BRA     SCRUPD_001
SCRUPD
        CLRB
SCRUPD_001
        STAB    $D4
        LDAB    $CC
        BEQ     SCRUPD_081
        BITB    #$01
        BNE     SCRUPD_081
        PSHA
        LDX     $D1
        STX     $D5
        INX
        STX     $D1
        FCB     $7A,$00,$D3
        BNE     SCRUPD_049
        LDAB    #$4F
        STAB    $D3
        LDAB    #$A0
        ADDB    $D2
        STAB    $D2
        LDAB    $D1
        ADCB    #$00
        STAB    $D1
        LDX     $D1
        CPX     $CF
        BNE     SCRUPD_030
        LDX     $CD
SCRUPD_030
        LDAB    #$20
        STAA    $7000
        NOP
        STAB    $00,X
        LDAB    #$94
        STAA    $7000
        NOP
        STAB    $50,X
        STAA    $7000
        NOP
        STAB    $A0,X
        INX
        STX     $D1
SCRUPD_049
        LDAB    #$91
        STAA    $7000
        NOP
        STAB    $00,X
        STAA    $7000
        NOP
        STAB    $50,X
        STAA    $7000
        NOP
        STAB    $A0,X
        LDX     $D5
        TAB
        JSR     $F008
        ORAA    $D4
        STAA    $7000
        NOP
        STAA    $50,X
        TBA
        JSR     $F00C
        ORAA    $D4
        STAA    $7000
        NOP
        STAA    $A0,X
        TBA
        ANDA    #$7F
        STAA    $7000
        NOP
        STAA    $00,X
        PULA
SCRUPD_081
        RTS
        FCB     $7D,$00,$32,$27,$47,$7F,$00,$32
        FCB     $CE,$FC,$0B,$20,$43
MSG_TIMER
        LDX     #$2710
        STX     $E3
        FCB     $7D,$00,$32
        BNE     MSG_POS1_02A
        FCB     $7C,$00,$32
        LDX     #$FC0B
        BRA     MSG_POS1_02B
DEC_CTR_E1
        FCB     $7A,$00,$E1
MSG_POS1
        LDAA    $00,X
        INX
        STX     $D9
        ADDA    $45
        STAA    $DC
        LDAA    $44
        ADCA    #$00
        STAA    $DB
MSG_POS1_00F
        LDX     $D9
        LDAA    $00,X
        BEQ     MSG_POS1_027
        INX
        STX     $D9
        LDX     $DB
        ANDA    $E1
        STAA    $7000
        NOP
        STAA    $00,X
        INX
        STX     $DB
        BRA     MSG_POS1_00F
MSG_POS1_027
        FCB     $7F,$00,$E1
MSG_POS1_02A
        RTS
MSG_POS1_02B
        FCB     $7A,$00,$E2
MSG_POS2
        LDAA    $00,X
        INX
        STX     $DD
        ADDA    $45
        STAA    $E0
        LDAA    $44
        ADCA    #$00
        STAA    $DF
MSG_POS2_00F
        LDX     $DD
        LDAA    $00,X
        BEQ     MSG_POS2_027
        INX
        STX     $DD
        LDX     $DF
        ANDA    $E2
        STAA    $7000
        NOP
        STAA    $00,X
        INX
        STX     $DF
        BRA     MSG_POS2_00F
MSG_POS2_027
        FCB     $7F,$00,$E2
        RTS
        FCB     $3C,$50,$47,$20,$31,$00,$41,$46
        FCB     $4F,$52,$4D,$53,$00,$36,$94,$42
        FCB     $45,$45,$50,$90,$00,$4C,$4C,$4F
        FCB     $43,$4C,$00,$4C,$52,$45,$43,$56
        FCB     $00,$4C,$58,$4D,$49,$54,$00,$47
        FCB     $4C,$54,$41,$49,$00,$FE,$11,$FC
        FCB     $87,$FC,$8E,$FC,$B2,$FD,$3C,$FE
        FCB     $24,$FC,$87,$FC,$8E,$FE,$3F,$FE
        FCB     $45,$FE,$79,$FE,$99,$FD,$99,$FC
        FCB     $57
MSG_POS2_074
        LDAB    $BB
        STAB    $BA
        STAA    $BB
        JSR     MSG_TIMER
        LDAA    $BB
        TAB
        EORB    $CA
        STAB    $CA
        FCB     $7D,$00,$CC
        BEQ     MSG_POS2_08C
        JSR     SCRUPD_ALT
MSG_POS2_08C
        LDAB    $BD
        CMPB    #$0B
        BEQ     MSG_POS2_09F
        ANDA    #$7F
        CMPA    #$04
        BNE     MSG_POS2_09F
        JSR     CLRV_BDC1
        FCB     $7C,$00,$BD
        RTS
MSG_POS2_09F
        LDAA    $BB
        BPL     MSG_POS2_0B7
        ANDA    $BA
        BPL     MSG_POS2_0B1
        LDAA    $47
        BEQ     MSG_POS2_0B1
        JSR     SER_INIT
        JMP     CLRV_BDC1
MSG_POS2_0B1
        LDAA    #$01
        STAA    $C0
        LDAA    #$3F
MSG_POS2_0B7
        LDX     #$FC11
        STX     $D7
        LDAB    $BD
        ASLB
        ADDB    $D8
        STAB    $D8
        BCC     MSG_POS2_0C8
        FCB     $7C,$00,$D7
MSG_POS2_0C8
        LDX     $D7
        LDX     $00,X
        JMP     $00,X
        FCB     $97,$C6,$5F,$D7,$BE,$20,$20,$97
        FCB     $C7,$DE,$C6,$9C,$18,$27,$11,$D6
        FCB     $48,$27,$14,$9C,$1A,$26,$10,$7A
        FCB     $00,$BE,$96,$C3,$97,$C4,$20,$07
        FCB     $7C,$00,$BE,$96,$C2,$97,$C4,$7C
        FCB     $00,$BD,$39,$97,$C5,$81,$70,$27
        FCB     $F6,$81,$71,$27,$F2,$81,$73,$26
        FCB     $08,$D6,$BE,$27,$2F,$2B,$33,$20
        FCB     $1C,$81,$74,$27,$22,$81,$07,$26
        FCB     $11,$BD,$FE,$11,$C6,$0D,$D7,$BD
        FCB     $D6,$BC,$C5,$08,$27,$03,$BD,$FF
        FCB     $32,$39,$7E,$FA,$B7,$96,$B3,$26
        FCB     $09,$96,$0B,$85,$04,$26,$03,$BD
        FCB     $FA,$AC,$8D,$0A,$7C,$00,$BD,$20
        FCB     $B6,$39,$8D,$1E,$20,$F6,$4F,$97
        FCB     $C1,$96,$B3,$9A,$BC,$9A,$B5,$26
        FCB     $2F,$DE,$7C,$9C,$7E,$26,$05,$BD
        FCB     $FA,$CF,$20,$03,$7C,$00,$C1,$96
        FCB     $C1,$39,$4F,$97,$C1,$96,$B1,$2B
        FCB     $F3,$96,$B3,$9A,$B5,$26,$ED,$B6
        FCB     $78,$02,$85,$04,$26,$0A,$86,$01
        FCB     $97,$B1,$86,$FF,$97,$BF,$20,$DF
        FCB     $BD,$E8,$D1,$20,$D7,$BD,$FE,$11
        FCB     $81,$05,$27,$03,$7E,$FA,$B7,$D6
        FCB     $C5,$C1,$70,$27,$23,$D6,$BE,$27
        FCB     $08,$2A,$09,$8D,$C5,$26,$11,$20
        FCB     $07,$7E,$FC,$AE,$8D,$A0,$26,$08
        FCB     $BD,$FC,$AE,$86,$06,$7E,$FF,$13
        FCB     $4F,$97,$BD,$86,$15,$7E,$FF,$13
        FCB     $D6,$BE,$27,$E5,$2A,$06,$D6,$AF
        FCB     $27,$15,$20,$0C,$DE,$C6,$9C,$16
        FCB     $27,$0D,$D6,$BC,$C5,$08,$27,$07
        FCB     $C6,$0C,$D7,$BD,$7E,$FF,$50,$BD
        FCB     $FA,$B7,$86,$04,$7E,$FF,$13,$7E
        FCB     $FA,$B7,$81,$06,$27,$05,$81,$15
        FCB     $27,$E6,$39,$96,$BE,$27,$F0,$2B
        FCB     $14,$BD,$F5,$03,$96,$C9,$8D,$18
        FCB     $97,$C9,$7F,$00,$BC,$CE,$FB,$F9
        FCB     $BD,$FB,$B9,$20,$D2,$96,$CB,$8D
        FCB     $07,$97,$CB,$7F,$00,$AF,$20,$C7
        FCB     $4C,$D6,$0C,$C4,$0F,$11,$2F,$01
        FCB     $4F,$39
SER_RXCHAR
        LDAA    $47
        BNE     SER_RXCHAR_011
        LDAA    $7A01
        ANDA    #$7F
        ANDB    #$70
        BEQ     SER_RXCHAR_03C
        ORAA    #$80
        BRA     SER_RXCHAR_03C
SER_RXCHAR_011
        LDAA    $7A01
        ANDA    #$7F
        CMPA    #$03
        BNE     SER_RXCHAR_01F
        FCB     $7F,$00,$B9
        BRA     SER_RXCHAR_028
SER_RXCHAR_01F
        FCB     $7D,$00,$B9
        BEQ     SER_RXCHAR_028
        CMPA    #$16
        BEQ     SER_RXCHAR_03F
SER_RXCHAR_028
        ANDB    #$60
        BEQ     SER_RXCHAR_036
        FCB     $7D,$00,$BB
        BPL     SER_RXCHAR_034
        JSR     SER_INIT
SER_RXCHAR_034
        ORAA    #$80
SER_RXCHAR_036
        LDAB    $BB
        STAB    $BA
        STAA    $BB
SER_RXCHAR_03C
        JMP     MSG_POS2_074
SER_RXCHAR_03F
        RTS
SER_INIT
        LDAB    $47
        BEQ     SER_INIT_012
        LDAB    $4A
        ORAB    #$09
        STAB    $7A00
        STAB    $B9
        LDAB    $4A
        STAB    $7A00
SER_INIT_012
        RTS
        FCB     $81,$01,$26,$06,$7F,$00,$CA,$7C
        FCB     $00,$BD,$39,$D6,$BE,$27,$F8,$D6
        FCB     $C4,$97,$C4,$11,$26,$F1,$BD,$FA
        FCB     $C1,$20,$EC,$81,$02,$26,$EC,$8D
        FCB     $E6,$81,$02,$26,$E5,$96,$BF,$2F
        FCB     $DE,$96,$C5,$81,$74,$27,$D8,$86
        FCB     $1B,$BD,$E7,$F5,$86,$7B,$BD,$E7
        FCB     $F5,$BD,$EB,$38,$D6,$0E,$C5,$40
        FCB     $27,$05,$86,$0C,$BD,$E7,$F5,$7F
        FCB     $00,$C8,$D6,$0E,$C5,$80,$26,$03
        FCB     $7C,$00,$C8,$20,$B2,$81,$03,$26
        FCB     $03,$7C,$00,$BD,$D6,$BF,$27,$AA
        FCB     $2A,$03,$7E,$F9,$4F,$81,$11,$26
        FCB     $09,$D6,$0F,$C5,$08,$26,$03,$7F
        FCB     $00,$C8,$7E,$E7,$F5,$BD,$FE,$11
        FCB     $7F,$00,$BD,$96,$BE,$26,$03,$7E
        FCB     $FA,$B7,$2B,$33,$D6,$C0,$DA,$CA
        FCB     $DA,$C1,$26,$1C,$BD,$FA,$C1,$D6
        FCB     $C8,$27,$0C,$D6,$BC,$CA,$04,$D7
        FCB     $BC,$CE,$FB,$F9,$BD,$FB,$B6,$96
        FCB     $C4,$97,$C2,$86,$06,$7E,$FF,$13
        FCB     $BD,$FC,$FD,$86,$05,$97,$BD,$4F
        FCB     $97,$C0,$86,$15,$7E,$FF,$13,$D6
        FCB     $C5,$C1,$74,$27,$0A,$96,$C1,$26
        FCB     $29,$96,$CA,$9A,$C0,$26,$16,$BD
        FCB     $FA,$C1,$96,$C4,$97,$C3,$D6,$C5
        FCB     $C1,$74,$27,$CF,$86,$80,$97,$B1
        FCB     $BD,$F9,$77,$20,$C6,$96,$12,$85
        FCB     $01,$27,$E4,$DE,$AB,$DF,$A9,$7F
        FCB     $00,$B1,$BD,$FD,$19,$20,$BC,$36
        FCB     $BD,$FB,$69,$BD,$F5,$C6,$96,$09
        FCB     $27,$03,$BD,$FF,$28,$32,$BD,$F6
        FCB     $0C,$7E,$F6,$44
SER_INIT_117
        LDAB    #$FA
DELAY_AB
        DECB
        TSTB
        BNE     DELAY_AB
        DECA
        BNE     SER_INIT_117
        RTS
        FCB     $BD,$FB,$69,$BD,$F5,$C6,$96,$18
        FCB     $BD,$F6,$0C,$96,$19,$BD,$F6,$0C
        FCB     $86,$70,$BD,$F6,$0C,$86,$05,$BD
        FCB     $F6,$0C,$BD,$F6,$44,$39,$BD,$FB
        FCB     $69,$BD,$F5,$C6,$96,$09,$27,$03
        FCB     $BD,$FF,$28,$0E,$86,$01,$BD,$F6
        FCB     $0C,$7F,$00,$CA,$96,$BE,$2B,$09
        FCB     $96,$18,$BD,$F6,$0C,$96,$19,$20
        FCB     $07,$96,$1A,$BD,$F6,$0C,$96,$1B
        FCB     $BD,$F6,$0C,$96,$0C,$16,$C4,$10
        FCB     $84,$0F,$27,$0F,$96,$C9,$7D,$00
        FCB     $BE,$2A,$02,$96,$CB,$8B,$30,$1B
        FCB     $BD,$F6,$0C,$86,$02,$BD,$F6,$0C
        FCB     $96,$BE,$2B,$20,$CE,$F3,$57,$96
        FCB     $9F,$2B,$0A,$CE,$F4,$6E,$81,$02
        FCB     $26,$03,$CE,$F3,$3E,$AD,$00,$86
        FCB     $03,$BD,$F6,$0C,$96,$CA,$BD,$F6
        FCB     $0C,$7E,$F6,$44,$86,$1B,$BD,$F6
        FCB     $0C,$86,$61,$BD,$F6,$0C,$20,$E7
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$F7,$13
        FCB     $F7,$13,$E0,$49,$E0,$49

        END