; 129867-67.bin -- ROM B ($E800-$EFFF)
; VERIFIED BYTE-EXACT: reassembled through acp6800, diffed identical to original.
;
; Holds the RESET/SWI/NMI vector target ($E800, labeled RESET below).
; Routines here are named to MATCH the functionally-equivalent routine in
; the 129827 set (e.g. this file's RESET corresponds to 129827-149's
; RESET at $E900) -- the underlying firmware logic is the same, just
; relocated between the two revisions; see the comparison summary.
;
; LABELS: routine entry points have evidence-based names; internal branch
; targets are <ROUTINE>_<offset>, capped at 11 base characters to fit
; acp6800's 15-char label limit.
;
; Traced coverage: 401 instructions, 863/2048 bytes (42.1%).
;
        ORG     $E800
RESET
        SEI
        STAA    $7F0E
        STAA    $7F0A
        LDX     #$7F00
        LDAA    #$65
        STAA    $00,X
        LDAA    #$44
        STAA    $01,X
        LDAA    #$5D
        STAA    $02,X
        LDAA    $7E00
        ANDA    #$02
        BEQ     RESET_027
        LDAA    #$20
        STAA    $04,X
        LDAA    #$14
        STAA    $05,X
        BRA     RESET_02F
RESET_027
        LDAA    #$40
        STAA    $04,X
        LDAA    #$35
        STAA    $05,X
RESET_02F
        LDAA    #$17
        STAA    $03,X
        STAA    $06,X
        STAA    $15
        CLRA
        STAA    $0D,X
        STAA    $0C,X
        STAA    $0E,X
        LDS     #$03FF
        CLR     $8F80
        CLR     $8F81
        LDX     #$03FF
        LDAB    #$AA
RESET_04C
        STAB    $00,X
        DEX
        BNE     RESET_04C
        LDX     #$03FF
RESET_054
        LDAB    #$AA
        CMPB    $00,X
        BNE     RESET_06A
        COMB
        STAB    $00,X
        CMPB    $00,X
        BNE     RESET_06A
RESET_061
        CLR     $00,X
        DEX
        BNE     RESET_054
        CLR     $00,X
        BRA     RESET_074
RESET_06A
        LDAA    $00,X
        STAA    $8F81
        STAB    $8F80
        BRA     RESET_061
RESET_074
        LDAA    $8F81
        PSHA
        LDAA    $8F80
        PSHA
        LDX     #$8FFF
        LDAB    #$AA
RESET_081
        STAB    $00,X
        DEX
        CPX     #$8000
        BNE     RESET_081
        LDX     #$8FFF
RESET_08C
        LDAB    #$AA
        CMPB    $00,X
        BNE     RESET_0A3
        COMB
        STAB    $00,X
        CMPB    $00,X
        BNE     RESET_0A3
RESET_099
        CLR     $00,X
        DEX
        CPX     #$8000
        BNE     RESET_08C
        BRA     RESET_0AB
RESET_0A3
        LDAA    $00,X
        STAA    $BA
        STAB    $B9
        BRA     RESET_099
RESET_0AB
        LDAA    $BA
        PSHA
        LDAA    $B9
        PSHA
        CLRA
        LDX     #$E800
RESET_0B5
        EORA    $00,X
        INX
        BNE     RESET_0B5
        PSHA
        LDX     $E000
        CPX     #$544A
        BNE     RESET_0D0
        LDAA    $7D00
        BMI     RESET_0D0
        FCB     $7C,$00,$00
        JSR     $E07D
        BRA     RESET_0D4
RESET_0D0
        LDAA    #$1D
        STAA    $DB
RESET_0D4
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
        LDAA    #$43
        STAA    $7A00
        STAA    $7C00
        LDAA    $7E00
        TAB
        ANDA    #$1C
        ORAA    #$C1
        STAA    $BF
        STAA    $7A00
        COMB
        ANDB    #$20
        ASLB
        ASLB
        STAB    $CE
        LDAA    $7900
        ANDA    #$1C
        ORAA    #$41
        STAA    $C0
        STAA    $7C00
        LDAA    #$17
        LDX     #$8000
        STX     $11
        STX     $13
        STAA    $15
        STX     $87D0
        STX     $87D2
        STAA    $87D4
        LDX     #$8800
        STX     $8FD0
        STX     $8FD2
        STAA    $8FD4
        JSR     BUF_INIT2
        JSR     $FD6A
        LDX     #$0045
        STX     $B1
        LDX     $7B1E
        CPX     #$3046
        BNE     RESET_14F
        LDX     #$7B00
        BRA     RESET_15B
RESET_14F
        LDAA    $00
        BNE     RESET_158
        LDX     #$E9F8
        BRA     RESET_15B
RESET_158
        LDX     #$E530
RESET_15B
        STX     $43
        STX     $B3
        LDAB    #$1E
        JSR     $F6BB
        FCB     $B6,$00,$4D,$F6,$00,$55
        BITB    #$40
        BNE     RESET_170
        LDAA    #$20
RESET_170
        PSHA
        JSR     $F65E
        JSR     $F790
        FCB     $B6,$00,$52
        JSR     $F556
        JSR     $F65E
        JSR     $F790
        FCB     $B6,$00,$52
        JSR     $F556
        PULA
        TSX
        LDAA    $01,X
        ORAA    $03,X
        ORAA    $00,X
        BEQ     RESET_1D5
        LDX     #$E9BD
        BSR     RESET_1CA
        JSR     $F313
        TSX
        LDAB    #$05
        JSR     $F1D0
        PULA
        PULA
        PULA
        PULA
        PULA
RESET_1A6
        JSR     KBD_PROBE
        FCB     $7D,$00,$AE
        BPL     RESET_1A6
        BRA     RESET_1DA
        LSRB
        FCB     $65,$73,$74,$20,$43,$6F,$6D,$70
        FCB     $6C,$65,$74,$65,$4D,$45,$4D,$4F
        FCB     $52,$59,$20,$45,$52,$52,$4F,$52
        FCB     $20
RESET_1CA
        STX     $B3
        LDAB    #$0D
        LDX     $13
        STX     $B1
        JMP     $F6BB
RESET_1D5
        LDX     #$E9B0
        BSR     RESET_1CA
RESET_1DA
        FCB     $B6,$00,$56
        TAB
        ANDA    #$01
        STAA    $7802
        BITB    #$08
        BEQ     RESET_1EA
        JSR     $F0B3
RESET_1EA
        LDAA    $7E00
        ANDA    #$C0
        STAA    $41
        JSR     $F143
        JMP     RESET_3F8
        FCB     $03,$1B,$0D,$00,$00,$00,$00,$01
        FCB     $00,$20,$00,$00,$00,$00,$00,$02
        FCB     $F0,$03,$01,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$03,$80,$D1,$D1,$D7,$D7,$C5
        FCB     $C5,$D2,$D2,$D4,$F4,$D9,$F9,$32
        FCB     $22,$1B,$1B,$7F,$7F,$9E,$9F,$D0
        FCB     $F0,$B4,$B6,$92,$93,$31,$21,$71
        FCB     $51,$98,$98,$33,$23,$34,$24,$35
        FCB     $25,$36,$26,$37,$27,$38,$28,$39
        FCB     $29,$30,$5F,$2D,$3D,$5E,$7E,$5C
        FCB     $7C,$09,$C9,$87,$87,$88,$88,$89
        FCB     $89,$2D,$2D,$77,$57,$65,$45,$72
        FCB     $52,$74,$54,$79,$59,$75,$55,$69
        FCB     $49,$6F,$4F,$70,$50,$5B,$7B,$5D
        FCB     $7D,$0D,$0D,$84,$84,$85,$85,$86
        FCB     $86,$09,$09,$61,$41,$73,$53,$64
        FCB     $44,$66,$46,$67,$47,$68,$48,$6A
        FCB     $4A,$6B,$4B,$6C,$4C,$3B,$2B,$3A
        FCB     $2A,$40,$60,$0A,$0A,$82,$82,$83
        FCB     $83,$81,$81,$90,$91,$7A,$5A,$78
        FCB     $58,$63,$43,$76,$56,$62,$42,$6E
        FCB     $4E,$6D,$4D,$2C,$3C,$2E,$3E,$2F
        FCB     $3F,$20,$20,$1F,$CA,$30,$30,$2E
        FCB     $2E,$0D,$0D,$9D,$94,$1E,$1E,$0A
        FCB     $0A,$0B,$0B,$08,$08,$0C,$0C,$E3
        FCB     $00,$2C,$2C,$EB,$EA,$EF,$EA,$EF
        FCB     $4A,$EF,$4E,$EF,$C6,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$EF,$61,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$EF,$C6,$EF
        FCB     $6D,$EF,$A5,$EB,$EA,$EB,$EA,$F0
        FCB     $AF,$F0,$AA,$EB,$EA,$EB,$EA,$F0
        FCB     $60,$F0,$70,$F0,$79,$F0,$74,$F7
        FCB     $67,$F7,$40,$F7,$63,$F5,$67,$F0
        FCB     $F3,$F9,$D1,$F5,$01,$F5,$0F,$F5
        FCB     $1B,$F5,$53,$F9,$B5,$F9,$BD,$F9
        FCB     $B9,$F9,$C1,$F2,$37,$F2,$3C,$F7
        FCB     $31,$F7,$3B,$EB,$EA,$F5,$AA,$EB
        FCB     $EA,$F9,$CD,$F2,$15,$F2,$21,$F0
        FCB     $7D,$F0,$83,$F0,$8A,$F8,$74,$EB
        FCB     $EA,$F0,$E8,$EB,$EA,$F4,$58,$F6
        FCB     $31,$F6,$31,$F2,$11,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$F2,$0D,$F8,$24,$F9
        FCB     $12,$F9,$C5,$F7,$D5,$F0,$A1,$EB
        FCB     $EA,$F8,$4B,$F0,$A6,$F6,$D5,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$F2,$2C,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$F3,$AA,$EB
        FCB     $EA,$EB,$EA,$F2,$21,$F2,$40,$EB
        FCB     $EA,$F1,$4E,$F2,$11,$F0,$D1,$F0
        FCB     $D6,$F9,$C9,$F8,$1D,$F0,$A6,$F0
        FCB     $B3,$F0,$CD,$EB,$EA,$F6,$E1,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$F9,$D5,$EB
        FCB     $EA,$F0,$DA,$F2,$8C,$F3,$AA,$F2
        FCB     $7D,$F2,$93,$F2,$72,$F2,$A1,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$EB,$EA,$EB
        FCB     $EA,$EB,$EA,$EB,$EA,$EB,$EA,$F2
        FCB     $59,$F2,$9A,$39,$5D,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00
RESET_3F8
        LDX     #$0085
        LDAA    #$80
        LDAB    #$08
        BSR     RESET_44C
        LDX     #$008D
        LDAB    #$08
        CLRA
        BSR     RESET_44C
        LDX     #$EE06
        STX     $65
        LDX     #$FD27
        STX     $73
        LDAA    $00
        BNE     RESET_432
        LDX     #$EEA1
        STX     $67
        LDX     #$ED05
        STX     $69
        LDX     #$ED58
        STX     $6B
        LDX     #$F9F5
        STX     $6D
        LDX     #$FE03
        STX     $6F
        BRA     RESET_435
RESET_432
        JSR     $E0CA
RESET_435
        LDX     #$0000
        STX     $9D
        STX     $9F
        LDX     #$0000
        JSR     CLR_HIBIT
        LDX     #$0002
        JSR     CLR_HIBIT
        CLI
        JMP     RESET_453
RESET_44C
        STAA    $00,X
        INX
        DECB
        BGT     RESET_44C
        RTS
RESET_453
        LDX     $9D
RESET_455
        LDAA    $85,X
        BPL     RESET_48C
RESET_459
        INX
        CPX     #$0008
        BNE     RESET_455
        FCB     $7F,$00,$9E
        LDAB    $7802
        BITB    #$02
        BNE     RESET_453
        LDAB    #$34
        STAB    $7801
        LDAB    #$3C
        STAB    $7801
        LDX     #$0000
RESET_476
        LDAA    $8D,X
        BEQ     RESET_484
        DEC     $8D,X
        BNE     RESET_484
        LDAA    $85,X
        ANDA    #$7F
        STAA    $85,X
RESET_484
        INX
        CPX     #$0008
        BNE     RESET_476
        BRA     RESET_453
RESET_48C
        STX     $9D
        STX     $9F
        TAB
        ANDA    #$7C
        STAA    $85,X
        LDAA    $95,X
        FCB     $78,$00,$A0
        LDX     $9F
        BITB    #$01
        BEQ     RESET_4AE
        BITB    #$02
        BEQ     RESET_4AA
        PSHA
        BSR     CLR_HIBIT_007
        PULA
        LDX     $9F
RESET_4AA
        LDX     $75,X
        BRA     RESET_4B0
RESET_4AE
        LDX     $65,X
RESET_4B0
        ANDB    #$30
        JSR     $00,X
        LDX     $9D
        BRA     RESET_459
        STAA    $95,X
CLR_HIBIT
        LDAA    $85,X
        ANDA    #$7F
        STAA    $85,X
        RTS
CLR_HIBIT_007
        LDX     $9D
        LDAA    $85,X
        ORAA    #$80
        STAA    $85,X
        CLR     $8D,X
        RTS
        FCB     $DE,$9D,$E6,$85,$CA,$81,$A7,$8D
        FCB     $26,$02,$C4,$7F,$E7,$85,$32,$33
        FCB     $DF,$9F,$78,$00,$A0,$DE,$9F,$A7
        FCB     $75,$E7,$76,$39,$DE,$9D,$E6,$85
        FCB     $CA,$83,$20,$E8,$DE,$9D,$36,$A6
        FCB     $85,$84,$CF,$C4,$30,$1B,$A7,$85
        FCB     $32,$39,$DE,$9D,$E6,$85,$C4,$30
        FCB     $39,$DE,$A1,$9C,$A3,$27,$4C,$8D
        FCB     $25,$7D,$00,$D2,$2F,$09,$BD,$FF
        FCB     $82,$D6,$D2,$C5,$02,$27,$3C,$CE
        FCB     $00,$03,$4D,$2A,$0E,$D6,$4C,$27
        FCB     $08,$E6,$85,$C4,$FE,$E7,$85,$20
        FCB     $02,$84,$7F,$7E,$EC,$B8,$A6,$00
        FCB     $16,$D8,$0E,$D7,$0E,$08,$8C,$03
        FCB     $80,$26,$03,$CE,$01,$10,$4D,$2A
        FCB     $0D,$E6,$00,$D7,$A5,$08,$8C,$03
        FCB     $80,$26,$03,$CE,$01,$10,$DF,$A1
        FCB     $7F,$00,$A6,$39,$36,$BD,$EC,$C1
        FCB     $32,$4D,$2A,$18,$84,$7F,$D6,$A5
        FCB     $C5,$10,$26,$EF,$C5,$60,$27,$0C
        FCB     $D6,$4C,$27,$08,$37,$BD,$F0,$DA
        FCB     $32,$7E,$F0,$3A,$7E,$EF,$F6
BUF_INIT2
        LDX     #$0110
        STX     $A3
        STX     $A1
        RTS
IRQ_HANDLER
        LDAB    $7A00
        BPL     IRQ_HANDLER_007
        BSR     IRQ_HANDLER_010
IRQ_HANDLER_007
        LDAB    $7C00
        BPL     IRQ_HANDLER_00F
        JSR     $FFAB
IRQ_HANDLER_00F
        RTI
IRQ_HANDLER_010
        BITB    #$01
        BEQ     IRQ_HANDLER_06C
        LDAA    $7A01
        ANDA    #$7F
        ANDB    #$70
        BEQ     IRQ_HANDLER_026
        BITB    #$10
        BEQ     IRQ_HANDLER_024
        STAB    $A8
        RTS
IRQ_HANDLER_024
        ORAA    #$80
IRQ_HANDLER_026
        FCB     $7D,$00,$A8
        BEQ     IRQ_HANDLER_02F
        FCB     $7F,$00,$A8
        RTS
IRQ_HANDLER_02F
        FCB     $7D,$00,$A6
        BMI     IRQ_HANDLER_065
        LDX     $A3
        STAA    $00,X
        INX
        CPX     #$0380
        BNE     IRQ_HANDLER_041
        LDX     #$0110
IRQ_HANDLER_041
        STX     $A3
        TSTA
        BPL     IRQ_HANDLER_053
        STAB    $00,X
        INX
        CPX     #$0380
        BNE     IRQ_HANDLER_051
        LDX     #$0110
IRQ_HANDLER_051
        STX     $A3
IRQ_HANDLER_053
        INX
        CPX     #$0380
        BNE     IRQ_HANDLER_05C
        LDX     #$0110
IRQ_HANDLER_05C
        CPX     $A1
        BNE     IRQ_HANDLER_064
        LDAA    #$80
        STAA    $A6
IRQ_HANDLER_064
        RTS
IRQ_HANDLER_065
        LDAA    #$80
        STAA    $A7
        JMP     $F0DA
IRQ_HANDLER_06C
        BITB    #$02
        BEQ     IRQ_HANDLER_07B
        LDAA    $BF
        ANDA    #$60
        CMPA    #$20
        BNE     IRQ_HANDLER_07B
        JMP     $FD85
IRQ_HANDLER_07B
        BITB    #$04
        BEQ     IRQ_HANDLER_082
        LDAA    $7A01
IRQ_HANDLER_082
        RTS
        FCB     $C6,$04,$96,$A9,$B7,$78,$00,$B6
        FCB     $78,$00,$2B,$0B,$26,$02,$86,$58
        FCB     $4A,$97,$A9,$5A,$26,$EC,$39,$F6
        FCB     $78,$02,$D7,$AB,$58,$49,$CE,$EA
        FCB     $1A,$BD,$EF,$AD,$C6,$0F,$D7,$AD
        FCB     $A6,$00,$2B,$1E,$D6,$AB,$C5,$01
        FCB     $27,$0A,$81,$61,$2D,$06,$81,$7A
        FCB     $2E,$02,$80,$20,$C5,$40,$27,$0A
        FCB     $81,$40,$2D,$06,$81,$7F,$27,$02
        FCB     $84,$1F,$4D,$2A,$0D,$81,$90,$2C
        FCB     $09,$7D,$00,$57,$2B,$04,$84,$7F
        FCB     $8B,$30,$97,$AA,$86,$7D,$97,$AC
        FCB     $CE,$00,$01,$96,$AA,$BD,$EC,$B8
        FCB     $86,$0A,$BD,$EC,$CC,$96,$AC,$27
        FCB     $1C,$86,$02,$BD,$EC,$CC,$B6,$78
        FCB     $00,$2A,$1C,$7A,$00,$AC,$26,$F1
        FCB     $96,$AD,$81,$03,$2F,$03,$7A,$00
        FCB     $AD,$97,$AC,$20,$D3,$86,$04,$BD
        FCB     $EC,$CC,$B6,$78,$00,$2B,$F6,$7F
        FCB     $00,$AC,$39,$36,$BD,$EC,$C1,$32
        FCB     $16,$C4,$F8,$C1,$98,$27,$0C,$D6
        FCB     $1D,$27,$08,$81,$90,$26,$03,$7F
        FCB     $00,$1D,$39,$4D,$2A,$1C,$5F,$BD
        FCB     $EC,$F0,$84,$7F,$85,$60,$27,$6B
        FCB     $D6,$41,$C4,$C0,$C1,$40,$26,$63
        FCB     $36,$96,$45,$BD,$FC,$F5,$32,$7E
        FCB     $FC,$F5,$81,$1B,$26,$06,$D6,$AB
        FCB     $2A,$02,$96,$45,$D6,$41,$C5,$40
        FCB     $27,$20,$BD,$FC,$F5,$D6,$41,$2B
        FCB     $01,$39,$85,$60,$26,$14,$81,$0D
        FCB     $27,$08,$81,$04,$27,$04,$81,$03
        FCB     $26,$08,$36,$CE,$00,$07,$BD,$EC
        FCB     $BA,$32,$BD,$EF,$F6,$DE,$9D,$E6
        FCB     $85,$C5,$01,$26,$01,$39,$DF,$9F
        FCB     $78,$00,$A0,$DE,$9F,$EE,$75,$DF
        FCB     $AF,$BD,$EC,$E8,$D6,$41,$C1,$C0
        FCB     $26,$03,$BD,$FC,$F5,$DE,$AF,$AD
        FCB     $00,$20,$DA,$84,$7F,$80,$10,$2B
        FCB     $0B,$CE,$EA,$CA,$48,$BD,$EF,$AD
        FCB     $EE,$00,$6E,$00,$8B,$4F,$7F,$00
        FCB     $AC,$7E,$F9,$D9,$96,$57,$20,$03
        FCB     $96,$57,$43,$85,$02,$27,$04,$86
        FCB     $D3,$20,$02,$86,$B5,$CE,$00,$01
        FCB     $7E,$EC,$B8,$7F,$00,$AC,$B6,$78
        FCB     $02,$88,$01,$B7,$78,$02,$39,$7F
        FCB     $00,$AC,$B6,$7E,$00,$84,$01,$26
        FCB     $F5,$96,$BF,$8A,$60,$B7,$7A,$00
        FCB     $86,$C8,$BD,$EC,$CC,$96,$BF,$B7
        FCB     $7A,$00,$7E,$EC,$C1
KBD_PROBE
        LDAB    $7800
        PSHB
        LDAB    #$09
        STAB    $7800
        LDAB    $7800
        BPL     KBD_PROBE_015
        LDAB    $7802
        BPL     KBD_PROBE_015
        BSR     KBD_PROBE_01A
KBD_PROBE_015
        PULB
        STAB    $7800
        RTS
KBD_PROBE_01A
        FCB     $7F,$00,$AC
        LDAB    #$80
        STAB    $AE
        RTS
        FCB     $DF,$9F,$9B,$A0,$97,$A0,$96,$9F
        FCB     $89,$00,$97,$9F,$DE,$9F,$39,$D6
        FCB     $9E,$C1,$01,$26,$03,$7F,$00,$AC
        FCB     $39,$BD,$F0,$DA,$7F,$00,$AC,$D6
        FCB     $AB,$2A,$0A,$BD,$EC,$E8,$7F,$00
        FCB     $AC,$4D,$7E,$EF,$31,$BD,$EC,$E8
        FCB     $7F,$00,$AC,$4D,$2B,$E2,$85,$60
        FCB     $27,$DE,$7E,$F9,$D9,$96,$AB,$85
        FCB     $40,$26,$03,$7E,$F7,$3B,$7E,$F7
        FCB     $67,$BD,$EC,$FE,$C5,$20,$26,$09
        FCB     $91,$45,$26

        END