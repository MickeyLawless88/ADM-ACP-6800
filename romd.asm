; =============================================================================
; ADM-31 ROM D  ($F800-$FFFF)  --  129867-65.bin
; 2KB system ROM, contains 6800 interrupt vectors at $FFF8-$FFFF
; Disassembled by Mickey W. Lawless
;
; Assemble:  crasm -o romd.bin romd.asm
; Verify:    python3 verify_romd.py
;
; MONDEB patch: change SWI_VEC/NMI_VEC/RST_VEC EQUs at bottom of file
; =============================================================================

        CPU     6800

; --- Hardware ---
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
SW_BNK3          EQU     $7D00
SW_BNK1          EQU     $7E00
VTAC             EQU     $7F00
VTAC_06          EQU     $7F06
VTAC_0C          EQU     $7F0C
CRTRAM           EQU     $8000
CRTRAM_84        EQU     $8084

; --- ROM B entry points ($E800-$EFFF) ---
ROMB_ECB8        EQU     $ECB8
ROMB_ECBA        EQU     $ECBA
ROMB_ECC1        EQU     $ECC1
ROMB_ECC3        EQU     $ECC3
ROMB_ECCC        EQU     $ECCC
ROMB_ECE8        EQU     $ECE8
ROMB_EF8B        EQU     $EF8B
ROMB_EFAD        EQU     $EFAD
ROMB_EFBC        EQU     $EFBC

; --- ROM C entry points ($F000-$F7FF) ---
ROMC_F079        EQU     $F079
ROMC_F0DA        EQU     $F0DA
ROMC_F259        EQU     $F259
ROMC_F28F        EQU     $F28F
ROMC_F29A        EQU     $F29A
ROMC_F2CF        EQU     $F2CF
ROMC_F2E5        EQU     $F2E5
ROMC_F2F0        EQU     $F2F0
ROMC_F313        EQU     $F313
ROMC_F36F        EQU     $F36F
ROMC_F3FA        EQU     $F3FA
ROMC_F5EA        EQU     $F5EA
ROMC_F626        EQU     $F626
ROMC_F65E        EQU     $F65E
ROMC_F6BB        EQU     $F6BB
ROMC_F7E2        EQU     $F7E2

; --- Zero page RAM variables ---
ZP_11            EQU     $11
ZP_13            EQU     $13
ZP_15            EQU     $15
ZP_16            EQU     $16
ZP_17            EQU     $17
ZP_18            EQU     $18
ZP_42            EQU     $42
ZP_45            EQU     $45
ZP_46            EQU     $46
ZP_47            EQU     $47
ZP_48            EQU     $48
ZP_49            EQU     $49
ZP_4A            EQU     $4A
ZP_4B            EQU     $4B
ZP_4D            EQU     $4D
ZP_4F            EQU     $4F
ZP_50            EQU     $50
ZP_54            EQU     $54
ZP_55            EQU     $55
ZP_B1            EQU     $B1
ZP_B2            EQU     $B2
ZP_B3            EQU     $B3
ZP_B4            EQU     $B4
ZP_B5            EQU     $B5
ZP_B7            EQU     $B7
ZP_B8            EQU     $B8
ZP_B9            EQU     $B9
ZP_BA            EQU     $BA
ZP_BB            EQU     $BB
ZP_BC            EQU     $BC
ZP_BD            EQU     $BD
ZP_BE            EQU     $BE
ZP_BF            EQU     $BF
ZP_C0            EQU     $C0
ZP_C1            EQU     $C1
ZP_C3            EQU     $C3
ZP_C4            EQU     $C4
ZP_C5            EQU     $C5
ZP_C6            EQU     $C6
ZP_C7            EQU     $C7
ZP_C8            EQU     $C8
ZP_C9            EQU     $C9
ZP_CA            EQU     $CA
ZP_CB            EQU     $CB
ZP_CC            EQU     $CC
ZP_CD            EQU     $CD
ZP_CF            EQU     $CF
ZP_D0            EQU     $D0
ZP_D1            EQU     $D1
ZP_D2            EQU     $D2
ZP_D3            EQU     $D3
ZP_D4            EQU     $D4
ZP_D5            EQU     $D5
ZP_D6            EQU     $D6
ZP_D7            EQU     $D7
ZP_D8            EQU     $D8
ZP_D9            EQU     $D9
ZP_DB            EQU     $DB

        *= $F800

                 CLC                          ; $F800  0C
                 STAA    HALT                 ; $F801  B7 70 00
                 NOP                          ; $F804  01
                 STAA    $00,X                ; $F805  A7 00
                 INX                          ; $F807  08
                 DB      $7A,$00,$BA              ; $F808  7A 00 BA (EXT ZP forced)
                 BNE     $F7F5                ; $F80B  26 E8
                 LDX     ZP_13                ; $F80D  DE 13
                 STAA    HALT                 ; $F80F  B7 70 00
                 NOP                          ; $F812  01
                 LDAA    $00,X                ; $F813  A6 00
                 BITA    ZP_18                ; $F815  95 18
                 BEQ     L_F81C               ; $F817  27 03
                 JSR     ROMC_F3FA            ; $F819  BD F3 FA
L_F81C           RTS                          ; $F81C  39
                 CLRA                         ; $F81D  4F
                 BRA     $F7DF                ; $F81E  20 BF
                 LDAA    ZP_4D                ; $F820  96 4D
                 BRA     $F7E2                ; $F822  20 BE
                 JSR     ROMC_F079            ; $F824  BD F0 79
                 LDX     ZP_13                ; $F827  DE 13
                 LDAA    #$50                 ; $F829  86 50
                 SUBA    ZP_17                ; $F82B  90 17
                 STAA    ZP_BA                ; $F82D  97 BA
                 LDAB    #$20                 ; $F82F  C6 20
L_F831           STAA    HALT                 ; $F831  B7 70 00
                 NOP                          ; $F834  01
                 LDAA    $00,X                ; $F835  A6 00
                 BITA    ZP_18                ; $F837  95 18
                 BNE     L_F848               ; $F839  26 0D
                 STAA    HALT                 ; $F83B  B7 70 00
                 NOP                          ; $F83E  01
                 STAB    $00,X                ; $F83F  E7 00
                 TAB                          ; $F841  16
                 INX                          ; $F842  08
                 DB      $7A,$00,$BA              ; $F843  7A 00 BA (EXT ZP forced)
                 BNE     L_F831               ; $F846  26 E9
L_F848           LDX     ZP_13                ; $F848  DE 13
                 RTS                          ; $F84A  39
                 JSR     ROMC_F079            ; $F84B  BD F0 79
                 LDX     ZP_13                ; $F84E  DE 13
                 LDAB    #$4F                 ; $F850  C6 4F
                 SUBB    $7F09                ; $F852  F0 7F 09
L_F855           BEQ     L_F86B               ; $F855  27 14
                 STAA    HALT                 ; $F857  B7 70 00
                 NOP                          ; $F85A  01
                 LDAA    $01,X                ; $F85B  A6 01
                 BITA    ZP_18                ; $F85D  95 18
                 BNE     L_F86B               ; $F85F  26 0A
                 STAA    HALT                 ; $F861  B7 70 00
                 NOP                          ; $F864  01
                 STAA    $00,X                ; $F865  A7 00
                 INX                          ; $F867  08
                 DECB                         ; $F868  5A
                 BRA     L_F855               ; $F869  20 EA
L_F86B           LDAA    ZP_4D                ; $F86B  96 4D
                 STAA    HALT                 ; $F86D  B7 70 00
                 NOP                          ; $F870  01
                 STAA    $00,X                ; $F871  A7 00
                 RTS                          ; $F873  39
                 DB      $7D,$00,$18              ; $F874  7D 00 18 (EXT ZP forced)
                 BEQ     L_F87A               ; $F877  27 01
                 RTS                          ; $F879  39
L_F87A           DB      $7F,$00,$19              ; $F87A  7F 00 19 (EXT ZP forced)
                 JSR     ROMC_F2E5            ; $F87D  BD F2 E5
                 LDX     ZP_13                ; $F880  DE 13
                 STX     ZP_BB                ; $F882  DF BB
                 LDAA    ZP_42                ; $F884  96 42
                 BPL     L_F8C5               ; $F886  2A 3D
                 LDAB    PIA1_DB              ; $F888  F6 78 02
                 ANDA    #$04                 ; $F88B  84 04
                 ANDB    #$04                 ; $F88D  C4 04
                 CBA                          ; $F88F  11
                 BNE     L_F8C5               ; $F890  26 33
                 LDAB    #$87                 ; $F892  C6 87
                 TSTA                         ; $F894  4D
                 BNE     L_F899               ; $F895  26 02
                 ADDB    #$08                 ; $F897  CB 08
L_F899           LDAA    #$D0                 ; $F899  86 D0
                 STAB    ZP_BB                ; $F89B  D7 BB
                 STAA    ZP_BC                ; $F89D  97 BC
                 LDX     ZP_BB                ; $F89F  DE BB
                 LDAA    $04,X                ; $F8A1  A6 04
                 PSHA                         ; $F8A3  36
                 DECA                         ; $F8A4  4A
                 BPL     L_F8A9               ; $F8A5  2A 02
                 LDAA    #$17                 ; $F8A7  86 17
L_F8A9           STAA    $04,X                ; $F8A9  A7 04
                 PULA                         ; $F8AB  32
                 JSR     ROMC_F5EA            ; $F8AC  BD F5 EA
                 ADDB    $00,X                ; $F8AF  EB 00
                 STAB    ZP_B1                ; $F8B1  D7 B1
                 STAA    ZP_B2                ; $F8B3  97 B2
                 LDAA    ZP_15                ; $F8B5  96 15
                 JSR     ROMC_F5EA            ; $F8B7  BD F5 EA
                 ADDB    ZP_11                ; $F8BA  DB 11
                 STAB    ZP_B3                ; $F8BC  D7 B3
                 STAA    ZP_B4                ; $F8BE  97 B4
                 LDAB    #$50                 ; $F8C0  C6 50
                 JSR     ROMC_F6BB            ; $F8C2  BD F6 BB
L_F8C5           LDAA    ZP_15                ; $F8C5  96 15
L_F8C7           CMPA    ZP_16                ; $F8C7  91 16
                 BEQ     L_F90D               ; $F8C9  27 42
                 TSTA                         ; $F8CB  4D
                 BEQ     L_F8F2               ; $F8CC  27 24
                 DECA                         ; $F8CE  4A
                 STAA    ZP_B9                ; $F8CF  97 B9
                 JSR     ROMC_F5EA            ; $F8D1  BD F5 EA
                 ADDB    ZP_11                ; $F8D4  DB 11
                 STAB    ZP_B7                ; $F8D6  D7 B7
                 STAA    ZP_B8                ; $F8D8  97 B8
                 LDX     ZP_B7                ; $F8DA  DE B7
                 LDAB    #$50                 ; $F8DC  C6 50
L_F8DE           STAA    HALT                 ; $F8DE  B7 70 00
                 NOP                          ; $F8E1  01
                 LDAA    $00,X                ; $F8E2  A6 00
                 STAA    HALT                 ; $F8E4  B7 70 00
                 NOP                          ; $F8E7  01
                 STAA    $50,X                ; $F8E8  A7 50
                 INX                          ; $F8EA  08
                 DECB                         ; $F8EB  5A
                 BNE     L_F8DE               ; $F8EC  26 F0
                 LDAA    ZP_B9                ; $F8EE  96 B9
                 BRA     L_F8C7               ; $F8F0  20 D5
L_F8F2           LDX     ZP_11                ; $F8F2  DE 11
                 STX     ZP_B1                ; $F8F4  DF B1
                 LDAA    ZP_B2                ; $F8F6  96 B2
                 ADDA    #$30                 ; $F8F8  8B 30
                 STAA    ZP_B4                ; $F8FA  97 B4
                 LDAA    ZP_B1                ; $F8FC  96 B1
                 ADCA    #$07                 ; $F8FE  89 07
                 STAA    ZP_B3                ; $F900  97 B3
                 LDAB    #$50                 ; $F902  C6 50
                 JSR     ROMC_F6BB            ; $F904  BD F6 BB
                 LDAA    #$17                 ; $F907  86 17
                 STAA    ZP_B9                ; $F909  97 B9
                 BRA     L_F8C7               ; $F90B  20 BA
L_F90D           LDAA    ZP_4D                ; $F90D  96 4D
                 JMP     ROMC_F7E2            ; $F90F  7E F7 E2
                 DB      $7D,$00,$18              ; $F912  7D 00 18 (EXT ZP forced)
                 BEQ     L_F918               ; $F915  27 01
                 RTS                          ; $F917  39
L_F918           DB      $7F,$00,$19              ; $F918  7F 00 19 (EXT ZP forced)
                 JSR     ROMC_F2E5            ; $F91B  BD F2 E5
                 LDAA    ZP_16                ; $F91E  96 16
L_F920           CMPA    ZP_15                ; $F920  91 15
                 BEQ     L_F960               ; $F922  27 3C
                 CMPA    #$17                 ; $F924  81 17
                 BNE     L_F93E               ; $F926  26 16
                 LDAB    ZP_11                ; $F928  D6 11
                 ADDB    #$07                 ; $F92A  CB 07
                 LDAA    #$30                 ; $F92C  86 30
                 STAB    ZP_B1                ; $F92E  D7 B1
                 STAA    ZP_B2                ; $F930  97 B2
                 LDX     ZP_11                ; $F932  DE 11
                 STX     ZP_B3                ; $F934  DF B3
                 LDAB    #$50                 ; $F936  C6 50
                 JSR     ROMC_F6BB            ; $F938  BD F6 BB
                 CLRA                         ; $F93B  4F
                 BRA     L_F920               ; $F93C  20 E2
L_F93E           PSHA                         ; $F93E  36
                 JSR     ROMC_F5EA            ; $F93F  BD F5 EA
                 ADDB    ZP_11                ; $F942  DB 11
                 STAB    ZP_B7                ; $F944  D7 B7
                 STAA    ZP_B8                ; $F946  97 B8
                 LDX     ZP_B7                ; $F948  DE B7
                 LDAB    #$50                 ; $F94A  C6 50
L_F94C           STAA    HALT                 ; $F94C  B7 70 00
                 NOP                          ; $F94F  01
                 LDAA    $50,X                ; $F950  A6 50
                 STAA    HALT                 ; $F952  B7 70 00
                 NOP                          ; $F955  01
                 STAA    $00,X                ; $F956  A7 00
                 INX                          ; $F958  08
                 DECB                         ; $F959  5A
                 BNE     L_F94C               ; $F95A  26 F0
                 PULA                         ; $F95C  32
                 INCA                         ; $F95D  4C
                 BRA     L_F920               ; $F95E  20 C0
L_F960           JSR     ROMC_F5EA            ; $F960  BD F5 EA
                 ADDB    ZP_11                ; $F963  DB 11
                 STAB    ZP_B1                ; $F965  D7 B1
                 STAB    ZP_B7                ; $F967  D7 B7
                 STAA    ZP_B2                ; $F969  97 B2
                 STAA    ZP_B8                ; $F96B  97 B8
                 LDAA    ZP_42                ; $F96D  96 42
                 BEQ     L_F9A4               ; $F96F  27 33
                 LDAB    PIA1_DB              ; $F971  F6 78 02
                 ANDB    #$04                 ; $F974  C4 04
                 ANDA    #$04                 ; $F976  84 04
                 CBA                          ; $F978  11
                 BNE     L_F9A4               ; $F979  26 29
                 EORA    #$04                 ; $F97B  88 04
                 ASLA                         ; $F97D  48
                 ADDA    #$87                 ; $F97E  8B 87
                 LDAB    #$D0                 ; $F980  C6 D0
                 STAA    ZP_B3                ; $F982  97 B3
                 STAB    ZP_B4                ; $F984  D7 B4
                 LDX     ZP_B3                ; $F986  DE B3
                 LDAA    $04,X                ; $F988  A6 04
                 INCA                         ; $F98A  4C
                 CMPA    #$17                 ; $F98B  81 17
                 BLE     L_F990               ; $F98D  2F 01
                 CLRA                         ; $F98F  4F
L_F990           STAA    $04,X                ; $F990  A7 04
                 JSR     ROMC_F5EA            ; $F992  BD F5 EA
                 ADDB    $00,X                ; $F995  EB 00
                 STAB    ZP_B3                ; $F997  D7 B3
                 STAA    ZP_B4                ; $F999  97 B4
                 LDX     ZP_B3                ; $F99B  DE B3
                 STX     ZP_B7                ; $F99D  DF B7
                 LDAB    #$50                 ; $F99F  C6 50
                 JSR     ROMC_F6BB            ; $F9A1  BD F6 BB
L_F9A4           LDX     ZP_B7                ; $F9A4  DE B7
                 LDAB    #$50                 ; $F9A6  C6 50
                 LDAA    ZP_4D                ; $F9A8  96 4D
L_F9AA           STAA    HALT                 ; $F9AA  B7 70 00
                 NOP                          ; $F9AD  01
                 STAA    $00,X                ; $F9AE  A7 00
                 INX                          ; $F9B0  08
                 DECB                         ; $F9B1  5A
                 BNE     L_F9AA               ; $F9B2  26 F6
                 RTS                          ; $F9B4  39
                 LDAA    #$02                 ; $F9B5  86 02
                 BRA     L_F9DA               ; $F9B7  20 21
                 LDAA    #$03                 ; $F9B9  86 03
                 BRA     L_F9DA               ; $F9BB  20 1D
                 LDAA    #$04                 ; $F9BD  86 04
                 BRA     L_F9DA               ; $F9BF  20 19
                 LDAA    #$05                 ; $F9C1  86 05
                 BRA     L_F9DA               ; $F9C3  20 15
                 LDAA    #$06                 ; $F9C5  86 06
                 BRA     L_F9DA               ; $F9C7  20 11
                 LDAA    #$07                 ; $F9C9  86 07
                 BRA     L_F9DA               ; $F9CB  20 0D
                 LDAA    #$08                 ; $F9CD  86 08
                 BRA     L_F9DA               ; $F9CF  20 09
                 LDAA    #$09                 ; $F9D1  86 09
                 BRA     L_F9DA               ; $F9D3  20 05
                 LDAA    #$0A                 ; $F9D5  86 0A
                 BRA     L_F9DA               ; $F9D7  20 01
                 COMA                         ; $F9D9  43
L_F9DA           STAA    ZP_C5                ; $F9DA  97 C5
                 JSR     ROMB_EFBC            ; $F9DC  BD EF BC
                 DB      $7F,$00,$AE              ; $F9DF  7F 00 AE (EXT ZP forced)
                 CLRA                         ; $F9E2  4F
                 LDX     #$0004               ; $F9E3  CE 00 04
                 JSR     ROMB_ECB8            ; $F9E6  BD EC B8
                 LDX     #$0000               ; $F9E9  CE 00 00
                 JSR     ROMB_ECC3            ; $F9EC  BD EC C3
                 LDX     #$0002               ; $F9EF  CE 00 02
                 JMP     ROMB_ECC3            ; $F9F2  7E EC C3
                 JSR     L_FCDD               ; $F9F5  BD FC DD
                 LDAA    ZP_C5                ; $F9F8  96 C5
                 BPL     L_FA01               ; $F9FA  2A 05
                 LDX     #L_FA77              ; $F9FC  CE FA 77
                 BRA     L_FA10               ; $F9FF  20 0F
L_FA01           LDAB    ZP_55                ; $FA01  D6 55
                 ANDB    #$20                 ; $FA03  C4 20
                 STAB    ZP_CD                ; $FA05  D7 CD
                 LDX     #L_FA32              ; $FA07  CE FA 32
                 ASLA                         ; $FA0A  48
                 JSR     ROMB_EFAD            ; $FA0B  BD EF AD
                 LDX     $00,X                ; $FA0E  EE 00
L_FA10           JSR     $00,X                ; $FA10  AD 00
                 LDAA    ZP_C5                ; $FA12  96 C5
                 CMPA    #$0A                 ; $FA14  81 0A
                 BEQ     L_FA26               ; $FA16  27 0E
                 LDAA    ZP_46                ; $FA18  96 46
                 BEQ     L_FA26               ; $FA1A  27 0A
                 JSR     L_FCF5               ; $FA1C  BD FC F5
                 LDAA    ZP_47                ; $FA1F  96 47
                 BEQ     L_FA26               ; $FA21  27 03
                 JSR     L_FCF5               ; $FA23  BD FC F5
L_FA26           JSR     L_FB2F               ; $FA26  BD FB 2F
                 LDX     #$0007               ; $FA29  CE 00 07
                 JSR     ROMB_ECBA            ; $FA2C  BD EC BA
                 JMP     ROMB_ECC1            ; $FA2F  7E EC C1

; --- Dispatch table: 10 DW entries ($FA32-$FA47) ---
L_FA32           DW      L_FA48               ; $FA32
                 DW      L_FA48               ; $FA34
                 DW      L_FAA5               ; $FA36
                 DW      L_FAA5               ; $FA38
                 DW      L_FAAD               ; $FA3A
                 DW      L_FAAD               ; $FA3C
                 DW      L_FC0B               ; $FA3E
                 DW      L_FC05               ; $FA40
                 DW      L_FA62               ; $FA42
                 DW      L_FA49               ; $FA44
                 DW      L_FA82               ; $FA46
L_FA48           RTS                          ; $FA48  39
L_FA49           LDAA    PIA1_DB              ; $FA49  B6 78 02
                 LDAB    ZP_42                ; $FA4C  D6 42
                 BEQ     L_FA52               ; $FA4E  27 02
                 EORA    ZP_42                ; $FA50  98 42
L_FA52           ANDA    #$04                 ; $FA52  84 04
                 LSRA                         ; $FA54  44
                 LSRA                         ; $FA55  44
                 ORAA    #$30                 ; $FA56  8A 30
                 LDAB    ZP_54                ; $FA58  D6 54
                 BITB    #$40                 ; $FA5A  C5 40
                 BNE     L_FA5F               ; $FA5C  26 01
                 INCA                         ; $FA5E  4C
L_FA5F           JSR     L_FCF5               ; $FA5F  BD FC F5
L_FA62           LDAA    ZP_16                ; $FA62  96 16
                 DECA                         ; $FA64  4A
                 SUBA    ZP_15                ; $FA65  90 15
                 BGE     L_FA6B               ; $FA67  2C 02
                 ADDA    #$18                 ; $FA69  8B 18
L_FA6B           ADDA    #$20                 ; $FA6B  8B 20
                 JSR     L_FCF5               ; $FA6D  BD FC F5
                 LDAA    ZP_17                ; $FA70  96 17
                 ADDA    #$20                 ; $FA72  8B 20
                 JMP     L_FCF5               ; $FA74  7E FC F5
L_FA77           LDAA    ZP_4B                ; $FA77  96 4B
                 JSR     L_FCF5               ; $FA79  BD FC F5
                 LDAA    ZP_C5                ; $FA7C  96 C5
                 COMA                         ; $FA7E  43
                 JMP     L_FCF5               ; $FA7F  7E FC F5
L_FA82           LDX     #$7B80               ; $FA82  CE 7B 80
                 STX     ZP_B7                ; $FA85  DF B7
                 LDAA    $1E,X                ; $FA87  A6 1E
                 CMPA    #$0D                 ; $FA89  81 0D
                 BNE     L_FAA4               ; $FA8B  26 17
                 LDAA    $1F,X                ; $FA8D  A6 1F
                 CMPA    #$8A                 ; $FA8F  81 8A
                 BNE     L_FAA4               ; $FA91  26 11
                 ANDA    #$7F                 ; $FA93  84 7F
                 STAA    ZP_C5                ; $FA95  97 C5
L_FA97           LDX     ZP_B7                ; $FA97  DE B7
                 LDAA    $00,X                ; $FA99  A6 00
                 INX                          ; $FA9B  08
                 STX     ZP_B7                ; $FA9C  DF B7
                 JSR     L_FCF5               ; $FA9E  BD FC F5
                 TSTA                         ; $FAA1  4D
                 BPL     L_FA97               ; $FAA2  2A F3
L_FAA4           RTS                          ; $FAA4  39
L_FAA5           JSR     L_FB26               ; $FAA5  BD FB 26
                 JSR     ROMC_F2E5            ; $FAA8  BD F2 E5
                 BRA     L_FAC4               ; $FAAB  20 17
L_FAAD           JSR     L_FB26               ; $FAAD  BD FB 26
                 LDAA    ZP_42                ; $FAB0  96 42
                 BEQ     L_FAC1               ; $FAB2  27 0D
                 LDAB    PIA1_DB              ; $FAB4  F6 78 02
                 ANDA    #$04                 ; $FAB7  84 04
                 ANDB    #$04                 ; $FAB9  C4 04
                 CBA                          ; $FABB  11
                 BEQ     L_FAC1               ; $FABC  27 03
                 JSR     ROMC_F65E            ; $FABE  BD F6 5E
L_FAC1           JSR     ROMC_F2CF            ; $FAC1  BD F2 CF
L_FAC4           CLRA                         ; $FAC4  4F
                 DB      $B7,$00,$1E              ; $FAC5  B7 00 1E (EXT ZP forced)
                 STAA    ZP_C6                ; $FAC8  97 C6
L_FACA           JSR     ROMB_EF8B            ; $FACA  BD EF 8B
                 DB      $7D,$00,$AE              ; $FACD  7D 00 AE (EXT ZP forced)
                 BMI     L_FAFF               ; $FAD0  2B 2D
                 JSR     L_FB57               ; $FAD2  BD FB 57
                 LDAB    ZP_50                ; $FAD5  D6 50
                 BPL     L_FADD               ; $FAD7  2A 04
                 CMPA    #$03                 ; $FAD9  81 03
                 BEQ     L_FAFF               ; $FADB  27 22
L_FADD           BITB    #$10                 ; $FADD  C5 10
                 BEQ     L_FAE7               ; $FADF  27 06
                 LDX     ZP_13                ; $FAE1  DE 13
                 CPX     ZP_C1                ; $FAE3  9C C1
                 BEQ     L_FAFF               ; $FAE5  27 18
L_FAE7           TSTA                         ; $FAE7  4D
                 BEQ     L_FAED               ; $FAE8  27 03
                 JSR     L_FCF5               ; $FAEA  BD FC F5
L_FAED           LDX     ZP_13                ; $FAED  DE 13
                 CPX     ZP_C1                ; $FAEF  9C C1
                 BEQ     L_FAFF               ; $FAF1  27 0C
                 JSR     L_FB4C               ; $FAF3  BD FB 4C
                 DB      $7D,$00,$17              ; $FAF6  7D 00 17 (EXT ZP forced)
                 BNE     L_FACA               ; $FAF9  26 CF
                 BSR     L_FB00               ; $FAFB  8D 03
                 BRA     L_FACA               ; $FAFD  20 CB
L_FAFF           RTS                          ; $FAFF  39
L_FB00           LDAA    ZP_55                ; $FB00  96 55
                 BITA    #$10                 ; $FB02  85 10
                 BEQ     L_FB0A               ; $FB04  27 04
                 LDAA    ZP_18                ; $FB06  96 18
                 BMI     L_FB25               ; $FB08  2B 1B
L_FB0A           LDAA    ZP_48                ; $FB0A  96 48
                 BEQ     L_FB25               ; $FB0C  27 17
                 JSR     L_FCF5               ; $FB0E  BD FC F5
                 LDAA    ZP_49                ; $FB11  96 49
                 BEQ     L_FB25               ; $FB13  27 10
                 JMP     L_FCF5               ; $FB15  7E FC F5
L_FB18           PSHA                         ; $FB18  36
                 LDAA    ZP_CD                ; $FB19  96 CD
                 BNE     L_FB24               ; $FB1B  26 07
                 LDAA    ZP_4A                ; $FB1D  96 4A
                 BEQ     L_FB24               ; $FB1F  27 03
                 JSR     L_FCF5               ; $FB21  BD FC F5
L_FB24           PULA                         ; $FB24  32
L_FB25           RTS                          ; $FB25  39
L_FB26           LDX     ZP_16                ; $FB26  DE 16
                 STX     ZP_C3                ; $FB28  DF C3
                 LDX     ZP_13                ; $FB2A  DE 13
                 STX     ZP_C1                ; $FB2C  DF C1
                 RTS                          ; $FB2E  39
L_FB2F           LDAA    ZP_18                ; $FB2F  96 18
                 BNE     L_FB48               ; $FB31  26 15
                 LDAA    ZP_C5                ; $FB33  96 C5
                 CMPA    #$02                 ; $FB35  81 02
                 BLT     L_FB48               ; $FB37  2D 0F
                 CMPA    #$06                 ; $FB39  81 06
                 BGT     L_FB48               ; $FB3B  2E 0B
                 BLT     L_FB45               ; $FB3D  2D 06
                 LDAB    ZP_54                ; $FB3F  D6 54
                 BITB    #$20                 ; $FB41  C5 20
                 BEQ     L_FB48               ; $FB43  27 03
L_FB45           JSR     ROMC_F29A            ; $FB45  BD F2 9A
L_FB48           DB      $7F,$00,$C5              ; $FB48  7F 00 C5 (EXT ZP forced)
                 RTS                          ; $FB4B  39
L_FB4C           JSR     ROMC_F2F0            ; $FB4C  BD F2 F0
                 DB      $7D,$00,$B5              ; $FB4F  7D 00 B5 (EXT ZP forced)
                 BEQ     L_FB72               ; $FB52  27 1E
                 JMP     ROMC_F313            ; $FB54  7E F3 13
L_FB57           LDX     ZP_13                ; $FB57  DE 13
                 STAA    HALT                 ; $FB59  B7 70 00
                 NOP                          ; $FB5C  01
                 LDAA    $00,X                ; $FB5D  A6 00
                 DB      $7D,$00,$18              ; $FB5F  7D 00 18 (EXT ZP forced)
                 BNE     L_FB73               ; $FB62  26 0F
                 TAB                          ; $FB64  16
                 ANDB    #$F0                 ; $FB65  C4 F0
                 CMPB    #$90                 ; $FB67  C1 90
                 BNE     L_FB6D               ; $FB69  26 02
                 LDAA    #$20                 ; $FB6B  86 20
L_FB6D           ANDA    #$7F                 ; $FB6D  84 7F
                 DB      $7F,$00,$CD              ; $FB6F  7F 00 CD (EXT ZP forced)
L_FB72           RTS                          ; $FB72  39
L_FB73           LDAB    ZP_C5                ; $FB73  D6 C5
                 BITB    #$01                 ; $FB75  C5 01
                 BNE     L_FBB6               ; $FB77  26 3D
                 LDAB    ZP_C6                ; $FB79  D6 C6
                 TSTA                         ; $FB7B  4D
                 BMI     L_FB89               ; $FB7C  2B 0B
                 CMPB    #$01                 ; $FB7E  C1 01
                 BNE     L_FB72               ; $FB80  26 F0
                 DB      $7F,$00,$C6              ; $FB82  7F 00 C6 (EXT ZP forced)
                 BSR     L_FB18               ; $FB85  8D 91
                 BRA     L_FB6D               ; $FB87  20 E4
L_FB89           CMPA    #$E0                 ; $FB89  81 E0
                 BEQ     L_FBA5               ; $FB8B  27 18
                 CMPB    #$02                 ; $FB8D  C1 02
                 BEQ     L_FB6D               ; $FB8F  27 DC
L_FB91           LDAB    #$01                 ; $FB91  C6 01
L_FB93           STAB    ZP_C6                ; $FB93  D7 C6
                 CPX     ZP_C1                ; $FB95  9C C1
                 BEQ     L_FBB4               ; $FB97  27 1B
L_FB99           JSR     L_FB4C               ; $FB99  BD FB 4C
                 LDAB    ZP_17                ; $FB9C  D6 17
                 BNE     L_FB57               ; $FB9E  26 B7
                 JSR     L_FB00               ; $FBA0  BD FB 00
                 BRA     L_FB57               ; $FBA3  20 B2
L_FBA5           CMPB    #$02                 ; $FBA5  C1 02
                 BEQ     L_FB91               ; $FBA7  27 E8
                 CMPB    #$01                 ; $FBA9  C1 01
                 BNE     L_FBB0               ; $FBAB  26 03
                 JSR     L_FB18               ; $FBAD  BD FB 18
L_FBB0           LDAB    #$02                 ; $FBB0  C6 02
                 BRA     L_FB93               ; $FBB2  20 DF
L_FBB4           CLRA                         ; $FBB4  4F
                 RTS                          ; $FBB5  39
L_FBB6           TSTA                         ; $FBB6  4D
                 BMI     L_FBCF               ; $FBB7  2B 16
                 DB      $7D,$00,$C6              ; $FBB9  7D 00 C6 (EXT ZP forced)
                 BEQ     L_FB6D               ; $FBBC  27 AF
                 PSHA                         ; $FBBE  36
                 LDAA    ZP_45                ; $FBBF  96 45
                 JSR     L_FCF5               ; $FBC1  BD FC F5
                 LDAA    #$28                 ; $FBC4  86 28
                 JSR     L_FCF5               ; $FBC6  BD FC F5
                 DB      $7F,$00,$C6              ; $FBC9  7F 00 C6 (EXT ZP forced)
                 PULA                         ; $FBCC  32
                 BRA     L_FB6D               ; $FBCD  20 9E
L_FBCF           TAB                          ; $FBCF  16
                 ANDB    #$F0                 ; $FBD0  C4 F0
                 CMPB    #$90                 ; $FBD2  C1 90
                 BNE     L_FBED               ; $FBD4  26 17
                 PSHA                         ; $FBD6  36
                 LDAA    ZP_45                ; $FBD7  96 45
                 JSR     L_FCF5               ; $FBD9  BD FC F5
                 LDAA    #$47                 ; $FBDC  86 47
                 JSR     L_FCF5               ; $FBDE  BD FC F5
                 PULA                         ; $FBE1  32
                 ANDA    #$0F                 ; $FBE2  84 0F
                 JSR     ROMC_F626            ; $FBE4  BD F6 26
                 JSR     L_FCF5               ; $FBE7  BD FC F5
                 JMP     L_FB99               ; $FBEA  7E FB 99
L_FBED           DB      $7D,$00,$C6              ; $FBED  7D 00 C6 (EXT ZP forced)
                 BNE     L_FC02               ; $FBF0  26 10
                 PSHA                         ; $FBF2  36
                 LDAA    ZP_45                ; $FBF3  96 45
                 JSR     L_FCF5               ; $FBF5  BD FC F5
                 LDAA    #$29                 ; $FBF8  86 29
                 JSR     L_FCF5               ; $FBFA  BD FC F5
                 LDAA    #$01                 ; $FBFD  86 01
                 STAA    ZP_C6                ; $FBFF  97 C6
                 PULA                         ; $FC01  32
L_FC02           JMP     L_FB6D               ; $FC02  7E FB 6D
L_FC05           LDAA    ZP_54                ; $FC05  96 54
                 BITA    #$20                 ; $FC07  85 20
                 BNE     L_FC02               ; $FC09  26 F7
L_FC0B           JSR     L_FB26               ; $FC0B  BD FB 26
                 DB      $7F,$00,$BB              ; $FC0E  7F 00 BB (EXT ZP forced)
                 DB      $7F,$00,$BC              ; $FC11  7F 00 BC (EXT ZP forced)
                 LDAB    PIA1_DB              ; $FC14  F6 78 02
                 ANDB    #$04                 ; $FC17  C4 04
                 STAB    ZP_BD                ; $FC19  D7 BD
                 LDAA    ZP_54                ; $FC1B  96 54
                 BITA    #$20                 ; $FC1D  85 20
                 BEQ     L_FC2F               ; $FC1F  27 0E
                 LDAA    #$1C                 ; $FC21  86 1C
                 STAA    ZP_B9                ; $FC23  97 B9
                 STAA    ZP_BA                ; $FC25  97 BA
                 STAA    HALT                 ; $FC27  B7 70 00
                 NOP                          ; $FC2A  01
                 STAA    $00,X                ; $FC2B  A7 00
                 BRA     L_FC52               ; $FC2D  20 23
L_FC2F           LDAA    #$02                 ; $FC2F  86 02
                 STAA    ZP_B9                ; $FC31  97 B9
                 LDAA    #$03                 ; $FC33  86 03
                 STAA    ZP_BA                ; $FC35  97 BA
                 LDAA    ZP_42                ; $FC37  96 42
                 BEQ     L_FC43               ; $FC39  27 08
                 ANDA    #$04                 ; $FC3B  84 04
                 CBA                          ; $FC3D  11
                 BNE     L_FC43               ; $FC3E  26 03
                 JSR     ROMC_F65E            ; $FC40  BD F6 5E
L_FC43           LDAA    ZP_15                ; $FC43  96 15
                 JSR     ROMC_F5EA            ; $FC45  BD F5 EA
                 ADDB    ZP_11                ; $FC48  DB 11
                 ADDA    #$4F                 ; $FC4A  8B 4F
                 ADCB    #$00                 ; $FC4C  C9 00
                 STAB    ZP_BB                ; $FC4E  D7 BB
                 STAA    ZP_BC                ; $FC50  97 BC
L_FC52           LDAA    ZP_42                ; $FC52  96 42
                 BEQ     L_FC63               ; $FC54  27 0D
                 ANDA    #$04                 ; $FC56  84 04
                 LDAB    PIA1_DB              ; $FC58  F6 78 02
                 ANDB    #$04                 ; $FC5B  C4 04
                 CBA                          ; $FC5D  11
                 BEQ     L_FC63               ; $FC5E  27 03
                 JSR     ROMC_F65E            ; $FC60  BD F6 5E
L_FC63           LDAA    ZP_15                ; $FC63  96 15
                 SUBA    #$17                 ; $FC65  80 17
                 BGE     L_FC6B               ; $FC67  2C 02
                 ADDA    #$18                 ; $FC69  8B 18
L_FC6B           JSR     ROMC_F5EA            ; $FC6B  BD F5 EA
                 ADDB    ZP_11                ; $FC6E  DB 11
                 STAB    ZP_B7                ; $FC70  D7 B7
                 STAA    ZP_B8                ; $FC72  97 B8
                 LDAB    PIA1_DB              ; $FC74  F6 78 02
                 ANDB    #$04                 ; $FC77  C4 04
                 CMPB    ZP_BD                ; $FC79  D1 BD
                 BEQ     L_FC80               ; $FC7B  27 03
                 JSR     ROMC_F65E            ; $FC7D  BD F6 5E
L_FC80           LDX     ZP_13                ; $FC80  DE 13
                 CPX     ZP_B7                ; $FC82  9C B7
                 BEQ     L_FCAD               ; $FC84  27 27
L_FC86           JSR     ROMC_F36F            ; $FC86  BD F3 6F
                 STAA    HALT                 ; $FC89  B7 70 00
                 NOP                          ; $FC8C  01
                 LDAA    $00,X                ; $FC8D  A6 00
                 CMPA    ZP_B9                ; $FC8F  91 B9
                 BEQ     L_FC99               ; $FC91  27 06
                 CPX     ZP_B7                ; $FC93  9C B7
                 BNE     L_FC86               ; $FC95  26 EF
                 BRA     L_FCAD               ; $FC97  20 14
L_FC99           LDAB    ZP_54                ; $FC99  D6 54
                 BITB    #$20                 ; $FC9B  C5 20
                 BEQ     L_FCA5               ; $FC9D  27 06
                 LDAB    ZP_16                ; $FC9F  D6 16
                 CMPB    ZP_C3                ; $FCA1  D1 C3
                 BNE     L_FCAA               ; $FCA3  26 05
L_FCA5           JSR     L_FB4C               ; $FCA5  BD FB 4C
                 BRA     L_FCAD               ; $FCA8  20 03
L_FCAA           JSR     ROMC_F313            ; $FCAA  BD F3 13
L_FCAD           LDX     ZP_BB                ; $FCAD  DE BB
                 STX     ZP_C1                ; $FCAF  DF C1
L_FCB1           JSR     ROMB_EF8B            ; $FCB1  BD EF 8B
                 DB      $7D,$00,$AE              ; $FCB4  7D 00 AE (EXT ZP forced)
                 BMI     L_FCD9               ; $FCB7  2B 20
                 JSR     L_FB57               ; $FCB9  BD FB 57
                 TSTA                         ; $FCBC  4D
                 BEQ     L_FCC6               ; $FCBD  27 07
                 CMPA    ZP_BA                ; $FCBF  91 BA
                 BEQ     L_FCD9               ; $FCC1  27 16
                 JSR     L_FCF5               ; $FCC3  BD FC F5
L_FCC6           LDX     ZP_13                ; $FCC6  DE 13
                 CPX     ZP_C1                ; $FCC8  9C C1
                 BEQ     L_FCDA               ; $FCCA  27 0E
                 JSR     L_FB4C               ; $FCCC  BD FB 4C
                 DB      $7D,$00,$17              ; $FCCF  7D 00 17 (EXT ZP forced)
                 BNE     L_FCB1               ; $FCD2  26 DD
                 JSR     L_FB00               ; $FCD4  BD FB 00
                 BRA     L_FCB1               ; $FCD7  20 D8
L_FCD9           RTS                          ; $FCD9  39
L_FCDA           JMP     ROMC_F28F            ; $FCDA  7E F2 8F
L_FCDD           LDAB    ZP_CC                ; $FCDD  D6 CC
                 ORAB    #$01                 ; $FCDF  CA 01
                 STAB    ZP_CC                ; $FCE1  D7 CC
                 PSHA                         ; $FCE3  36
                 LDAB    SW_BNK1              ; $FCE4  F6 7E 00
                 ANDB    #$1C                 ; $FCE7  C4 1C
                 LDAA    ZP_BF                ; $FCE9  96 BF
                 ANDA    #$83                 ; $FCEB  84 83
                 ABA                          ; $FCED  1B
                 STAA    ZP_BF                ; $FCEE  97 BF
                 STAA    ACIA_CS              ; $FCF0  B7 7A 00
                 PULA                         ; $FCF3  32
                 RTS                          ; $FCF4  39
L_FCF5           PSHA                         ; $FCF5  36
                 DB      $7D,$00,$CC              ; $FCF6  7D 00 CC (EXT ZP forced)
                 BNE     L_FCFD               ; $FCF9  26 02
                 BSR     L_FCDD               ; $FCFB  8D E0
L_FCFD           LDAB    ZP_CB                ; $FCFD  D6 CB
                 CMPB    #$0C                 ; $FCFF  C1 0C
                 BEQ     L_FCFD               ; $FD01  27 FA
                 LDX     ZP_C9                ; $FD03  DE C9
                 PULA                         ; $FD05  32
                 STAA    $00,X                ; $FD06  A7 00
                 TAB                          ; $FD08  16
                 EORB    $0E                  ; $FD09  D8 0E
                 STAB    $0E                  ; $FD0B  D7 0E
                 DB      $7C,$00,$CB              ; $FD0D  7C 00 CB (EXT ZP forced)
                 INX                          ; $FD10  08
                 CPX     #$010C               ; $FD11  8C 01 0C
                 BNE     L_FD19               ; $FD14  26 03
                 LDX     #$0100               ; $FD16  CE 01 00
L_FD19           STX     ZP_C9                ; $FD19  DF C9
                 LDAB    ZP_BF                ; $FD1B  D6 BF
                 ANDB    #$9F                 ; $FD1D  C4 9F
                 ORAB    #$20                 ; $FD1F  CA 20
                 STAB    ZP_BF                ; $FD21  D7 BF
                 STAB    ACIA_CS              ; $FD23  F7 7A 00
                 RTS                          ; $FD26  39
                 DB      $7F,$00,$CC              ; $FD27  7F 00 CC (EXT ZP forced)
L_FD2A           LDAA    ZP_CB                ; $FD2A  96 CB
                 BEQ     L_FD35               ; $FD2C  27 07
                 LDAA    #$01                 ; $FD2E  86 01
                 JSR     ROMB_ECCC            ; $FD30  BD EC CC
                 BRA     L_FD2A               ; $FD33  20 F5
L_FD35           LDAA    ACIA_CS              ; $FD35  B6 7A 00
                 BITA    #$02                 ; $FD38  85 02
                 BEQ     L_FD2A               ; $FD3A  27 EE
                 LDAA    ZP_4F                ; $FD3C  96 4F
                 BNE     L_FD4D               ; $FD3E  26 0D
                 LDX     #L_FD75              ; $FD40  CE FD 75
                 LDAA    $7E80                ; $FD43  B6 7E 80
                 ANDA    #$0F                 ; $FD46  84 0F
                 JSR     ROMB_EFAD            ; $FD48  BD EF AD
                 LDAA    $00,X                ; $FD4B  A6 00
L_FD4D           JSR     ROMB_ECCC            ; $FD4D  BD EC CC
                 LDAA    ZP_BF                ; $FD50  96 BF
                 ANDA    #$9F                 ; $FD52  84 9F
                 ORAA    #$40                 ; $FD54  8A 40
                 STAA    ZP_BF                ; $FD56  97 BF
                 STAA    ACIA_CS              ; $FD58  B7 7A 00
                 LDX     #$0000               ; $FD5B  CE 00 00
                 JSR     ROMB_ECBA            ; $FD5E  BD EC BA
                 LDX     #$0002               ; $FD61  CE 00 02
                 JSR     ROMB_ECBA            ; $FD64  BD EC BA
                 JMP     ROMB_ECC1            ; $FD67  7E EC C1
                 LDX     #$0100               ; $FD6A  CE 01 00
                 STX     ZP_C9                ; $FD6D  DF C9
                 STX     ZP_C7                ; $FD6F  DF C7
                 DB      $7F,$00,$CB              ; $FD71  7F 00 CB (EXT ZP forced)
                 RTS                          ; $FD74  39

; --- Baud rate lookup table ($FD75-$FD84) ---
L_FD75           DB      $AC,$73,$58,$40,$3A,$1D,$0F,$08
                 DB      $05,$05,$04,$03,$02,$02,$02,$01
                 DB      $7D,$00,$CB              ; $FD85  7D 00 CB (EXT ZP forced)
                 BEQ     L_FDA4               ; $FD88  27 1A
                 LDX     ZP_C7                ; $FD8A  DE C7
                 LDAA    $00,X                ; $FD8C  A6 00
                 ANDA    #$7F                 ; $FD8E  84 7F
                 ORAA    $CE                  ; $FD90  9A CE
                 STAA    ACIA_DA              ; $FD92  B7 7A 01
                 DB      $7A,$00,$CB              ; $FD95  7A 00 CB (EXT ZP forced)
                 INX                          ; $FD98  08
                 CPX     #$010C               ; $FD99  8C 01 0C
                 BNE     L_FDA1               ; $FD9C  26 03
                 LDX     #$0100               ; $FD9E  CE 01 00
L_FDA1           STX     ZP_C7                ; $FDA1  DF C7
                 RTS                          ; $FDA3  39
L_FDA4           LDAA    ZP_BF                ; $FDA4  96 BF
                 ANDA    #$9F                 ; $FDA6  84 9F
                 STAA    ZP_BF                ; $FDA8  97 BF
                 STAA    ACIA_CS              ; $FDAA  B7 7A 00
                 RTS                          ; $FDAD  39
                 ORAA    $D6,X                ; $FDAE  AA D6
                 COMB                         ; $FDB0  53
                 BITB    #$04                 ; $FDB1  C5 04
                 BNE     L_FE00               ; $FDB3  26 4B
                 LDAB    ZP_D1                ; $FDB5  D6 D1
                 BNE     L_FE00               ; $FDB7  26 47
                 ORAB    #$80                 ; $FDB9  CA 80
                 STAB    ZP_D1                ; $FDBB  D7 D1
                 STAA    ZP_D0                ; $FDBD  97 D0
                 JSR     ROMB_EFBC            ; $FDBF  BD EF BC
                 DB      $7F,$00,$AE              ; $FDC2  7F 00 AE (EXT ZP forced)
                 LDAA    ZP_D0                ; $FDC5  96 D0
                 BMI     L_FDD9               ; $FDC7  2B 10
                 LDX     ZP_13                ; $FDC9  DE 13
                 LDAA    ZP_DB                ; $FDCB  96 DB
                 STAA    HALT                 ; $FDCD  B7 70 00
                 NOP                          ; $FDD0  01
                 STAA    $00,X                ; $FDD1  A7 00
                 JSR     ROMC_F259            ; $FDD3  BD F2 59
                 JSR     ROMC_F2CF            ; $FDD6  BD F2 CF
L_FDD9           LDAA    $9E                  ; $FDD9  96 9E
                 STAA    ZP_CF                ; $FDDB  97 CF
                 LDX     #$0000               ; $FDDD  CE 00 00
                 STX     ZP_B7                ; $FDE0  DF B7
L_FDE2           LDAA    SW_BNK2              ; $FDE2  B6 79 00
                 ANDA    #$1C                 ; $FDE5  84 1C
                 ORAA    #$01                 ; $FDE7  8A 01
                 STAA    ZP_C0                ; $FDE9  97 C0
                 STAA    PRNTER               ; $FDEB  B7 7C 00
                 LDX     #$0005               ; $FDEE  CE 00 05
                 JSR     ROMB_ECBA            ; $FDF1  BD EC BA
                 LDX     #$0000               ; $FDF4  CE 00 00
                 JSR     ROMB_ECC3            ; $FDF7  BD EC C3
                 LDX     #$0002               ; $FDFA  CE 00 02
                 JMP     ROMB_ECC3            ; $FDFD  7E EC C3
L_FE00           JMP     ROMC_F0DA            ; $FE00  7E F0 DA
                 BSR     L_FE45               ; $FE03  8D 40
                 DB      $7D,$00,$D0              ; $FE05  7D 00 D0 (EXT ZP forced)
                 BEQ     L_FE0B               ; $FE08  27 01
                 RTS                          ; $FE0A  39
L_FE0B           LDAA    ZP_CF                ; $FE0B  96 CF
                 CMPA    #$03                 ; $FE0D  81 03
                 BNE     L_FE36               ; $FE0F  26 25
                 LDAA    #$01                 ; $FE11  86 01
                 JSR     L_F9DA               ; $FE13  BD F9 DA
                 JMP     ROMB_ECC1            ; $FE16  7E EC C1
                 LDX     #$0002               ; $FE19  CE 00 02
                 JSR     ROMB_ECBA            ; $FE1C  BD EC BA
L_FE1F           DB      $B6,$00,$01              ; $FE1F  B6 00 01 (EXT ZP forced)
                 CMPA    #$02                 ; $FE22  81 02
                 BEQ     L_FE28               ; $FE24  27 02
                 BSR     L_FE45               ; $FE26  8D 1D
L_FE28           DB      $7D,$00,$D0              ; $FE28  7D 00 D0 (EXT ZP forced)
                 BEQ     L_FE36               ; $FE2B  27 09
                 LDAA    #$01                 ; $FE2D  86 01
                 JSR     ROMB_ECCC            ; $FE2F  BD EC CC
                 BRA     L_FE1F               ; $FE32  20 EB
                 BEQ     L_FE8C               ; $FE34  27 56
L_FE36           LDX     #$0002               ; $FE36  CE 00 02
                 JSR     ROMB_ECBA            ; $FE39  BD EC BA
                 LDX     #$0000               ; $FE3C  CE 00 00
                 JSR     ROMB_ECBA            ; $FE3F  BD EC BA
                 JMP     ROMB_ECC1            ; $FE42  7E EC C1
L_FE45           JSR     ROMB_EF8B            ; $FE45  BD EF 8B
                 LDAB    PRNTER               ; $FE48  F6 7C 00
                 ANDB    #$0A                 ; $FE4B  C4 0A
                 CMPB    #$02                 ; $FE4D  C1 02
                 BEQ     L_FE57               ; $FE4F  27 06
                 DB      $7D,$00,$AE              ; $FE51  7D 00 AE (EXT ZP forced)
                 DB      $2B,$78                  ; $FE54  2B 78 (BMI forced)
                 RTS                          ; $FE56  39
L_FE57           LDAB    ZP_D0                ; $FE57  D6 D0
                 DB      $2B,$73                  ; $FE59  2B 73 (BMI forced)
                 ANDB    #$0F                 ; $FE5B  C4 0F
                 DECB                         ; $FE5D  5A
                 BEQ     L_FE7F               ; $FE5E  27 1F
                 DECB                         ; $FE60  5A
                 BEQ     L_FE8C               ; $FE61  27 29
                 DECB                         ; $FE63  5A
                 BEQ     L_FE88               ; $FE64  27 22
                 DECB                         ; $FE66  5A
                 BEQ     L_FEA4               ; $FE67  27 3B
                 DECB                         ; $FE69  5A
                 BEQ     L_FECE               ; $FE6A  27 62
                 DECB                         ; $FE6C  5A
                 BEQ     L_FE7F               ; $FE6D  27 10
                 DECB                         ; $FE6F  5A
                 BEQ     L_FE8C               ; $FE70  27 1A
                 DECB                         ; $FE72  5A
                 BEQ     L_FE88               ; $FE73  27 13
                 DECB                         ; $FE75  5A
                 BEQ     L_FE8C               ; $FE76  27 14
                 DECB                         ; $FE78  5A
                 BEQ     L_FE8F               ; $FE79  27 14
                 CLRB                         ; $FE7B  5F
                 STAB    ZP_D0                ; $FE7C  D7 D0
                 RTS                          ; $FE7E  39
L_FE7F           LDAA    #$0D                 ; $FE7F  86 0D
L_FE81           DB      $7C,$00,$D0              ; $FE81  7C 00 D0 (EXT ZP forced)
                 STAA    $7C01                ; $FE84  B7 7C 01
                 RTS                          ; $FE87  39
L_FE88           LDAA    #$0A                 ; $FE88  86 0A
                 BRA     L_FE81               ; $FE8A  20 F5
L_FE8C           CLRA                         ; $FE8C  4F
                 BRA     L_FE81               ; $FE8D  20 F2
L_FE8F           DB      $7F,$00,$D0              ; $FE8F  7F 00 D0 (EXT ZP forced)
                 LDAA    ZP_D1                ; $FE92  96 D1
                 ANDA    #$7F                 ; $FE94  84 7F
                 STAA    ZP_D1                ; $FE96  97 D1
                 LDAA    ZP_C0                ; $FE98  96 C0
                 ANDA    #$9F                 ; $FE9A  84 9F
                 ORAA    #$40                 ; $FE9C  8A 40
                 STAA    ZP_C0                ; $FE9E  97 C0
                 STAA    PRNTER               ; $FEA0  B7 7C 00
                 RTS                          ; $FEA3  39
L_FEA4           BSR     L_FE8C               ; $FEA4  8D E6
                 LDX     ZP_13                ; $FEA6  DE 13
                 STX     ZP_B7                ; $FEA8  DF B7
                 LDAA    ZP_B8                ; $FEAA  96 B8
                 ADDA    #$50                 ; $FEAC  8B 50
                 STAA    ZP_B8                ; $FEAE  97 B8
                 LDAA    ZP_B7                ; $FEB0  96 B7
                 ADCA    #$00                 ; $FEB2  89 00
                 STAA    ZP_B7                ; $FEB4  97 B7
                 LDX     ZP_B7                ; $FEB6  DE B7
L_FEB8           DEX                          ; $FEB8  09
                 CPX     ZP_13                ; $FEB9  9C 13
                 BEQ     L_FECB               ; $FEBB  27 0E
                 STAA    HALT                 ; $FEBD  B7 70 00
                 NOP                          ; $FEC0  01
                 LDAA    $00,X                ; $FEC1  A6 00
                 ANDA    #$7F                 ; $FEC3  84 7F
                 BEQ     L_FEB8               ; $FEC5  27 F1
                 CMPA    #$20                 ; $FEC7  81 20
                 BEQ     L_FEB8               ; $FEC9  27 ED
L_FECB           STX     ZP_B7                ; $FECB  DF B7
                 RTS                          ; $FECD  39
L_FECE           LDX     ZP_13                ; $FECE  DE 13
                 STAA    HALT                 ; $FED0  B7 70 00
                 NOP                          ; $FED3  01
                 LDAA    $00,X                ; $FED4  A6 00
                 TAB                          ; $FED6  16
                 CMPB    ZP_DB                ; $FED7  D1 DB
                 BEQ     L_FF25               ; $FED9  27 4A
                 DB      $7D,$00,$AE              ; $FEDB  7D 00 AE (EXT ZP forced)
                 BMI     L_FEFE               ; $FEDE  2B 1E
                 DB      $7D,$00,$D0              ; $FEE0  7D 00 D0 (EXT ZP forced)
                 BMI     L_FEF7               ; $FEE3  2B 12
                 BITB    ZP_18                ; $FEE5  D5 18
                 BEQ     L_FEF1               ; $FEE7  27 08
                 LDAB    ZP_D0                ; $FEE9  D6 D0
                 BITB    #$10                 ; $FEEB  C5 10
                 BEQ     L_FEF1               ; $FEED  27 02
                 LDAA    #$20                 ; $FEEF  86 20
L_FEF1           ANDA    #$7F                 ; $FEF1  84 7F
                 BNE     L_FEF7               ; $FEF3  26 02
                 LDAA    #$20                 ; $FEF5  86 20
L_FEF7           STAA    $7C01                ; $FEF7  B7 7C 01
                 CPX     ZP_B7                ; $FEFA  9C B7
                 BEQ     L_FF1B               ; $FEFC  27 1D
L_FEFE           LDAA    ZP_17                ; $FEFE  96 17
                 CMPA    #$4F                 ; $FF00  81 4F
                 BNE     L_FF18               ; $FF02  26 14
                 LDAA    ZP_16                ; $FF04  96 16
                 CMPA    ZP_15                ; $FF06  91 15
                 BNE     L_FF18               ; $FF08  26 0E
                 LDAA    ZP_42                ; $FF0A  96 42
                 BEQ     L_FE8F               ; $FF0C  27 81
                 LDAB    PIA1_DB              ; $FF0E  F6 78 02
                 ANDA    #$02                 ; $FF11  84 02
                 ANDB    #$04                 ; $FF13  C4 04
                 CBA                          ; $FF15  11
                 BNE     L_FF36               ; $FF16  26 1E
L_FF18           JMP     ROMC_F2F0            ; $FF18  7E F2 F0
L_FF1B           LDAA    ZP_D0                ; $FF1B  96 D0
                 ANDA    #$F0                 ; $FF1D  84 F0
                 INCA                         ; $FF1F  4C
                 STAA    ZP_D0                ; $FF20  97 D0
                 JMP     ROMC_F313            ; $FF22  7E F3 13
L_FF25           LDAA    #$20                 ; $FF25  86 20
                 STAA    HALT                 ; $FF27  B7 70 00
                 NOP                          ; $FF2A  01
                 STAA    $00,X                ; $FF2B  A7 00
                 DB      $7D,$00,$AE              ; $FF2D  7D 00 AE (EXT ZP forced)
                 BMI     L_FF36               ; $FF30  2B 04
                 LDAA    ZP_D0                ; $FF32  96 D0
                 BPL     L_FF39               ; $FF34  2A 03
L_FF36           JMP     L_FE8F               ; $FF36  7E FE 8F
L_FF39           ANDA    #$F0                 ; $FF39  84 F0
                 ORAA    #$06                 ; $FF3B  8A 06
                 STAA    ZP_D0                ; $FF3D  97 D0
                 RTS                          ; $FF3F  39
                 JSR     ROMB_ECE8            ; $FF40  BD EC E8
                 ANDA    #$03                 ; $FF43  84 03
                 BEQ     L_FF7A               ; $FF45  27 33
                 CMPA    #$03                 ; $FF47  81 03
                 BEQ     L_FF81               ; $FF49  27 36
                 CLI                          ; $FF4B  0E
                 DB      $7D,$00,$D2              ; $FF4C  7D 00 D2 (EXT ZP forced)
                 BNE     L_FF77               ; $FF4F  26 26
                 STAA    ZP_D2                ; $FF51  97 D2
                 DB      $7F,$00,$42              ; $FF53  7F 00 42 (EXT ZP forced)
                 LDAA    ZP_11                ; $FF56  96 11
                 BITA    #$08                 ; $FF58  85 08
                 BEQ     L_FF61               ; $FF5A  27 05
                 LDX     #CRTRAM              ; $FF5C  CE 80 00
                 BRA     L_FF64               ; $FF5F  20 03
L_FF61           LDX     #$8800               ; $FF61  CE 88 00
L_FF64           STX     ZP_D3                ; $FF64  DF D3
                 STX     ZP_D7                ; $FF66  DF D7
                 STX     ZP_D9                ; $FF68  DF D9
                 LDAA    ZP_D3                ; $FF6A  96 D3
                 ADDA    #$07                 ; $FF6C  8B 07
                 STAA    ZP_D5                ; $FF6E  97 D5
                 LDAA    #$CF                 ; $FF70  86 CF
                 STAA    ZP_D6                ; $FF72  97 D6
                 JMP     L_FDE2               ; $FF74  7E FD E2
L_FF77           STAA    ZP_D2                ; $FF77  97 D2
                 RTS                          ; $FF79  39
L_FF7A           DB      $7D,$00,$D2              ; $FF7A  7D 00 D2 (EXT ZP forced)
                 BEQ     L_FF81               ; $FF7D  27 02
                 BRA     L_FF88               ; $FF7F  20 07
L_FF81           RTS                          ; $FF81  39
                 ANDA    #$7F                 ; $FF82  84 7F
                 CMPA    #$14                 ; $FF84  81 14
                 BNE     L_FF8E               ; $FF86  26 06
L_FF88           LDAA    #$80                 ; $FF88  86 80
                 STAA    ZP_D2                ; $FF8A  97 D2
                 BRA     L_FF9F               ; $FF8C  20 11
L_FF8E           LDX     ZP_D7                ; $FF8E  DE D7
                 STAA    HALT                 ; $FF90  B7 70 00
                 NOP                          ; $FF93  01
                 STAA    $00,X                ; $FF94  A7 00
                 INX                          ; $FF96  08
                 CPX     ZP_D5                ; $FF97  9C D5
                 BNE     L_FF9D               ; $FF99  26 02
                 LDX     ZP_D3                ; $FF9B  DE D3
L_FF9D           STX     ZP_D7                ; $FF9D  DF D7
L_FF9F           LDAB    ZP_C0                ; $FF9F  D6 C0
                 ANDB    #$9F                 ; $FFA1  C4 9F
                 ORAB    #$20                 ; $FFA3  CA 20
                 STAB    ZP_C0                ; $FFA5  D7 C0
                 STAB    PRNTER               ; $FFA7  F7 7C 00
                 RTS                          ; $FFAA  39
                 LDX     ZP_D9                ; $FFAB  DE D9
                 CPX     ZP_D7                ; $FFAD  9C D7
                 BEQ     L_FFC4               ; $FFAF  27 13
                 STAA    HALT                 ; $FFB1  B7 70 00
                 NOP                          ; $FFB4  01
                 LDAA    $00,X                ; $FFB5  A6 00
                 STAA    $7C01                ; $FFB7  B7 7C 01
                 INX                          ; $FFBA  08
                 CPX     ZP_D5                ; $FFBB  9C D5
                 BNE     L_FFC1               ; $FFBD  26 02
                 LDX     ZP_D3                ; $FFBF  DE D3
L_FFC1           STX     ZP_D9                ; $FFC1  DF D9
                 RTS                          ; $FFC3  39
L_FFC4           LDAA    ZP_C0                ; $FFC4  96 C0
                 ANDA    #$9F                 ; $FFC6  84 9F
                 LDAB    ZP_D1                ; $FFC8  D6 D1
                 CMPB    #$01                 ; $FFCA  C1 01
                 BEQ     L_FFD2               ; $FFCC  27 04
                 LDAB    ZP_D2                ; $FFCE  D6 D2
                 BPL     L_FFE0               ; $FFD0  2A 0E
L_FFD2           LDAB    ZP_D2                ; $FFD2  D6 D2
                 BITB    #$08                 ; $FFD4  C5 08
                 BEQ     L_FFE6               ; $FFD6  27 0E
                 DB      $7F,$00,$D2              ; $FFD8  7F 00 D2 (EXT ZP forced)
                 ORAA    #$40                 ; $FFDB  8A 40
                 DB      $7F,$00,$D1              ; $FFDD  7F 00 D1 (EXT ZP forced)
L_FFE0           STAA    ZP_C0                ; $FFE0  97 C0
                 STAA    PRNTER               ; $FFE2  B7 7C 00
                 RTS                          ; $FFE5  39
L_FFE6           CLRA                         ; $FFE6  4F
                 STAA    $7C01                ; $FFE7  B7 7C 01
                 LDAA    #$88                 ; $FFEA  86 88
                 STAA    ZP_D2                ; $FFEC  97 D2
                 RTS                          ; $FFEE  39

; --- Padding before interrupt vectors ($FFEF-$FFF7) ($FFEF-$FFF7) ---
                 DB      $00,$00,$00,$00,$00,$00,$00,$00
                 DB      $72

; --- Interrupt vectors ($FFF8-$FFFF) ($FFF8-$FFFF) ---
                 DB      $ED,$83,$E8,$00,$E8,$00,$E8,$00

; =============================================================================
; Interrupt vectors at $FFF8-$FFFF
; Stock: all three targets = $E800 (ROM B entry = stock ADM-31 monitor)
; MONDEB patch: change SWI_VEC -> MONDEB_SWIADR
;               change NMI_VEC -> MONDEB_NMIADR
;               change RST_VEC -> MONDEB_START (=$E800 if MONDEB in ROM B)
; =============================================================================

IRQ_VEC          EQU     $ED83   ; ADM-31 ACIA IRQ (ROM B, do not change)
SWI_VEC          EQU     $E800   ; [PATCH for MONDEB: MONDEB SWIADR]
NMI_VEC          EQU     $E800   ; [PATCH for MONDEB: MONDEB NMIADR]
RST_VEC          EQU     $E800   ; [PATCH for MONDEB: MONDEB START=$E800]

        *= $FFF8   ; anchor interrupt vector table
                 DW      IRQ_VEC ; $FFF8-$FFF9  IRQ
                 DW      SWI_VEC ; $FFFA-$FFFB  SWI
                 DW      NMI_VEC ; $FFFC-$FFFD  NMI
                 DW      RST_VEC ; $FFFE-$FFFF  RST