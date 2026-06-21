; =============================================================================
; ADM-31 ROM B  ($E800-$EFFF)  --  129867-67.bin
; 2KB system firmware: cold-boot/RESET, hardware init, escape-command dispatch
; table, serial/printer IRQ service, and screen-write primitives.
;
; Full byte-exact 6800 disassembly; reassembles identically with crasm.
; Code traced from RESET ($E800), IRQ ($ED83), the dispatch table, and the
; cross-ROM entry points referenced by ROM C/ROM D.  DB/DW used only for
; genuine data: strings, keyboard table, dispatch pointer table, and padding.
;
;   Assemble:  crasm -o romb.srec romb.asm
;   Raw image: srec_cat romb.srec -o romb.bin -binary   (-> $E800-$EFFF, 2KB)
;   Verify:    python3 verify_romb.py
;
; Disassembled by Mickey W. Lawless
; =============================================================================

        

; --- Hardware registers (manual Table 4-1 chip selects) ---
HALT             EQU     $7000
PIA1_DA          EQU     $7800
PIA1_CRA         EQU     $7801
PIA1_DB          EQU     $7802
PIA1_CRB         EQU     $7803
SW_BNK2          EQU     $7900
ACIA_CS          EQU     $7A00
ACIA_DA          EQU     $7A01
PERROM           EQU     $7B00
PRNTER           EQU     $7C00
PRNTER_01        EQU     $7C01
SW_BNK3          EQU     $7D00
SW_BNK1          EQU     $7E00
VTAC             EQU     $7F00
VTAC_06          EQU     $7F06
VTAC_0A          EQU     $7F0A
VTAC_0C          EQU     $7F0C
VTAC_0E          EQU     $7F0E
CRTRAM           EQU     $8000
CRTRAM_84        EQU     $8084

; --- Zero-page RAM variables ---
ZP_00            EQU     $00
ZP_0E            EQU     $0E
ZP_11            EQU     $11
ZP_13            EQU     $13
ZP_15            EQU     $15
ZP_1D            EQU     $1D
ZP_41            EQU     $41
ZP_43            EQU     $43
ZP_45            EQU     $45
ZP_4C            EQU     $4C
ZP_57            EQU     $57
ZP_65            EQU     $65
ZP_67            EQU     $67
ZP_69            EQU     $69
ZP_6B            EQU     $6B
ZP_6D            EQU     $6D
ZP_6F            EQU     $6F
ZP_73            EQU     $73
ZP_9D            EQU     $9D
ZP_9E            EQU     $9E
ZP_9F            EQU     $9F
ZP_A0            EQU     $A0
ZP_A1            EQU     $A1
ZP_A3            EQU     $A3
ZP_A5            EQU     $A5
ZP_A6            EQU     $A6
ZP_A7            EQU     $A7
ZP_A8            EQU     $A8
ZP_A9            EQU     $A9
ZP_AA            EQU     $AA
ZP_AB            EQU     $AB
ZP_AC            EQU     $AC
ZP_AD            EQU     $AD
ZP_AE            EQU     $AE
ZP_AF            EQU     $AF
ZP_B1            EQU     $B1
ZP_B3            EQU     $B3
ZP_B9            EQU     $B9
ZP_BA            EQU     $BA
ZP_BF            EQU     $BF
ZP_C0            EQU     $C0
ZP_CE            EQU     $CE
ZP_D2            EQU     $D2
ZP_DB            EQU     $DB

        ORG      $E800

        SEI                         ; $E800  0F
        STAA    VTAC_0E             ; $E801  B7 7F 0E
        STAA    VTAC_0A             ; $E804  B7 7F 0A
        LDX     #$7F00              ; $E807  CE 7F 00
        LDAA    #$65                ; $E80A  86 65
        STAA    $00,X               ; $E80C  A7 00
        LDAA    #$44                ; $E80E  86 44
        STAA    $01,X               ; $E810  A7 01
        LDAA    #$5D                ; $E812  86 5D
        STAA    $02,X               ; $E814  A7 02
        LDAA    SW_BNK1             ; $E816  B6 7E 00
        ANDA    #$02                ; $E819  84 02
        BEQ     L_E827              ; $E81B  27 0A
        LDAA    #$20                ; $E81D  86 20
        STAA    $04,X               ; $E81F  A7 04
        LDAA    #$14                ; $E821  86 14
        STAA    $05,X               ; $E823  A7 05
        BRA     L_E82F              ; $E825  20 08
L_E827
        LDAA    #$40                ; $E827  86 40
        STAA    $04,X               ; $E829  A7 04
        LDAA    #$35                ; $E82B  86 35
        STAA    $05,X               ; $E82D  A7 05
L_E82F
        LDAA    #$17                ; $E82F  86 17
        STAA    $03,X               ; $E831  A7 03
        STAA    $06,X               ; $E833  A7 06
        STAA    ZP_15               ; $E835  97 15
        CLRA                        ; $E837  4F
        STAA    $0D,X               ; $E838  A7 0D
        STAA    $0C,X               ; $E83A  A7 0C
        STAA    $0E,X               ; $E83C  A7 0E
        LDS     #$03FF              ; $E83E  8E 03 FF
        CLR     $8F80               ; $E841  7F 8F 80
        CLR     $8F81               ; $E844  7F 8F 81
        LDX     #$03FF              ; $E847  CE 03 FF
        LDAB    #$AA                ; $E84A  C6 AA
L_E84C
        STAB    $00,X               ; $E84C  E7 00
        DEX                         ; $E84E  09
        BNE     L_E84C              ; $E84F  26 FB
        LDX     #$03FF              ; $E851  CE 03 FF
L_E854
        LDAB    #$AA                ; $E854  C6 AA
        CMPB    $00,X               ; $E856  E1 00
        BNE     L_E86A              ; $E858  26 10
        COMB                        ; $E85A  53
        STAB    $00,X               ; $E85B  E7 00
        CMPB    $00,X               ; $E85D  E1 00
        BNE     L_E86A              ; $E85F  26 09
L_E861
        CLR     $00,X               ; $E861  6F 00
        DEX                         ; $E863  09
        BNE     L_E854              ; $E864  26 EE
        CLR     $00,X               ; $E866  6F 00
        BRA     L_E874              ; $E868  20 0A
L_E86A
        LDAA    $00,X               ; $E86A  A6 00
        STAA    $8F81               ; $E86C  B7 8F 81
        STAB    $8F80               ; $E86F  F7 8F 80
        BRA     L_E861              ; $E872  20 ED
L_E874
        LDAA    $8F81               ; $E874  B6 8F 81
        PSHA                        ; $E877  36
        LDAA    $8F80               ; $E878  B6 8F 80
        PSHA                        ; $E87B  36
        LDX     #$8FFF              ; $E87C  CE 8F FF
        LDAB    #$AA                ; $E87F  C6 AA
L_E881
        STAB    $00,X               ; $E881  E7 00
        DEX                         ; $E883  09
        CPX     #$8000              ; $E884  8C 80 00
        BNE     L_E881              ; $E887  26 F8
        LDX     #$8FFF              ; $E889  CE 8F FF
L_E88C
        LDAB    #$AA                ; $E88C  C6 AA
        CMPB    $00,X               ; $E88E  E1 00
        BNE     L_E8A3              ; $E890  26 11
        COMB                        ; $E892  53
        STAB    $00,X               ; $E893  E7 00
        CMPB    $00,X               ; $E895  E1 00
        BNE     L_E8A3              ; $E897  26 0A
L_E899
        CLR     $00,X               ; $E899  6F 00
        DEX                         ; $E89B  09
        CPX     #$8000              ; $E89C  8C 80 00
        BNE     L_E88C              ; $E89F  26 EB
        BRA     L_E8AB              ; $E8A1  20 08
L_E8A3
        LDAA    $00,X               ; $E8A3  A6 00
        STAA    ZP_BA               ; $E8A5  97 BA
        STAB    ZP_B9               ; $E8A7  D7 B9
        BRA     L_E899              ; $E8A9  20 EE
L_E8AB
        LDAA    ZP_BA               ; $E8AB  96 BA
        PSHA                        ; $E8AD  36
        LDAA    ZP_B9               ; $E8AE  96 B9
        PSHA                        ; $E8B0  36
        CLRA                        ; $E8B1  4F
        LDX     #$E800              ; $E8B2  CE E8 00
L_E8B5
        EORA    $00,X               ; $E8B5  A8 00
        INX                         ; $E8B7  08
        BNE     L_E8B5              ; $E8B8  26 FB
        PSHA                        ; $E8BA  36
        LDX     $E000               ; $E8BB  FE E0 00
        CPX     #$544A              ; $E8BE  8C 54 4A
        BNE     L_E8D0              ; $E8C1  26 0D
        LDAA    SW_BNK3             ; $E8C3  B6 7D 00
        BMI     L_E8D0              ; $E8C6  2B 08
        INC     $0000               ; $E8C8  7C 00 00
        JSR     $E07D               ; $E8CB  BD E0 7D
        BRA     L_E8D4              ; $E8CE  20 04
L_E8D0
        LDAA    #$1D                ; $E8D0  86 1D
        STAA    ZP_DB               ; $E8D2  97 DB
L_E8D4
        LDX     #$7800              ; $E8D4  CE 78 00
        CLR     $01,X               ; $E8D7  6F 01
        CLR     $03,X               ; $E8D9  6F 03
        LDAA    #$7F                ; $E8DB  86 7F
        STAA    $00,X               ; $E8DD  A7 00
        LDAA    #$1D                ; $E8DF  86 1D
        STAA    $02,X               ; $E8E1  A7 02
        LDAA    #$3C                ; $E8E3  86 3C
        STAA    $01,X               ; $E8E5  A7 01
        STAA    $03,X               ; $E8E7  A7 03
        LDAA    #$01                ; $E8E9  86 01
        STAA    $00,X               ; $E8EB  A7 00
        STAA    $02,X               ; $E8ED  A7 02
        LDAA    #$43                ; $E8EF  86 43
        STAA    ACIA_CS             ; $E8F1  B7 7A 00
        STAA    PRNTER              ; $E8F4  B7 7C 00
        LDAA    SW_BNK1             ; $E8F7  B6 7E 00
        TAB                         ; $E8FA  16
        ANDA    #$1C                ; $E8FB  84 1C
        ORAA    #$C1                ; $E8FD  8A C1
        STAA    ZP_BF               ; $E8FF  97 BF
        STAA    ACIA_CS             ; $E901  B7 7A 00
        COMB                        ; $E904  53
        ANDB    #$20                ; $E905  C4 20
        ASLB                        ; $E907  58
        ASLB                        ; $E908  58
        STAB    ZP_CE               ; $E909  D7 CE
        LDAA    SW_BNK2             ; $E90B  B6 79 00
        ANDA    #$1C                ; $E90E  84 1C
        ORAA    #$41                ; $E910  8A 41
        STAA    ZP_C0               ; $E912  97 C0
        STAA    PRNTER              ; $E914  B7 7C 00
        LDAA    #$17                ; $E917  86 17
        LDX     #$8000              ; $E919  CE 80 00
        STX     ZP_11               ; $E91C  DF 11
        STX     ZP_13               ; $E91E  DF 13
        STAA    ZP_15               ; $E920  97 15
        STX     $87D0               ; $E922  FF 87 D0
        STX     $87D2               ; $E925  FF 87 D2
        STAA    $87D4               ; $E928  B7 87 D4
        LDX     #$8800              ; $E92B  CE 88 00
        STX     $8FD0               ; $E92E  FF 8F D0
        STX     $8FD2               ; $E931  FF 8F D2
        STAA    $8FD4               ; $E934  B7 8F D4
        JSR     L_ED7B              ; $E937  BD ED 7B
        JSR     $FD6A               ; $E93A  BD FD 6A
        LDX     #$0045              ; $E93D  CE 00 45
        STX     ZP_B1               ; $E940  DF B1
        LDX     $7B1E               ; $E942  FE 7B 1E
        CPX     #$3046              ; $E945  8C 30 46
        BNE     L_E94F              ; $E948  26 05
        LDX     #$7B00              ; $E94A  CE 7B 00
        BRA     L_E95B              ; $E94D  20 0C
L_E94F
        LDAA    ZP_00               ; $E94F  96 00
        BNE     L_E958              ; $E951  26 05
        LDX     #$E9F8              ; $E953  CE E9 F8
        BRA     L_E95B              ; $E956  20 03
L_E958
        LDX     #$E530              ; $E958  CE E5 30
L_E95B
        STX     ZP_43               ; $E95B  DF 43
        STX     ZP_B3               ; $E95D  DF B3
        LDAB    #$1E                ; $E95F  C6 1E
        JSR     $F6BB               ; $E961  BD F6 BB
        DB      $B6,$00,$4D                         ; $E964  B6 00 4D  LDAA $004D (EXT<$100)
        DB      $F6,$00,$55                         ; $E967  F6 00 55  LDAB $0055 (EXT<$100)
        BITB    #$40                ; $E96A  C5 40
        BNE     L_E970              ; $E96C  26 02
        LDAA    #$20                ; $E96E  86 20
L_E970
        PSHA                        ; $E970  36
        JSR     $F65E               ; $E971  BD F6 5E
        JSR     $F790               ; $E974  BD F7 90
        DB      $B6,$00,$52                         ; $E977  B6 00 52  LDAA $0052 (EXT<$100)
        JSR     $F556               ; $E97A  BD F5 56
        JSR     $F65E               ; $E97D  BD F6 5E
        JSR     $F790               ; $E980  BD F7 90
        DB      $B6,$00,$52                         ; $E983  B6 00 52  LDAA $0052 (EXT<$100)
        JSR     $F556               ; $E986  BD F5 56
        PULA                        ; $E989  32
        TSX                         ; $E98A  30
        LDAA    $01,X               ; $E98B  A6 01
        ORAA    $03,X               ; $E98D  AA 03
        ORAA    $00,X               ; $E98F  AA 00
        BEQ     L_E9D5              ; $E991  27 42
        LDX     #$E9BD              ; $E993  CE E9 BD
        BSR     L_E9CA              ; $E996  8D 32
        JSR     $F313               ; $E998  BD F3 13
        TSX                         ; $E99B  30
        LDAB    #$05                ; $E99C  C6 05
        JSR     $F1D0               ; $E99E  BD F1 D0
        PULA                        ; $E9A1  32
        PULA                        ; $E9A2  32
        PULA                        ; $E9A3  32
        PULA                        ; $E9A4  32
        PULA                        ; $E9A5  32
L_E9A6
        JSR     L_EF8B              ; $E9A6  BD EF 8B
        TST     $00AE               ; $E9A9  7D 00 AE
        BPL     L_E9A6              ; $E9AC  2A F8
        BRA     L_E9DA              ; $E9AE  20 2A
; --- String table: "Test Complete" / "MEMORY ERROR " ($E9B0-$E9C9) ---
        DB      $54,$65,$73,$74,$20,$43,$6F,$6D     ; $E9B0  Test Com
        DB      $70,$6C,$65,$74,$65,$4D,$45,$4D     ; $E9B8  pleteMEM
        DB      $4F,$52,$59,$20,$45,$52,$52,$4F     ; $E9C0  ORY ERRO
        DB      $52,$20                             ; $E9C8  R 
L_E9CA
        STX     ZP_B3               ; $E9CA  DF B3
        LDAB    #$0D                ; $E9CC  C6 0D
        LDX     ZP_13               ; $E9CE  DE 13
        STX     ZP_B1               ; $E9D0  DF B1
        JMP     $F6BB               ; $E9D2  7E F6 BB
L_E9D5
        LDX     #$E9B0              ; $E9D5  CE E9 B0
        BSR     L_E9CA              ; $E9D8  8D F0
L_E9DA
        DB      $B6,$00,$56                         ; $E9DA  B6 00 56  LDAA $0056 (EXT<$100)
        TAB                         ; $E9DD  16
        ANDA    #$01                ; $E9DE  84 01
        STAA    PIA1_DB             ; $E9E0  B7 78 02
        BITB    #$08                ; $E9E3  C5 08
        BEQ     L_E9EA              ; $E9E5  27 03
        JSR     $F0B3               ; $E9E7  BD F0 B3
L_E9EA
        LDAA    SW_BNK1             ; $E9EA  B6 7E 00
        ANDA    #$C0                ; $E9ED  84 C0
        STAA    ZP_41               ; $E9EF  97 41
        JSR     $F143               ; $E9F1  BD F1 43
        JMP     L_EBF8              ; $E9F4  7E EB F8
; --- Init/parameter table + keyboard scancode table ($E9F7-$EAC9) ---
        DB      $03,$1B,$0D,$00,$00,$00,$00,$01     ; $E9F7  ........
        DB      $00,$20,$00,$00,$00,$00,$00,$02     ; $E9FF  . ......
        DB      $F0,$03,$01,$00,$00,$00,$00,$00     ; $EA07  ........
        DB      $00,$00,$00,$00,$00,$00,$00,$00     ; $EA0F  ........
        DB      $00,$03,$80,$D1,$D1,$D7,$D7,$C5     ; $EA17  ........
        DB      $C5,$D2,$D2,$D4,$F4,$D9,$F9,$32     ; $EA1F  .......2
        DB      $22,$1B,$1B,$7F,$7F,$9E,$9F,$D0     ; $EA27  ".......
        DB      $F0,$B4,$B6,$92,$93,$31,$21,$71     ; $EA2F  .....1!q
        DB      $51,$98,$98,$33,$23,$34,$24,$35     ; $EA37  Q..3#4$5
        DB      $25,$36,$26,$37,$27,$38,$28,$39     ; $EA3F  %6&7'8(9
        DB      $29,$30,$5F,$2D,$3D,$5E,$7E,$5C     ; $EA47  )0_-=^~\
        DB      $7C,$09,$C9,$87,$87,$88,$88,$89     ; $EA4F  |.......
        DB      $89,$2D,$2D,$77,$57,$65,$45,$72     ; $EA57  .--wWeEr
        DB      $52,$74,$54,$79,$59,$75,$55,$69     ; $EA5F  RtTyYuUi
        DB      $49,$6F,$4F,$70,$50,$5B,$7B,$5D     ; $EA67  IoOpP[{]
        DB      $7D,$0D,$0D,$84,$84,$85,$85,$86     ; $EA6F  }.......
        DB      $86,$09,$09,$61,$41,$73,$53,$64     ; $EA77  ...aAsSd
        DB      $44,$66,$46,$67,$47,$68,$48,$6A     ; $EA7F  DfFgGhHj
        DB      $4A,$6B,$4B,$6C,$4C,$3B,$2B,$3A     ; $EA87  JkKlL;+:
        DB      $2A,$40,$60,$0A,$0A,$82,$82,$83     ; $EA8F  *@`.....
        DB      $83,$81,$81,$90,$91,$7A,$5A,$78     ; $EA97  .....zZx
        DB      $58,$63,$43,$76,$56,$62,$42,$6E     ; $EA9F  XcCvVbBn
        DB      $4E,$6D,$4D,$2C,$3C,$2E,$3E,$2F     ; $EAA7  NmM,<.>/
        DB      $3F,$20,$20,$1F,$CA,$30,$30,$2E     ; $EAAF  ?  ..00.
        DB      $2E,$0D,$0D,$9D,$94,$1E,$1E,$0A     ; $EAB7  ........
        DB      $0A,$0B,$0B,$08,$08,$0C,$0C,$E3     ; $EABF  ........
        DB      $00,$2C,$2C                         ; $EAC7  .,,
; --- Escape/control command dispatch table ($EACA-$EBE9) ---
;     144 x 16-bit handler addresses. Default entry $EBEA = bare RTS.
;     Targets: $E8-$EF = ROM B, $F0-$F7 = ROM C, $F8-$FF = ROM D.
        DW      L_EBEA                              ; $EACA  EB EA
        DW      L_EFEA                              ; $EACC  EF EA
        DW      L_EF4A                              ; $EACE  EF 4A
        DW      L_EF4E                              ; $EAD0  EF 4E
        DW      L_EFC6                              ; $EAD2  EF C6
        DW      L_EBEA                              ; $EAD4  EB EA
        DW      L_EBEA                              ; $EAD6  EB EA
        DW      L_EBEA                              ; $EAD8  EB EA
        DW      L_EF61                              ; $EADA  EF 61
        DW      L_EBEA                              ; $EADC  EB EA
        DW      L_EBEA                              ; $EADE  EB EA
        DW      L_EBEA                              ; $EAE0  EB EA
        DW      L_EBEA                              ; $EAE2  EB EA
        DW      L_EFC6                              ; $EAE4  EF C6
        DW      L_EF6D                              ; $EAE6  EF 6D
        DW      L_EFA5                              ; $EAE8  EF A5
        DW      L_EBEA                              ; $EAEA  EB EA
        DW      L_EBEA                              ; $EAEC  EB EA
        DW      $F0AF                               ; $EAEE  F0 AF
        DW      $F0AA                               ; $EAF0  F0 AA
        DW      L_EBEA                              ; $EAF2  EB EA
        DW      L_EBEA                              ; $EAF4  EB EA
        DW      $F060                               ; $EAF6  F0 60
        DW      $F070                               ; $EAF8  F0 70
        DW      $F079                               ; $EAFA  F0 79
        DW      $F074                               ; $EAFC  F0 74
        DW      $F767                               ; $EAFE  F7 67
        DW      $F740                               ; $EB00  F7 40
        DW      $F763                               ; $EB02  F7 63
        DW      $F567                               ; $EB04  F5 67
        DW      $F0F3                               ; $EB06  F0 F3
        DW      $F9D1                               ; $EB08  F9 D1
        DW      $F501                               ; $EB0A  F5 01
        DW      $F50F                               ; $EB0C  F5 0F
        DW      $F51B                               ; $EB0E  F5 1B
        DW      $F553                               ; $EB10  F5 53
        DW      $F9B5                               ; $EB12  F9 B5
        DW      $F9BD                               ; $EB14  F9 BD
        DW      $F9B9                               ; $EB16  F9 B9
        DW      $F9C1                               ; $EB18  F9 C1
        DW      $F237                               ; $EB1A  F2 37
        DW      $F23C                               ; $EB1C  F2 3C
        DW      $F731                               ; $EB1E  F7 31
        DW      $F73B                               ; $EB20  F7 3B
        DW      L_EBEA                              ; $EB22  EB EA
        DW      $F5AA                               ; $EB24  F5 AA
        DW      L_EBEA                              ; $EB26  EB EA
        DW      $F9CD                               ; $EB28  F9 CD
        DW      $F215                               ; $EB2A  F2 15
        DW      $F221                               ; $EB2C  F2 21
        DW      $F07D                               ; $EB2E  F0 7D
        DW      $F083                               ; $EB30  F0 83
        DW      $F08A                               ; $EB32  F0 8A
        DW      $F874                               ; $EB34  F8 74
        DW      L_EBEA                              ; $EB36  EB EA
        DW      $F0E8                               ; $EB38  F0 E8
        DW      L_EBEA                              ; $EB3A  EB EA
        DW      $F458                               ; $EB3C  F4 58
        DW      $F631                               ; $EB3E  F6 31
        DW      $F631                               ; $EB40  F6 31
        DW      $F211                               ; $EB42  F2 11
        DW      L_EBEA                              ; $EB44  EB EA
        DW      L_EBEA                              ; $EB46  EB EA
        DW      L_EBEA                              ; $EB48  EB EA
        DW      $F20D                               ; $EB4A  F2 0D
        DW      $F824                               ; $EB4C  F8 24
        DW      $F912                               ; $EB4E  F9 12
        DW      $F9C5                               ; $EB50  F9 C5
        DW      $F7D5                               ; $EB52  F7 D5
        DW      $F0A1                               ; $EB54  F0 A1
        DW      L_EBEA                              ; $EB56  EB EA
        DW      $F84B                               ; $EB58  F8 4B
        DW      $F0A6                               ; $EB5A  F0 A6
        DW      $F6D5                               ; $EB5C  F6 D5
        DW      L_EBEA                              ; $EB5E  EB EA
        DW      L_EBEA                              ; $EB60  EB EA
        DW      L_EBEA                              ; $EB62  EB EA
        DW      L_EBEA                              ; $EB64  EB EA
        DW      L_EBEA                              ; $EB66  EB EA
        DW      L_EBEA                              ; $EB68  EB EA
        DW      $F22C                               ; $EB6A  F2 2C
        DW      L_EBEA                              ; $EB6C  EB EA
        DW      L_EBEA                              ; $EB6E  EB EA
        DW      L_EBEA                              ; $EB70  EB EA
        DW      L_EBEA                              ; $EB72  EB EA
        DW      L_EBEA                              ; $EB74  EB EA
        DW      L_EBEA                              ; $EB76  EB EA
        DW      L_EBEA                              ; $EB78  EB EA
        DW      L_EBEA                              ; $EB7A  EB EA
        DW      $F3AA                               ; $EB7C  F3 AA
        DW      L_EBEA                              ; $EB7E  EB EA
        DW      L_EBEA                              ; $EB80  EB EA
        DW      $F221                               ; $EB82  F2 21
        DW      $F240                               ; $EB84  F2 40
        DW      L_EBEA                              ; $EB86  EB EA
        DW      $F14E                               ; $EB88  F1 4E
        DW      $F211                               ; $EB8A  F2 11
        DW      $F0D1                               ; $EB8C  F0 D1
        DW      $F0D6                               ; $EB8E  F0 D6
        DW      $F9C9                               ; $EB90  F9 C9
        DW      $F81D                               ; $EB92  F8 1D
        DW      $F0A6                               ; $EB94  F0 A6
        DW      $F0B3                               ; $EB96  F0 B3
        DW      $F0CD                               ; $EB98  F0 CD
        DW      L_EBEA                              ; $EB9A  EB EA
        DW      $F6E1                               ; $EB9C  F6 E1
        DW      L_EBEA                              ; $EB9E  EB EA
        DW      L_EBEA                              ; $EBA0  EB EA
        DW      L_EBEA                              ; $EBA2  EB EA
        DW      L_EBEA                              ; $EBA4  EB EA
        DW      L_EBEA                              ; $EBA6  EB EA
        DW      L_EBEA                              ; $EBA8  EB EA
        DW      L_EBEA                              ; $EBAA  EB EA
        DW      L_EBEA                              ; $EBAC  EB EA
        DW      L_EBEA                              ; $EBAE  EB EA
        DW      L_EBEA                              ; $EBB0  EB EA
        DW      L_EBEA                              ; $EBB2  EB EA
        DW      $F9D5                               ; $EBB4  F9 D5
        DW      L_EBEA                              ; $EBB6  EB EA
        DW      $F0DA                               ; $EBB8  F0 DA
        DW      $F28C                               ; $EBBA  F2 8C
        DW      $F3AA                               ; $EBBC  F3 AA
        DW      $F27D                               ; $EBBE  F2 7D
        DW      $F293                               ; $EBC0  F2 93
        DW      $F272                               ; $EBC2  F2 72
        DW      $F2A1                               ; $EBC4  F2 A1
        DW      L_EBEA                              ; $EBC6  EB EA
        DW      L_EBEA                              ; $EBC8  EB EA
        DW      L_EBEA                              ; $EBCA  EB EA
        DW      L_EBEA                              ; $EBCC  EB EA
        DW      L_EBEA                              ; $EBCE  EB EA
        DW      L_EBEA                              ; $EBD0  EB EA
        DW      L_EBEA                              ; $EBD2  EB EA
        DW      L_EBEA                              ; $EBD4  EB EA
        DW      L_EBEA                              ; $EBD6  EB EA
        DW      L_EBEA                              ; $EBD8  EB EA
        DW      L_EBEA                              ; $EBDA  EB EA
        DW      L_EBEA                              ; $EBDC  EB EA
        DW      L_EBEA                              ; $EBDE  EB EA
        DW      L_EBEA                              ; $EBE0  EB EA
        DW      L_EBEA                              ; $EBE2  EB EA
        DW      L_EBEA                              ; $EBE4  EB EA
        DW      $F259                               ; $EBE6  F2 59
        DW      $F29A                               ; $EBE8  F2 9A
L_EBEA
        RTS                         ; $EBEA  39
; --- Padding after default dispatch handler (RTS @ $EBEA) ($EBEB-$EBF7) ---
        DB      $5D,$00,$00,$00,$00,$00,$00,$00     ; $EBEB  ].......
        DB      $00,$00,$00,$00,$00                 ; $EBF3  .....
L_EBF8
        LDX     #$0085              ; $EBF8  CE 00 85
        LDAA    #$80                ; $EBFB  86 80
        LDAB    #$08                ; $EBFD  C6 08
        BSR     L_EC4C              ; $EBFF  8D 4B
        LDX     #$008D              ; $EC01  CE 00 8D
        LDAB    #$08                ; $EC04  C6 08
        CLRA                        ; $EC06  4F
        BSR     L_EC4C              ; $EC07  8D 43
        LDX     #$EE06              ; $EC09  CE EE 06
        STX     ZP_65               ; $EC0C  DF 65
        LDX     #$FD27              ; $EC0E  CE FD 27
        STX     ZP_73               ; $EC11  DF 73
        LDAA    ZP_00               ; $EC13  96 00
        BNE     L_EC32              ; $EC15  26 1B
        LDX     #$EEA1              ; $EC17  CE EE A1
        STX     ZP_67               ; $EC1A  DF 67
        LDX     #$ED05              ; $EC1C  CE ED 05
        STX     ZP_69               ; $EC1F  DF 69
        LDX     #$ED58              ; $EC21  CE ED 58
        STX     ZP_6B               ; $EC24  DF 6B
        LDX     #$F9F5              ; $EC26  CE F9 F5
        STX     ZP_6D               ; $EC29  DF 6D
        LDX     #$FE03              ; $EC2B  CE FE 03
        STX     ZP_6F               ; $EC2E  DF 6F
        BRA     L_EC35              ; $EC30  20 03
L_EC32
        JSR     $E0CA               ; $EC32  BD E0 CA
L_EC35
        LDX     #$0000              ; $EC35  CE 00 00
        STX     ZP_9D               ; $EC38  DF 9D
        STX     ZP_9F               ; $EC3A  DF 9F
        LDX     #$0000              ; $EC3C  CE 00 00
        JSR     L_ECBA              ; $EC3F  BD EC BA
        LDX     #$0002              ; $EC42  CE 00 02
        JSR     L_ECBA              ; $EC45  BD EC BA
        CLI                         ; $EC48  0E
        JMP     L_EC53              ; $EC49  7E EC 53
L_EC4C
        STAA    $00,X               ; $EC4C  A7 00
        INX                         ; $EC4E  08
        DECB                        ; $EC4F  5A
        BGT     L_EC4C              ; $EC50  2E FA
        RTS                         ; $EC52  39
L_EC53
        LDX     ZP_9D               ; $EC53  DE 9D
L_EC55
        LDAA    $85,X               ; $EC55  A6 85
        BPL     L_EC8C              ; $EC57  2A 33
L_EC59
        INX                         ; $EC59  08
        CPX     #$0008              ; $EC5A  8C 00 08
        BNE     L_EC55              ; $EC5D  26 F6
        CLR     $009E               ; $EC5F  7F 00 9E
        LDAB    PIA1_DB             ; $EC62  F6 78 02
        BITB    #$02                ; $EC65  C5 02
        BNE     L_EC53              ; $EC67  26 EA
        LDAB    #$34                ; $EC69  C6 34
        STAB    PIA1_CRA            ; $EC6B  F7 78 01
        LDAB    #$3C                ; $EC6E  C6 3C
        STAB    PIA1_CRA            ; $EC70  F7 78 01
        LDX     #$0000              ; $EC73  CE 00 00
L_EC76
        LDAA    $8D,X               ; $EC76  A6 8D
        BEQ     L_EC84              ; $EC78  27 0A
        DEC     $8D,X               ; $EC7A  6A 8D
        BNE     L_EC84              ; $EC7C  26 06
        LDAA    $85,X               ; $EC7E  A6 85
        ANDA    #$7F                ; $EC80  84 7F
        STAA    $85,X               ; $EC82  A7 85
L_EC84
        INX                         ; $EC84  08
        CPX     #$0008              ; $EC85  8C 00 08
        BNE     L_EC76              ; $EC88  26 EC
        BRA     L_EC53              ; $EC8A  20 C7
L_EC8C
        STX     ZP_9D               ; $EC8C  DF 9D
        STX     ZP_9F               ; $EC8E  DF 9F
        TAB                         ; $EC90  16
        ANDA    #$7C                ; $EC91  84 7C
        STAA    $85,X               ; $EC93  A7 85
        LDAA    $95,X               ; $EC95  A6 95
        ASL     $00A0               ; $EC97  78 00 A0
        LDX     ZP_9F               ; $EC9A  DE 9F
        BITB    #$01                ; $EC9C  C5 01
        BEQ     L_ECAE              ; $EC9E  27 0E
        BITB    #$02                ; $ECA0  C5 02
        BEQ     L_ECAA              ; $ECA2  27 06
        PSHA                        ; $ECA4  36
        BSR     L_ECC1              ; $ECA5  8D 1A
        PULA                        ; $ECA7  32
        LDX     ZP_9F               ; $ECA8  DE 9F
L_ECAA
        LDX     $75,X               ; $ECAA  EE 75
        BRA     L_ECB0              ; $ECAC  20 02
L_ECAE
        LDX     $65,X               ; $ECAE  EE 65
L_ECB0
        ANDB    #$30                ; $ECB0  C4 30
        JSR     $00,X               ; $ECB2  AD 00
        LDX     ZP_9D               ; $ECB4  DE 9D
        BRA     L_EC59              ; $ECB6  20 A1
L_ECB8
        STAA    $95,X               ; $ECB8  A7 95
L_ECBA
        LDAA    $85,X               ; $ECBA  A6 85
        ANDA    #$7F                ; $ECBC  84 7F
        STAA    $85,X               ; $ECBE  A7 85
        RTS                         ; $ECC0  39
L_ECC1
        LDX     ZP_9D               ; $ECC1  DE 9D
        LDAA    $85,X               ; $ECC3  A6 85
        ORAA    #$80                ; $ECC5  8A 80
        STAA    $85,X               ; $ECC7  A7 85
        CLR     $8D,X               ; $ECC9  6F 8D
        RTS                         ; $ECCB  39
L_ECCC
        LDX     ZP_9D               ; $ECCC  DE 9D
        LDAB    $85,X               ; $ECCE  E6 85
        ORAB    #$81                ; $ECD0  CA 81
        STAA    $8D,X               ; $ECD2  A7 8D
        BNE     L_ECD8              ; $ECD4  26 02
        ANDB    #$7F                ; $ECD6  C4 7F
L_ECD8
        STAB    $85,X               ; $ECD8  E7 85
        PULA                        ; $ECDA  32
        PULB                        ; $ECDB  33
        STX     ZP_9F               ; $ECDC  DF 9F
        ASL     $00A0               ; $ECDE  78 00 A0
        LDX     ZP_9F               ; $ECE1  DE 9F
        STAA    $75,X               ; $ECE3  A7 75
        STAB    $76,X               ; $ECE5  E7 76
        RTS                         ; $ECE7  39
L_ECE8
        LDX     ZP_9D               ; $ECE8  DE 9D
        LDAB    $85,X               ; $ECEA  E6 85
        ORAB    #$83                ; $ECEC  CA 83
        BRA     L_ECD8              ; $ECEE  20 E8
L_ECF0
        LDX     ZP_9D               ; $ECF0  DE 9D
        PSHA                        ; $ECF2  36
        LDAA    $85,X               ; $ECF3  A6 85
        ANDA    #$CF                ; $ECF5  84 CF
        ANDB    #$30                ; $ECF7  C4 30
        ABA                         ; $ECF9  1B
        STAA    $85,X               ; $ECFA  A7 85
        PULA                        ; $ECFC  32
        RTS                         ; $ECFD  39
L_ECFE
        LDX     ZP_9D               ; $ECFE  DE 9D
        LDAB    $85,X               ; $ED00  E6 85
        ANDB    #$30                ; $ED02  C4 30
        RTS                         ; $ED04  39
        LDX     ZP_A1               ; $ED05  DE A1
        CPX     ZP_A3               ; $ED07  9C A3
        BEQ     L_ED57              ; $ED09  27 4C
        BSR     L_ED32              ; $ED0B  8D 25
        TST     $00D2               ; $ED0D  7D 00 D2
        BLE     L_ED1B              ; $ED10  2F 09
        JSR     $FF82               ; $ED12  BD FF 82
        LDAB    ZP_D2               ; $ED15  D6 D2
        BITB    #$02                ; $ED17  C5 02
        BEQ     L_ED57              ; $ED19  27 3C
L_ED1B
        LDX     #$0003              ; $ED1B  CE 00 03
        TSTA                        ; $ED1E  4D
        BPL     L_ED2F              ; $ED1F  2A 0E
        LDAB    ZP_4C               ; $ED21  D6 4C
        BEQ     L_ED2D              ; $ED23  27 08
        LDAB    $85,X               ; $ED25  E6 85
        ANDB    #$FE                ; $ED27  C4 FE
        STAB    $85,X               ; $ED29  E7 85
        BRA     L_ED2F              ; $ED2B  20 02
L_ED2D
        ANDA    #$7F                ; $ED2D  84 7F
L_ED2F
        JMP     L_ECB8              ; $ED2F  7E EC B8
L_ED32
        LDAA    $00,X               ; $ED32  A6 00
        TAB                         ; $ED34  16
        EORB    ZP_0E               ; $ED35  D8 0E
        STAB    ZP_0E               ; $ED37  D7 0E
        INX                         ; $ED39  08
        CPX     #$0380              ; $ED3A  8C 03 80
        BNE     L_ED42              ; $ED3D  26 03
        LDX     #$0110              ; $ED3F  CE 01 10
L_ED42
        TSTA                        ; $ED42  4D
        BPL     L_ED52              ; $ED43  2A 0D
        LDAB    $00,X               ; $ED45  E6 00
        STAB    ZP_A5               ; $ED47  D7 A5
        INX                         ; $ED49  08
        CPX     #$0380              ; $ED4A  8C 03 80
        BNE     L_ED52              ; $ED4D  26 03
        LDX     #$0110              ; $ED4F  CE 01 10
L_ED52
        STX     ZP_A1               ; $ED52  DF A1
        CLR     $00A6               ; $ED54  7F 00 A6
L_ED57
        RTS                         ; $ED57  39
        PSHA                        ; $ED58  36
        JSR     L_ECC1              ; $ED59  BD EC C1
        PULA                        ; $ED5C  32
        TSTA                        ; $ED5D  4D
        BPL     L_ED78              ; $ED5E  2A 18
        ANDA    #$7F                ; $ED60  84 7F
        LDAB    ZP_A5               ; $ED62  D6 A5
        BITB    #$10                ; $ED64  C5 10
        BNE     L_ED57              ; $ED66  26 EF
        BITB    #$60                ; $ED68  C5 60
        BEQ     L_ED78              ; $ED6A  27 0C
        LDAB    ZP_4C               ; $ED6C  D6 4C
        BEQ     L_ED78              ; $ED6E  27 08
        PSHB                        ; $ED70  37
        JSR     $F0DA               ; $ED71  BD F0 DA
        PULA                        ; $ED74  32
        JMP     $F03A               ; $ED75  7E F0 3A
L_ED78
        JMP     L_EFF6              ; $ED78  7E EF F6
L_ED7B
        LDX     #$0110              ; $ED7B  CE 01 10
        STX     ZP_A3               ; $ED7E  DF A3
        STX     ZP_A1               ; $ED80  DF A1
        RTS                         ; $ED82  39
        LDAB    ACIA_CS             ; $ED83  F6 7A 00
        BPL     L_ED8A              ; $ED86  2A 02
        BSR     L_ED93              ; $ED88  8D 09
L_ED8A
        LDAB    PRNTER              ; $ED8A  F6 7C 00
        BPL     L_ED92              ; $ED8D  2A 03
        JSR     $FFAB               ; $ED8F  BD FF AB
L_ED92
        RTI                         ; $ED92  3B
L_ED93
        BITB    #$01                ; $ED93  C5 01
        BEQ     L_EDEF              ; $ED95  27 58
        LDAA    ACIA_DA             ; $ED97  B6 7A 01
        ANDA    #$7F                ; $ED9A  84 7F
        ANDB    #$70                ; $ED9C  C4 70
        BEQ     L_EDA9              ; $ED9E  27 09
        BITB    #$10                ; $EDA0  C5 10
        BEQ     L_EDA7              ; $EDA2  27 03
        STAB    ZP_A8               ; $EDA4  D7 A8
        RTS                         ; $EDA6  39
L_EDA7
        ORAA    #$80                ; $EDA7  8A 80
L_EDA9
        TST     $00A8               ; $EDA9  7D 00 A8
        BEQ     L_EDB2              ; $EDAC  27 04
        CLR     $00A8               ; $EDAE  7F 00 A8
        RTS                         ; $EDB1  39
L_EDB2
        TST     $00A6               ; $EDB2  7D 00 A6
        BMI     L_EDE8              ; $EDB5  2B 31
        LDX     ZP_A3               ; $EDB7  DE A3
        STAA    $00,X               ; $EDB9  A7 00
        INX                         ; $EDBB  08
        CPX     #$0380              ; $EDBC  8C 03 80
        BNE     L_EDC4              ; $EDBF  26 03
        LDX     #$0110              ; $EDC1  CE 01 10
L_EDC4
        STX     ZP_A3               ; $EDC4  DF A3
        TSTA                        ; $EDC6  4D
        BPL     L_EDD6              ; $EDC7  2A 0D
        STAB    $00,X               ; $EDC9  E7 00
        INX                         ; $EDCB  08
        CPX     #$0380              ; $EDCC  8C 03 80
        BNE     L_EDD4              ; $EDCF  26 03
        LDX     #$0110              ; $EDD1  CE 01 10
L_EDD4
        STX     ZP_A3               ; $EDD4  DF A3
L_EDD6
        INX                         ; $EDD6  08
        CPX     #$0380              ; $EDD7  8C 03 80
        BNE     L_EDDF              ; $EDDA  26 03
        LDX     #$0110              ; $EDDC  CE 01 10
L_EDDF
        CPX     ZP_A1               ; $EDDF  9C A1
        BNE     L_EDE7              ; $EDE1  26 04
        LDAA    #$80                ; $EDE3  86 80
        STAA    ZP_A6               ; $EDE5  97 A6
L_EDE7
        RTS                         ; $EDE7  39
L_EDE8
        LDAA    #$80                ; $EDE8  86 80
        STAA    ZP_A7               ; $EDEA  97 A7
        JMP     $F0DA               ; $EDEC  7E F0 DA
L_EDEF
        BITB    #$02                ; $EDEF  C5 02
        BEQ     L_EDFE              ; $EDF1  27 0B
        LDAA    ZP_BF               ; $EDF3  96 BF
        ANDA    #$60                ; $EDF5  84 60
        CMPA    #$20                ; $EDF7  81 20
        BNE     L_EDFE              ; $EDF9  26 03
        JMP     $FD85               ; $EDFB  7E FD 85
L_EDFE
        BITB    #$04                ; $EDFE  C5 04
        BEQ     L_EE05              ; $EE00  27 03
        LDAA    ACIA_DA             ; $EE02  B6 7A 01
L_EE05
        RTS                         ; $EE05  39
        LDAB    #$04                ; $EE06  C6 04
L_EE08
        LDAA    ZP_A9               ; $EE08  96 A9
        STAA    PIA1_DA             ; $EE0A  B7 78 00
        LDAA    PIA1_DA             ; $EE0D  B6 78 00
        BMI     L_EE1D              ; $EE10  2B 0B
        BNE     L_EE16              ; $EE12  26 02
        LDAA    #$58                ; $EE14  86 58
L_EE16
        DECA                        ; $EE16  4A
        STAA    ZP_A9               ; $EE17  97 A9
        DECB                        ; $EE19  5A
        BNE     L_EE08              ; $EE1A  26 EC
        RTS                         ; $EE1C  39
L_EE1D
        LDAB    PIA1_DB             ; $EE1D  F6 78 02
        STAB    ZP_AB               ; $EE20  D7 AB
        ASLB                        ; $EE22  58
        ROLA                        ; $EE23  49
        LDX     #$EA1A              ; $EE24  CE EA 1A
        JSR     L_EFAD              ; $EE27  BD EF AD
        LDAB    #$0F                ; $EE2A  C6 0F
        STAB    ZP_AD               ; $EE2C  D7 AD
        LDAA    $00,X               ; $EE2E  A6 00
        BMI     L_EE50              ; $EE30  2B 1E
        LDAB    ZP_AB               ; $EE32  D6 AB
        BITB    #$01                ; $EE34  C5 01
        BEQ     L_EE42              ; $EE36  27 0A
        CMPA    #$61                ; $EE38  81 61
        BLT     L_EE42              ; $EE3A  2D 06
        CMPA    #$7A                ; $EE3C  81 7A
        BGT     L_EE42              ; $EE3E  2E 02
        SUBA    #$20                ; $EE40  80 20
L_EE42
        BITB    #$40                ; $EE42  C5 40
        BEQ     L_EE50              ; $EE44  27 0A
        CMPA    #$40                ; $EE46  81 40
        BLT     L_EE50              ; $EE48  2D 06
        CMPA    #$7F                ; $EE4A  81 7F
        BEQ     L_EE50              ; $EE4C  27 02
        ANDA    #$1F                ; $EE4E  84 1F
L_EE50
        TSTA                        ; $EE50  4D
        BPL     L_EE60              ; $EE51  2A 0D
        CMPA    #$90                ; $EE53  81 90
        BGE     L_EE60              ; $EE55  2C 09
        TST     $0057               ; $EE57  7D 00 57
        BMI     L_EE60              ; $EE5A  2B 04
        ANDA    #$7F                ; $EE5C  84 7F
        ADDA    #$30                ; $EE5E  8B 30
L_EE60
        STAA    ZP_AA               ; $EE60  97 AA
        LDAA    #$7D                ; $EE62  86 7D
        STAA    ZP_AC               ; $EE64  97 AC
L_EE66
        LDX     #$0001              ; $EE66  CE 00 01
        LDAA    ZP_AA               ; $EE69  96 AA
        JSR     L_ECB8              ; $EE6B  BD EC B8
        LDAA    #$0A                ; $EE6E  86 0A
        JSR     L_ECCC              ; $EE70  BD EC CC
        LDAA    ZP_AC               ; $EE73  96 AC
        BEQ     L_EE93              ; $EE75  27 1C
L_EE77
        LDAA    #$02                ; $EE77  86 02
        JSR     L_ECCC              ; $EE79  BD EC CC
        LDAA    PIA1_DA             ; $EE7C  B6 78 00
        BPL     L_EE9D              ; $EE7F  2A 1C
        DEC     $00AC               ; $EE81  7A 00 AC
        BNE     L_EE77              ; $EE84  26 F1
        LDAA    ZP_AD               ; $EE86  96 AD
        CMPA    #$03                ; $EE88  81 03
        BLE     L_EE8F              ; $EE8A  2F 03
        DEC     $00AD               ; $EE8C  7A 00 AD
L_EE8F
        STAA    ZP_AC               ; $EE8F  97 AC
        BRA     L_EE66              ; $EE91  20 D3
L_EE93
        LDAA    #$04                ; $EE93  86 04
        JSR     L_ECCC              ; $EE95  BD EC CC
        LDAA    PIA1_DA             ; $EE98  B6 78 00
        BMI     L_EE93              ; $EE9B  2B F6
L_EE9D
        CLR     $00AC               ; $EE9D  7F 00 AC
        RTS                         ; $EEA0  39
        PSHA                        ; $EEA1  36
        JSR     L_ECC1              ; $EEA2  BD EC C1
        PULA                        ; $EEA5  32
        TAB                         ; $EEA6  16
        ANDB    #$F8                ; $EEA7  C4 F8
        CMPB    #$98                ; $EEA9  C1 98
        BEQ     L_EEB9              ; $EEAB  27 0C
        LDAB    ZP_1D               ; $EEAD  D6 1D
        BEQ     L_EEB9              ; $EEAF  27 08
        CMPA    #$90                ; $EEB1  81 90
        BNE     L_EEB8              ; $EEB3  26 03
        CLR     $001D               ; $EEB5  7F 00 1D
L_EEB8
        RTS                         ; $EEB8  39
L_EEB9
        TSTA                        ; $EEB9  4D
        BPL     L_EED8              ; $EEBA  2A 1C
        CLRB                        ; $EEBC  5F
        JSR     L_ECF0              ; $EEBD  BD EC F0
        ANDA    #$7F                ; $EEC0  84 7F
        BITA    #$60                ; $EEC2  85 60
        BEQ     L_EF31              ; $EEC4  27 6B
        LDAB    ZP_41               ; $EEC6  D6 41
        ANDB    #$C0                ; $EEC8  C4 C0
        CMPB    #$40                ; $EECA  C1 40
        BNE     L_EF31              ; $EECC  26 63
        PSHA                        ; $EECE  36
        LDAA    ZP_45               ; $EECF  96 45
        JSR     $FCF5               ; $EED1  BD FC F5
        PULA                        ; $EED4  32
        JMP     $FCF5               ; $EED5  7E FC F5
L_EED8
        CMPA    #$1B                ; $EED8  81 1B
        BNE     L_EEE2              ; $EEDA  26 06
        LDAB    ZP_AB               ; $EEDC  D6 AB
        BPL     L_EEE2              ; $EEDE  2A 02
        LDAA    ZP_45               ; $EEE0  96 45
L_EEE2
        LDAB    ZP_41               ; $EEE2  D6 41
        BITB    #$40                ; $EEE4  C5 40
        BEQ     L_EF08              ; $EEE6  27 20
        JSR     $FCF5               ; $EEE8  BD FC F5
        LDAB    ZP_41               ; $EEEB  D6 41
        BMI     L_EEF0              ; $EEED  2B 01
        RTS                         ; $EEEF  39
L_EEF0
        BITA    #$60                ; $EEF0  85 60
        BNE     L_EF08              ; $EEF2  26 14
        CMPA    #$0D                ; $EEF4  81 0D
        BEQ     L_EF00              ; $EEF6  27 08
        CMPA    #$04                ; $EEF8  81 04
        BEQ     L_EF00              ; $EEFA  27 04
        CMPA    #$03                ; $EEFC  81 03
        BNE     L_EF08              ; $EEFE  26 08
L_EF00
        PSHA                        ; $EF00  36
        LDX     #$0007              ; $EF01  CE 00 07
        JSR     L_ECBA              ; $EF04  BD EC BA
        PULA                        ; $EF07  32
L_EF08
        JSR     L_EFF6              ; $EF08  BD EF F6
L_EF0B
        LDX     ZP_9D               ; $EF0B  DE 9D
        LDAB    $85,X               ; $EF0D  E6 85
        BITB    #$01                ; $EF0F  C5 01
        BNE     L_EF14              ; $EF11  26 01
        RTS                         ; $EF13  39
L_EF14
        STX     ZP_9F               ; $EF14  DF 9F
        ASL     $00A0               ; $EF16  78 00 A0
        LDX     ZP_9F               ; $EF19  DE 9F
        LDX     $75,X               ; $EF1B  EE 75
        STX     ZP_AF               ; $EF1D  DF AF
        JSR     L_ECE8              ; $EF1F  BD EC E8
        LDAB    ZP_41               ; $EF22  D6 41
        CMPB    #$C0                ; $EF24  C1 C0
        BNE     L_EF2B              ; $EF26  26 03
        JSR     $FCF5               ; $EF28  BD FC F5
L_EF2B
        LDX     ZP_AF               ; $EF2B  DE AF
        JSR     $00,X               ; $EF2D  AD 00
        BRA     L_EF0B              ; $EF2F  20 DA
L_EF31
        ANDA    #$7F                ; $EF31  84 7F
        SUBA    #$10                ; $EF33  80 10
        BMI     L_EF42              ; $EF35  2B 0B
        LDX     #$EACA              ; $EF37  CE EA CA
        ASLA                        ; $EF3A  48
        JSR     L_EFAD              ; $EF3B  BD EF AD
        LDX     $00,X               ; $EF3E  EE 00
        JMP     $00,X               ; $EF40  6E 00
L_EF42
        ADDA    #$4F                ; $EF42  8B 4F
        CLR     $00AC               ; $EF44  7F 00 AC
        JMP     $F9D9               ; $EF47  7E F9 D9
L_EF4A
        LDAA    ZP_57               ; $EF4A  96 57
        BRA     L_EF51              ; $EF4C  20 03
L_EF4E
        LDAA    ZP_57               ; $EF4E  96 57
        COMA                        ; $EF50  43
L_EF51
        BITA    #$02                ; $EF51  85 02
        BEQ     L_EF59              ; $EF53  27 04
        LDAA    #$D3                ; $EF55  86 D3
        BRA     L_EF5B              ; $EF57  20 02
L_EF59
        LDAA    #$B5                ; $EF59  86 B5
L_EF5B
        LDX     #$0001              ; $EF5B  CE 00 01
        JMP     L_ECB8              ; $EF5E  7E EC B8
L_EF61
        CLR     $00AC               ; $EF61  7F 00 AC
        LDAA    PIA1_DB             ; $EF64  B6 78 02
        EORA    #$01                ; $EF67  88 01
        STAA    PIA1_DB             ; $EF69  B7 78 02
L_EF6C
        RTS                         ; $EF6C  39
L_EF6D
        CLR     $00AC               ; $EF6D  7F 00 AC
        LDAA    SW_BNK1             ; $EF70  B6 7E 00
        ANDA    #$01                ; $EF73  84 01
        BNE     L_EF6C              ; $EF75  26 F5
        LDAA    ZP_BF               ; $EF77  96 BF
        ORAA    #$60                ; $EF79  8A 60
        STAA    ACIA_CS             ; $EF7B  B7 7A 00
        LDAA    #$C8                ; $EF7E  86 C8
        JSR     L_ECCC              ; $EF80  BD EC CC
        LDAA    ZP_BF               ; $EF83  96 BF
        STAA    ACIA_CS             ; $EF85  B7 7A 00
        JMP     L_ECC1              ; $EF88  7E EC C1
L_EF8B
        LDAB    PIA1_DA             ; $EF8B  F6 78 00
        PSHB                        ; $EF8E  37
        LDAB    #$09                ; $EF8F  C6 09
        STAB    PIA1_DA             ; $EF91  F7 78 00
        LDAB    PIA1_DA             ; $EF94  F6 78 00
        BPL     L_EFA0              ; $EF97  2A 07
        LDAB    PIA1_DB             ; $EF99  F6 78 02
        BPL     L_EFA0              ; $EF9C  2A 02
        BSR     L_EFA5              ; $EF9E  8D 05
L_EFA0
        PULB                        ; $EFA0  33
        STAB    PIA1_DA             ; $EFA1  F7 78 00
        RTS                         ; $EFA4  39
L_EFA5
        CLR     $00AC               ; $EFA5  7F 00 AC
        LDAB    #$80                ; $EFA8  C6 80
        STAB    ZP_AE               ; $EFAA  D7 AE
        RTS                         ; $EFAC  39
L_EFAD
        STX     ZP_9F               ; $EFAD  DF 9F
        ADDA    ZP_A0               ; $EFAF  9B A0
        STAA    ZP_A0               ; $EFB1  97 A0
        LDAA    ZP_9F               ; $EFB3  96 9F
        ADCA    #$00                ; $EFB5  89 00
        STAA    ZP_9F               ; $EFB7  97 9F
        LDX     ZP_9F               ; $EFB9  DE 9F
        RTS                         ; $EFBB  39
        LDAB    ZP_9E               ; $EFBC  D6 9E
        CMPB    #$01                ; $EFBE  C1 01
        BNE     L_EFC5              ; $EFC0  26 03
        CLR     $00AC               ; $EFC2  7F 00 AC
L_EFC5
        RTS                         ; $EFC5  39
L_EFC6
        JSR     $F0DA               ; $EFC6  BD F0 DA
        CLR     $00AC               ; $EFC9  7F 00 AC
        LDAB    ZP_AB               ; $EFCC  D6 AB
        BPL     L_EFDA              ; $EFCE  2A 0A
        JSR     L_ECE8              ; $EFD0  BD EC E8
        CLR     $00AC               ; $EFD3  7F 00 AC
        TSTA                        ; $EFD6  4D
        JMP     L_EF31              ; $EFD7  7E EF 31
L_EFDA
        JSR     L_ECE8              ; $EFDA  BD EC E8
        CLR     $00AC               ; $EFDD  7F 00 AC
        TSTA                        ; $EFE0  4D
        BMI     L_EFC5              ; $EFE1  2B E2
        BITA    #$60                ; $EFE3  85 60
        BEQ     L_EFC5              ; $EFE5  27 DE
        JMP     $F9D9               ; $EFE7  7E F9 D9
L_EFEA
        LDAA    ZP_AB               ; $EFEA  96 AB
        BITA    #$40                ; $EFEC  85 40
        BNE     L_EFF3              ; $EFEE  26 03
        JMP     $F73B               ; $EFF0  7E F7 3B
L_EFF3
        JMP     $F767               ; $EFF3  7E F7 67
L_EFF6
        JSR     L_ECFE              ; $EFF6  BD EC FE
        BITB    #$20                ; $EFF9  C5 20
        BNE     $F006               ; $EFFB  26 09
        CMPA    ZP_45               ; $EFFD  91 45
; --- Trailing/unused byte ($EFFF-$EFFF) ---
        DB      $26                                 ; $EFFF  &
        END
