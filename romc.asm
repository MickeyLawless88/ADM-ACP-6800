; ===========================================================================
; ADM-31 ROM C  ($F000-$F7FF)  --  129867-66.bin
; Full byte-exact 6800 disassembly; reassembles identically with crasm.
; Code traced from all entry points; DB used only for genuine data tables.
; Disassembled by Mickey W. Lawless
; ===========================================================================

        

HALT             EQU     $7000
PIA1_DA          EQU     $7800
SW_BNK2          EQU     $7900
ACIA_CS          EQU     $7A00
ACIA_DA          EQU     $7A01
PERROM           EQU     $7B00
PRNTER           EQU     $7C00
SW_BNK3          EQU     $7D00
SW_BNK1          EQU     $7E00
VTAC             EQU     $7F00
CRTRAM           EQU     $8000

        ORG      $F000

        BRA     $EFC8               ; $F000  20 C6
        BRA     $F082               ; $F002  20 7E
        DB      $EC,$F0,$5F,$BD,$EC,$F0,$81,$58   ; $F004  .._....X
        DB      $27,$04,$81,$75,$26,$03,$7E,$F0   ; $F00C  '..u&.~.
        DB      $A6,$85,$60,$27,$21,$F6,$00,$1A   ; $F014  ..`'!...
        DB      $26,$33,$7E,$EF,$31   ; $F01C  &3~.1
        BITA    #$60                ; $F021  85 60
        BEQ     L_F02F              ; $F023  27 0A
        CMPA    #$7F                ; $F025  81 7F
        BNE     L_F03A              ; $F027  26 11
        DB      $F6,$00,$1A   ; $F029 LDAB $001A (EXT<$100)
        BNE     L_F03A              ; $F02C  26 0C
        RTS                         ; $F02E  39
L_F02F          DB      $F6,$00,$1A   ; $F02F LDAB $001A (EXT<$100)
        BNE     L_F03A              ; $F032  26 06
        LDX     #$EBAA              ; $F034  CE EB AA
        JMP     $EF3A               ; $F037  7E EF 3A
L_F03A          DB      $7D,$00,$1E   ; $F03A TST $001E (EXT<$100)
        BEQ     L_F044              ; $F03D  27 05
        PSHA                        ; $F03F  36
        JSR     $F827               ; $F040  BD F8 27
        PULA                        ; $F043  32
L_F044          ORAA    $19                 ; $F044  9A 19
        LDX     $13                 ; $F046  DE 13
        STAA    HALT                ; $F048  B7 70 00
        NOP                         ; $F04B  01
        STAA    $00,X               ; $F04C  A7 00
        JMP     L_F272              ; $F04E  7E F2 72
        DB      $36,$86,$1B,$8D,$E4,$32,$20,$E1   ; $F051  6....2 .
        DB      $00,$00,$00,$00,$00,$00,$BF,$86   ; $F059  ........
        DB      $80,$97,$18,$96,$54,$85,$10,$27   ; $F061  ....T..'
        DB      $03,$7E,$F2,$59,$7E,$F2,$79,$7F   ; $F069  .~.Y~.y.
        DB      $00,$18,$39,$86,$80,$97,$19,$39   ; $F071  ..9....9
        DB      $7F,$00,$19   ; $F079 CLR $0019 (EXT<$100)
        RTS                         ; $F07C  39
        LDAA    $41                 ; $F07D  96 41
        ANDA    #$BF                ; $F07F  84 BF
        BRA     $F087               ; $F081  20 04
        DB      $96,$41,$8A,$40,$97,$41,$39,$BD   ; $F083  .A.@.A9.
        DB      $EC,$E8,$81,$46,$26,$06,$96,$41   ; $F08B  ...F&..A
        DB      $84,$7F,$20,$F0,$81,$48,$26,$EE   ; $F093  .. ..H&.
        DB      $96,$41,$8A,$80,$20,$E6,$86,$80   ; $F09B  .A.. ...
        DB      $97,$1A,$39   ; $F0A3  ..9
        DB      $7F,$00,$1A   ; $F0A6 CLR $001A (EXT<$100)
        RTS                         ; $F0A9  39
        DB      $86,$80,$97,$1D,$39,$7F,$00,$1D   ; $F0AA  ....9...
        DB      $39   ; $F0B2  9
        DB      $7D,$00,$42   ; $F0B3 TST $0042 (EXT<$100)
        BNE     L_F0CC              ; $F0B6  26 14
        DB      $7D,$00,$D2   ; $F0B8 TST $00D2 (EXT<$100)
        BNE     L_F0CC              ; $F0BB  26 0F
        LDAA    $50                 ; $F0BD  96 50
        BITA    #$20                ; $F0BF  85 20
        BNE     L_F0CC              ; $F0C1  26 09
        LDAA    $7802               ; $F0C3  B6 78 02
        ANDA    #$04                ; $F0C6  84 04
        ORAA    #$80                ; $F0C8  8A 80
        DB      $97,$42   ; $F0CA  .B
L_F0CC          RTS                         ; $F0CC  39
        DB      $7F,$00,$42,$39,$86,$02,$97,$1E   ; $F0CD  ..B9....
        DB      $39,$7F,$00,$1E,$39   ; $F0D5  9...9
L_F0DA          LDAA    $7803               ; $F0DA  B6 78 03
        ANDA    #$F7                ; $F0DD  84 F7
        STAA    $7803               ; $F0DF  B7 78 03
        ORAA    #$08                ; $F0E2  8A 08
        STAA    $7803               ; $F0E4  B7 78 03
        RTS                         ; $F0E7  39
        JSR     $ECE8               ; $F0E8  BD EC E8
        JSR     L_F607              ; $F0EB  BD F6 07
        ORAA    #$90                ; $F0EE  8A 90
        JMP     L_F03A              ; $F0F0  7E F0 3A
        LDAB    $9E                 ; $F0F3  D6 9E
        CMPB    #$01                ; $F0F5  C1 01
        BNE     L_F0FD              ; $F0F7  26 04
        LDAB    $53                 ; $F0F9  D6 53
        BMI     L_F14A              ; $F0FB  2B 4D
L_F0FD          JSR     $ECE8               ; $F0FD  BD EC E8
        DB      $7F,$00,$64   ; $F100 CLR $0064 (EXT<$100)
        CMPA    #$2E                ; $F103  81 2E
        BNE     L_F10E              ; $F105  26 07
        LDAA    #$10                ; $F107  86 10
        DB      $97,$64,$BD,$EC,$E8   ; $F109  .d...
L_F10E          JSR     L_F607              ; $F10E  BD F6 07
        BCS     L_F14B              ; $F111  25 38
        ADDA    $64                 ; $F113  9B 64
        DB      $97,$64,$BD,$EC,$E8,$BD,$F6,$07   ; $F115  .d......
        DB      $48,$48,$48,$48,$97,$63,$BD,$EC   ; $F11D  HHHH.c..
        DB      $E8,$BD,$F6,$07,$25,$20,$CE,$00   ; $F125  ....% ..
        DB      $45,$DF,$9F,$D6,$64,$DB,$A0,$D7   ; $F12D  E...d...
        DB      $A0,$D6,$9F,$C9,$00,$D7,$9F,$DE   ; $F135  ........
        DB      $9F,$D6,$63,$1B,$A7,$00   ; $F13D  ..c...
        LDAB    $00                 ; $F143  D6 00
        BEQ     L_F14A              ; $F145  27 03
        JSR     $E08A               ; $F147  BD E0 8A
L_F14A          RTS                         ; $F14A  39
L_F14B          JMP     L_F0DA              ; $F14B  7E F0 DA
        JSR     $ECE8               ; $F14E  BD EC E8
        PSHA                        ; $F151  36
        JSR     L_F767              ; $F152  BD F7 67
        PULA                        ; $F155  32
        CMPA    #$21                ; $F156  81 21
        BNE     L_F15D              ; $F158  26 03
        JMP     $E800               ; $F15A  7E E8 00
L_F15D          CMPA    #$30                ; $F15D  81 30
        BLT     L_F1C2              ; $F15F  2D 61
        BNE     L_F165              ; $F161  26 02
        BSR     L_F172              ; $F163  8D 0D
L_F165          CMPA    #$39                ; $F165  81 39
        BNE     L_F16B              ; $F167  26 02
        BSR     L_F199              ; $F169  8D 2E
L_F16B          CMPA    #$38                ; $F16B  81 38
        BNE     L_F171              ; $F16D  26 02
        BSR     L_F1AC              ; $F16F  8D 3B
L_F171          RTS                         ; $F171  39
L_F172          LDX     $43                 ; $F172  DE 43
        LDAB    #$10                ; $F174  C6 10
        BSR     L_F1D0              ; $F176  8D 58
        STX     $B7                 ; $F178  DF B7
        BSR     L_F1CD              ; $F17A  8D 51
        LDX     #$0045              ; $F17C  CE 00 45
        LDAB    #$10                ; $F17F  C6 10
        BSR     L_F1D0              ; $F181  8D 4D
        BSR     L_F1CD              ; $F183  8D 48
        BSR     L_F1CD              ; $F185  8D 46
        LDX     $B7                 ; $F187  DE B7
        LDAB    #$0E                ; $F189  C6 0E
        BSR     L_F1D0              ; $F18B  8D 43
        BSR     L_F1CD              ; $F18D  8D 3E
        LDX     #$0055              ; $F18F  CE 00 55
        LDAB    #$0E                ; $F192  C6 0E
        BSR     L_F1D0              ; $F194  8D 3A
        BSR     L_F1CD              ; $F196  8D 35
        RTS                         ; $F198  39
L_F199          LDX     #$EAC6              ; $F199  CE EA C6
        LDAB    #$02                ; $F19C  C6 02
        BSR     L_F1D0              ; $F19E  8D 30
        BSR     L_F1CD              ; $F1A0  8D 2B
        LDX     #$EA18              ; $F1A2  CE EA 18
        LDAB    #$02                ; $F1A5  C6 02
        BSR     L_F1D0              ; $F1A7  8D 27
        BSR     L_F1CD              ; $F1A9  8D 22
        RTS                         ; $F1AB  39
L_F1AC          LDAA    SW_BNK1             ; $F1AC  B6 7E 00
        BSR     $F1F0               ; $F1AF  8D 3F
        BSR     L_F1CD              ; $F1B1  8D 1A
        LDAA    SW_BNK2             ; $F1B3  B6 79 00
        BSR     $F1F0               ; $F1B6  8D 38
        BSR     L_F1CD              ; $F1B8  8D 13
        LDAA    SW_BNK3             ; $F1BA  B6 7D 00
        BSR     $F1F0               ; $F1BD  8D 31
        BSR     L_F1CD              ; $F1BF  8D 0C
        RTS                         ; $F1C1  39
L_F1C2          BSR     L_F172              ; $F1C2  8D AE
        BSR     L_F1CD              ; $F1C4  8D 07
        BSR     L_F199              ; $F1C6  8D D1
        BSR     L_F1CD              ; $F1C8  8D 03
        BSR     L_F1AC              ; $F1CA  8D E0
        RTS                         ; $F1CC  39
L_F1CD          JMP     L_F313              ; $F1CD  7E F3 13
L_F1D0          STX     $9F                 ; $F1D0  DF 9F
        PSHB                        ; $F1D2  37
        LDAA    $00,X               ; $F1D3  A6 00
        PSHA                        ; $F1D5  36
        JSR     L_F622              ; $F1D6  BD F6 22
        JSR     L_F03A              ; $F1D9  BD F0 3A
        PULA                        ; $F1DC  32
        JSR     L_F626              ; $F1DD  BD F6 26
        JSR     L_F03A              ; $F1E0  BD F0 3A
        JSR     L_F2F0              ; $F1E3  BD F2 F0
        PULB                        ; $F1E6  33
        LDX     $9F                 ; $F1E7  DE 9F
        INX                         ; $F1E9  08
        STX     $9F                 ; $F1EA  DF 9F
        DECB                        ; $F1EC  5A
        BNE     L_F1D0              ; $F1ED  26 E1
        RTS                         ; $F1EF  39
        DB      $97,$B7,$C6,$08,$D7,$B8   ; $F1F0  ......
L_F1F6          JSR     L_F2F0              ; $F1F6  BD F2 F0
        DB      $74,$00,$B7   ; $F1F9 LSR $00B7 (EXT<$100)
        BCC     L_F202              ; $F1FC  24 04
        LDAA    #$46                ; $F1FE  86 46
        BRA     L_F204              ; $F200  20 02
L_F202          LDAA    #$4E                ; $F202  86 4E
L_F204          JSR     L_F03A              ; $F204  BD F0 3A
        DB      $7A,$00,$B8   ; $F207 DEC $00B8 (EXT<$100)
        BNE     L_F1F6              ; $F20A  26 EA
        RTS                         ; $F20C  39
        LDAA    #$01                ; $F20D  86 01
        BRA     L_F217              ; $F20F  20 06
        DB      $86,$80,$20,$02,$86,$11   ; $F211  .. ...
L_F217          LDAB    SW_BNK2             ; $F217  F6 79 00
        BITB    #$80                ; $F21A  C5 80
        BNE     L_F22B              ; $F21C  26 0D
        JMP     $FDAF               ; $F21E  7E FD AF
        DB      $F6,$79,$00,$C5,$80,$26,$03,$7E   ; $F221  .y...&.~
        DB      $FF,$40   ; $F229  .@
L_F22B          RTS                         ; $F22B  39
        DB      $FE,$E0,$00,$8C,$54,$4A,$26,$F7   ; $F22C  ....TJ&.
        DB      $7E,$E0,$3C,$86,$02,$7E,$F0,$3A   ; $F234  ~.<..~.:
        DB      $86,$03,$20,$F9,$BD,$EC,$E8,$80   ; $F23C  .. .....
        DB      $20,$97,$63,$BD,$EC,$E8,$91,$45   ; $F244   .c....E
        DB      $27,$0A,$36,$BD,$F0,$21,$32,$7A   ; $F24C  '.6..!2z
        DB      $00,$63,$2E,$F6,$39   ; $F254  .c..9
        LDAA    $42                 ; $F259  96 42
        BPL     L_F26A              ; $F25B  2A 0D
        ANDA    #$04                ; $F25D  84 04
        LDAB    $7802               ; $F25F  F6 78 02
        ANDB    #$04                ; $F262  C4 04
        CBA                         ; $F264  11
        BEQ     L_F26A              ; $F265  27 03
        JSR     L_F65E              ; $F267  BD F6 5E
L_F26A          JSR     L_F2CF              ; $F26A  BD F2 CF
        BSR     L_F2C0              ; $F26D  8D 51
L_F26F          JMP     L_F3FA              ; $F26F  7E F3 FA
L_F272          JSR     L_F2F0              ; $F272  BD F2 F0
L_F275          BSR     L_F2C0              ; $F275  8D 49
        BRA     L_F26F              ; $F277  20 F6
L_F279          LDX     $13                 ; $F279  DE 13
        BRA     L_F275              ; $F27B  20 F8
        LDAB    $18                 ; $F27D  D6 18
        BEQ     L_F285              ; $F27F  27 04
        LDAB    $54                 ; $F281  D6 54
        BMI     L_F29A              ; $F283  2B 15
L_F285          JSR     L_F317              ; $F285  BD F3 17
        BSR     L_F2C0              ; $F288  8D 36
        BRA     L_F26F              ; $F28A  20 E3
L_F28C          JSR     L_F36F              ; $F28C  BD F3 6F
        BSR     L_F2C0              ; $F28F  8D 2F
        BRA     L_F28C              ; $F291  20 F9
        JSR     L_F388              ; $F293  BD F3 88
        BSR     L_F2C0              ; $F296  8D 28
        BRA     L_F28C              ; $F298  20 F2
L_F29A          JSR     L_F313              ; $F29A  BD F3 13
        BSR     L_F2C0              ; $F29D  8D 21
        BRA     L_F26F              ; $F29F  20 CE
        LDAB    $18                 ; $F2A1  D6 18
        ORAB    $B5                 ; $F2A3  DA B5
        BNE     L_F2B0              ; $F2A5  26 09
        LDAB    $53                 ; $F2A7  D6 53
        BITB    #$40                ; $F2A9  C5 40
        BEQ     L_F2B0              ; $F2AB  27 03
        JSR     $F820               ; $F2AD  BD F8 20
L_F2B0          JSR     L_F2E5              ; $F2B0  BD F2 E5
        LDAB    $53                 ; $F2B3  D6 53
        BITB    #$20                ; $F2B5  C5 20
        BEQ     L_F2BC              ; $F2B7  27 03
        JSR     L_F317              ; $F2B9  BD F3 17
L_F2BC          BSR     L_F2C0              ; $F2BC  8D 02
        BRA     L_F26F              ; $F2BE  20 AF
L_F2C0          LDAA    $18                 ; $F2C0  96 18
        BPL     L_F2CC              ; $F2C2  2A 08
        STAA    HALT                ; $F2C4  B7 70 00
        NOP                         ; $F2C7  01
        LDAA    $00,X               ; $F2C8  A6 00
        BMI     L_F2CE              ; $F2CA  2B 02
L_F2CC          INS                         ; $F2CC  31
        INS                         ; $F2CD  31
L_F2CE          RTS                         ; $F2CE  39
L_F2CF          CLRB                        ; $F2CF  5F
        STAB    $7F0C               ; $F2D0  F7 7F 0C
        DB      $D7,$17,$96,$15   ; $F2D3  ....
L_F2D7          SUBA    #$17                ; $F2D7  80 17
        BGE     L_F2DD              ; $F2D9  2C 02
        ADDA    #$18                ; $F2DB  8B 18
L_F2DD          STAA    $7F0D               ; $F2DD  B7 7F 0D
        DB      $97,$16,$7E,$F5,$F8   ; $F2E0  ..~..
L_F2E5          CLRB                        ; $F2E5  5F
        STAB    $7F0C               ; $F2E6  F7 7F 0C
        DB      $D7,$17,$D7,$B5,$7E,$F5,$F8   ; $F2E9  ....~..
L_F2F0          LDAA    $17                 ; $F2F0  96 17
        CMPA    #$4F                ; $F2F2  81 4F
        BEQ     L_F305              ; $F2F4  27 0F
        DB      $7F,$00,$B5   ; $F2F6 CLR $00B5 (EXT<$100)
        INCA                        ; $F2F9  4C
        STAA    $7F0C               ; $F2FA  B7 7F 0C
        DB      $97,$17,$DE,$13,$08,$DF,$13,$39   ; $F2FD  .......9
L_F305          LDAB    $18                 ; $F305  D6 18
        BMI     L_F313              ; $F307  2B 0A
        LDAB    $53                 ; $F309  D6 53
        BITB    #$10                ; $F30B  C5 10
        BEQ     L_F313              ; $F30D  27 04
        DB      $7C,$00,$B5   ; $F30F INC $00B5 (EXT<$100)
        RTS                         ; $F312  39
L_F313          BSR     L_F2E5              ; $F313  8D D0
        BRA     L_F317              ; $F315  20 00
L_F317          LDAA    $16                 ; $F317  96 16
        CMPA    $15                 ; $F319  91 15
        BEQ     L_F327              ; $F31B  27 0A
        CMPA    #$17                ; $F31D  81 17
        BNE     L_F323              ; $F31F  26 02
        LDAA    #$FF                ; $F321  86 FF
L_F323          INCA                        ; $F323  4C
L_F324          JMP     L_F2DD              ; $F324  7E F2 DD
L_F327          DB      $7D,$00,$42   ; $F327 TST $0042 (EXT<$100)
        BNE     L_F362              ; $F32A  26 36
        DB      $7D,$00,$18   ; $F32C TST $0018 (EXT<$100)
        BEQ     L_F334              ; $F32F  27 03
L_F331          JMP     L_F2D7              ; $F331  7E F2 D7
L_F334          LDAB    $55                 ; $F334  D6 55
        BITB    #$08                ; $F336  C5 08
        BNE     L_F331              ; $F338  26 F7
        INCA                        ; $F33A  4C
        CMPA    #$18                ; $F33B  81 18
        BLT     $F340               ; $F33D  2D 01
        CLRA                        ; $F33F  4F
        DB      $97,$15,$B7,$7F,$06,$BD,$F2,$DD   ; $F340  ........
        DB      $90,$17,$C2,$00,$D7,$B7,$97,$B8   ; $F348  ........
        DB      $DE,$B7,$C6,$50,$4F,$B7,$70,$00   ; $F350  ...PO.p.
        DB      $01,$A7,$00,$08,$5A,$26,$F6,$DE   ; $F358  ....Z&..
        DB      $13,$39   ; $F360  .9
L_F362          JSR     L_F65E              ; $F362  BD F6 5E
        LDAA    $15                 ; $F365  96 15
        SUBA    #$17                ; $F367  80 17
        BPL     L_F36D              ; $F369  2A 02
        ADDA    #$18                ; $F36B  8B 18
L_F36D          BRA     L_F324              ; $F36D  20 B5
L_F36F          LDAA    $17                 ; $F36F  96 17
        BEQ     L_F37F              ; $F371  27 0C
        DECA                        ; $F373  4A
        STAA    $7F0C               ; $F374  B7 7F 0C
        DB      $97,$17,$DE,$13,$09,$DF,$13,$39   ; $F377  .......9
L_F37F          LDAA    #$4F                ; $F37F  86 4F
        STAA    $7F0C               ; $F381  B7 7F 0C
        DB      $97,$17,$20,$00   ; $F384  .. .
L_F388          LDAA    $16                 ; $F388  96 16
        BNE     L_F38E              ; $F38A  26 02
        LDAA    #$18                ; $F38C  86 18
L_F38E          DECA                        ; $F38E  4A
        STAA    $7F0D               ; $F38F  B7 7F 0D
        DB      $97,$16,$91,$15,$26,$0F,$7D,$00   ; $F392  ....&.}.
        DB      $42,$27,$0A,$BD,$F6,$5E,$96,$15   ; $F39A  B'...^..
        DB      $B7,$7F,$0D,$97,$16,$7E,$F5,$F8   ; $F3A2  .....~..
        DB      $7D,$00,$18,$27,$5B,$BD,$F4,$9B   ; $F3AA  }..'[...
        DB      $96,$17,$DE,$13,$DF,$B7,$20,$04   ; $F3B2  ...... .
        DB      $9C,$BB,$27,$26,$81,$4F,$27,$2A   ; $F3BA  ..'&.O'*
        DB      $08,$4C,$9C,$B7,$27,$1C,$B7,$70   ; $F3C2  .L..'..p
        DB      $00,$01,$E6,$00,$2A,$EA   ; $F3CA  ....*.
L_F3D0          CMPA    #$4F                ; $F3D0  81 4F
        BEQ     L_F3F3              ; $F3D2  27 1F
        INX                         ; $F3D4  08
        INCA                        ; $F3D5  4C
L_F3D6          STAA    HALT                ; $F3D6  B7 70 00
        NOP                         ; $F3D9  01
        LDAB    $00,X               ; $F3DA  E6 00
        BPL     L_F3E4              ; $F3DC  2A 06
        CPX     $B7                 ; $F3DE  9C B7
        BEQ     L_F400              ; $F3E0  27 1E
        BRA     L_F3D0              ; $F3E2  20 EC
L_F3E4          STAA    $7F0C               ; $F3E4  B7 7F 0C
        DB      $97,$17,$DF,$13,$39,$BD,$F3,$13   ; $F3E7  ....9...
        DB      $96,$17,$20,$D1   ; $F3EF  .. .
L_F3F3          JSR     L_F313              ; $F3F3  BD F3 13
        LDAA    $17                 ; $F3F6  96 17
        BRA     L_F3D6              ; $F3F8  20 DC
L_F3FA          LDAA    $17                 ; $F3FA  96 17
        STX     $B7                 ; $F3FC  DF B7
        BRA     L_F3D0              ; $F3FE  20 D0
L_F400          JSR     L_F2CF              ; $F400  BD F2 CF
        JSR     L_F36F              ; $F403  BD F3 6F
        CLRA                        ; $F406  4F
        STAA    $00,X               ; $F407  A7 00
        RTS                         ; $F409  39
        DB      $7D,$00,$1F   ; $F40A TST $001F (EXT<$100)
        BEQ     L_F43C              ; $F40D  27 2D
        BMI     L_F43D              ; $F40F  2B 2C
        CLRA                        ; $F411  4F
        LDAB    $17                 ; $F412  D6 17
L_F414          ADDA    $1F                 ; $F414  9B 1F
        CMPA    #$4F                ; $F416  81 4F
        BHI     L_F41F              ; $F418  22 05
        CBA                         ; $F41A  11
        BGT     L_F422              ; $F41B  2E 05
        BRA     L_F414              ; $F41D  20 F5
L_F41F          JMP     L_F313              ; $F41F  7E F3 13
L_F422          PSHA                        ; $F422  36
        LDAB    $13                 ; $F423  D6 13
        LDAA    $14                 ; $F425  96 14
        SUBA    $17                 ; $F427  90 17
        SBCB    #$00                ; $F429  C2 00
        TSX                         ; $F42B  30
        ADDA    $00,X               ; $F42C  AB 00
        ADCB    #$00                ; $F42E  C9 00
        DB      $D7,$13,$97,$14   ; $F430  ....
        PULA                        ; $F434  32
        STAA    $7F0C               ; $F435  B7 7F 0C
        DB      $97,$17,$DE,$13   ; $F438  ....
L_F43C          RTS                         ; $F43C  39
L_F43D          LDAA    $17                 ; $F43D  96 17
        CMPA    #$4F                ; $F43F  81 4F
        BEQ     L_F455              ; $F441  27 12
        DB      $7C,$00,$17   ; $F443 INC $0017 (EXT<$100)
        JSR     L_F53B              ; $F446  BD F5 3B
        BITB    $00,X               ; $F449  E5 00
        BEQ     L_F43D              ; $F44B  27 F0
        LDAA    $17                 ; $F44D  96 17
        STAA    $7F0C               ; $F44F  B7 7F 0C
        JMP     L_F5F8              ; $F452  7E F5 F8
L_F455          JMP     L_F313              ; $F455  7E F3 13
        DB      $7D,$00,$18,$27,$7A,$8D,$3C,$96   ; $F458  }..'z.<.
        DB      $17,$DE,$13,$DF,$B7,$8D,$1F,$2B   ; $F460  .......+
        DB      $13,$9C,$B7,$27,$16,$9C,$BB,$27   ; $F468  ...'...'
        DB      $12,$8D,$13,$2A,$F4,$DF,$13,$97   ; $F470  ...*....
        DB      $17,$7E,$F2,$F0,$BD,$F4,$86,$2B   ; $F478  .~.....+
        DB      $FB,$20,$E6,$7E,$F3,$E4   ; $F480  . .~..
        TSTA                        ; $F486  4D
        BEQ     L_F492              ; $F487  27 09
        DECA                        ; $F489  4A
        DEX                         ; $F48A  09
L_F48B          STAA    HALT                ; $F48B  B7 70 00
        NOP                         ; $F48E  01
        LDAB    $00,X               ; $F48F  E6 00
        RTS                         ; $F491  39
L_F492          STX     $13                 ; $F492  DF 13
        JSR     L_F37F              ; $F494  BD F3 7F
        LDAA    $17                 ; $F497  96 17
        BRA     L_F48B              ; $F499  20 F0
        LDAA    $15                 ; $F49B  96 15
        DB      $97   ; $F49D  .
        CPX     $4FD6               ; $F49E  BC 4F D6
        DB      $42,$27,$1D,$C4,$04,$F8,$78,$02   ; $F4A1  B'....x.
        DB      $C5,$04,$27,$14,$86,$08,$98,$11   ; $F4A9  ..'.....
        DB      $8B,$07,$97,$B9,$C6,$D4,$D7,$BA   ; $F4B1  ........
        DB      $DE,$B9,$A6,$00,$97,$BC,$86,$08   ; $F4B9  ........
        DB      $98,$11,$97,$BB,$96,$BC,$80,$17   ; $F4C1  ........
        DB      $2C,$02,$8B,$18,$BD,$F5,$EA,$DB   ; $F4C9  ,.......
        DB      $BB,$D7,$BB,$97,$BC,$39,$7D,$00   ; $F4D1  .....9}.
        DB      $1F,$27,$24,$2B,$14,$D6,$17,$26   ; $F4D9  .'$+...&
        DB      $05,$BD,$F3,$6F,$D6,$17,$4F,$9B   ; $F4E1  ...o..O.
        DB      $1F,$11,$2B,$FB,$90,$1F,$7E,$F4   ; $F4E9  ..+...~.
        DB      $22,$BD,$F3,$6F,$96,$17,$27,$07   ; $F4F1  "..o..'.
        DB      $BD,$F5,$3B,$E5,$00,$27,$F2,$39   ; $F4F9  ..;..'.9
L_F501          LDX     #$0020              ; $F501  CE 00 20
        LDAB    #$0A                ; $F504  C6 0A
        CLRA                        ; $F506  4F
L_F507          STAA    $00,X               ; $F507  A7 00
        INX                         ; $F509  08
        DECB                        ; $F50A  5A
        BNE     L_F507              ; $F50B  26 FA
        BRA     L_F530              ; $F50D  20 21
        BSR     L_F53B              ; $F50F  8D 2A
        ORAB    $00,X               ; $F511  EA 00
        STAB    $00,X               ; $F513  E7 00
        LDAB    $1F                 ; $F515  D6 1F
        ORAB    #$80                ; $F517  CA 80
        BRA     $F538               ; $F519  20 1D
        DB      $8D,$1E,$53,$E4,$00,$E7,$00,$CE   ; $F51B  ..S.....
        DB      $00,$20,$C6,$0A,$4F,$A1,$00,$26   ; $F523  . ..O..&
        DB      $0E,$08,$5A,$26,$F8   ; $F52B  ..Z&.
L_F530          LDAB    $1F                 ; $F530  D6 1F
        CMPB    #$D0                ; $F532  C1 D0
        BEQ     L_F53A              ; $F534  27 04
        ANDB    #$7F                ; $F536  C4 7F
        DB      $D7,$1F   ; $F538  ..
L_F53A          RTS                         ; $F53A  39
L_F53B          LDX     #$0020              ; $F53B  CE 00 20
        LDAA    $17                 ; $F53E  96 17
        LSRA                        ; $F540  44
        LSRA                        ; $F541  44
        LSRA                        ; $F542  44
        JSR     $EFAD               ; $F543  BD EF AD
        LDAB    #$01                ; $F546  C6 01
        LDAA    $17                 ; $F548  96 17
        ANDA    #$07                ; $F54A  84 07
        BEQ     L_F552              ; $F54C  27 04
L_F54E          ASLB                        ; $F54E  58
        DECA                        ; $F54F  4A
        BNE     L_F54E              ; $F550  26 FC
L_F552          RTS                         ; $F552  39
        DB      $BD,$EC,$E8   ; $F553  ...
        ANDA    #$7F                ; $F556  84 7F
        SUBA    #$20                ; $F558  80 20
        BMI     L_F566              ; $F55A  2B 0A
        CMPA    #$50                ; $F55C  81 50
        BLT     $F564               ; $F55E  2D 04
        BGT     L_F566              ; $F560  2E 04
        LDAA    #$D0                ; $F562  86 D0
        DB      $97,$1F   ; $F564  ..
L_F566          RTS                         ; $F566  39
        JSR     $ECE8               ; $F567  BD EC E8
        LDAB    $54                 ; $F56A  D6 54
        BITB    #$40                ; $F56C  C5 40
        BNE     L_F571              ; $F56E  26 01
        DECA                        ; $F570  4A
L_F571          CMPA    #$30                ; $F571  81 30
        BGE     L_F577              ; $F573  2C 02
        LDAA    #$30                ; $F575  86 30
L_F577          CMPA    #$31                ; $F577  81 31
        BLE     L_F57D              ; $F579  2F 02
        LDAA    #$31                ; $F57B  86 31
L_F57D          ANDA    #$01                ; $F57D  84 01
        LDAB    $42                 ; $F57F  D6 42
        BNE     L_F592              ; $F581  26 0F
        ASLA                        ; $F583  48
        ASLA                        ; $F584  48
        LDAB    $7802               ; $F585  F6 78 02
        ANDB    #$04                ; $F588  C4 04
        CBA                         ; $F58A  11
        BEQ     L_F5AA              ; $F58B  27 1D
        JSR     L_F631              ; $F58D  BD F6 31
        BRA     L_F5AA              ; $F590  20 18
L_F592          PSHA                        ; $F592  36
        ANDB    #$04                ; $F593  C4 04
        LDAA    $7802               ; $F595  B6 78 02
        ANDA    #$04                ; $F598  84 04
        CBA                         ; $F59A  11
        BNE     L_F5A3              ; $F59B  26 06
        PULB                        ; $F59D  33
        TSTB                        ; $F59E  5D
        BEQ     L_F5AA              ; $F59F  27 09
        BRA     L_F5A7              ; $F5A1  20 04
L_F5A3          PULB                        ; $F5A3  33
        TSTB                        ; $F5A4  5D
        BNE     L_F5AA              ; $F5A5  26 03
L_F5A7          JSR     L_F631              ; $F5A7  BD F6 31
L_F5AA          JSR     $ECE8               ; $F5AA  BD EC E8
        BSR     L_F5E2              ; $F5AD  8D 33
        CMPA    #$18                ; $F5AF  81 18
        BLT     L_F5B5              ; $F5B1  2D 02
        LDAA    #$17                ; $F5B3  86 17
L_F5B5          ADDA    $15                 ; $F5B5  9B 15
        INCA                        ; $F5B7  4C
        CMPA    #$18                ; $F5B8  81 18
        BLT     L_F5BE              ; $F5BA  2D 02
        SUBA    #$18                ; $F5BC  80 18
L_F5BE          STAA    $7F0D               ; $F5BE  B7 7F 0D
        DB      $97   ; $F5C1  .
        TAB                         ; $F5C2  16
        JSR     $ECE8               ; $F5C3  BD EC E8
        BSR     L_F5E2              ; $F5C6  8D 1A
        CMPA    #$50                ; $F5C8  81 50
        BLT     L_F5CE              ; $F5CA  2D 02
        LDAA    #$4F                ; $F5CC  86 4F
L_F5CE          STAA    $7F0C               ; $F5CE  B7 7F 0C
        DB      $97,$17,$BD,$F5,$F8,$96,$53,$85   ; $F5D1  ......S.
        DB      $02,$27,$0D,$BD,$F2,$C0,$7E,$F3   ; $F5D9  .'....~.
        DB      $FA   ; $F5E1  .
L_F5E2          ANDA    #$7F                ; $F5E2  84 7F
        SUBA    #$20                ; $F5E4  80 20
        BGE     L_F5E9              ; $F5E6  2C 01
        CLRA                        ; $F5E8  4F
L_F5E9          RTS                         ; $F5E9  39
L_F5EA          TAB                         ; $F5EA  16
        ASLA                        ; $F5EB  48
        ASLA                        ; $F5EC  48
        ABA                         ; $F5ED  1B
        CLRB                        ; $F5EE  5F
        ASLA                        ; $F5EF  48
        ROLB                        ; $F5F0  59
        ASLA                        ; $F5F1  48
        ROLB                        ; $F5F2  59
        ASLA                        ; $F5F3  48
        ROLB                        ; $F5F4  59
        ASLA                        ; $F5F5  48
        ROLB                        ; $F5F6  59
        RTS                         ; $F5F7  39
L_F5F8          LDAA    $16                 ; $F5F8  96 16
        BSR     L_F5EA              ; $F5FA  8D EE
        ADDA    $17                 ; $F5FC  9B 17
        ADCB    $11                 ; $F5FE  D9 11
        DB      $D7,$13,$97,$14,$DE,$13,$39   ; $F600  ......9
L_F607          CMPA    #$30                ; $F607  81 30
        BMI     L_F61F              ; $F609  2B 14
        CMPA    #$39                ; $F60B  81 39
        BLE     L_F61B              ; $F60D  2F 0C
        ANDA    #$DF                ; $F60F  84 DF
        CMPA    #$41                ; $F611  81 41
        BMI     L_F61F              ; $F613  2B 0A
        CMPA    #$46                ; $F615  81 46
        BGT     L_F61F              ; $F617  2E 06
        SUBA    #$07                ; $F619  80 07
L_F61B          ANDA    #$0F                ; $F61B  84 0F
        CLC                         ; $F61D  0C
        RTS                         ; $F61E  39
L_F61F          CLRA                        ; $F61F  4F
        SEC                         ; $F620  0D
        RTS                         ; $F621  39
L_F622          LSRA                        ; $F622  44
        LSRA                        ; $F623  44
        LSRA                        ; $F624  44
        LSRA                        ; $F625  44
L_F626          ANDA    #$0F                ; $F626  84 0F
        CMPA    #$0A                ; $F628  81 0A
        BLT     L_F62E              ; $F62A  2D 02
        ADDA    #$07                ; $F62C  8B 07
L_F62E          ADDA    #$30                ; $F62E  8B 30
        RTS                         ; $F630  39
L_F631          DB      $7D,$00,$D2   ; $F631 TST $00D2 (EXT<$100)
        BNE     L_F671              ; $F634  26 3B
        LDAA    $50                 ; $F636  96 50
        BITA    #$20                ; $F638  85 20
        BNE     L_F671              ; $F63A  26 35
        LDAB    #$07                ; $F63C  C6 07
        BSR     $F660               ; $F63E  8D 20
        STAA    HALT                ; $F640  B7 70 00
        NOP                         ; $F643  01
        LDAA    $00,X               ; $F644  A6 00
        BITA    $18                 ; $F646  95 18
        BEQ     L_F671              ; $F648  27 27
        LDAA    $42                 ; $F64A  96 42
        BEQ     L_F65B              ; $F64C  27 0D
        ANDA    #$04                ; $F64E  84 04
        LDAB    $7802               ; $F650  F6 78 02
        ANDB    #$04                ; $F653  C4 04
        CBA                         ; $F655  11
        BEQ     L_F65B              ; $F656  27 03
        JMP     L_F28C              ; $F658  7E F2 8C
L_F65B          JMP     L_F3FA              ; $F65B  7E F3 FA
L_F65E          LDAB    #$06                ; $F65E  C6 06
        DB      $D7,$B6,$BD,$F6,$72,$B6,$78,$02   ; $F660  ....r.x.
        DB      $88,$04,$B7,$78,$02,$8D,$16,$DE   ; $F668  ...x....
        DB      $13   ; $F670  .
L_F671          RTS                         ; $F671  39
        LDAA    $11                 ; $F672  96 11
        ADDA    #$07                ; $F674  8B 07
        DB      $97,$B1,$86,$D0,$97,$B2,$CE,$00   ; $F676  ........
        DB      $11,$DF,$B3,$C6,$30,$20,$36,$CE   ; $F67E  ....0 6.
        DB      $00,$11,$DF,$B1,$B6,$78,$02,$84   ; $F686  .....x..
        DB      $04,$48,$8B,$80,$97,$11,$8B,$07   ; $F68E  .H......
        DB      $97,$B3,$86,$D0,$97,$B4,$7D,$00   ; $F696  ......}.
        DB      $42,$27,$04,$D6,$B6,$20,$02,$C6   ; $F69E  B'... ..
        DB      $30,$8D,$12,$96,$15,$B7,$7F,$06   ; $F6A6  0.......
        DB      $96,$16,$B7,$7F,$0D,$96,$17,$B7   ; $F6AE  ........
        DB      $7F,$0C,$7E,$F5,$F8   ; $F6B6  ..~..
L_F6BB          LDX     $B3                 ; $F6BB  DE B3
        STAA    HALT                ; $F6BD  B7 70 00
        NOP                         ; $F6C0  01
        LDAA    $00,X               ; $F6C1  A6 00
        INX                         ; $F6C3  08
        STX     $B3                 ; $F6C4  DF B3
        LDX     $B1                 ; $F6C6  DE B1
        STAA    HALT                ; $F6C8  B7 70 00
        NOP                         ; $F6CB  01
        STAA    $00,X               ; $F6CC  A7 00
        INX                         ; $F6CE  08
        STX     $B1                 ; $F6CF  DF B1
        DECB                        ; $F6D1  5A
        BNE     L_F6BB              ; $F6D2  26 E7
        RTS                         ; $F6D4  39
        LDAA    #$20                ; $F6D5  86 20
        LDAB    $55                 ; $F6D7  D6 55
        BITB    #$80                ; $F6D9  C5 80
        BEQ     L_F6E2              ; $F6DB  27 05
        LDAA    $4D                 ; $F6DD  96 4D
        BRA     L_F6E2              ; $F6DF  20 01
        DB      $4F   ; $F6E1  O
L_F6E2          LDAB    $55                 ; $F6E2  D6 55
        BITB    #$02                ; $F6E4  C5 02
        BEQ     L_F6EB              ; $F6E6  27 03
        DB      $7F,$00,$19   ; $F6E8 CLR $0019 (EXT<$100)
L_F6EB          ORAA    $19                 ; $F6EB  9A 19
        PSHA                        ; $F6ED  36
        JSR     $EFBC               ; $F6EE  BD EF BC
        LDAA    $42                 ; $F6F1  96 42
        BPL     L_F72A              ; $F6F3  2A 35
        ANDA    #$04                ; $F6F5  84 04
        LDAB    $7802               ; $F6F7  F6 78 02
        ANDB    #$04                ; $F6FA  C4 04
        CBA                         ; $F6FC  11
        BNE     L_F72A              ; $F6FD  26 2B
        PULA                        ; $F6FF  32
        LDAB    $13                 ; $F700  D6 13
        PSHB                        ; $F702  37
        LDAB    $14                 ; $F703  D6 14
        PSHB                        ; $F705  37
        LDAB    $16                 ; $F706  D6 16
        PSHB                        ; $F708  37
        LDAB    $17                 ; $F709  D6 17
        PSHB                        ; $F70B  37
        PSHA                        ; $F70C  36
        JSR     L_F65E              ; $F70D  BD F6 5E
        JSR     L_F790              ; $F710  BD F7 90
        JSR     L_F65E              ; $F713  BD F6 5E
        PULA                        ; $F716  32
        PULB                        ; $F717  33
        STAB    $7F0C               ; $F718  F7 7F 0C
        DB      $D7,$17,$33,$F7,$7F,$0D,$D7,$16   ; $F71B  ..3.....
        DB      $33,$D7,$14,$33,$D7,$13,$36   ; $F723  3..3..6
L_F72A          JSR     L_F793              ; $F72A  BD F7 93
        INS                         ; $F72D  31
        JMP     L_F279              ; $F72E  7E F2 79
        DB      $D6,$55,$C5,$04,$27,$30,$4F,$36   ; $F731  .U..'0O6
        DB      $20,$33   ; $F739   3
L_F73B          BSR     L_F74C              ; $F73B  8D 0F
        PSHA                        ; $F73D  36
        BRA     L_F76E              ; $F73E  20 2E
        LDAB    $55                 ; $F740  D6 55
        BITB    #$04                ; $F742  C5 04
        BEQ     L_F73B              ; $F744  27 F5
        BSR     L_F757              ; $F746  8D 0F
        BSR     L_F74C              ; $F748  8D 02
        BRA     L_F76A              ; $F74A  20 1E
L_F74C          LDAA    #$20                ; $F74C  86 20
        LDAB    $55                 ; $F74E  D6 55
        BITB    #$40                ; $F750  C5 40
        BEQ     L_F756              ; $F752  27 02
        LDAA    $4D                 ; $F754  96 4D
L_F756          RTS                         ; $F756  39
L_F757          LDAA    $1F                 ; $F757  96 1F
        BPL     L_F762              ; $F759  2A 07
        LDAA    $52                 ; $F75B  96 52
        BPL     L_F762              ; $F75D  2A 03
        JSR     L_F501              ; $F75F  BD F5 01
L_F762          RTS                         ; $F762  39
        DB      $86,$A0,$20,$03   ; $F763  .. .
L_F767          BSR     L_F757              ; $F767  8D EE
        CLRA                        ; $F769  4F
L_F76A          PSHA                        ; $F76A  36
        DB      $7F,$00,$18   ; $F76B CLR $0018 (EXT<$100)
L_F76E          DB      $7F,$00,$19   ; $F76E CLR $0019 (EXT<$100)
        JSR     $EFBC               ; $F771  BD EF BC
        LDAA    $42                 ; $F774  96 42
        BEQ     L_F78A              ; $F776  27 12
        ANDA    #$04                ; $F778  84 04
        LDAB    $7802               ; $F77A  F6 78 02
        ANDB    #$04                ; $F77D  C4 04
        CBA                         ; $F77F  11
        BNE     L_F785              ; $F780  26 03
        JSR     L_F65E              ; $F782  BD F6 5E
L_F785          BSR     L_F790              ; $F785  8D 09
        JSR     L_F65E              ; $F787  BD F6 5E
L_F78A          BSR     L_F790              ; $F78A  8D 04
        INS                         ; $F78C  31
        JMP     L_F279              ; $F78D  7E F2 79
L_F790          JSR     L_F2CF              ; $F790  BD F2 CF
L_F793          LDAB    $11                 ; $F793  D6 11
        ADDB    #$07                ; $F795  CB 07
        LDAA    #$7F                ; $F797  86 7F
        DB      $D7,$B7,$97,$B8,$96,$15,$BD,$F5   ; $F799  ........
        DB      $EA,$8B,$4F,$D9,$11,$D7,$B9,$97   ; $F7A1  ..O.....
        DB      $BA,$30,$E6,$02,$DE,$13,$96,$18   ; $F7A9  .0......
        DB      $2A,$08,$B7,$70,$00,$01,$A5,$00   ; $F7B1  *..p....
        DB      $26,$06,$B7,$70,$00,$01,$E7,$00   ; $F7B9  &..p....
        DB      $9C,$B9,$27,$0D,$9C,$B7,$27,$03   ; $F7C1  ..'...'.
        DB      $08,$20,$E3,$DE,$11,$DF,$13,$20   ; $F7C9  . ..... 
        DB      $DD,$7E,$F5,$F8,$86,$20,$D6,$55   ; $F7D1  .~... .U
        DB      $C5,$80,$27,$02,$96,$4D,$BD,$EF   ; $F7D9  ..'..M..
        DB      $BC   ; $F7E1  .
        LDAB    $55                 ; $F7E2  D6 55
        BITB    #$01                ; $F7E4  C5 01
        BEQ     L_F7EB              ; $F7E6  27 03
        DB      $7F,$00,$19   ; $F7E8 CLR $0019 (EXT<$100)
L_F7EB          ORAA    $19                 ; $F7EB  9A 19
        LDAB    #$50                ; $F7ED  C6 50
        SUBB    $17                 ; $F7EF  D0 17
        DB      $D7,$BA,$DE,$13,$D6,$18,$2A,$08   ; $F7F1  ......*.
        DB      $B7,$70,$00,$01,$E6,$00,$2B   ; $F7F9  .p....+
        END
