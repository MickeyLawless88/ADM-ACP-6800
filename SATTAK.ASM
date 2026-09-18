; shuttleattack.bin -- "SHUTTLE ATTACK V.2", COPYRIGHT (C) 1982
; ADM-31 plugin ROM ($E000-$E7FF), MD5 a3d616ea819c7b361d741eae6bb829ad
;
; VERIFIED BYTE-EXACT: reassembled through acp6800, diffed identical to
; original (confirmed 0 errors, matching MD5).
;
; Standard plugin-ROM header: "TJ" signature at $E000-$E001, entry at
; $E03C (3 NOPs then JMP to the real init routine at $E03F -- a slight
; variant of the usual bare "JMP" directly at $E03C seen elsewhere in
; this project). $E002 is unused padding -- this game does not implement
; the KEY_ENTRY ($E002) callback convention seen in some other ADM-31
; game ROMs (Cosmic Intruders, Space Invaders); it polls the keyboard
; directly instead.
;
; Embedded UI text confirms this is a Space-Invaders-style shooting game:
; "GAME OVER", "SCORE", "HIGH SCORE", "3 SHIPS LEFT",
; "PRESS FUNCTION TO START".
;
; LABELS: routine entry points (JSR/BSR-independent call targets) have
; evidence-based descriptive names; internal branch targets are named
; <ROUTINE>_<offset>. Base names capped at 7 characters. A small number
; of branch targets that land in the middle of another instruction's own
; operand bytes (a real overlapping-code case, not a tracer error -- see
; ENTRY's neighborhood) can't be given a symbolic label at all, since a
; linear listing can't represent one byte range as two different things;
; those stay as raw hex targets, still byte-exact.
;
; Control-flow-traced coverage: ~66.7% of bytes; the rest is raw FCB data
; (sprite/UI-text tables, an object table, etc.), not verified as code.
; =============================================================================

        ORG     $E000
        FCB     $54,$4A,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF
ENTRY
        NOP
        NOP
        NOP
        JMP     RESET
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$7F,$00,$00,$39,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$20,$F4,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$47,$41
        FCB     $4D,$45,$20,$4F,$56,$45,$52,$53
        FCB     $43,$4F,$52,$45,$90,$30,$30,$30
        FCB     $30,$30,$90,$48,$49,$47,$48,$20
        FCB     $53,$43,$4F,$52,$45,$90,$30,$30
        FCB     $30,$30,$30,$90,$33,$20,$53,$48
        FCB     $49,$50,$53,$20,$4C,$45,$46,$54
        FCB     $50,$52,$45,$53,$53,$20,$46,$55
        FCB     $4E,$43,$54,$49,$4F,$4E,$20,$54
        FCB     $4F,$20,$53,$54,$41,$52,$54
ENTRY_225
        LDX     #$8017
ENTRY_228
        TST     $7000
        NOP
        LDAA    $00,X
        TST     $7000
        NOP
        CMPA    $11,X
        BHI     ENTRY_241
        BNE     ENTRY_23E
        INX
        CPX     #$801C
        BNE     ENTRY_228
ENTRY_23E
        JMP     RESET_086
ENTRY_241
        LDX     #$8017
ENTRY_244
        TST     $7000
        NOP
        LDAA    $00,X
        TST     $7000
        NOP
        STAA    $11,X
        INX
        CPX     #$801C
        BNE     ENTRY_244
        LDAA    #$92
        TST     $7000
        NOP
        STAA    $8027
        BRA     ENTRY_23E
ENTRY_261
        LDX     #$E218
        STX     $F2
        LDX     #$8391
        LDAB    #$09
        BSR     RESET_04D
        BRA     ENTRY_225
ENTRY_26F
        TST     $7000
        NOP
        LDAA    $802F
        DECA
        CMPA    #$30
        BEQ     ENTRY_261
        TST     $7000
        NOP
        STAA    $802F
        JMP     RESET_0B1
BEEP
        LDAA    $7803
        EORA    #$08
        STAA    $7803
        EORA    #$08
        STAA    $7803
        RTS
RESET
        LDX     #$8000
RESET_003
        TST     $7000
        NOP
        CLR     $00,X
        INX
        CPX     #$8780
        BNE     RESET_003
        LDAA    #$03
        STAA    $7A00
        STAA    $7C00
        LDAA    #$17
        STAA    $7F06
        LDAA    #$51
        STAA    $7F0C
        LDAA    $7802
        ANDA    #$FB
        STAA    $7802
        LDAA    #$98
        STAA    $8730
        LDS     #$003F
        LDX     #$E7B7
        STX     $F2
        LDAB    #$12
        LDX     #$833D
        BSR     RESET_04D
        LDAB    #$12
        LDX     #$83DD
        BSR     RESET_04D
        LDAB    #$25
        LDX     #$8474
        BSR     RESET_04D
        BRA     RESET_063
RESET_04D
        STX     $F0
        LDX     $F2
        LDAA    $00,X
        INX
        STX     $F2
        LDX     $F0
        TST     $7000
        NOP
        STAA    $00,X
        INX
        DECB
        BNE     RESET_04D
        RTS
RESET_063
        LDAA    #$10
RESET_065
        DEX
        BNE     RESET_065
        DECA
        BNE     RESET_065
        LDX     #$E221
        STX     $F2
        LDAB    #$1D
        LDX     #$8011
        BSR     RESET_04D
        LDX     #$8320
RESET_07A
        TST     $7000
        NOP
        CLR     $00,X
        INX
        CPX     #$8550
        BNE     RESET_07A
RESET_086
        LDX     #$E23E
        STX     $F2
        LDAB    #$0C
        LDX     #$802F
        BSR     RESET_04D
        LDX     #$842A
        LDAB    #$17
        BSR     RESET_04D
        LDAA    #$50
        STAA    $7800
RESET_09E
        TST     $7800
        BPL     RESET_09E
        LDX     #$E221
        STX     $F2
        LDAB    #$0C
        LDX     #$8011
        BSR     RESET_04D
        NOP
        NOP
RESET_0B1
        LDX     #$8320
        LDAA    #$98
RESET_0B6
        LDAB    #$50
        TST     $7000
        NOP
        STAA    $00,X
RESET_0BE
        TST     $7000
        NOP
        CLR     $01,X
        INX
        DECB
        BNE     RESET_0BE
        CPX     #$8550
        BNE     RESET_0B6
        LDX     #$0060
RESET_0D0
        CLR     $00,X
        INX
        CPX     #$00D9
        BNE     RESET_0D0
        LDAA    #$0D
        STAA    $C8
        LDAA    #$20
        STAA    $C9
        LDAA    #$90
        TST     $7000
        NOP
        STAA    $8027
        JMP     RESET_1B8
RESET_0EC
        LDX     #$801B
RESET_0EF
        TST     $7000
        NOP
        LDAA    $00,X
        INCA
        CMPA    #$39
        BHI     RESET_102
        TST     $7000
        NOP
        STAA    $00,X
        BRA     RESET_110
RESET_102
        LDAA    #$30
        TST     $7000
        NOP
        STAA    $00,X
        DEX
        CPX     #$8016
        BNE     RESET_0EF
RESET_110
        DECB
        BNE     RESET_0EC
        RTS
RESET_114
        INX
RESET_115
        LDS     #$003F
        TST     $7000
        NOP
        STAA    $00,X
        LDAA    #$10
RESET_120
        PSHA
        JSR     BEEP
        PULA
        LDX     #$0D00
RESET_128
        DEX
        BNE     RESET_128
        DECA
        BNE     RESET_120
        JMP     ENTRY_26F
RESET_131
        LDAA    #$69
        TST     $7000
        NOP
        STAA    $00,X
        STX     $F4
        DEX
        CPX     $CA
        BEQ     RESET_115
        INX
        CPX     $CA
        BEQ     RESET_114
        CPX     $82
        BEQ     RESET_1A4
        CPX     $8A
        BEQ     RESET_1A8
        CPX     $92
        BEQ     RESET_1AC
RESET_151
        LDX     $F0
        CLR     $06,X
        CLR     $07,X
        CLR     $02,X
        CLR     $03,X
        LDX     #$0060
RESET_15E
        LDAA    $02,X
        CMPA    $F4
        BNE     RESET_16A
        LDAA    $03,X
        CMPA    $F5
        BEQ     RESET_177
RESET_16A
        LDAB    #$08
RESET_16C
        INX
        DECB
        BNE     RESET_16C
        CPX     #$00C8
        BNE     RESET_15E
        BRA     RESET_19B
RESET_177
        CLR     $06,X
        CLR     $07,X
        LDX     #$00D0
RESET_17E
        TST     $02,X
        BNE     RESET_18E
        LDAA    $F4
        STAA    $00,X
        LDAA    $F5
        STAA    $01,X
        INC     $02,X
        BRA     RESET_198
RESET_18E
        INX
        INX
        INX
        CPX     #$00D9
        BNE     RESET_17E
        BRA     RESET_19B
RESET_198
        JMP     BEEP
RESET_19B
        LDX     $F4
        TST     $7000
        NOP
        CLR     $00,X
        RTS
RESET_1A4
        LDAB    #$0F
        BRA     RESET_1AE
RESET_1A8
        LDAB    #$19
        BRA     RESET_1AE
RESET_1AC
        LDAB    #$23
RESET_1AE
        PSHB
        BSR     RESET_151
        PULB
        JMP     RESET_0EC
        FCB     $43,$19,$82
RESET_1B8
        LDAA    #$01
        BITA    $CF
        BNE     RESET_1C1
        JSR     SCRDRAW
RESET_1C1
        LDX     #$00D0
RESET_1C4
        STX     $F0
        TST     $02,X
        BEQ     RESET_1DE
        LDAA    #$02
        BITA    $02,X
        BNE     RESET_1DC
        CLR     $02,X
        LDX     $00,X
        TST     $7000
        NOP
        CLR     $00,X
        BRA     RESET_1DE
RESET_1DC
        INC     $02,X
RESET_1DE
        LDX     $F0
        INX
        INX
        INX
        CPX     #$00D9
        BNE     RESET_1C4
        FCB     $7C,$00,$CF
        LDAA    #$01
        BITA    $CF
        BNE     RESET_1F4
        JMP     RESET_328
RESET_1F4
        LDX     $C8
        STX     $F0
        LDAA    #$01
        BITA    $CE
        BNE     RESET_22A
        LDAA    #$52
        LDAB    $C8
        ANDB    #$7F
        STAA    $7800
        TST     $7800
        BPL     RESET_213
        CMPB    #$10
        BEQ     RESET_211
        INCB
RESET_211
        BRA     RESET_221
RESET_213
        INCA
        STAA    $7800
        TST     $7800
        BPL     RESET_22A
        CMPB    #$0A
        BEQ     RESET_221
        DECB
RESET_221
        FCB     $7D,$00,$C8
        BPL     RESET_228
        ORAB    #$80
RESET_228
        STAB    $C8
RESET_22A
        FCB     $7C,$00,$CE
        LDAA    #$01
        BITA    $CE
        BNE     RESET_272
        LDAA    #$55
        STAA    $7800
        TST     $7800
        BPL     RESET_252
        LDAB    $C8
        ANDB    #$7F
        STAB    $C8
        LDAB    #$01
        BITB    $CE
        BNE     RESET_28F
        LDAB    $C9
        CMPB    #$28
        BCC     RESET_250
        INCB
RESET_250
        BRA     RESET_26E
RESET_252
        DECA
        STAA    $7800
        TST     $7800
        BPL     RESET_272
        LDAB    $C8
        ORAB    #$80
        STAB    $C8
        LDAB    #$01
        BITB    $CE
        BNE     RESET_28F
        LDAB    $C9
        CMPB    #$28
        BCS     RESET_26E
        DECB
RESET_26E
        STAB    $C9
        BRA     RESET_28F
RESET_272
        LDAB    #$03
        BITB    $CE
        BNE     RESET_292
        LDAB    $C9
        FCB     $7D,$00,$C8
        BMI     RESET_286
        CMPB    #$10
        BEQ     RESET_284
        DECB
RESET_284
        BRA     RESET_28B
RESET_286
        CMPB    #$3A
        BEQ     RESET_28B
        INCB
RESET_28B
        STAB    $C9
        BRA     RESET_292
RESET_28F
        FCB     $78,$00,$CF
RESET_292
        LDX     $C8
        CPX     $F0
        BEQ     RESET_2D2
        LDX     $CA
        STX     $CC
        LDX     #$00C8
        JSR     POSADR
        LDX     $04,X
        TST     $7000
        NOP
        CLR     $00,X
        TST     $7000
        NOP
        CLR     $01,X
        LDX     $CA
        LDAA    #$2D
        FCB     $7D,$00,$C8
        BMI     RESET_2C3
        TST     $7000
        NOP
        STAA    $01,X
        LDAA    #$29
        BRA     RESET_2CC
RESET_2C3
        TST     $7000
        NOP
        STAA    $00,X
        INX
        LDAA    #$28
RESET_2CC
        TST     $7000
        NOP
        STAA    $00,X
RESET_2D2
        LDAA    #$AF
        BITA    $CE
        BNE     RESET_2E5
        LDX     #$0098
        STX     $F2
        LDX     #$0080
        STX     $F0
        JSR     FINDOBJ
RESET_2E5
        LDX     #$00C8
        STX     $F2
        LDX     #$0060
        STX     $F0
        BSR     RESET_331
        LDAA    #$01
        BITA    $CE
        BEQ     RESET_304
        LDX     #$0098
        STX     $F2
        LDX     #$0080
        STX     $F0
        JSR     PROCOBJ
RESET_304
        LDAA    #$09
        STAA    $7800
        TST     $7800
        BPL     RESET_30F
        SWI
RESET_30F
        LDAA    #$40
        STAA    $7800
        TST     $7800
        BPL     RESET_328
        LDX     #$0080
        STX     $F2
        LDX     #$0060
        STX     $F0
        LDAA    #$2D
        JSR     FINDOBJ
RESET_328
        LDX     #$1200
RESET_32B
        DEX
        BNE     RESET_32B
        JMP     RESET_1B8
RESET_331
        LDAA    $06,X
        BEQ     RESET_337
        BSR     RESET_33F
RESET_337
        JSR     NEXTOBJ
        CPX     $F2
        BNE     $E5FE
        RTS
RESET_33F
        CMPA    #$2D
        BEQ     RESET_3B8
        LDAB    #$01
        BITB    $CE
        BNE     RESET_379
        LDAB    $00,X
        TSTB
        BMI     RESET_364
        ANDA    #$07
        ASLA
        ASLA
        BITA    $CE
        BNE     RESET_35D
        CMPB    #$0A
        BEQ     RESET_35B
        DECB
RESET_35B
        BRA     RESET_377
RESET_35D
        CMPB    #$10
        BEQ     RESET_362
        INCB
RESET_362
        BRA     RESET_377
RESET_364
        FCB     $7D,$00,$C8
        BMI     RESET_36B
        ANDB    #$7F
RESET_36B
        CMPB    $C8
        BEQ     $E645
        BCS     RESET_374
        DECB
        BRA     RESET_375
RESET_374
        INCB
RESET_375
        ORAB    #$80
RESET_377
        STAB    $00,X
RESET_379
        TST     $07,X
        BEQ     RESET_389
        LDX     $04,X
        TST     $7000
        NOP
        CLR     $00,X
        LDX     $F0
        BRA     RESET_38C
RESET_389
        INC     $07,X
        RTS
RESET_38C
        LDAA    $06,X
        LDAB    $01,X
        TSTB
        BNE     RESET_39C
RESET_393
        CMPA    #$2D
        BNE     RESET_399
        CLR     $06,X
RESET_399
        CLR     $07,X
        RTS
RESET_39C
        CMPB    #$4F
        BCC     RESET_393
        BSR     POSADR
        LDAA    $06,X
        LDX     $02,X
        TST     $7000
        NOP
        TST     $00,X
        BEQ     RESET_3B1
        JMP     RESET_131
RESET_3B1
        TST     $7000
        NOP
        STAA    $00,X
        RTS
RESET_3B8
        TST     $00,X
        BMI     RESET_3C0
        INC     $01,X
        BRA     RESET_379
RESET_3C0
        DEC     $01,X
        BRA     RESET_379
POSADR
        LDAA    $00,X
        ANDA    #$7F
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
        ADDA    $01,X
        ADCB    #$80
        STAA    $03,X
        STAB    $02,X
        RTS
SCRDRAW
        FCB     $7D,$00,$C8
        BMI     SCRDRAW_02B
        LDX     #$8731
SCRDRAW_008
        TST     $7000
        NOP
        LDAA    $01,X
        TST     $7000
        NOP
        STAA    $00,X
        INX
        CPX     #$877F
        BNE     SCRDRAW_008
        LDAB    #$01
        BITB    $CE
        BNE     SCRDRAW_029
        FCB     $7A,$00,$81,$7A,$00,$89,$7A,$00
        FCB     $91
SCRDRAW_029
        BRA     SCRDRAW_050
SCRDRAW_02B
        LDX     #$877E
SCRDRAW_02E
        TST     $7000
        NOP
        LDAA    $00,X
        TST     $7000
        NOP
        STAA    $01,X
        DEX
        CPX     #$8730
        BNE     SCRDRAW_02E
        INX
        LDAB    #$01
        BITB    $CE
        BNE     SCRDRAW_050
        FCB     $7C,$00,$81,$7C,$00,$89,$7C,$00
        FCB     $91
SCRDRAW_050
        LDAB    #$5F
        LDAA    #$0A
        BITA    $CE
        BEQ     SCRDRAW_059
        DECB
SCRDRAW_059
        TST     $7000
        NOP
        STAB    $00,X
        LDX     #$0060
        STX     $F0
SCRDRAW_064
        LDAA    $02,X
        STAA    $04,X
        LDAA    $03,X
        STAA    $05,X
        BSR     NEXTOBJ
        CPX     #$00C8
        BNE     SCRDRAW_064
        RTS
NEXTOBJ
        LDX     $F0
        LDAB    #$08
NEXTOBJ_004
        INX
        DECB
        BNE     NEXTOBJ_004
        STX     $F0
        RTS
        FCB     $DF,$F0
FINDOBJ
        TST     $06,X
        BEQ     FINDOBJ_00B
        BSR     NEXTOBJ
        CPX     $F2
        BNE     FINDOBJ
        RTS
FINDOBJ_00B
        STAA    $06,X
        CMPA    #$2D
        BEQ     FINDOBJ_02F
        LDAA    $F1
        LSRA
        LSRA
        ORAA    #$40
        STAA    $06,X
        LDAB    #$0D
        CMPA    #$60
        BNE     FINDOBJ_021
        ORAB    #$80
FINDOBJ_021
        STAB    $00,X
        LDAA    #$68
        FCB     $7D,$00,$C8
        BPL     FINDOBJ_02C
        ORAA    #$80
FINDOBJ_02C
        STAA    $01,X
        RTS
FINDOBJ_02F
        LDAA    $C8
        STAA    $00,X
        LDAA    $C9
        TST     $00,X
        BMI     FINDOBJ_03A
        INCA
FINDOBJ_03A
        STAA    $01,X
        RTS
PROCOBJ
        LDAA    $06,X
        BEQ     PROCOBJ_006
        BSR     PROCOBJ_00D
PROCOBJ_006
        BSR     NEXTOBJ
        CPX     $F2
        BNE     PROCOBJ
        RTS
PROCOBJ_00D
        LDAB    $01,X
        TSTB
        BNE     PROCOBJ_013
PROCOBJ_012
        RTS
PROCOBJ_013
        CMPB    #$4F
        BCC     PROCOBJ_012
        LDAA    #$2D
        BITB    #$07
        BNE     PROCOBJ_012
        TST     $1E,X
        BEQ     PROCOBJ_026
        TST     $36,X
        BEQ     PROCOBJ_039
        RTS
PROCOBJ_026
        STAA    $1E,X
        LDAA    $00,X
        ANDA    #$7F
        LDAB    $01,X
        STAB    $19,X
        CMPB    $C9
        BCS     PROCOBJ_036
        ORAA    #$80
PROCOBJ_036
        STAA    $18,X
        RTS
PROCOBJ_039
        STAA    $36,X
        LDAA    $00,X
        ANDA    #$7F
        LDAB    $01,X
        STAB    $31,X
        CMPB    $C9
        BCS     PROCOBJ_049
        ORAA    #$80
PROCOBJ_049
        STAA    $30,X
        RTS
        FCB     $53,$48,$55,$54,$54,$4C,$45,$20
        FCB     $41,$54,$54,$41,$43,$4B,$20,$56
        FCB     $2E,$32,$43,$4F,$50,$59,$52,$49
        FCB     $47,$48,$54,$20,$28,$43,$29,$20
        FCB     $31,$39,$38,$32,$55,$4E,$41,$55
        FCB     $54,$48,$4F,$52,$49,$5A,$45,$44
        FCB     $20,$52,$45,$50,$52,$4F,$44,$55
        FCB     $43,$54,$49,$4F,$4E,$20,$50,$52
        FCB     $4F,$48,$49,$42,$49,$54,$45,$44
        FCB     $2E

        END