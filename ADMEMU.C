/* ========================================================================
 * ADMEMU.C  -  Lear Siegler ADM-31 functional emulator (Motorola 6800),
 *              DOS/Turbo C port of adm31emu.c for use as ACPIDE's
 *              Run|Emulate target.
 *
 * The CPU core, memory map, ROM loading and keyboard-matrix logic below
 * are unchanged from adm31emu.c (same behaviour, same not-cycle-exact
 * scope described there).  Three front ends select at compile time:
 *
 *   tcc ADMEMU.C                 DOS/Turbo C, direct-video conio front end
 *   tcc -DHEADLESS ADMEMU.C      DOS/Turbo C, no display (regression test)
 *   cc -o admemu adm31emu.c -lncurses      original curses front end (Unix)
 *   cc -DHEADLESS -o admtest adm31emu.c    original headless self-test
 *
 * Usage (DOS, interactive):
 *     ADMEMU --romA cint.bin --romB rom67.bin --romC rom65.bin ^
 *            --romD rom66.bin [--boot firmware|plugin]
 *     ADMEMU --plugin cint.bin --boot plugin        (run plugin alone --
 *                                                     this is what ACPIDE's
 *                                                     Run|Emulate uses)
 *     ADMEMU --rom file@E000                         (load file at $E000)
 * ====================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(__TURBOC__) || defined(__BORLANDC__)
  typedef unsigned char  uint8_t;
  typedef unsigned int   uint16_t;
  typedef signed char    int8_t;
# define ADM_FAR far
# include <alloc.h>          /* farmalloc/farfree */
#else
# include <stdint.h>
# define ADM_FAR
#endif

#if !defined(HEADLESS) && !defined(__TURBOC__) && !defined(__BORLANDC__)
# include <curses.h>
#endif

#define MEM_SIZE 0x10000UL     /* full 64K; a compile-time array of exactly
                                 * this many bytes will not compile under
                                 * 16-bit Turbo C (sizeof/array bounds are
                                 * 16-bit and can't represent 65536), so on
                                 * that toolchain mem[]/is_rom[] are heap-
                                 * allocated far pointers instead of static
                                 * arrays -- see adm_alloc_mem() below.    */
#if defined(__TURBOC__) || defined(__BORLANDC__)
static uint8_t ADM_FAR *mem;
static uint8_t ADM_FAR *is_rom;
static void adm_alloc_mem(void)
{
    mem    = (uint8_t far *)farmalloc(MEM_SIZE);
    is_rom = (uint8_t far *)farmalloc(MEM_SIZE);
    if (!mem || !is_rom) { fprintf(stderr, "out of memory\n"); exit(1); }
}
/* memset()'s length is size_t -- also 16-bit here, so it can't take
 * 65536 in one call either (0x10000 truncates to 0).  Zero it in two
 * 32K halves instead; farmalloc's block is one contiguous segment, so
 * offset 0x8000 is still safely within it. */
static void adm_far_zero(uint8_t far *p)
{
    memset(p, 0, 0x8000);
    memset(p + 0x8000, 0, 0x8000);
}
#else
static uint8_t  mem[0x10000];       /* full 64K address space             */
static uint8_t  is_rom[0x10000];    /* 1 => writes ignored (ROM region)   */
#define adm_alloc_mem()  /* no-op -- mem/is_rom are static arrays here    */
#define adm_far_zero(p)  memset(p, 0, (size_t)MEM_SIZE)
#endif

static uint8_t  A, B, CC;
static uint16_t IX, SP, PC;
static int      halted;
static unsigned long cycles;

/* VSYNC / IRQ generation.  A real ADM-31 drives screen refresh, cursor
 * blink and keyboard scan from a periodic vertical-retrace interrupt.
 * Terminal firmware typically does nothing visible until it receives one,
 * so we generate a periodic IRQ (gated by the I flag) and also expose a
 * toggling retrace bit on the HALT/VSYNC strobe for poll-style waits. */
static int           irq_enabled = 0;
static unsigned long irq_period  = 20000; /* instrs between VSYNC IRQs    */
static unsigned long irq_accum   = 0;
static uint8_t       halt_op;             /* last bad opcode (for display)*/
static uint16_t      halt_pc;             /* address of last bad opcode   */

/* condition-code bits */
#define FLAG_C 0x01
#define FLAG_V 0x02
#define FLAG_Z 0x04
#define FLAG_N 0x08
#define FLAG_I 0x10
#define FLAG_H 0x20
#define CC_HI  0xC0                 /* bits 6,7 always read as 1          */

/* ---- I/O addresses --------------------------------------------------- */
#define IO_HALT  0x7000
#define IO_PIA1  0x7800
#define IO_ACIA  0x7A00             /* $7A00 status/ctrl, $7A01 data      */
#define IO_VTAC  0x7F00

/* ---- CRTRAM display geometry ----------------------------------------- */
#define CRTRAM_BASE 0x8000
#define SCR_COLS    80
#define SCR_ROWS    24

/* ---- ACIA receive queue (host keyboard -> 6800) ---------------------- */
static unsigned char rxq[256];
static int rxq_head, rxq_tail;
static int rx_empty(void) { return rxq_head == rxq_tail; }
static void rx_push(unsigned char c)
{
    int nt = (rxq_tail + 1) & 0xFF;
    if (nt != rxq_head) { rxq[rxq_tail] = c; rxq_tail = nt; }
}
static unsigned char rx_pop(void)
{
    unsigned char c;
    if (rx_empty()) return 0;
    c = rxq[rxq_head];
    rxq_head = (rxq_head + 1) & 0xFF;
    return c;
}

/* tx capture (6800 -> host) - logged, not otherwise used here */
static FILE *txlog;

/* ---- PIA1 keyboard matrix --------------------------------------------
 * Derived from the ADM-31 manual (sec 4.7) and verified against ROM67:
 *   - MPU writes a binary scan count to PIA Per.Reg.A ($7800).
 *     low 4 bits = column (4-to-16 decoder), high 3 bits = row (8-to-1 mux).
 *   - On a key at the selected intersection, STROBE feeds back as $7800 bit7.
 *   - SHIFT / CONTROL are read on Per.Reg.B ($7802): bit0 = SHIFT, bit6 = CTRL.
 * We hold one "pressed" key as a scan index (0..KBD_NSCAN-1) plus modifiers,
 * for a short number of scan cycles so the firmware's debounce accepts it. */
#define KBD_NSCAN 79
static const unsigned char kbd_tbl[KBD_NSCAN][2] = {
  {0xD1,0xD1},{0xD7,0xD7},{0xC5,0xC5},{0xD2,0xD2},
  {0xD4,0xF4},{0xD9,0xF9},{0x32,0x22},{0x1B,0x1B},
  {0x7F,0x7F},{0x9E,0x9F},{0xD0,0xF0},{0xB4,0xB6},
  {0x92,0x93},{0x31,0x21},{0x71,0x51},{0x98,0x98},
  {0x33,0x23},{0x34,0x24},{0x35,0x25},{0x36,0x26},
  {0x37,0x27},{0x38,0x28},{0x39,0x29},{0x30,0x5F},
  {0x2D,0x3D},{0x5E,0x7E},{0x5C,0x7C},{0x09,0xC9},
  {0x87,0x87},{0x88,0x88},{0x89,0x89},{0x2D,0x2D},
  {0x77,0x57},{0x65,0x45},{0x72,0x52},{0x74,0x54},
  {0x79,0x59},{0x75,0x55},{0x69,0x49},{0x6F,0x4F},
  {0x70,0x50},{0x5B,0x7B},{0x5D,0x7D},{0x0D,0x0D},
  {0x84,0x84},{0x85,0x85},{0x86,0x86},{0x09,0x09},
  {0x61,0x41},{0x73,0x53},{0x64,0x44},{0x66,0x46},
  {0x67,0x47},{0x68,0x48},{0x6A,0x4A},{0x6B,0x4B},
  {0x6C,0x4C},{0x3B,0x2B},{0x3A,0x2A},{0x40,0x60},
  {0x0A,0x0A},{0x82,0x82},{0x83,0x83},{0x81,0x81},
  {0x90,0x91},{0x7A,0x5A},{0x78,0x58},{0x63,0x43},
  {0x76,0x56},{0x62,0x42},{0x6E,0x4E},{0x6D,0x4D},
  {0x2C,0x3C},{0x2E,0x3E},{0x2F,0x3F},{0x20,0x20},
  {0x1F,0xCA},{0x30,0x30},{0x2E,0x2E},
};

static int     kbd_scan_idx = -1;      /* pressed key's scan index, -1=none  */
static int     kbd_shift = 0;          /* SHIFT held ($7802 bit0)            */
static int     kbd_ctrl  = 0;          /* CTRL  held ($7802 bit6)            */
static int     kbd_hold  = 0;          /* scan cycles remaining to hold key  */
static uint8_t pia_a_scan = 0;         /* last value MPU wrote to $7800      */

/* press an ASCII char: find its scan index + needed modifiers from the table */
/* press the numpad ENTER key (scan $4F) - distinct from main RETURN (scan 43).
 * Both decode to CR, but some programs (e.g. CINT) poll the numpad-ENTER line
 * directly, so the two are NOT interchangeable. */
static void kbd_press_numpad_enter(void)
{
    kbd_scan_idx = 0x4F; kbd_shift = 0; kbd_ctrl = 0; kbd_hold = 20000;
}

static void kbd_press_ascii(unsigned char ch)
{
    int i;
    for (i = 0; i < KBD_NSCAN; i++) {
        if (kbd_tbl[i][0] == ch) { kbd_scan_idx = i; kbd_shift = 0; kbd_ctrl = 0; kbd_hold = 20000; return; }
    }
    for (i = 0; i < KBD_NSCAN; i++) {
        if (kbd_tbl[i][1] == ch) { kbd_scan_idx = i; kbd_shift = 1; kbd_ctrl = 0; kbd_hold = 20000; return; }
    }
    /* control chars $00-$1F: press the base key with CTRL held */
    if (ch < 0x20) {
        unsigned char base = (unsigned char)(ch | 0x40);   /* ^A -> 'A' etc */
        for (i = 0; i < KBD_NSCAN; i++) {
            if (kbd_tbl[i][0] == (base|0x20) || kbd_tbl[i][0] == base) {
                kbd_scan_idx = i; kbd_shift = 0; kbd_ctrl = 1; kbd_hold = 20000; return;
            }
        }
    }
}

/* ====================================================================== */
/*  memory access with I/O side effects                                   */
/* ====================================================================== */

static uint8_t rd8(uint16_t a)
{
    /* I/O page */
    if (a >= 0x7000 && a < 0x8000) {
        if (a == IO_ACIA) {                 /* ACIA status                */
            uint8_t s = 0x02;               /* TDRE: always ready to send */
            if (!rx_empty()) s |= 0x01;     /* RDRF: receive data ready   */
            return s;
        }
        if (a == IO_ACIA + 1) {             /* ACIA data (read clears RDRF)*/
            return rx_pop();
        }
        if (a == IO_HALT) {                 /* VSYNC strobe: toggling bit  */
            return ((cycles >> 13) & 1) ? 0x80 : 0x00;
        }
        if (a == 0x7800) {                  /* PIA1 Per.Reg.A: scan readback */
            uint8_t base = pia_a_scan & 0x7F;
            /* STROBE (bit7) high when the held key's scan index is selected */
            if (kbd_scan_idx >= 0 && kbd_hold > 0 &&
                base == (uint8_t)kbd_scan_idx) {
                return (uint8_t)(0x80 | base);
            }
            return base;
        }
        if (a == 0x7802) {                  /* PIA1 Per.Reg.B: SHIFT/CTRL    */
            uint8_t v = 0;
            if (kbd_scan_idx >= 0 && kbd_hold > 0) {
                if (kbd_shift) v |= 0x80;   /* SHIFT on bit7 (selects shifted */
                                            /* table variant via ASLB/ROLA)  */
                if (kbd_ctrl)  v |= 0x40;   /* CTRL  on bit6                 */
            }
            return v;
        }
        /* PIA1, VTAC, bank regs: return last value written (in mem[])     */
        return mem[a];
    }
    return mem[a];
}

static void wr8(uint16_t a, uint8_t v)
{
    if (a >= 0x7000 && a < 0x8000) {
        if (a == IO_ACIA + 1) {             /* ACIA data write -> tx       */
            if (txlog) { fputc(v, txlog); fflush(txlog); }
            return;
        }
        if (a == 0x7800) {                  /* MPU writes scan count to PIA-A */
            pia_a_scan = v;
        }
        mem[a] = v;                         /* latch control/bank/VTAC     */
        return;
    }
    if (is_rom[a]) return;                   /* writes to ROM ignored       */
    mem[a] = v;
}

static uint16_t rd16(uint16_t a)
{
    return (uint16_t)((rd8(a) << 8) | rd8((uint16_t)(a + 1)));
}

/* ---- fetch / stack --------------------------------------------------- */
static uint8_t  fetch8(void)  { return rd8(PC++); }
static uint16_t fetch16(void) { uint16_t v = rd16(PC); PC += 2; return v; }

static void push8(uint8_t v)  { wr8(SP, v); SP = (uint16_t)(SP - 1); }
static uint8_t pull8(void)    { SP = (uint16_t)(SP + 1); return rd8(SP); }
static void push16(uint16_t v){ push8((uint8_t)(v & 0xFF)); push8((uint8_t)(v >> 8)); }
static uint16_t pull16(void)  { uint8_t hi = pull8(); uint8_t lo = pull8();
                                return (uint16_t)((hi << 8) | lo); }

/* ====================================================================== */
/*  flag helpers                                                          */
/* ====================================================================== */

static void setNZ8(uint8_t v)
{
    CC &= ~(FLAG_N | FLAG_Z);
    if (v & 0x80) CC |= FLAG_N;
    if (v == 0)   CC |= FLAG_Z;
}
static void setNZ16(uint16_t v)
{
    CC &= ~(FLAG_N | FLAG_Z);
    if (v & 0x8000) CC |= FLAG_N;
    if (v == 0)     CC |= FLAG_Z;
}

/* 8-bit add with optional carry-in; sets H,N,Z,V,C */
static uint8_t do_add(uint8_t a, uint8_t m, int carry)
{
    unsigned r = (unsigned)a + m + carry;
    unsigned h = (unsigned)(a & 0x0F) + (m & 0x0F) + carry;
    CC &= ~(FLAG_H | FLAG_N | FLAG_Z | FLAG_V | FLAG_C);
    if (h & 0x10) CC |= FLAG_H;
    if (r & 0x100) CC |= FLAG_C;
    if ((~(a ^ m) & (a ^ r) & 0x80)) CC |= FLAG_V;
    setNZ8((uint8_t)r);
    return (uint8_t)r;
}

/* 8-bit subtract with optional borrow-in; sets N,Z,V,C (H unaffected) */
static uint8_t do_sub(uint8_t a, uint8_t m, int borrow)
{
    unsigned r = (unsigned)a - m - borrow;
    CC &= ~(FLAG_N | FLAG_Z | FLAG_V | FLAG_C);
    if (r & 0x100) CC |= FLAG_C;                 /* borrow                */
    if (((a ^ m) & (a ^ r) & 0x80)) CC |= FLAG_V;
    setNZ8((uint8_t)r);
    return (uint8_t)r;
}

/* ====================================================================== */
/*  effective-address helpers                                             */
/* ====================================================================== */
static uint16_t ea_dir(void) { return fetch8(); }
static uint16_t ea_ext(void) { return fetch16(); }
static uint16_t ea_idx(void) { return (uint16_t)(IX + fetch8()); }

/* read-modify-write helpers for shifts/rotates/inc/dec on memory or acc */
static uint8_t op_neg(uint8_t m)
{
    uint8_t r = (uint8_t)(0 - m);
    CC &= ~(FLAG_N | FLAG_Z | FLAG_V | FLAG_C);
    if (r != 0) CC |= FLAG_C;
    if (m == 0x80) CC |= FLAG_V;
    setNZ8(r);
    return r;
}
static uint8_t op_com(uint8_t m)
{
    uint8_t r = (uint8_t)~m;
    CC &= ~(FLAG_N | FLAG_Z | FLAG_V);
    CC |= FLAG_C;                                /* COM sets C=1          */
    setNZ8(r);
    return r;
}
static uint8_t op_inc(uint8_t m)
{
    uint8_t r = (uint8_t)(m + 1);
    CC &= ~(FLAG_N | FLAG_Z | FLAG_V);
    if (m == 0x7F) CC |= FLAG_V;
    setNZ8(r);
    return r;
}
static uint8_t op_dec(uint8_t m)
{
    uint8_t r = (uint8_t)(m - 1);
    CC &= ~(FLAG_N | FLAG_Z | FLAG_V);
    if (m == 0x80) CC |= FLAG_V;
    setNZ8(r);
    return r;
}
static void op_tst(uint8_t m)
{
    CC &= ~(FLAG_N | FLAG_Z | FLAG_V | FLAG_C);
    setNZ8(m);
}
static uint8_t op_clr(void)
{
    CC &= ~(FLAG_N | FLAG_V | FLAG_C);
    CC |= FLAG_Z;
    return 0;
}
static void setV_shift(uint8_t r)               /* V = N ^ C             */
{
    int n = (r & 0x80) ? 1 : 0;
    int c = (CC & FLAG_C) ? 1 : 0;
    if (n ^ c) CC |= FLAG_V; else CC &= ~FLAG_V;
}
static uint8_t op_asl(uint8_t m)
{
    uint8_t r = (uint8_t)(m << 1);
    CC &= ~(FLAG_C);
    if (m & 0x80) CC |= FLAG_C;
    setNZ8(r); setV_shift(r);
    return r;
}
static uint8_t op_asr(uint8_t m)
{
    uint8_t r = (uint8_t)((m >> 1) | (m & 0x80));
    CC &= ~(FLAG_C);
    if (m & 0x01) CC |= FLAG_C;
    setNZ8(r); setV_shift(r);
    return r;
}
static uint8_t op_lsr(uint8_t m)
{
    uint8_t r = (uint8_t)(m >> 1);
    CC &= ~(FLAG_C);
    if (m & 0x01) CC |= FLAG_C;
    setNZ8(r); setV_shift(r);
    return r;
}
static uint8_t op_rol(uint8_t m)
{
    int cin = (CC & FLAG_C) ? 1 : 0;
    uint8_t r = (uint8_t)((m << 1) | cin);
    CC &= ~(FLAG_C);
    if (m & 0x80) CC |= FLAG_C;
    setNZ8(r); setV_shift(r);
    return r;
}
static uint8_t op_ror(uint8_t m)
{
    int cin = (CC & FLAG_C) ? 0x80 : 0;
    uint8_t r = (uint8_t)((m >> 1) | cin);
    CC &= ~(FLAG_C);
    if (m & 0x01) CC |= FLAG_C;
    setNZ8(r); setV_shift(r);
    return r;
}
static void op_daa(void)
{
    uint8_t corr = 0;
    int setc = (CC & FLAG_C) ? 1 : 0;
    if ((A & 0x0F) > 9 || (CC & FLAG_H)) corr |= 0x06;
    if (A > 0x99 || (CC & FLAG_C))       { corr |= 0x60; setc = 1; }
    A = (uint8_t)(A + corr);
    CC &= ~(FLAG_C);
    if (setc) CC |= FLAG_C;
    setNZ8(A);
}

/* generic RMW dispatch on an effective address */
typedef uint8_t (*rmw_fn)(uint8_t);
static void rmw_mem(uint16_t ea, rmw_fn f) { wr8(ea, f(rd8(ea))); }

/* 16-bit compare (CPX): functional full-width form; sets N,Z,V (C left) */
static void op_cpx(uint16_t m)
{
    uint16_t x = IX;
    unsigned r = (unsigned)x - m;
    CC &= ~(FLAG_N | FLAG_Z | FLAG_V);
    if (r & 0x8000) CC |= FLAG_N;
    if ((r & 0xFFFF) == 0) CC |= FLAG_Z;
    if (((x ^ m) & (x ^ r) & 0x8000)) CC |= FLAG_V;
}

/* ---- interrupt entry (IRQ/SWI/NMI) ----------------------------------- */
static void do_interrupt(uint16_t vector)
{
    push16(PC);
    push16(IX);
    push8(A);
    push8(B);
    push8((uint8_t)(CC | CC_HI));
    CC |= FLAG_I;
    PC = rd16(vector);
}

/* periodic VSYNC IRQ: fire if enabled, interval elapsed, and I-flag clear */
static void maybe_irq(void)
{
    if (kbd_hold > 0) kbd_hold--;        /* time-based key auto-release      */
    if (!irq_enabled) return;
    if (++irq_accum >= irq_period) {
        irq_accum = 0;
        if (!(CC & FLAG_I)) do_interrupt(0xFFF8);   /* IRQ vector $FFF8    */
    }
}

/* ====================================================================== */
/*  one instruction                                                       */
/* ====================================================================== */
static const char *last_err = NULL;

static void step(void)
{
    uint8_t op = fetch8();
    uint16_t ea;
    uint8_t  m;

    switch (op) {

    /* ---- inherent ------------------------------------------------- */
    case 0x01: break;                                   /* NOP           */
    case 0x06: CC = (uint8_t)(A | CC_HI); break;        /* TAP           */
    case 0x07: A = (uint8_t)(CC | CC_HI); break;        /* TPA           */
    case 0x08: IX = (uint16_t)(IX + 1);                 /* INX           */
               CC &= ~FLAG_Z; if (IX == 0) CC |= FLAG_Z; break;
    case 0x09: IX = (uint16_t)(IX - 1);                 /* DEX           */
               CC &= ~FLAG_Z; if (IX == 0) CC |= FLAG_Z; break;
    case 0x0A: CC &= ~FLAG_V; break;                    /* CLV           */
    case 0x0B: CC |= FLAG_V; break;                     /* SEV           */
    case 0x0C: CC &= ~FLAG_C; break;                    /* CLC           */
    case 0x0D: CC |= FLAG_C; break;                     /* SEC           */
    case 0x0E: CC &= ~FLAG_I; break;                    /* CLI           */
    case 0x0F: CC |= FLAG_I; break;                     /* SEI           */
    case 0x10: A = do_sub(A, B, 0); break;              /* SBA           */
    case 0x11: do_sub(A, B, 0); break;                  /* CBA (no store)*/
    case 0x16: B = A; CC &= ~FLAG_V; setNZ8(B); break;  /* TAB           */
    case 0x17: A = B; CC &= ~FLAG_V; setNZ8(A); break;  /* TBA           */
    case 0x19: op_daa(); break;                         /* DAA           */
    case 0x1B: A = do_add(A, B, 0); break;              /* ABA           */

    case 0x30: IX = (uint16_t)(SP + 1); break;          /* TSX           */
    case 0x31: SP = (uint16_t)(SP + 1); break;          /* INS           */
    case 0x32: A = pull8(); break;                      /* PULA          */
    case 0x33: B = pull8(); break;                      /* PULB          */
    case 0x34: SP = (uint16_t)(SP - 1); break;          /* DES           */
    case 0x35: SP = (uint16_t)(IX - 1); break;          /* TXS           */
    case 0x36: push8(A); break;                         /* PSHA          */
    case 0x37: push8(B); break;                         /* PSHB          */

    case 0x39: PC = pull16(); break;                    /* RTS           */
    case 0x3B:                                           /* RTI           */
        CC = (uint8_t)(pull8() | CC_HI);
        B  = pull8();
        A  = pull8();
        IX = pull16();
        PC = pull16();
        break;
    case 0x3E: halted = 1; last_err = "WAI (waiting for interrupt)"; break; /* WAI */
    case 0x3F: do_interrupt(0xFFFA); break;             /* SWI           */

    /* accumulator A inherent ops */
    case 0x40: A = op_neg(A); break;                    /* NEGA          */
    case 0x43: A = op_com(A); break;                    /* COMA          */
    case 0x44: A = op_lsr(A); break;                    /* LSRA          */
    case 0x46: A = op_ror(A); break;                    /* RORA          */
    case 0x47: A = op_asr(A); break;                    /* ASRA          */
    case 0x48: A = op_asl(A); break;                    /* ASLA/LSLA     */
    case 0x49: A = op_rol(A); break;                    /* ROLA          */
    case 0x4A: A = op_dec(A); break;                    /* DECA          */
    case 0x4C: A = op_inc(A); break;                    /* INCA          */
    case 0x4D: op_tst(A); break;                        /* TSTA          */
    case 0x4F: A = op_clr(); break;                     /* CLRA          */

    /* accumulator B inherent ops */
    case 0x50: B = op_neg(B); break;                    /* NEGB          */
    case 0x53: B = op_com(B); break;                    /* COMB          */
    case 0x54: B = op_lsr(B); break;                    /* LSRB          */
    case 0x56: B = op_ror(B); break;                    /* RORB          */
    case 0x57: B = op_asr(B); break;                    /* ASRB          */
    case 0x58: B = op_asl(B); break;                    /* ASLB/LSLB     */
    case 0x59: B = op_rol(B); break;                    /* ROLB          */
    case 0x5A: B = op_dec(B); break;                    /* DECB          */
    case 0x5C: B = op_inc(B); break;                    /* INCB          */
    case 0x5D: op_tst(B); break;                        /* TSTB          */
    case 0x5F: B = op_clr(); break;                     /* CLRB          */

    /* indexed RMW */
    case 0x60: ea = ea_idx(); rmw_mem(ea, op_neg); break; /* NEG ,X      */
    case 0x63: ea = ea_idx(); rmw_mem(ea, op_com); break; /* COM ,X      */
    case 0x64: ea = ea_idx(); rmw_mem(ea, op_lsr); break; /* LSR ,X      */
    case 0x66: ea = ea_idx(); rmw_mem(ea, op_ror); break; /* ROR ,X      */
    case 0x67: ea = ea_idx(); rmw_mem(ea, op_asr); break; /* ASR ,X      */
    case 0x68: ea = ea_idx(); rmw_mem(ea, op_asl); break; /* ASL ,X      */
    case 0x69: ea = ea_idx(); rmw_mem(ea, op_rol); break; /* ROL ,X      */
    case 0x6A: ea = ea_idx(); rmw_mem(ea, op_dec); break; /* DEC ,X      */
    case 0x6C: ea = ea_idx(); rmw_mem(ea, op_inc); break; /* INC ,X      */
    case 0x6D: ea = ea_idx(); op_tst(rd8(ea)); break;     /* TST ,X      */
    case 0x6E: ea = ea_idx(); PC = ea; break;             /* JMP ,X      */
    case 0x6F: ea = ea_idx(); wr8(ea, op_clr()); break;   /* CLR ,X      */

    /* extended RMW */
    case 0x70: ea = ea_ext(); rmw_mem(ea, op_neg); break; /* NEG ext     */
    case 0x73: ea = ea_ext(); rmw_mem(ea, op_com); break; /* COM ext     */
    case 0x74: ea = ea_ext(); rmw_mem(ea, op_lsr); break; /* LSR ext     */
    case 0x76: ea = ea_ext(); rmw_mem(ea, op_ror); break; /* ROR ext     */
    case 0x77: ea = ea_ext(); rmw_mem(ea, op_asr); break; /* ASR ext     */
    case 0x78: ea = ea_ext(); rmw_mem(ea, op_asl); break; /* ASL ext     */
    case 0x79: ea = ea_ext(); rmw_mem(ea, op_rol); break; /* ROL ext     */
    case 0x7A: ea = ea_ext(); rmw_mem(ea, op_dec); break; /* DEC ext     */
    case 0x7C: ea = ea_ext(); rmw_mem(ea, op_inc); break; /* INC ext     */
    case 0x7D: ea = ea_ext(); op_tst(rd8(ea)); break;     /* TST ext     */
    case 0x7E: ea = ea_ext(); PC = ea; break;             /* JMP ext     */
    case 0x7F: ea = ea_ext(); wr8(ea, op_clr()); break;   /* CLR ext     */

    /* ---- branches (relative) -------------------------------------- */
#define BRANCH(cond) do { int8_t off = (int8_t)fetch8(); \
                          if (cond) PC = (uint16_t)(PC + off); } while (0)
    case 0x20: BRANCH(1); break;                        /* BRA           */
    case 0x22: BRANCH(!((CC&FLAG_C)||(CC&FLAG_Z))); break; /* BHI        */
    case 0x23: BRANCH(((CC&FLAG_C)||(CC&FLAG_Z))); break;  /* BLS        */
    case 0x24: BRANCH(!(CC&FLAG_C)); break;             /* BCC           */
    case 0x25: BRANCH((CC&FLAG_C)); break;              /* BCS           */
    case 0x26: BRANCH(!(CC&FLAG_Z)); break;             /* BNE           */
    case 0x27: BRANCH((CC&FLAG_Z)); break;              /* BEQ           */
    case 0x28: BRANCH(!(CC&FLAG_V)); break;             /* BVC           */
    case 0x29: BRANCH((CC&FLAG_V)); break;              /* BVS           */
    case 0x2A: BRANCH(!(CC&FLAG_N)); break;             /* BPL           */
    case 0x2B: BRANCH((CC&FLAG_N)); break;              /* BMI           */
    case 0x2C: { int n=(CC&FLAG_N)?1:0,v=(CC&FLAG_V)?1:0;
                 BRANCH(!(n^v)); } break;               /* BGE           */
    case 0x2D: { int n=(CC&FLAG_N)?1:0,v=(CC&FLAG_V)?1:0;
                 BRANCH((n^v)); } break;                /* BLT           */
    case 0x2E: { int n=(CC&FLAG_N)?1:0,v=(CC&FLAG_V)?1:0,z=(CC&FLAG_Z)?1:0;
                 BRANCH(!z && !(n^v)); } break;         /* BGT           */
    case 0x2F: { int n=(CC&FLAG_N)?1:0,v=(CC&FLAG_V)?1:0,z=(CC&FLAG_Z)?1:0;
                 BRANCH(z || (n^v)); } break;           /* BLE           */
    case 0x8D: { int8_t off = (int8_t)fetch8();         /* BSR           */
                 push16(PC); PC = (uint16_t)(PC + off); } break;

    /* ---- immediate / direct / indexed / extended data ops --------- */
    /* SUBA */
    case 0x80: A = do_sub(A, fetch8(), 0); break;
    case 0x90: A = do_sub(A, rd8(ea_dir()), 0); break;
    case 0xA0: A = do_sub(A, rd8(ea_idx()), 0); break;
    case 0xB0: A = do_sub(A, rd8(ea_ext()), 0); break;
    /* CMPA */
    case 0x81: do_sub(A, fetch8(), 0); break;
    case 0x91: do_sub(A, rd8(ea_dir()), 0); break;
    case 0xA1: do_sub(A, rd8(ea_idx()), 0); break;
    case 0xB1: do_sub(A, rd8(ea_ext()), 0); break;
    /* SBCA */
    case 0x82: A = do_sub(A, fetch8(), (CC&FLAG_C)?1:0); break;
    case 0x92: A = do_sub(A, rd8(ea_dir()), (CC&FLAG_C)?1:0); break;
    case 0xA2: A = do_sub(A, rd8(ea_idx()), (CC&FLAG_C)?1:0); break;
    case 0xB2: A = do_sub(A, rd8(ea_ext()), (CC&FLAG_C)?1:0); break;
    /* ANDA */
    case 0x84: A &= fetch8();        CC&=~FLAG_V; setNZ8(A); break;
    case 0x94: A &= rd8(ea_dir());   CC&=~FLAG_V; setNZ8(A); break;
    case 0xA4: A &= rd8(ea_idx());   CC&=~FLAG_V; setNZ8(A); break;
    case 0xB4: A &= rd8(ea_ext());   CC&=~FLAG_V; setNZ8(A); break;
    /* BITA */
    case 0x85: { uint8_t r=A&fetch8();       CC&=~FLAG_V; setNZ8(r);} break;
    case 0x95: { uint8_t r=A&rd8(ea_dir());  CC&=~FLAG_V; setNZ8(r);} break;
    case 0xA5: { uint8_t r=A&rd8(ea_idx());  CC&=~FLAG_V; setNZ8(r);} break;
    case 0xB5: { uint8_t r=A&rd8(ea_ext());  CC&=~FLAG_V; setNZ8(r);} break;
    /* LDAA */
    case 0x86: A = fetch8();        CC&=~FLAG_V; setNZ8(A); break;
    case 0x96: A = rd8(ea_dir());   CC&=~FLAG_V; setNZ8(A); break;
    case 0xA6: A = rd8(ea_idx());   CC&=~FLAG_V; setNZ8(A); break;
    case 0xB6: A = rd8(ea_ext());   CC&=~FLAG_V; setNZ8(A); break;
    /* STAA */
    case 0x97: ea=ea_dir(); wr8(ea,A); CC&=~FLAG_V; setNZ8(A); break;
    case 0xA7: ea=ea_idx(); wr8(ea,A); CC&=~FLAG_V; setNZ8(A); break;
    case 0xB7: ea=ea_ext(); wr8(ea,A); CC&=~FLAG_V; setNZ8(A); break;
    /* EORA */
    case 0x88: A ^= fetch8();        CC&=~FLAG_V; setNZ8(A); break;
    case 0x98: A ^= rd8(ea_dir());   CC&=~FLAG_V; setNZ8(A); break;
    case 0xA8: A ^= rd8(ea_idx());   CC&=~FLAG_V; setNZ8(A); break;
    case 0xB8: A ^= rd8(ea_ext());   CC&=~FLAG_V; setNZ8(A); break;
    /* ADCA */
    case 0x89: A = do_add(A, fetch8(), (CC&FLAG_C)?1:0); break;
    case 0x99: A = do_add(A, rd8(ea_dir()), (CC&FLAG_C)?1:0); break;
    case 0xA9: A = do_add(A, rd8(ea_idx()), (CC&FLAG_C)?1:0); break;
    case 0xB9: A = do_add(A, rd8(ea_ext()), (CC&FLAG_C)?1:0); break;
    /* ORAA */
    case 0x8A: A |= fetch8();        CC&=~FLAG_V; setNZ8(A); break;
    case 0x9A: A |= rd8(ea_dir());   CC&=~FLAG_V; setNZ8(A); break;
    case 0xAA: A |= rd8(ea_idx());   CC&=~FLAG_V; setNZ8(A); break;
    case 0xBA: A |= rd8(ea_ext());   CC&=~FLAG_V; setNZ8(A); break;
    /* ADDA */
    case 0x8B: A = do_add(A, fetch8(), 0); break;
    case 0x9B: A = do_add(A, rd8(ea_dir()), 0); break;
    case 0xAB: A = do_add(A, rd8(ea_idx()), 0); break;
    case 0xBB: A = do_add(A, rd8(ea_ext()), 0); break;
    /* CPX (16-bit) */
    case 0x8C: op_cpx(fetch16()); break;
    case 0x9C: op_cpx(rd16(ea_dir())); break;
    case 0xAC: op_cpx(rd16(ea_idx())); break;
    case 0xBC: op_cpx(rd16(ea_ext())); break;
    /* JSR */
    case 0xAD: ea=ea_idx(); push16(PC); PC=ea; break;
    case 0xBD: ea=ea_ext(); push16(PC); PC=ea; break;
    /* LDS (16-bit) */
    case 0x8E: SP = fetch16();        CC&=~FLAG_V; setNZ16(SP); break;
    case 0x9E: SP = rd16(ea_dir());   CC&=~FLAG_V; setNZ16(SP); break;
    case 0xAE: SP = rd16(ea_idx());   CC&=~FLAG_V; setNZ16(SP); break;
    case 0xBE: SP = rd16(ea_ext());   CC&=~FLAG_V; setNZ16(SP); break;
    /* STS (16-bit) */
    case 0x9F: ea=ea_dir(); wr8(ea,(uint8_t)(SP>>8)); wr8((uint16_t)(ea+1),(uint8_t)SP);
               CC&=~FLAG_V; setNZ16(SP); break;
    case 0xAF: ea=ea_idx(); wr8(ea,(uint8_t)(SP>>8)); wr8((uint16_t)(ea+1),(uint8_t)SP);
               CC&=~FLAG_V; setNZ16(SP); break;
    case 0xBF: ea=ea_ext(); wr8(ea,(uint8_t)(SP>>8)); wr8((uint16_t)(ea+1),(uint8_t)SP);
               CC&=~FLAG_V; setNZ16(SP); break;

    /* SUBB */
    case 0xC0: B = do_sub(B, fetch8(), 0); break;
    case 0xD0: B = do_sub(B, rd8(ea_dir()), 0); break;
    case 0xE0: B = do_sub(B, rd8(ea_idx()), 0); break;
    case 0xF0: B = do_sub(B, rd8(ea_ext()), 0); break;
    /* CMPB */
    case 0xC1: do_sub(B, fetch8(), 0); break;
    case 0xD1: do_sub(B, rd8(ea_dir()), 0); break;
    case 0xE1: do_sub(B, rd8(ea_idx()), 0); break;
    case 0xF1: do_sub(B, rd8(ea_ext()), 0); break;
    /* SBCB */
    case 0xC2: B = do_sub(B, fetch8(), (CC&FLAG_C)?1:0); break;
    case 0xD2: B = do_sub(B, rd8(ea_dir()), (CC&FLAG_C)?1:0); break;
    case 0xE2: B = do_sub(B, rd8(ea_idx()), (CC&FLAG_C)?1:0); break;
    case 0xF2: B = do_sub(B, rd8(ea_ext()), (CC&FLAG_C)?1:0); break;
    /* ANDB */
    case 0xC4: B &= fetch8();        CC&=~FLAG_V; setNZ8(B); break;
    case 0xD4: B &= rd8(ea_dir());   CC&=~FLAG_V; setNZ8(B); break;
    case 0xE4: B &= rd8(ea_idx());   CC&=~FLAG_V; setNZ8(B); break;
    case 0xF4: B &= rd8(ea_ext());   CC&=~FLAG_V; setNZ8(B); break;
    /* BITB */
    case 0xC5: { uint8_t r=B&fetch8();       CC&=~FLAG_V; setNZ8(r);} break;
    case 0xD5: { uint8_t r=B&rd8(ea_dir());  CC&=~FLAG_V; setNZ8(r);} break;
    case 0xE5: { uint8_t r=B&rd8(ea_idx());  CC&=~FLAG_V; setNZ8(r);} break;
    case 0xF5: { uint8_t r=B&rd8(ea_ext());  CC&=~FLAG_V; setNZ8(r);} break;
    /* LDAB */
    case 0xC6: B = fetch8();        CC&=~FLAG_V; setNZ8(B); break;
    case 0xD6: B = rd8(ea_dir());   CC&=~FLAG_V; setNZ8(B); break;
    case 0xE6: B = rd8(ea_idx());   CC&=~FLAG_V; setNZ8(B); break;
    case 0xF6: B = rd8(ea_ext());   CC&=~FLAG_V; setNZ8(B); break;
    /* STAB */
    case 0xD7: ea=ea_dir(); wr8(ea,B); CC&=~FLAG_V; setNZ8(B); break;
    case 0xE7: ea=ea_idx(); wr8(ea,B); CC&=~FLAG_V; setNZ8(B); break;
    case 0xF7: ea=ea_ext(); wr8(ea,B); CC&=~FLAG_V; setNZ8(B); break;
    /* EORB */
    case 0xC8: B ^= fetch8();        CC&=~FLAG_V; setNZ8(B); break;
    case 0xD8: B ^= rd8(ea_dir());   CC&=~FLAG_V; setNZ8(B); break;
    case 0xE8: B ^= rd8(ea_idx());   CC&=~FLAG_V; setNZ8(B); break;
    case 0xF8: B ^= rd8(ea_ext());   CC&=~FLAG_V; setNZ8(B); break;
    /* ADCB */
    case 0xC9: B = do_add(B, fetch8(), (CC&FLAG_C)?1:0); break;
    case 0xD9: B = do_add(B, rd8(ea_dir()), (CC&FLAG_C)?1:0); break;
    case 0xE9: B = do_add(B, rd8(ea_idx()), (CC&FLAG_C)?1:0); break;
    case 0xF9: B = do_add(B, rd8(ea_ext()), (CC&FLAG_C)?1:0); break;
    /* ORAB */
    case 0xCA: B |= fetch8();        CC&=~FLAG_V; setNZ8(B); break;
    case 0xDA: B |= rd8(ea_dir());   CC&=~FLAG_V; setNZ8(B); break;
    case 0xEA: B |= rd8(ea_idx());   CC&=~FLAG_V; setNZ8(B); break;
    case 0xFA: B |= rd8(ea_ext());   CC&=~FLAG_V; setNZ8(B); break;
    /* ADDB */
    case 0xCB: B = do_add(B, fetch8(), 0); break;
    case 0xDB: B = do_add(B, rd8(ea_dir()), 0); break;
    case 0xEB: B = do_add(B, rd8(ea_idx()), 0); break;
    case 0xFB: B = do_add(B, rd8(ea_ext()), 0); break;
    /* LDX (16-bit) */
    case 0xCE: IX = fetch16();        CC&=~FLAG_V; setNZ16(IX); break;
    case 0xDE: IX = rd16(ea_dir());   CC&=~FLAG_V; setNZ16(IX); break;
    case 0xEE: IX = rd16(ea_idx());   CC&=~FLAG_V; setNZ16(IX); break;
    case 0xFE: IX = rd16(ea_ext());   CC&=~FLAG_V; setNZ16(IX); break;
    /* STX (16-bit) */
    case 0xDF: ea=ea_dir(); wr8(ea,(uint8_t)(IX>>8)); wr8((uint16_t)(ea+1),(uint8_t)IX);
               CC&=~FLAG_V; setNZ16(IX); break;
    case 0xEF: ea=ea_idx(); wr8(ea,(uint8_t)(IX>>8)); wr8((uint16_t)(ea+1),(uint8_t)IX);
               CC&=~FLAG_V; setNZ16(IX); break;
    case 0xFF: ea=ea_ext(); wr8(ea,(uint8_t)(IX>>8)); wr8((uint16_t)(ea+1),(uint8_t)IX);
               CC&=~FLAG_V; setNZ16(IX); break;

    default:
        halted = 1;
        last_err = "illegal/unimplemented opcode";
        halt_op = op;
        halt_pc = (uint16_t)(PC - 1);
        break;
    }

    (void)m;
    cycles++;
}

/* ====================================================================== */
/*  ROM / image loading                                                   */
/* ====================================================================== */
static int load_at(const char *path, uint16_t base, int mark_rom)
{
    FILE *f = fopen(path, "rb");
    long n;
    size_t got;
    if (!f) { fprintf(stderr, "cannot open %s\n", path); return -1; }
    fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
    if (n <= 0 || base + n > 0x10000) { fprintf(stderr, "bad size %s\n", path); fclose(f); return -1; }
    got = fread(mem + base, 1, (size_t)n, f);
    fclose(f);
    if (mark_rom) { long i; for (i = 0; i < n; i++) is_rom[base + i] = 1; }
    fprintf(stderr, "loaded %s -> $%04X (%ld bytes%s)\n",
            path, base, n, mark_rom ? ", ROM" : "");
    return (int)got;
}

static void reset_cpu(uint16_t pc, uint16_t sp)
{
    A = B = 0; IX = 0; CC = CC_HI | FLAG_I;
    SP = sp; PC = pc; halted = 0; cycles = 0;
}

/* ====================================================================== */
/*  headless self-test (no display): identical to adm31emu.c's -- used to */
/*  verify the CPU core, on any platform including DOS/Turbo C            */
/* ====================================================================== */
#ifdef HEADLESS
int main(int argc, char **argv)
{
    const char *img = NULL;
    const char *romA=NULL,*romB=NULL,*romC=NULL,*romD=NULL;
    const char *boot = "plugin";
    uint16_t org = 0xE000;
    uint16_t sp  = 0x003F;
    unsigned long budget = 200000UL;
    int i, trace = 0;
    long dump_lo = 0x0040, dump_hi = 0x004F;   /* long: --dump can reach up
                                                 * to $FFFF, which overflows
                                                 * signed 16-bit int        */
    const char *keys = NULL; unsigned long keys_at = 100000; int keys_i = 0;
    unsigned long next_key = 0;

    for (i = 1; i < argc; i++) {
        if      (!strcmp(argv[i],"--img")  && i+1<argc) img = argv[++i];
        else if (!strcmp(argv[i],"--romA") && i+1<argc) romA = argv[++i];
        else if (!strcmp(argv[i],"--romB") && i+1<argc) romB = argv[++i];
        else if (!strcmp(argv[i],"--romC") && i+1<argc) romC = argv[++i];
        else if (!strcmp(argv[i],"--romD") && i+1<argc) romD = argv[++i];
        else if (!strcmp(argv[i],"--boot") && i+1<argc) boot = argv[++i];
        else if (!strcmp(argv[i],"--org")  && i+1<argc) org = (uint16_t)strtol(argv[++i],0,16);
        else if (!strcmp(argv[i],"--sp")   && i+1<argc) sp  = (uint16_t)strtol(argv[++i],0,16);
        else if (!strcmp(argv[i],"--budget")&&i+1<argc) budget = strtoul(argv[++i],0,10);
        else if (!strcmp(argv[i],"--irq"))              irq_enabled = 1;
        else if (!strcmp(argv[i],"--trace"))            trace = 1;
        else if (!strcmp(argv[i],"--keys") && i+1<argc) keys = argv[++i];
        else if (!strcmp(argv[i],"--keysat")&&i+1<argc) keys_at = strtoul(argv[++i],0,10);
        else if (!strcmp(argv[i],"--dump") && i+1<argc) sscanf(argv[++i], "%lx:%lx", &dump_lo, &dump_hi);
    }

    adm_alloc_mem();
    adm_far_zero(mem);
    adm_far_zero(is_rom);

    if (romA||romB||romC||romD) {                 /* firmware/ROM-set boot  */
        if (romA) load_at(romA,0xE000,1);
        if (romB) load_at(romB,0xE800,1);
        if (romC) load_at(romC,0xF000,1);
        if (romD) load_at(romD,0xF800,1);
        if (!strcmp(boot,"firmware")) { org = rd16(0xFFFE);
            fprintf(stderr,"reset vector $FFFE -> $%04X\n", org); }
    } else if (img) {
        if (load_at(img, org, 0) < 0) return 1;
    } else {
        fprintf(stderr,"usage: %s --img file [--org HEX] [--dump LO:HI]\n", argv[0]);
        fprintf(stderr,"   or: %s --romA a --romB b --romC c --romD d --boot firmware [--irq] [--trace]\n", argv[0]);
        return 2;
    }

    reset_cpu(org, sp);

    if (trace) {
        /* Sample PC periodically and report movement + tight-loop detection */
        unsigned long step_no = 0;
        uint16_t lo_seen = 0xFFFF, hi_seen = 0x0000;
        uint16_t window_lo = 0xFFFF, window_hi = 0;
        unsigned long sample = budget / 40;
        unsigned long next;
        if (sample < 1) sample = 1;
        next = sample;
        fprintf(stderr,"--- trace (sampling PC) ---\n");
        while (!halted && cycles < budget) {
            maybe_irq();
            /* feed injected keys one at a time once the key before it is consumed */
            if (keys && step_no >= keys_at && keys[keys_i] &&
                (kbd_scan_idx < 0 || kbd_hold == 0) && step_no >= next_key) {
                kbd_press_ascii((unsigned char)keys[keys_i]);
                fprintf(stderr,"  >>> key '%c' (0x%02X) pressed at instr %lu\n",
                        keys[keys_i]>=32?keys[keys_i]:'.', (unsigned char)keys[keys_i], step_no);
                keys_i++; next_key = step_no + 40000;
            }
            step();
            step_no++;
            if (PC >= 0xE000 && PC <= 0xE7FF && lo_seen != 0xE0FF) {
                static int announced=0;
                if(!announced){fprintf(stderr,"  >>> entered plugin region PC=$%04X at instr %lu\n",PC,step_no);announced=1;}
            }
            if (PC < window_lo) window_lo = PC;
            if (PC > window_hi) window_hi = PC;
            if (PC < lo_seen) lo_seen = PC;
            if (PC > hi_seen) hi_seen = PC;
            if (step_no >= next) {
                fprintf(stderr,"  @%8lu instr: PC=$%04X A=%02X B=%02X X=%04X SP=%04X CC=%02X  window[$%04X-$%04X]\n",
                        step_no, PC, A, B, IX, SP, (uint8_t)(CC|CC_HI), window_lo, window_hi);
                window_lo = 0xFFFF; window_hi = 0;
                next += sample;
            }
        }
        fprintf(stderr,"PC ranged over $%04X-$%04X total\n", lo_seen, hi_seen);
    } else {
        while (!halted && cycles < budget) { maybe_irq(); step(); }
    }

    fprintf(stderr, "stopped: %s after %lu instrs, PC=$%04X A=$%02X B=$%02X X=$%04X SP=$%04X CC=$%02X\n",
            halted ? (last_err ? last_err : "halted") : "budget",
            cycles, PC, A, B, IX, SP, (uint8_t)(CC|CC_HI));
    if (halted && last_err && last_err[0]=='i')
        fprintf(stderr, "  bad opcode $%02X at $%04X\n", halt_op, halt_pc);
    {
        long a; int nz = 0;
        printf("DUMP $%04X-$%04X:", (unsigned)dump_lo, (unsigned)dump_hi);
        for (a = dump_lo; a <= dump_hi; a++) { printf(" %02X", mem[a]); if(mem[a]) nz++; }
        printf("   (%d non-zero)\n", nz);
    }
    {   /* CRTRAM activity summary */
        long a; int nz = 0;
        for (a = 0x8000; a < 0x8000 + SCR_COLS*SCR_ROWS; a++) if (mem[a] && mem[a]!=0x20) nz++;
        fprintf(stderr,"CRTRAM non-blank cells: %d / %d\n", nz, SCR_COLS*SCR_ROWS);
    }
    return 0;
}

/* ====================================================================== */
/*  DOS / Turbo C front end -- direct video writes, conio keyboard        */
/* ====================================================================== */
#elif defined(__TURBOC__) || defined(__BORLANDC__)
#include <conio.h>
#include <dos.h>

static unsigned char far *avmem;

static void av_init(void)
{
    unsigned char mode = peekb(0x0040, 0x0049);
    avmem = (mode == 7) ? (unsigned char far *)MK_FP(0xB000, 0)
                         : (unsigned char far *)MK_FP(0xB800, 0);
    textmode(C80);
    _setcursortype(_NOCURSOR);
}

static void av_done(void)
{
    _setcursortype(_NORMALCURSOR);
    clrscr();
}

static void av_putc(int x, int y, int ch, int attr)
{
    long off = ((long)y * 80 + x) * 2;
    avmem[off]     = (unsigned char)ch;
    avmem[off + 1] = (unsigned char)attr;
}

/* row/col loop mirrors render_crtram() in the curses front end below,
 * just writing straight to the video segment instead of through curses */
static void dos_render(void)
{
    int row, col, i;
    char buf[90];

    for (row = 0; row < SCR_ROWS; row++) {
        for (col = 0; col < SCR_COLS; col++) {
            uint8_t c = mem[CRTRAM_BASE + row * SCR_COLS + col];
            uint8_t g = c & 0x7F;      /* bit 7 is an attribute, mask it   */
            int ch = (g >= 0x20 && g < 0x7F) ? g : ' ';
            av_putc(col, row, ch, 0x07);
        }
    }
    sprintf(buf, "PC=%04X A=%02X B=%02X X=%04X SP=%04X CC=%02X  [ESC-q quit]",
            PC, A, B, IX, SP, (unsigned)(CC | CC_HI));
    for (i = 0; buf[i] && i < 80; i++) av_putc(i, SCR_ROWS, (unsigned char)buf[i], 0x70);
    for (; i < 80; i++) av_putc(i, SCR_ROWS, ' ', 0x70);
}

/* returns -1 if no key is pending; otherwise a decoded key: plain ASCII,
 * or (0x100 | scancode) for the 0-prefixed extended keys. */
static int dos_poll_key(void)
{
    int c;
    if (!kbhit()) return -1;
    c = getch();
    if (c == 0) { int sc = getch(); return 0x100 | sc; }
    return c;
}

int main(int argc, char **argv)
{
    int i;
    const char *boot = "firmware";
    uint16_t plugin_org = 0xE000;
    int have_any = 0;

    adm_alloc_mem();
    adm_far_zero(mem);
    adm_far_zero(is_rom);
    txlog = fopen("adm31_tx.log", "wb");

    for (i = 1; i < argc; i++) {
        if      (!strcmp(argv[i],"--romA")  && i+1<argc) { load_at(argv[++i],0xE000,1); have_any=1; }
        else if (!strcmp(argv[i],"--plugin")&& i+1<argc) { load_at(argv[++i],0xE000,1); have_any=1; }
        else if (!strcmp(argv[i],"--romB")  && i+1<argc) { load_at(argv[++i],0xE800,1); have_any=1; }
        else if (!strcmp(argv[i],"--romC")  && i+1<argc) { load_at(argv[++i],0xF000,1); have_any=1; }
        else if (!strcmp(argv[i],"--romD")  && i+1<argc) { load_at(argv[++i],0xF800,1); have_any=1; }
        else if (!strcmp(argv[i],"--boot")  && i+1<argc) { boot = argv[++i]; }
        else if (!strcmp(argv[i],"--rom")   && i+1<argc) {
            char *spec = argv[++i]; char *at = strchr(spec, '@');
            if (at) { *at = 0; load_at(spec, (uint16_t)strtol(at+1,0,16), 1); have_any=1; }
        }
    }
    if (!have_any) {
        fprintf(stderr,
          "usage: %s --romA plugin.bin --romB rom67.bin --romC rom65.bin --romD rom66.bin [--boot firmware|plugin]\n",
          argv[0]);
        fprintf(stderr, "   or: %s --plugin plugin.bin --boot plugin\n", argv[0]);
        return 2;
    }

    if (!strcmp(boot, "plugin")) {
        reset_cpu(plugin_org, 0x003F);
    } else if (!strcmp(boot, "firmware")) {
        reset_cpu(rd16(0xFFFE), 0x003F); irq_enabled = 1;
    } else {
        /* anything else: an explicit hex address to direct-boot at (e.g.
         * "E800"), so a caller can start execution at any ROM socket
         * without needing a valid reset vector there. */
        uint16_t boot_addr = (uint16_t)strtol(boot, NULL, 16);
        reset_cpu(boot_addr, 0x003F);
    }

    if (!strcmp(boot, "game")) {
        unsigned long b;
        for (b = 0; b < 400000 && !halted; b++) { maybe_irq(); step(); }
        SP = 0x003F; PC = 0xE088;
    }

    av_init();
    dos_render();

    for (;;) {
        int n, k;
        for (n = 0; n < 5000 && !halted; n++) { maybe_irq(); step(); }

        while ((k = dos_poll_key()) != -1) {
            if (k == 27) {                       /* ESC: check for ESC-q  */
                if (kbhit()) {
                    int c2 = getch();
                    if (c2 == 'q' || c2 == 'Q') goto done;
                    kbd_press_ascii(27);
                    dos_render(); delay(30);
                    kbd_press_ascii((unsigned char)c2);
                } else {
                    kbd_press_ascii(27);
                }
            } else if (k == 0x13B || k == 5) {   /* F1 or Ctrl-E -> numpad Enter */
                kbd_press_numpad_enter();
            } else if (k == '\n' || k == '\r') {
                kbd_press_ascii('\r');
            } else if (k == 8 || k == 127) {
                kbd_press_ascii(0x08);
            } else if (k >= 0 && k < 128) {
                kbd_press_ascii((unsigned char)k);
            }
            /* other extended keys (arrows, other F-keys) aren't part of
             * the ADM-31 keyboard matrix this emulator drives -- ignored */
        }

        dos_render();

        if (halted) {
            char buf[90];
            sprintf(buf, "CPU HALTED: %s ($%02X at $%04X)  (press q)",
                    last_err ? last_err : "?", halt_op, halt_pc);
            { int j; for (j = 0; buf[j] && j < 80; j++) av_putc(j, SCR_ROWS + 0, (unsigned char)buf[j], 0x4F);
              for (; j < 80; j++) av_putc(j, SCR_ROWS + 0, ' ', 0x4F); }
            for (;;) { int c = getch(); if (c=='q' || c=='Q') break; }
            goto done;
        }
        delay(5);
    }
done:
    av_done();
    if (txlog) fclose(txlog);
    return 0;
}


/* ====================================================================== */
/*  curses TUI front-end (original adm31emu.c front end, unchanged --     */
/*  builds on Unix-like hosts for reference/testing; DOS builds never     */
/*  compile this branch)                                                  */
/* ====================================================================== */
#else
static void render_crtram(void)
{
    int row, col;
    for (row = 0; row < SCR_ROWS; row++) {
        for (col = 0; col < SCR_COLS; col++) {
            uint8_t c = mem[CRTRAM_BASE + row * SCR_COLS + col];
            uint8_t g = c & 0x7F;
            int ch = (g >= 0x20 && g < 0x7F) ? g : ' ';
            mvaddch(row, col, ch);
        }
    }
    mvprintw(SCR_ROWS, 0,
        "PC=%04X A=%02X B=%02X X=%04X SP=%04X CC=%02X  [ESC-q quit]   ",
        PC, A, B, IX, SP, (uint8_t)(CC|CC_HI));
    refresh();
}

int main(int argc, char **argv)
{
    int i;
    const char *boot = "firmware";
    uint16_t plugin_org = 0xE000;
    int have_any = 0;

    adm_alloc_mem();
    adm_far_zero(mem);
    adm_far_zero(is_rom);
    txlog = fopen("adm31_tx.log", "wb");

    for (i = 1; i < argc; i++) {
        if      (!strcmp(argv[i],"--romA")  && i+1<argc) { load_at(argv[++i],0xE000,1); have_any=1; }
        else if (!strcmp(argv[i],"--plugin")&& i+1<argc) { load_at(argv[++i],0xE000,1); have_any=1; }
        else if (!strcmp(argv[i],"--romB")  && i+1<argc) { load_at(argv[++i],0xE800,1); have_any=1; }
        else if (!strcmp(argv[i],"--romC")  && i+1<argc) { load_at(argv[++i],0xF000,1); have_any=1; }
        else if (!strcmp(argv[i],"--romD")  && i+1<argc) { load_at(argv[++i],0xF800,1); have_any=1; }
        else if (!strcmp(argv[i],"--boot")  && i+1<argc) { boot = argv[++i]; }
        else if (!strcmp(argv[i],"--rom")   && i+1<argc) {
            char *spec = argv[++i]; char *at = strchr(spec, '@');
            if (at) { *at = 0; load_at(spec, (uint16_t)strtol(at+1,0,16), 1); have_any=1; }
        }
    }
    if (!have_any) {
        fprintf(stderr,
          "usage: %s --romA plugin.bin --romB rom67.bin --romC rom65.bin --romD rom66.bin [--boot firmware|plugin]\n",
          argv[0]);
        return 2;
    }

    if (!strcmp(boot, "plugin")) {
        reset_cpu(plugin_org, 0x003F);
    } else if (!strcmp(boot, "firmware")) {
        reset_cpu(rd16(0xFFFE), 0x003F); irq_enabled = 1;
    } else {
        uint16_t boot_addr = (uint16_t)strtol(boot, NULL, 16);
        reset_cpu(boot_addr, 0x003F);
    }

    if (!strcmp(boot, "game")) {
        unsigned long b;
        for (b = 0; b < 400000 && !halted; b++) { maybe_irq(); step(); }
        SP = 0x003F; PC = 0xE088;
    }

    initscr(); cbreak(); noecho(); nodelay(stdscr, TRUE); keypad(stdscr, TRUE);
    curs_set(0);

    if (LINES < SCR_ROWS + 2 || COLS < SCR_COLS) {
        endwin();
        fprintf(stderr,
            "terminal too small: need at least %dx%d, have %dx%d.\n"
            "Resize the window (or reduce font size) and re-run.\n",
            SCR_COLS, SCR_ROWS + 2, COLS, LINES);
        return 3;
    }
    render_crtram();

    for (;;) {
        int n;
        int ch;
        for (n = 0; n < 5000 && !halted; n++) { maybe_irq(); step(); }

        while ((ch = getch()) != ERR) {
            if (ch == 27) {
                int c2 = getch();
                if (c2 == 'q' || c2 == 'Q') goto done;
                kbd_press_ascii(27);
                if (c2 != ERR) { render_crtram(); napms(30); kbd_press_ascii((unsigned char)c2); }
            } else if (ch == KEY_ENTER || ch == KEY_F(1) || ch == 5) {
                kbd_press_numpad_enter();
            } else if (ch == '\n' || ch == '\r') {
                kbd_press_ascii('\r');
            } else if (ch == KEY_BACKSPACE || ch == 127) {
                kbd_press_ascii(0x08);
            } else if (ch >= 0 && ch < 128) {
                kbd_press_ascii((unsigned char)ch);
            }
        }

        render_crtram();

        if (halted) {
            mvprintw(SCR_ROWS + 1, 0, "CPU HALTED: %s ($%02X at $%04X)  (press q)",
                     last_err ? last_err : "?", halt_op, halt_pc);
            refresh();
            while ((ch = getch()) != 'q' && ch != 'Q') { napms(50); }
            goto done;
        }
        napms(5);
    }
done:
    endwin();
    if (txlog) fclose(txlog);
    return 0;
}
#endif
