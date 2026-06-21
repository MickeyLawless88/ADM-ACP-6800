* ----------------------------------------------------------------
*	 SINE - plot one full cycle of a sine wave down the screen.
* Uses a precomputed column table (no runtime math needed on the
* 6800).  Each table byte = number of leading spaces before the
* plotted point for that row.  Polled MC6850 ACIA output.
* ----------------------------------------------------------------
ACIAC   EQU   $7A00          ACIA control/status  (ADM-31 ACIA1)
ACIAD   EQU   $7A01          ACIA transmit/receive data
TDRE    EQU   $02            status bit: xmit data register empty
*
ROWS    EQU   48             samples in one cycle
SPACE   EQU   $20
STAR    EQU   $2A            '*'
CR      EQU   $0D
LF      EQU   $0A
*
        ORG   $0100
*
START   LDX   #SINTAB        X -> column table
        LDAB  #ROWS          B = row counter
ROW     PSHB                 save the row counter
        LDAA  0,X            A = column for this row
        TAB                  B = leading-space count
PAD     TSTB                 spaces remaining?
        BEQ   PLOT
        LDAA  #SPACE
        BSR   PUTC
        DECB
        BRA   PAD
PLOT    LDAA  #STAR          draw the point
        BSR   PUTC
        LDAA  #CR
        BSR   PUTC
        LDAA  #LF
        BSR   PUTC
        INX                  advance to next sample
        PULB                 restore the row counter
        DECB
        BNE   ROW
        SWI                  done -- back to monitor
*
* PUTC -- transmit A out the ACIA; preserves A and B
PUTC    PSHB
WAIT    LDAB  ACIAC
        BITB  #TDRE
        BEQ   WAIT
        STAA  ACIAD
        PULB
        RTS
*
* one cycle of sine, scaled to columns 2..38 (center 20, amplitude 18)
SINTAB  FCB   20,22,25,27,29,31,33,34
        FCB   36,37,37,38,38,38,37,37
        FCB   36,34,33,31,29,27,25,22
        FCB   20,18,15,13,11,9,7,6
        FCB   4,3,3,2,2,2,3,3
        FCB   4,6,7,9,11,13,15,18
        END
