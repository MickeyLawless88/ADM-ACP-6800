; datamax socket 3.bin -- ROM C ($F000-$F7FF)
; MD5 937214198a17350b66176317d7030e81
;
; VERIFIED BYTE-EXACT: reassembled through the real acp6800 toolchain and
; diffed against the original .bin -- 0 errors, identical MD5.
;
; Holds the IRQ/SWI interrupt handler entered via the vector at $F713
; (labeled IRQ_HANDLER below):
;   LDAB $7A00 / BPL / BSR   -- poll ACIA1 (serial) status, service if ready
;   LDAB $7C00 / BPL / JSR   -- poll PRNTER status, service if ready
;   RTI
; Also contains the serial receive-buffer reader (SER_GETCH), the serial
; port control-register setup (SER_INIT), and the parity-stripping serial
; receive-character routine (SER_RXCHAR).
;
; LABELS: same scheme as DATAMAX1.ASM's header.
; Control-flow-traced coverage: 130 instructions, 274/2048 bytes (13.4%).
;
        ORG     $F000
        FCB     $07,$84,$0F,$0C,$39,$4F,$0D,$39
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
        FCB     $DE,$44,$DF,$87,$86,$7F,$97,$43
        FCB     $DE,$42,$08,$96,$2F,$B7,$70,$00
        FCB     $01,$A7,$7F,$96,$3F,$B7,$70,$00
        FCB     $01,$A7,$7E,$BD,$EB,$35,$BD,$E8
        FCB     $A8,$B6,$78,$02,$D6,$48,$27,$10
        FCB     $D6,$12,$C4,$20,$27,$0F,$DE,$AB
        FCB     $9C,$A9,$26,$09,$D6,$B0,$26,$05
        FCB     $88,$04,$B7,$78,$02,$84,$04,$48
        FCB     $8B,$80,$97,$27,$8B,$07,$97,$42
        FCB     $86,$7F,$97,$43,$DE,$42,$08,$B7
        FCB     $70,$00,$01,$A6,$7F,$97,$2F,$B7
        FCB     $70,$00,$01,$A6,$7E,$97,$3F,$B7
        FCB     $7F,$06,$81,$18,$27,$04,$86,$CF
        FCB     $97,$43,$7F,$00,$2E,$4F,$BD,$EF
        FCB     $E3,$BD,$EF,$D4,$DF,$40,$86,$18
        FCB     $BD,$EF,$E3,$BD,$EF,$D4,$DF,$83
        FCB     $DF,$74,$86,$4F,$97,$2E,$86,$17
        FCB     $BD,$EF,$E3,$BD,$EF,$D4,$DF,$2B
        FCB     $C6,$50,$8D,$20,$DE,$74,$DF,$44
        FCB     $B6,$78,$02,$84,$04,$47,$47,$8B
        FCB     $31,$B7,$70,$00,$01,$A7,$3F,$96
        FCB     $2F,$26,$06,$BD,$E8,$A2,$7E,$E8
        FCB     $92,$7E,$E8,$82,$DE,$87,$B7,$70
        FCB     $00,$01,$A6,$00,$08,$DF,$87,$DE
        FCB     $83,$B7,$70,$00,$01,$A7,$00,$08
        FCB     $DF,$83,$5A,$26,$E7,$39,$BD,$E6
        FCB     $87,$96,$4F,$27,$1D,$BD,$F1,$3B
        FCB     $20,$18,$96,$0F,$85,$01,$27,$03
        FCB     $BD,$EF,$17,$D6,$0D,$C5,$10,$27
        FCB     $03,$BD,$E8,$92,$BD,$E6,$87,$BD
        FCB     $EB,$EE,$BD,$E8,$A8,$C6,$20,$DE
        FCB     $29,$96,$2F,$A5,$00,$26,$02,$E7
        FCB     $00,$9C,$2B,$27,$0B,$9C,$42,$26
        FCB     $04,$DE,$27,$20,$EE,$08,$20,$EB
        FCB     $BD,$E8,$A2,$BD,$EF,$D1,$B7,$70
        FCB     $00,$01,$A6,$00,$95,$2F,$27,$03
        FCB     $BD,$EE,$C7,$39,$86,$20,$BD,$E6
        FCB     $87,$D6,$4F,$26,$1F,$C6,$50,$D0
        FCB     $2E,$D7,$92,$DE,$29,$B7,$70,$00
        FCB     $01,$E6,$00,$D5,$2F,$26,$0C,$B7
        FCB     $70,$00,$01,$A7,$00,$08,$7A,$00
        FCB     $92,$26,$EA,$39,$DE,$29,$B7,$70
        FCB     $00,$01,$6D,$00,$2B,$F5,$B7,$70
        FCB     $00,$01,$A7,$00,$9C,$40,$27,$EB
        FCB     $9C,$27,$26,$04,$DE,$42,$20,$E6
        FCB     $09,$20,$E3,$DE,$2B,$DF,$74,$20
        FCB     $18,$86,$20,$D6,$4F,$27,$03,$7E
        FCB     $E7,$15,$D6,$2F,$26,$ED,$86,$4F
        FCB     $90,$2E,$DE,$29,$BD,$E7,$AB,$DF
        FCB     $74,$DE,$29,$C6,$20,$B7,$70,$00
        FCB     $01,$A6,$00,$95,$2F,$26,$16,$B7
        FCB     $70,$00,$01,$E7,$00,$16,$9C,$74
        FCB     $27,$0B,$9C,$42,$26,$04,$DE,$27
        FCB     $20,$E3,$08,$20,$E0,$DE,$29,$7F
        FCB     $00,$26,$39,$DE,$2B,$DF,$74,$20
        FCB     $13,$D6,$4F,$26,$53,$D6,$2F,$26
        FCB     $F2,$86,$4F,$90,$2E,$DE,$29,$BD
        FCB     $E7,$AB,$DF,$74,$DE,$29,$9C,$74
        FCB     $27,$2D,$9C,$42,$26,$0E,$DF,$8F
        FCB     $DE,$27,$B7,$70,$00,$01,$A6,$00
        FCB     $DE,$8F,$20,$06,$B7,$70,$00,$01
        FCB     $A6,$01,$95,$2F,$26,$11,$B7,$70
        FCB     $00,$01,$A7,$00,$9C,$42,$26,$04
        FCB     $DE,$27,$20,$D2,$08,$20,$CF,$7D
        FCB     $00,$53,$26,$08,$86,$20,$B7,$70
        FCB     $00,$01,$A7,$00,$7F,$00,$26,$39
        FCB     $DE,$29,$DF,$74,$8D,$26,$DF,$8F
        FCB     $9C,$40,$27,$1C,$B7,$70,$00,$01
        FCB     $A6,$00,$2B,$14,$DE,$74,$B7,$70
        FCB     $00,$01,$A7,$00,$8D,$0E,$DF,$74
        FCB     $DE,$8F,$8D,$08,$DF,$8F,$20,$E0
        FCB     $DE,$74,$20,$C3,$9C,$27,$26,$03
        FCB     $DE,$42,$39,$09,$39,$D6,$2F,$26
        FCB     $FB,$BD,$EC,$0D,$86,$17,$91,$2D
        FCB     $27,$28,$97,$8F,$BD,$EF,$E3,$BD
        FCB     $EF,$D4,$DF,$74,$DE,$74,$DF,$83
        FCB     $96,$8F,$4A,$97,$8F,$BD,$EF,$E3
        FCB     $BD,$EF,$D4,$DF,$74,$DF,$87,$C6
        FCB     $50,$BD,$F0,$CB,$96,$8F,$91,$2D
        FCB     $26,$E2,$86,$20,$7E,$F1,$40,$D6
        FCB     $2F,$26,$31,$BD,$EC,$0D,$96,$2D
        FCB     $81,$17,$27,$EE,$DE,$29,$DF,$74
        FCB     $4C,$97,$8F,$DE,$74,$DF,$83,$BD
        FCB     $EF,$E3,$BD,$EF,$D4,$DF,$74,$DF
        FCB     $87,$C6,$50,$BD,$F0,$CB,$96,$8F
        FCB     $81,$17,$26,$E4,$86,$20,$BD,$F1
        FCB     $40,$BD,$EF,$D1,$39,$F2,$CE,$00
        FCB     $00,$00,$03,$00,$1C,$1D,$07,$1F
        FCB     $09,$0A,$0B,$0C,$0D,$0E,$0F,$1E
        FCB     $19,$18,$18,$0E,$0E,$0E,$0E,$0F
        FCB     $0F,$0F,$0F,$0F,$0F,$0F,$0F,$7F
        FCB     $00,$9F,$96,$51,$27,$03,$BD,$E8
        FCB     $92,$BD,$F3,$9F,$4F,$20,$22,$96
        FCB     $0F,$85,$80,$26,$EA,$96,$51,$27
        FCB     $06,$BD,$E8,$95,$BD,$EC,$0D,$86
        FCB     $01,$97,$9F,$BD,$F3,$7D,$86,$01
        FCB     $20,$07,$86,$02,$20,$03,$43,$20
        FCB     $00,$97,$9F,$BD,$EB,$38,$BD,$E6
        FCB     $87,$CE,$FC,$05,$BD,$FB,$88,$C6
        FCB     $08,$D7,$BC,$D6,$BD,$C1,$0D,$26
        FCB     $05,$0F,$BD,$FF,$32,$0E,$39,$86
        FCB     $1B,$BD,$F6,$0C,$86,$22,$BD,$F6
        FCB     $0C,$96,$2E,$8B,$20,$BD,$F6,$0C
        FCB     $96,$2D,$8B,$20,$BD,$F6,$0C,$39
        FCB     $96,$52,$81,$30,$2D,$15,$81,$39
        FCB     $2E,$11,$86,$1B,$BD,$F6,$0C,$96
        FCB     $52,$BD,$F6,$0C,$96,$9F,$43,$BD
        FCB     $F6,$0C,$39,$96,$06,$BD,$F6,$0C
        FCB     $96,$52,$BD,$F6,$0C,$39,$DE,$29
        FCB     $DF,$91,$96,$92,$90,$2E,$97,$92
        FCB     $96,$91,$82,$00,$97,$91,$DE,$91
        FCB     $DF,$93,$96,$94,$8B,$4F,$97,$94
        FCB     $96,$93,$89,$00,$97,$93,$20,$08
        FCB     $DE,$40,$DF,$91,$DE,$2B,$DF,$93
        FCB     $D6,$0E,$C4,$10,$D7,$A1,$7D,$00
        FCB     $4F,$27,$03,$7C,$00,$A1,$7D,$00
        FCB     $2F,$27,$09,$D6,$0E,$C5,$04,$27
        FCB     $03,$7E,$F4,$51,$DE,$29,$D6,$2F
        FCB     $C8,$80,$53,$D7,$95,$B7,$70,$00
        FCB     $01,$A6,$00,$94,$95,$81,$03,$27
        FCB     $67,$9C,$93,$27,$0B,$9C,$42,$26
        FCB     $04,$DE,$27,$20,$E8,$08,$20,$E5
        FCB     $DE,$91,$7F,$00,$A2,$B7,$70,$00
        FCB     $01,$A6,$00,$95,$2F,$27,$27,$81
        FCB     $85,$26,$04,$97,$A2,$20,$14,$7D
        FCB     $00,$A2,$27,$0F,$81,$86,$27,$08
        FCB     $81,$88,$27,$04,$81,$90,$26,$0E
        FCB     $7F,$00,$A2,$9C,$42,$26,$04,$DE
        FCB     $27,$20,$D2,$08,$20,$CF,$9C,$29
        FCB     $27,$30,$DE,$2D,$DF,$99,$DE,$29
        FCB     $DF,$97,$7D,$00,$9F,$26,$03,$7F
        FCB     $00,$2D,$7F,$00,$2E,$DE,$91,$DF
        FCB     $29,$DF,$9D,$DE,$2D,$DF,$9B,$39
        FCB     $DE,$93,$DF,$97,$7C,$00,$A1,$DE
        FCB     $2D,$DF,$99,$DF,$9B,$DE,$29,$DF
        FCB     $9D,$39,$DE,$93,$DF,$97,$7C,$00
        FCB     $A1,$DE,$91,$DF,$9D,$7D,$00,$9F
        FCB     $26,$03,$7F,$00,$2D,$7F,$00,$2E
        FCB     $DE,$2D,$DF,$99,$DF,$9B,$39,$96
        FCB     $9B,$97,$2D,$BD,$EF,$E1,$B7,$7F
        FCB     $0D,$96,$9C,$97,$2E,$B7,$7F,$0C
        FCB     $DE,$9D,$DF,$29,$7F,$00,$A0,$BD
        FCB     $F5,$1A,$81,$20,$2C,$10,$BB,$F2
        FCB     $CD,$97,$D8,$B6,$F2,$CC,$89,$00
        FCB     $97,$D7,$DE,$D7,$A6,$00,$7D,$00
        FCB     $A1,$26,$06,$DE,$29,$9C,$97,$27
        FCB     $47,$36,$81,$04,$2F,$03,$BD,$F6
        FCB     $0C,$96,$A1,$27,$09,$DE,$29,$9C
        FCB     $97,$26,$03,$32,$20,$32,$BD,$F5
        FCB     $A3,$32,$81,$09,$26,$16,$D6,$0D
        FCB     $DA,$07,$C5,$02,$27,$B9,$D6,$51
        FCB     $26,$B5,$D6,$A0,$26,$B1,$C6,$03
        FCB     $D7,$A0,$20,$AB,$81,$03,$27,$10
        FCB     $81,$0D,$26,$A3,$D6,$0D,$C5,$40
        FCB     $27,$9D,$C6,$04,$D7,$A0,$20,$97
        FCB     $BD,$F5,$46,$7F,$00,$31,$B7,$70
        FCB     $00,$01,$A6,$00,$95,$2F,$27,$03
        FCB     $7E,$EE,$C7,$39,$96,$0E,$85,$02
        FCB     $27,$0D,$96,$9F,$9A,$2F,$2B,$07
        FCB     $81,$02,$2C,$03,$BD,$EB,$C8,$7F
        FCB     $00,$9F,$39,$DE,$29,$B7,$70,$00
        FCB     $01,$A6,$00,$D6,$2F,$26,$30,$D6
        FCB     $A0,$C1,$04,$26,$07,$7D,$00,$2E
        FCB     $26,$5C,$20,$0D,$C1,$03,$26,$0C
        FCB     $36,$BD,$EF,$26,$E5,$00,$32,$27
        FCB     $4D,$7F,$00,$A0,$84,$7F,$39,$D6
        FCB     $2E,$F7,$7F,$0C,$36,$96,$2D,$BD
        FCB     $EF,$E1,$B7,$7F,$0D,$32,$39,$D6
        FCB     $A0,$C1,$04,$26,$09,$7D,$00,$2E
        FCB     $26,$2C,$5F,$7F,$00,$A0,$4D,$2B
        FCB     $0D,$C1,$03,$27,$21,$C1,$01,$26
        FCB     $D3,$7F,$00,$A0,$20,$CE,$81,$85
        FCB     $27,$23,$81,$90,$27,$0C,$81,$86
        FCB     $27,$08,$81,$88,$27,$04,$C1,$02
        FCB     $27,$BA,$C6,$01,$D7,$A0,$DE,$29
        FCB     $9C,$97,$27,$0D,$81,$03,$27,$AC
        FCB     $8D,$0A,$7E,$F5,$1A,$C6,$02,$20
        FCB     $EB,$4F,$20,$A0,$96,$2E,$81,$4F
        FCB     $27,$09,$4C,$97,$2E,$DE,$29,$08
        FCB     $DF,$29,$39,$7F,$00,$2E,$96,$2D
        FCB     $4C,$81,$18,$26,$01,$4F,$97,$2D
        FCB     $BD,$EF,$E1,$BD,$EF,$D4,$39,$CE
        FCB     $01,$00,$DF,$A6,$DF,$A4,$D6,$47
        FCB     $26,$13,$36,$D6,$11,$C4,$1C,$C8
        FCB     $08,$96,$4A,$84,$03,$1B,$97,$4A
        FCB     $B7,$7A,$00,$32,$39,$36,$C6,$09
        FCB     $F7,$7A,$00,$D6,$4B,$C4,$FC,$CA
        FCB     $42,$D7,$4B,$F7,$7A,$01,$C6,$C9
        FCB     $D7,$4A,$F7,$7A,$00,$86,$16,$BD
        FCB     $F6,$0C,$BD,$F6,$0C,$BD,$F6,$0C
        FCB     $BD,$F6,$0C,$32,$39,$84,$7F,$DE
        FCB     $A4,$A7,$00,$08,$8C,$03,$80,$26
        FCB     $03,$CE,$01,$00,$9C,$A6,$27,$FC
        FCB     $16,$D8,$CA,$D7,$CA,$DF,$A4,$C6
        FCB     $FF,$D7,$A8,$D6,$47,$26,$0C,$D6
        FCB     $4A,$C4,$9F,$CA,$20,$D7,$4A,$F7
        FCB     $7A,$00,$39,$D6,$4A,$CA,$10,$D7
        FCB     $4A,$F7,$7A,$00,$39,$86,$FF,$20
        FCB     $C6
SER_GETCH
        LDX     $A6
        CPX     $A4
        BEQ     SER_GETCH_048
        LDAA    $00,X
        INX
        CPX     #$0380
        BNE     SER_GETCH_011
        LDX     #$0100
SER_GETCH_011
        STX     $A6
        LDAB    $CC
        BEQ     SER_GETCH_01D
        TSTA
        BMI     SER_GETCH_01D
        JSR     $FAE7
SER_GETCH_01D
        LDAB    $47
        BNE     SER_GETCH_039
        STAA    $7A01
        ANDA    #$80
        STAA    $A3
        BPL     SER_GETCH_038
SER_GETCH_02A
        LDAA    $7A00
        BITA    #$02
        BEQ     SER_GETCH_02A
        LDAA    #$03
        STAA    $7A00
        BRA     SER_GETCH_048
SER_GETCH_038
        RTS
SER_GETCH_039
        BITA    #$80
        BNE     SER_GETCH_077
        LDAB    $4A
        ORAB    #$C0
        STAB    $7A00
        STAA    $7A01
        RTS
SER_GETCH_048
        FCB     $7F,$00,$A8
        LDAB    $47
        BNE     SER_GETCH_06D
        LDAA    $4A
        ANDA    #$9F
        LDAB    $A3
        BEQ     SER_GETCH_067
        FCB     $7F,$00,$A3
        ORAA    #$C0
        PSHA
        LDAA    $1D
        LDAB    $1E
        BEQ     SER_GETCH_066
        JSR     $FF2A
SER_GETCH_066
        PULA
SER_GETCH_067
        STAA    $4A
        STAA    $7A00
        RTS
SER_GETCH_06D
        LDAA    $4A
        ANDA    #$EF
        STAA    $4A
        STAA    $7A00
        RTS
SER_GETCH_077
        LDAB    $4A
        ANDB    #$3F
        ORAB    #$89
        STAB    $7A00
        LDAA    #$FF
        STAA    $7A01
        EORB    #$C0
        STAB    $7A00
        LDAA    #$0E
        STAA    $7A01
SER_GETCH_08F
        LDAA    $7A00
        BITA    #$10
        BEQ     SER_GETCH_08F
        LDAA    #$01
        LDAB    #$46
        FCB     $7D,$00,$1E
        BEQ     SER_GETCH_0A3
        LDAA    $1D
        LDAB    $1E
SER_GETCH_0A3
        JSR     $FF2A
        LDAA    #$0B
        STAA    $7A00
        LDAA    $4B
        ANDA    #$BC
        STAA    $4B
        STAA    $7A01
        LDAA    #$8B
        STAA    $7A00
        LDAA    $46
        STAA    $7A01
        LDAA    #$20
        STAA    $4A
        STAA    $7A00
        STAA    $B9
        FCB     $7F,$00,$A8
        RTS
IRQ_HANDLER
        LDAB    $7A00
        BPL     IRQ_HANDLER_007
        BSR     IRQ_HANDLER_010
IRQ_HANDLER_007
        LDAB    $7C00
        BPL     IRQ_HANDLER_00F
        JSR     $F8AB
IRQ_HANDLER_00F
        RTI
IRQ_HANDLER_010
        LDAA    $47
        BNE     IRQ_HANDLER_018
        LDAA    $4A
        BPL     IRQ_HANDLER_020
IRQ_HANDLER_018
        BITB    #$01
        BEQ     IRQ_HANDLER_020
        JSR     $FDD1
        RTS
IRQ_HANDLER_020
        BITB    #$02
        BEQ     IRQ_HANDLER_02C
        LDAA    $A8
        BEQ     IRQ_HANDLER_02C
        JSR     SER_GETCH
IRQ_HANDLER_02B
        RTS
IRQ_HANDLER_02C
        LDAA    $47
        BNE     IRQ_HANDLER_02B
        BITB    #$04
        BEQ     IRQ_HANDLER_02B
        LDAA    $7A01
        RTS
        FCB     $97,$B3,$7F,$00,$B6,$BD,$E6,$87
        FCB     $DE,$2B,$DF,$B7,$DF,$8F,$96,$B3
        FCB     $2B,$0D,$96,$15,$85,$08,$27,$02
        FCB     $DE,$29,$DF,$B7,$BD,$EB,$EE,$96
        FCB     $73,$97,$B2,$96,$4D,$84,$1C,$8A
        FCB     $01,$97,$4D,$B7,$7C,$00,$CE,$00
        FCB     $03,$BD,$E4,$EF,$CE,$00,$01,$BD
        FCB     $E4,$F8,$39,$8D,$1E,$96,$B3,$27
        FCB     $11,$96,$B4,$26,$05,$BD,$E5,$21
        FCB     $20,$03,$BD,$E5,$01,$7F,$00,$B4
        FCB     $20,$E9,$CE,$00,$01,$BD,$E4,$EF
        FCB     $7E,$E4,$F6,$F6,$7C,$00,$C4,$0A
        FCB     $C1,$02,$27,$06,$7D,$00,$B6,$26
        FCB     $42,$39,$D6,$B3,$2B,$77,$C4,$0F
        FCB     $5A,$27,$16,$5A,$27,$1F,$5A,$27
        FCB     $27,$5A,$27,$69,$5A,$27,$0A,$5A
        FCB     $27,$13,$5A,$27,$1B,$5F,$D7,$B3
        FCB     $39,$86,$0D,$7C,$00,$B3,$B7,$7C
        FCB     $01,$BD,$F8,$A2,$39,$86,$0A,$D6
        FCB     $12,$C5,$40,$27,$EE,$7C,$00,$B3
        FCB     $4F,$8D,$E8,$96,$B3,$84,$0F,$81
        FCB     $08,$26,$13,$7F,$00,$B3,$96,$4D
        FCB     $84,$9F,$8A,$40,$97

        END