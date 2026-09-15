; 129827-149.bin -- ROM B ($E800-$EFFF)
; VERIFIED BYTE-EXACT: reassembled through acp6800, diffed identical to original.
;
; Holds the RESET/SWI vector target ($E900, labeled RESET below): SEI,
; VTAC register init, switch-bank read. Also contains keyboard-probe
; (KBD_PROBE) and screen-output-queue (SCRN_OUTQ) routines.
;
; This is the same ROM role independently confirmed, in the sister
; 129867 firmware set, to contain the identical structural pattern --
; see the comparison summary for the shared keyboard self-test table
; that first established this correspondence.
;
; LABELS: see ROM129827_A.ASM's header for the naming scheme.
; Traced coverage: 317 instructions, 685/2048 bytes (33.4%).
;
        ORG     $E800
        FCB     $F0,$4C,$97,$13,$7E,$F0,$6A,$86
        FCB     $20,$B7,$70,$00,$01,$A7,$00,$7D
        FCB     $00,$7A,$2B,$04,$96,$13,$2A,$03
        FCB     $7E,$E7,$59,$84,$F0,$8A,$06,$97
        FCB     $13,$39,$BD,$F9,$C0,$D6,$60,$C5
        FCB     $20,$26,$43,$84,$03,$27,$38,$81
        FCB     $03,$27,$3B,$0E,$7D,$00,$15,$26
        FCB     $2B,$97,$15,$7F,$00,$52,$96,$21
        FCB     $85,$08,$27,$05,$CE,$80,$00,$20
        FCB     $03,$CE,$88,$00,$DF,$16,$DF,$1A
        FCB     $DF,$1F,$DF,$1C,$96,$16,$8B,$07
        FCB     $97,$18,$7F,$00,$7A,$86,$CF,$97
        FCB     $19,$7E,$E6,$A4,$97,$15,$39,$7D
        FCB     $00,$15,$27,$02,$20,$07,$39,$84
        FCB     $7F,$81,$14,$26,$06,$86,$80,$97
        FCB     $15,$20,$27,$DE,$1F,$B7,$70,$00
        FCB     $01,$A7,$00,$08,$9C,$1C,$26,$0B
        FCB     $96,$03,$8A,$20,$97,$03,$BD,$FB
        FCB     $8B,$20,$0F,$9C,$18,$26,$02,$DE
        FCB     $16,$DF,$1F,$7D,$00,$00,$2B,$02
        FCB     $DF,$1A,$D6,$84,$C4,$9F,$CA,$20
        FCB     $D7,$84,$F7,$7C,$00,$39
SCRN_OUTQ
        LDX     $1C
        CPX     $1A
        BEQ     SCRN_OUTQ_019
        STAA    $7000
        NOP
        LDAA    $00,X
        STAA    $7C01
        INX
        CPX     $18
        BNE     SCRN_OUTQ_016
        LDX     $16
SCRN_OUTQ_016
        STX     $1C
        RTS
SCRN_OUTQ_019
        LDAA    $84
        ANDA    #$9F
        LDAB    $14
        CMPB    #$01
        BEQ     SCRN_OUTQ_027
        LDAB    $15
        BPL     SCRN_OUTQ_035
SCRN_OUTQ_027
        LDAB    $15
        BITB    #$08
        BEQ     SCRN_OUTQ_03B
        FCB     $7F,$00,$15
        ORAA    #$40
        FCB     $7F,$00,$14
SCRN_OUTQ_035
        STAA    $84
        STAA    $7C00
        RTS
SCRN_OUTQ_03B
        CLRA
        STAA    $7C01
        LDAA    #$88
        STAA    $15
        RTS
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00
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
        STAA    $25
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
        STAA    $DB
        STAB    $DA
        BRA     RESET_099
RESET_0AB
        LDAA    $DB
        PSHA
        LDAA    $DA
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
        JSR     $E087
        BRA     RESET_0D4
RESET_0D0
        LDAA    #$1D
        STAA    $1E
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
        LDAA    #$11
        STAA    $02,X
        LDAA    #$43
        STAA    $7A00
        STAA    $7C00
        LDAA    $7E00
        TAB
        ANDA    #$1C
        ORAA    #$C1
        STAA    $83
        STAA    $7A00
        COMB
        ANDB    #$20
        ASLB
        ASLB
        STAB    $92
        LDAA    $7900
        ANDA    #$1C
        ORAA    #$41
        STAA    $84
        STAA    $7C00
        LDAA    #$17
        LDX     #$8000
        STX     $21
        STX     $23
        STAA    $25
        STX     $87D0
        STX     $87D2
        STAA    $87D4
        LDX     #$8800
        STX     $8FD0
        STX     $8FD2
        STAA    $8FD4
        JSR     $FA7F
        JSR     $F827
        LDX     #$0055
        STX     $7D
        LDX     $7B1E
        CPX     #$3046
        BNE     RESET_151
        LDX     #$7B00
        BRA     RESET_15D
RESET_151
        LDAA    $00
        BNE     RESET_15A
        LDX     #$EAF9
        BRA     RESET_15D
RESET_15A
        LDX     #$E545
RESET_15D
        STX     $53
        STX     $7F
        LDAB    #$1E
        JSR     $F412
        FCB     $B6,$00,$5D,$F6,$00,$65
        BITB    #$40
        BNE     RESET_172
        LDAA    #$20
RESET_172
        PSHA
        JSR     $F3B5
        JSR     $FDD3
        FCB     $B6,$00,$62
        JSR     $F2AD
        JSR     $F3B5
        JSR     $FDD3
        FCB     $B6,$00,$62
        JSR     $F2AD
        PULA
        TSX
        LDAA    $01,X
        ORAA    $03,X
        ORAA    $00,X
        BEQ     RESET_1D7
        LDX     #$EABF
        BSR     RESET_1CC
        JSR     $F06A
        TSX
        LDAB    #$05
        JSR     $FC81
        PULA
        PULA
        PULA
        PULA
        PULA
RESET_1A8
        JSR     KBD_PROBE
        FCB     $7D,$00,$7A
        BPL     RESET_1A8
        BRA     RESET_1DC
        LSRB
        FCB     $65,$73,$74,$20,$43,$6F,$6D,$70
        FCB     $6C,$65,$74,$65,$4D,$45,$4D,$4F
        FCB     $52,$59,$20,$45,$52,$52,$4F,$52
        FCB     $20
RESET_1CC
        STX     $7F
        LDAB    #$0D
        LDX     $23
        STX     $7D
        JMP     $F412
RESET_1D7
        LDX     #$EAB2
        BSR     RESET_1CC
RESET_1DC
        FCB     $B6,$00,$66
        TAB
        ANDA    #$01
        STAA    $7802
        BITB    #$08
        BEQ     RESET_1EC
        JSR     $FB64
RESET_1EC
        LDAA    $7E00
        ANDA    #$C0
        STAA    $51
        JSR     $FBF4
        JMP     $F8D0
        FCB     $1B,$0D,$00,$00,$00,$00,$01,$00
        FCB     $20,$00,$00,$00,$00,$00,$02,$F0
        FCB     $03,$01,$00,$00,$00,$00,$00,$00
        FCB     $00,$00,$00,$00,$00,$00,$00,$00
        FCB     $09,$21,$D1,$D1,$D7,$D7,$C5,$C5
        FCB     $D2,$D2,$D4,$F4,$D9,$F9,$32,$22
        FCB     $1B,$1B,$7F,$7F,$9E,$9F,$D0,$F0
        FCB     $B4,$B6,$92,$93,$31,$21,$71,$51
        FCB     $98,$98,$33,$23,$34,$24,$35,$25
        FCB     $36,$26,$37,$27,$38,$28,$39,$29
        FCB     $30,$5F,$2D,$3D,$5E,$7E,$5C,$7C
        FCB     $09,$C9,$87,$87,$88,$88,$89,$89
        FCB     $2D,$2D,$77,$57,$65,$45,$72,$52
        FCB     $74,$54,$79,$59,$75,$55,$69,$49
        FCB     $6F,$4F,$70,$50,$5B,$7B,$5D,$7D
        FCB     $0D,$0D,$84,$84,$85,$85,$86,$86
        FCB     $09,$09,$61,$41,$73,$53,$64,$44
        FCB     $66,$46,$67,$47,$68,$48,$6A,$4A
        FCB     $6B,$4B,$6C,$4C,$3B,$2B,$3A,$2A
        FCB     $40,$60,$0A,$0A,$82,$82,$83,$83
        FCB     $81,$81,$90,$91,$7A,$5A,$78,$58
        FCB     $63,$43,$76,$56,$62,$42,$6E,$4E
        FCB     $6D,$4D,$2C,$3C,$2E,$3E,$2F,$3F
        FCB     $20,$20,$1F,$CA,$30,$30,$2E,$2E
        FCB     $0D,$0D,$9D,$94,$1E,$1E,$0A,$0A
        FCB     $0B,$0B,$08,$08,$0C,$0C,$E3,$40
        FCB     $2C,$2C,$EC,$EB,$EE,$D9,$EE,$39
        FCB     $EE,$3D,$EE,$B5,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$EE,$50,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$EE,$B5,$EE,$5C
        FCB     $EE,$94,$EC,$EB,$EC,$EB,$FB,$60
        FCB     $FB,$5B,$EC,$EB,$EC,$EB,$FB,$11
        FCB     $FB,$21,$FB,$2A,$FB,$25,$FD,$AA
        FCB     $FD,$83,$FD,$A6,$F2,$BE,$FB,$A4
        FCB     $F4,$82,$F2,$58,$F2,$66,$F2,$72
        FCB     $F2,$AA,$F4,$60,$F4,$68,$F4,$64
        FCB     $F4,$6C,$FC,$F6,$FC,$FB,$FD,$74
        FCB     $FD,$7E,$EC,$EB,$F3,$01,$EC,$EB
        FCB     $F4,$7E,$FC,$C6,$FC,$D9,$FB,$2E
        FCB     $FB,$34,$FB,$3B,$FE,$B7,$EC,$EB
        FCB     $FB,$99,$EC,$EB,$F1,$AF,$F3,$88
        FCB     $F3,$88,$FC,$C2,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$FC,$BE,$FE,$67,$FF,$55
        FCB     $F4,$70,$FE,$18,$FB,$52,$EC,$EB
        FCB     $FE,$8E,$FB,$57,$FD,$18,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$FC,$EB,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$F1,$01,$EC,$EB
        FCB     $EC,$EB,$FC,$D9,$FC,$FF,$EC,$EB
        FCB     $FB,$FF,$FC,$C2,$FB,$82,$FB,$87
        FCB     $F4,$74,$FE,$60,$FB,$57,$FB,$64
        FCB     $FB,$7E,$EC,$EB,$FD,$24,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$F4,$86,$EC,$EB
        FCB     $FB,$8B,$EF,$E3,$F1,$01,$EF,$D4
        FCB     $EF,$EA,$EF,$C9,$EF,$F8,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$EC,$EB,$EC,$EB
        FCB     $EC,$EB,$EC,$EB,$EC,$EB,$EF,$B0
        FCB     $EF,$F1,$39,$C6,$04,$96,$75,$B7
        FCB     $78,$00,$B6,$78,$00,$2B,$0B,$26
        FCB     $02,$86,$58,$4A,$97,$75,$5A,$26
        FCB     $EC,$39,$F6,$78,$02,$D7,$77,$58
        FCB     $49,$CE,$EB,$1B,$BD,$EE,$9C,$C6
        FCB     $0F,$D7,$79,$A6,$00,$2B,$1E,$D6
        FCB     $77,$C5,$01,$27,$0A,$81,$61,$2D
        FCB     $06,$81,$7A,$2E,$02,$80,$20,$C5
        FCB     $40,$27,$0A,$81,$40,$2D,$06,$81
        FCB     $7F,$27,$02,$84,$1F,$4D,$2A,$0D
        FCB     $81,$90,$2C,$09,$7D,$00,$67,$2B
        FCB     $04,$84,$7F,$8B,$30,$97,$76,$86
        FCB     $7D,$97,$78,$CE,$00,$01,$96,$76
        FCB     $BD,$F9,$90,$86,$0A,$BD,$F9,$A4
        FCB     $96,$78,$27,$1C,$86,$02,$BD,$F9
        FCB     $A4,$B6,$78,$00,$2A,$1C,$7A,$00
        FCB     $78,$26,$F1,$96,$79,$81,$03,$2F
        FCB     $03,$7A,$00,$79,$97,$78,$20,$D3
        FCB     $86,$04,$BD,$F9,$A4,$B6,$78,$00
        FCB     $2B,$F6,$7F,$00,$78,$39,$36,$BD
        FCB     $F9,$99,$32,$16,$C4,$F8,$C1,$98
        FCB     $27,$0C,$D6,$2D,$27,$08,$81,$90
        FCB     $26,$03,$7F,$00,$2D,$39,$4D,$2A
        FCB     $25,$5F,$BD,$F9,$C8,$84,$7F,$85
        FCB     $60,$27,$74,$D6,$51,$C4,$C0,$C1
        FCB     $40,$26,$6C,$D6,$67,$C4,$04,$27
        FCB     $03,$7E,$EE,$20,$36,$96,$55,$BD
        FCB     $F7,$B2,$32,$7E,$F7,$B2,$81,$1B
        FCB     $26,$06,$D6,$77,$2A,$02,$96,$55
        FCB     $D6,$51,$C5,$40,$27,$20,$BD,$F7
        FCB     $B2,$D6,$51,$2B,$01,$39,$85,$60
        FCB     $26,$14,$81,$0D,$27,$08,$81,$04
        FCB     $27,$04,$81,$03,$26,$08,$36,$CE
        FCB     $00,$07,$BD,$F9,$92,$32,$BD,$EE
        FCB     $E5,$DE,$CB,$E6,$B3,$C5,$01,$26
        FCB     $01,$39,$DF,$CD,$78,$00,$CE,$DE
        FCB     $CD,$EE,$A3,$DF,$7B,$BD,$F9,$C0
        FCB     $D6,$51,$C1,$C0,$26,$03,$BD,$F7
        FCB     $B2,$DE,$7B,$AD,$00,$20,$DA,$84
        FCB     $7F,$80,$10,$2B,$0B,$CE,$EB,$CB
        FCB     $48,$BD,$EE,$9C,$EE,$00,$6E,$00
        FCB     $8B,$4F,$7F,$00,$78,$7E,$F4,$8A
        FCB     $96,$67,$20,$03,$96,$67,$43,$85
        FCB     $02,$27,$04,$86,$D3,$20,$02,$86
        FCB     $B5,$CE,$00,$01,$7E,$F9,$90,$7F
        FCB     $00,$78,$B6,$78,$02,$88,$01,$B7
        FCB     $78,$02,$39,$7F,$00,$78,$B6,$7E
        FCB     $00,$84,$01,$26,$F5,$96,$83,$8A
        FCB     $60,$B7,$7A,$00,$86,$C8,$BD,$F9
        FCB     $A4,$96,$83,$B7,$7A,$00,$7E,$F9
        FCB     $99
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
        FCB     $7F,$00,$78
        LDAB    #$80
        STAB    $7A
        RTS
        FCB     $DF,$CD,$9B,$CE,$97,$CE,$96,$CD
        FCB     $89,$00,$97,$CD,$DE,$CD,$39,$D6
        FCB     $CC,$C1,$01,$26,$03,$7F,$00,$78
        FCB     $39,$BD,$FB,$8B,$7F,$00,$78,$D6
        FCB     $77,$2A,$0A,$BD,$F9,$C0,$7F,$00
        FCB     $78,$4D,$7E,$EE,$20,$BD,$F9,$C0
        FCB     $7F,$00,$78,$4D,$2B,$E2,$85,$60
        FCB     $27,$DE,$7E,$F4,$8A,$96,$77,$85
        FCB     $40,$26,$03,$7E,$FD,$7E,$7E,$FD
        FCB     $AA,$BD,$F9,$D6,$C5,$20,$26,$10
        FCB     $91,$55,$26,$26,$C6,$20,$7E,$F9
        FCB     $C8,$91,$55,$26,$1D,$BD,$F9,$C0
        FCB     $5F,$BD,$F9,$C8,$81,$58,$27,$04
        FCB     $81,$75,$26,$03,$7E,$FB,$57,$85
        FCB     $60,$27,$1E,$D6,$2A,$26,$31,$7E
        FCB     $EE,$20,$85,$60,$27,$09,$81,$7F
        FCB     $26,$0F,$D6,$2A,$26,$0B,$39,$D6
        FCB     $2A,$26,$06,$CE,$EC,$AB,$7E,$EE
        FCB     $29
SCRDISP
        FCB     $7D,$00,$2E
        BEQ     SCRDISP_00A
        PSHA
        JSR     $FE6A
        PULA
SCRDISP_00A
        ORAA    $29
        LDX     $23
        STAA    $7000
        NOP
        STAA    $00,X
        JMP     SHIFT_CHK_019
        FCB     $36,$86,$1B,$8D,$E4,$32,$20,$E1
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
        FCB     $00,$00,$00,$00
SHIFT_CHK
        LDAA    $52
        BPL     SHIFT_CHK_011
        ANDA    #$04
        LDAB    $7802
        ANDB    #$04
        CBA
        BEQ     SHIFT_CHK_011
        JSR     $F3B5
SHIFT_CHK_011
        JSR     $F026
        BSR     $F017
SHIFT_CHK_016
        JMP     $F151
SHIFT_CHK_019
        JSR     $F047
SHIFT_CHK_01C
        BSR     $F017
        BRA     SHIFT_CHK_016
        LDX     $23
        BRA     SHIFT_CHK_01C
        LDAB    $28
        BEQ     SHIFT_CHK_02C
        LDAB    $64
        BMI     SHIFT_CHK_041
SHIFT_CHK_02C
        JSR     $F06E
        BSR     $F017
        BRA     SHIFT_CHK_016
SHIFT_CHK_033
        JSR     $F0C6
        BSR     $F017
        BRA     SHIFT_CHK_033
        JSR     $F0DF
        BSR     $F017
        BRA     SHIFT_CHK_033
SHIFT_CHK_041
        JSR     $F06A
        BSR     $F017
        BRA     SHIFT_CHK_016
        LDAB    $28
        ORAB    $81
        BNE     $F007
        LDAB    $63

        END