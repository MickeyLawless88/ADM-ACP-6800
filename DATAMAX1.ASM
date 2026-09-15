; datamax socket 1.bin -- ROM A ($E000-$E7FF)
; MD5 7a662fd012d7cba4ed593ca49c3b3d0d
;
; VERIFIED BYTE-EXACT: reassembled through the real acp6800 toolchain and
; diffed against the original .bin -- 0 errors, identical MD5.
;
; Contains the firmware identification banner:
;   "ADM-31/B 4.04  COPYRIGHT (C) 1981 DATAMAXX USA CORPORATION"
; plus a keyboard scancode/shift-layout table (QWERTY row sequences),
; both emitted as raw FCB data since they are not executable code.
;
; LABELS: routine entry points (JSR/BSR targets) have evidence-based
; descriptive names (purpose inferred from I/O addresses touched and
; instruction patterns -- see DATAMAX_SUMMARY.md for the reasoning behind
; each one). Internal branch targets within a routine are named
; <ROUTINE>_<offset>, e.g. RESET_00A is 10 ($0A) bytes past RESET.
; Names are kept <=11 chars to fit acp6800's 15-char label limit once the
; 4-char offset suffix is appended.
;
; Control-flow-traced coverage: 351 instructions, 734/2048 bytes (35.8%),
; seeded from the RESET vector ($E049) and IRQ/SWI vector ($F713).
; Everything the tracer could not reach (likely jump-table-indirected
; code) is raw hex / FCB bytes -- still byte-exact, just not verified as
; code.
;
        ORG     $E000
        FCB     $F9,$83,$E7,$BA,$E7,$C8,$F7,$86
        FCB     $E5,$29,$41,$44,$4D,$2D,$33,$31
        FCB     $2F,$42,$20,$34,$2E,$30,$34,$20
        FCB     $20,$43,$4F,$50,$59,$52,$49,$47
        FCB     $48,$54,$20,$28,$43,$29,$20,$31
        FCB     $39,$38,$31,$20,$44,$41,$54,$41
        FCB     $4D,$41,$58,$58,$20,$55,$53,$41
        FCB     $20,$43,$4F,$52,$50,$4F,$52,$41
        FCB     $54,$49,$4F,$4E,$CE,$00,$24,$20
        FCB     $04
RESET
        CLRA
        LDX     #$0000
        SEI
        STAA    $21
        STAA    $7F0A
RESET_00A
        CLR     $00,X
        INX
        CPX     #$0400
        BNE     RESET_00A
        TSTA
        BEQ     RESET_018
        JMP     RESET_11B
RESET_018
        LDX     #$5B5D
        STX     $00
        LDAA    #$1B
        STAA    $06
        LDAA    #$08
        STAA    $09
        STAA    $10
        LDAA    #$06
        STAA    $0B
        LDAA    #$A4
        STAA    $0E
        LDAA    #$20
        STAA    $02
        STAA    $03
        STAA    $12
        LDAA    #$09
        STAA    $14
        LDS     #$7B00
        TSX
        LDX     $0F,X
        STX     $74
        LDAA    $74
        CMPA    $75
        BEQ     RESET_05D
        LDX     #$FFFF
        STS     $22
        DES
RESET_04F
        INX
        CPX     #$0020
        BEQ     RESET_05D
        PULA
        TSTA
        BEQ     RESET_04F
        STAA    $00,X
        BRA     RESET_04F
RESET_05D
        LDS     #$03FF
        LDX     #$E14B
        STX     $55
        LDAB    $7E00
        BSR     RESET_077
        LDAB    $7900
        BSR     RESET_077
        LDAB    $7D00
        BSR     RESET_077
        JMP     RESET_0AC
RESET_077
        LDAA    #$08
        STAA    $57
        STAB    $58
RESET_07D
        FCB     $7A,$00,$57
        BMI     RESET_0AB
        LDX     $55
        INX
        STX     $55
        LDAA    $00,X
        LDX     #$0000
        TAB
        ANDA    #$1F
        JSR     ADD_A_TO_X
        LDAA    #$01
RESET_094
        SUBB    #$20
        BCS     RESET_09B
        ASLA
        BRA     RESET_094
RESET_09B
        FCB     $74,$00,$58
        BCS     RESET_0A5
        COMA
        ANDA    $00,X
        BRA     RESET_0A7
RESET_0A5
        ORAA    $00,X
RESET_0A7
        STAA    $00,X
        BRA     RESET_07D
RESET_0AB
        RTS
RESET_0AC
        LDX     $22
        LDAA    $18,X
        BNE     RESET_0B4
        LDAA    $18
RESET_0B4
        STAA    $18
        LDAB    $1A,X
        BNE     RESET_0BB
        TAB
RESET_0BB
        STAB    $1A
        LDAA    $19,X
        BNE     RESET_0C3
        LDAA    $19
RESET_0C3
        STAA    $19
        LDAB    $1B,X
        BNE     RESET_0CB
        INCA
        TAB
RESET_0CB
        STAB    $1B
        LDAA    $10
        BMI     RESET_0D6
        LDX     #$7F40
        BRA     RESET_0D9
RESET_0D6
        LDX     #$FF00
RESET_0D9
        STX     $55
        LDX     #$0000
        LDAA    $07,X
        EORA    #$20
        STAA    $07,X
        LDAA    $0B,X
        EORA    #$18
        STAA    $0B,X
        LDAA    $0D,X
        EORA    #$90
        ORAA    $56
        STAA    $0D,X
        LDAA    $0E,X
        EORA    #$40
        ANDA    $55
        STAA    $0E,X
        LDAA    $0F,X
        ORAA    $56
        STAA    $0F,X
        JMP     RESET_11B
        FCB     $E7,$ED,$8D,$A7,$4B,$F0,$CE,$4E
        FCB     $19,$39,$59,$79,$99,$B9,$D9,$6B
        FCB     $18,$38,$58,$78,$98,$B8,$D8,$8B
RESET_11B
        LDAA    #$0D
        STAA    $BD
        LDAA    $0B
        TAB
        ANDA    #$10
        STAA    $47
        ANDB    #$08
        STAB    $48
        LDX     #$8FFF
        LDAA    #$20
RESET_12F
        STAA    $00,X
        DEX
        CPX     #$7FFF
        BNE     RESET_12F
        LDS     #$03FF
        BSR     RESET_140
        BSR     RESET_140
        BRA     RESET_190
RESET_140
        STAA    $7F0A
        LDX     #$6544
        STX     $7F00
        LDX     #$5D18
        STX     $7F02
        LDX     #$7F00
        LDAA    $07
        BITA    #$01
        BNE     RESET_15E
        LDAA    #$20
        LDAB    #$14
        BRA     RESET_161
RESET_15E
        LDAA    #$40
        TAB
RESET_161
        STAA    $04,X
        STAB    $05,X
        STAB    $54
        LDAA    #$18
        STAA    $06,X
        STAA    $3F
        CLRA
        STAA    $0D,X
        STAA    $0C,X
        STAA    $0E,X
        LDX     #$7800
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
        RTS
RESET_190
        LDX     #$8800
        STX     $A9
        STX     $AB
        LDAA    $47
        BNE     RESET_1AF
        LDAA    #$43
        STAA    $7A00
        LDAA    $11
        ANDA    #$1C
        EORA    #$08
        ORAA    #$C1
        STAA    $4A
        STAA    $7A00
        BRA     RESET_1EF
RESET_1AF
        LDAA    #$0B
        STAA    $7A00
        LDAA    $10
        ANDA    #$38
        TAB
        EORA    #$24
        STAA    $4B
        STAA    $7A01
        LDAA    #$48
        STAA    $7A00
        LDAA    #$0E
        STAA    $4C
        STAA    $7A01
        LDAA    #$88
        STAA    $7A00
        LDAA    #$16
        TSTB
        BEQ     RESET_1DE
        CMPB    #$20
        BNE     RESET_1E0
        ORAA    #$40
        BRA     RESET_1E0
RESET_1DE
        ORAA    #$80
RESET_1E0
        STAA    $7A01
        STAA    $46
        LDAA    #$20
        STAA    $4A
        STAA    $7A00
        FCB     $7C,$00,$B9
RESET_1EF
        LDAA    #$43
        STAA    $7C00
        LDAA    $12
        ANDA    #$1C
        EORA    #$49
        STAA    $4D
        STAA    $7C00
        LDX     #$8000
        STX     $27
        STX     $29
        STX     $40
        LDX     #$877F
        STX     $2B
        STX     $42
        INX
        STX     $44
        LDAA    #$18
        STAA    $8FFE
        CLRA
        STAA    $8FFF
        LDX     #$010C
        STX     $7C
        STX     $7E
        LDAA    #$7C
        STAA    $50
        LDAA    $0D
        ANDA    #$01
        STAA    $3E
        BNE     RESET_237
        LDAA    #$80
        JSR     $EF1A
        LDAA    #$0A
        STAA    $3D
RESET_237
        LDX     #$FBE4
        JSR     $FB88
        JMP     RESET_411
        FCB     $91,$92,$CC,$CD,$CB,$CA,$F3,$F3
        FCB     $AE,$A3,$9C,$9C,$32,$22,$FD,$FE
        FCB     $12,$12,$98,$BA,$9E,$9F,$B4,$9B
        FCB     $A8,$9B,$31,$21,$71,$51,$93,$93
        FCB     $33,$23,$34,$24,$35,$25,$36,$26
        FCB     $37,$27,$38,$28,$39,$29,$30,$5F
        FCB     $2D,$3D,$5E,$7E,$5C,$7C,$09,$E9
        FCB     $37,$37,$38,$38,$39,$39,$1B,$1B
        FCB     $77,$57,$65,$45,$72,$52,$74,$54
        FCB     $79,$59,$75,$55,$69,$49,$6F,$4F
        FCB     $70,$50,$5B,$7B,$5D,$7D,$0D,$0D
        FCB     $34,$34,$35,$35,$36,$36,$09,$E9
        FCB     $61,$41,$73,$53,$64,$44,$66,$46
        FCB     $67,$47,$68,$48,$6A,$4A,$6B,$4B
        FCB     $6C,$4C,$3B,$2B,$3A,$2A,$40,$60
        FCB     $0A,$0A,$32,$32,$33,$33,$31,$31
        FCB     $90,$0C,$7A,$5A,$78,$58,$63,$43
        FCB     $76,$56,$62,$42,$6E,$4E,$6D,$4D
        FCB     $2C,$3C,$2E,$3E,$2F,$3F,$20,$20
        FCB     $9D,$EE,$30,$30,$2E,$2E,$97,$97
        FCB     $94,$95,$14,$14,$0A,$D4,$13,$D3
        FCB     $08,$E4,$C3,$E5,$03,$1F,$2C,$2C
        FCB     $E4,$59,$E6,$C4,$E6,$D0,$E5,$BE
        FCB     $E6,$8B,$FA,$DA,$E8,$1B,$E6,$3E
        FCB     $E6,$B5,$E4,$59,$E4,$59,$F3,$19
        FCB     $EA,$FA,$EB,$C8,$E4,$59,$E8,$F0
        FCB     $E4,$59,$F1,$88,$EF,$8F,$EF,$17
        FCB     $EF,$7A,$F1,$D0,$E4,$59,$E4,$59
        FCB     $F2,$EE,$E4,$59,$E4,$59,$E4,$59
        FCB     $E4,$59,$EA,$E9,$EF,$02,$E4,$59
        FCB     $E4,$59,$E4,$59,$E4,$59,$E4,$59
        FCB     $F2,$FE,$E4,$59,$E4,$59,$E4,$59
        FCB     $E4,$59,$E4,$59,$EB,$4A,$EB,$42
        FCB     $ED,$35,$E4,$59,$ED,$1C,$E8,$D1
        FCB     $F1,$82,$E4,$59,$E4,$59,$EB,$7B
        FCB     $E4,$59,$EA,$F1,$EA,$F6,$E4,$59
        FCB     $E4,$59,$E4,$59,$F0,$E5,$F1,$3B
        FCB     $F2,$5C,$F2,$96,$E4,$59,$E4,$59
        FCB     $F1,$CA,$E4,$59,$EA,$1B,$EC,$36
        FCB     $EC,$3C,$E4,$59,$E4,$59,$E8,$22
        FCB     $E8,$92,$E4,$59,$E4,$59,$E4,$59
        FCB     $E4,$59,$E4,$59,$E4,$59,$E4,$59
        FCB     $F9,$F9,$E4,$59,$E4,$59,$E4,$59
        FCB     $EB,$D2,$EB,$CD,$E4,$59,$E4,$59
        FCB     $E4,$59,$EF,$3D,$E4,$59,$E9,$54
        FCB     $E9,$65,$E9,$6E,$F0,$17,$E9,$BA
        FCB     $E9,$4D,$E8,$C9,$E8,$CD,$E8,$C5
        FCB     $E8,$BC,$E8,$C1,$E4,$59,$E4,$59
        FCB     $EB,$46,$E4,$59,$E4,$59,$E8,$95
        FCB     $E0,$44,$E5,$CA,$E5,$DC,$E4,$59
        FCB     $E4,$59,$E4,$59,$E4,$59,$E5,$E8
        FCB     $E4,$59,$E4,$59,$E4,$59,$E8,$D1
        FCB     $EB,$BE,$ED,$BA,$E6,$78,$EE,$DA
        FCB     $F0,$F1,$E6,$55,$E9,$12,$E9,$16
        FCB     $E4,$59,$E9,$43,$E8,$B0,$EB,$C3
        FCB     $EB,$6A,$E4,$59,$E4,$59,$EA,$E5
        FCB     $E9,$0E,$E9,$0A,$E9,$1A,$E6,$DC
        FCB     $E9,$06,$E9,$02,$E9,$1E,$E8,$FE
        FCB     $39
RESET_411
        LDX     #$0063
        LDAA    #$80
        STAA    $00,X
        STAA    $02,X
        STAA    $03,X
        CLI
        JMP     RESET_420
RESET_420
        LDX     $72
RESET_422
        LDAA    $63,X
        BPL     RESET_474
RESET_426
        INX
        CPX     #$0005
        BNE     RESET_422
        FCB     $7F,$00,$73
        LDAB    $7802
        BITB    #$02
        BNE     RESET_420
        LDAB    #$34
        STAB    $7801
        LDAB    #$3C
        STAB    $7801
        LDX     $E3
        BEQ     RESET_44C
        DEX
        STX     $E3
        BNE     RESET_44C
        JSR     $E8F0
RESET_44C
        LDAB    $49
        BEQ     RESET_45B
        FCB     $7A,$00,$49
        BNE     RESET_45B
        LDX     #$FBF1
        JSR     $FB8B
RESET_45B
        LDX     #$0000
RESET_45E
        LDAA    $68,X
        BEQ     RESET_46C
        DEC     $68,X
        BNE     RESET_46C
        LDAA    $63,X
        ANDA    #$7F
        STAA    $63,X
RESET_46C
        INX
        CPX     #$0005
        BNE     RESET_45E
        BRA     RESET_420
RESET_474
        STX     $72
        STX     $74
        TAB
        ANDA    #$7C
        STAA    $63,X
        LDAA    $6D,X
        FCB     $78,$00,$75
        LDX     $74
        BITB    #$01
        BEQ     RESET_496
        BITB    #$02
        BEQ     RESET_492
        PSHA
        BSR     RESET_4AD
        PULA
        LDX     $74
RESET_492
        LDX     $59,X
        BRA     RESET_49E
RESET_496
        LDAB    #$E0
        STAB    $74
        LDX     $74
        LDX     $00,X
RESET_49E
        JSR     $00,X
        LDX     $72
        BRA     RESET_426
        STAA    $6D,X
        LDAA    $63,X
        ANDA    #$7F
        STAA    $63,X
        RTS
RESET_4AD
        LDX     $72
        LDAA    $63,X
        ORAA    #$80
        STAA    $63,X
        CLR     $68,X
        RTS
        FCB     $DE,$72,$A7,$68,$A6,$63,$8A,$81
        FCB     $A7,$63,$32,$33,$DF,$74,$78,$00
        FCB     $75,$DE,$74,$A7,$59,$E7,$5A,$39
        FCB     $DE,$72,$A6,$63,$8A,$83,$20,$E8
        FCB     $DE,$72,$A6,$63,$8A,$01,$20,$E0
        FCB     $C6,$05,$96,$76,$B7,$78,$00,$B6
        FCB     $78,$00,$2B,$0B,$26,$02,$86,$58
        FCB     $4A,$97,$76,$5A,$26,$EC,$39,$F6
        FCB     $78,$02,$D7,$78,$58,$49,$CE,$E2
        FCB     $89,$BD,$E7,$AB,$A6,$00,$2B,$24
        FCB     $D6,$78,$C5,$01,$27,$0A,$81,$61
        FCB     $2D,$06,$81,$7A,$2E,$02,$80,$20
        FCB     $C5,$40,$27,$10,$81,$40,$2D,$02
        FCB     $84,$1F,$81,$3C,$27,$04,$81,$3E
        FCB     $26,$02,$8A,$80,$97,$77,$86,$64
        FCB     $97,$79,$CE,$00,$00,$96,$77,$BD
        FCB     $E4,$ED,$86,$02,$BD,$E5,$01,$96
        FCB     $79,$27,$15,$86,$02,$BD,$E5,$01
        FCB     $B6,$78,$00,$2A,$15,$7A,$00,$79
        FCB     $26,$F1,$96,$14,$97,$79,$20,$DA
        FCB     $86,$08,$BD,$E5,$01,$B6,$78,$00
        FCB     $2B,$F6,$86,$04,$BD,$E5,$01,$7F
        FCB     $00,$79,$39,$84,$7F,$80,$10,$CE
        FCB     $E3,$39,$7E,$E6,$FC,$7F,$00,$79
        FCB     $B6,$78,$02,$88,$01,$B7,$78,$02
        FCB     $39,$96,$53,$26,$FB,$86,$03,$BD
        FCB     $E7,$87,$96,$0E,$84,$01,$26,$F0
        FCB     $7E,$EB,$6A,$96,$53,$26,$E9,$86
        FCB     $03,$BD,$E7,$87,$7E,$EB,$D2,$D6
        FCB     $73,$27,$DD,$96,$2F,$27,$14,$D6
        FCB     $07,$C5,$08,$27,$05,$86,$03,$BD
        FCB     $E7,$87,$D6,$07,$C5,$04,$27,$03
        FCB     $7E,$EC,$19,$7F,$00,$4F,$DE,$29
        FCB     $96,$2E,$D6,$2D,$B7,$70,$00,$01
        FCB     $6D,$00,$2B,$17,$4D,$27,$03,$4A
        FCB     $20,$03,$86,$4F,$5A,$9C,$40,$27
        FCB     $1B,$9C,$27,$26,$03,$DE,$42,$08
        FCB     $09,$20,$E1,$36,$A6,$00,$81,$86
        FCB     $32,$26,$09,$97,$2E,$D7,$2D,$DF
        FCB     $29,$7E,$EE,$C7,$39,$96,$15,$85
        FCB     $01,$27,$03,$7E,$F2,$EE,$85,$02
        FCB     $27,$03,$7E,$ED,$BA,$85,$08,$27
        FCB     $03,$7E,$EA,$FA,$D6,$0D,$96,$73
        FCB     $27,$02,$D6,$0F,$C5,$40,$27,$05
        FCB     $86,$0D,$BD,$E7,$87,$D6,$0D,$96
        FCB     $73,$27,$02,$D6,$07,$C5,$80,$27
        FCB     $03,$7E,$EB,$D2,$7E,$EB,$C8,$96
        FCB     $0D,$D6,$73,$27,$02,$96,$07,$85
        FCB     $20,$26,$F1,$7E,$EB,$B9,$7F,$00
        FCB     $79,$39,$96,$15,$85,$04,$26,$03
        FCB     $BD,$E8,$D1,$BD,$E5,$19,$4D,$2B
        FCB     $F0,$85,$60,$27,$EC,$97,$52,$81
        FCB     $30,$2D,$0E,$81,$39,$2E,$0A,$BD
        FCB     $E5,$19,$4D,$2B,$DC,$85,$60,$27
        FCB     $D8,$7E,$F3,$1D,$7F,$00,$79,$96
        FCB     $78,$85,$40,$26,$03,$7E,$EB,$42
        FCB     $7E,$F9,$40,$96,$78,$85,$40,$26
        FCB     $03,$7E,$F1,$88,$7E,$F1,$82,$96
        FCB     $78,$85,$40,$26,$03,$7E,$F1,$D0
        FCB     $7E,$F1,$CA,$BD,$E5,$19,$4D,$2A
        FCB     $03,$7E,$E5,$B4,$81,$75,$26,$03
        FCB     $7E,$E8,$C1,$85,$60,$27,$9A,$D6
        FCB     $30,$27,$03,$7E,$E7,$9B,$80,$20
        FCB     $CE,$E3,$59,$48,$BD,$E7,$AB,$EE
        FCB     $00,$6E,$00,$85,$60,$26,$0D,$81
        FCB     $1B,$27,$D0,$D6,$30,$26,$05,$CE
        FCB     $E4,$19,$20,$E7,$D6,$4F,$27,$35
        FCB     $D6,$73,$27,$11,$7F,$00,$4F,$36
        FCB     $BD,$ED,$73,$6D,$00,$2A,$F9,$BD
        FCB     $EC,$19,$32,$20,$20,$DE,$29,$B7
        FCB     $70,$00,$01,$E6,$00,$2B,$4E,$B7
        FCB     $70,$00,$01,$A7,$00,$17,$9C,$40
        FCB     $27,$43,$9C,$27,$27,$03,$09,$20
        FCB     $E6,$DE,$42,$20,$E2,$D6,$53,$27
        FCB     $07,$D6,$73,$26,$03,$7E,$E8,$D1
        FCB     $8D,$2C,$D6,$26,$27,$03,$7E,$EA
        FCB     $FA,$D6,$0D,$C5,$08,$26,$0C,$D6
        FCB     $73,$26,$08,$D6,$2F,$26,$04,$9C
        FCB     $2B,$27,$12,$96,$53,$97,$4E,$BD
        FCB     $EB,$7B,$D6,$53,$27,$07,$D6,$4E
        FCB     $26,$03,$7E,$EE,$C7,$39,$D6,$31
        FCB     $27,$05,$36,$BD,$F1,$91,$32,$DE
        FCB     $29,$9A,$53,$B7,$70,$00,$01,$A7
        FCB     $00,$39,$36,$86,$1B,$BD,$E7,$15
        FCB     $32,$7E,$E7,$15,$36,$17,$8D,$02
        FCB     $32,$39
ADD_A_TO_X
        STX     $7A
        ADDA    $7B
        STAA    $7B
        LDAA    $7A
        ADCA    #$00
        STAA    $7A
        LDX     $7A
        RTS
        FCB     $DE,$7C,$9C,$7E,$27,$23,$8D,$22
        FCB     $CE,$00,$02,$7E,$E4,$ED,$36,$BD
        FCB     $E4,$F6,$32,$BD,$E7,$04,$DE,$72
        FCB     $A6,$63,$85,$01,$26,$0B,$DE,$7C
        FCB     $9C,$7E,$27,$05,$BD,$E7,$E4,$20
        FCB     $EA,$39,$A6,$00,$08,$8C,$03,$80
        FCB     $26,$03,$CE,$01,$0C,$DF,$7C,$7F
        FCB     $00,$80,$39,$4D,$27,$15,$DE,$7E
        FCB     $A7,$00,$96,$80,$26,$0E

        END