## Historical Background

**Author:** Mickey White Lawless
**Revision:** 1.0
**Date:** June 21, 2026

### About This Project

The software documented in this manual is a modern reconstruction of a software development environment described in Lear Siegler technical literature for the ADM series of intelligent terminals.

Unlike many historical software systems, no known copy of the original development environment has survived. No source code, executable distribution, backup media, or archival images are presently known to exist. What remains are references contained within surviving Lear Siegler documentation, including descriptions of an interactive assembly-language development system used to create software for ADM-series terminals.

The original documentation describes a workflow involving an Assembly Control Program (ACP), source editing facilities, assembly tools, and support utilities. However, the software itself appears to have been lost.

Historically, ADM-series systems could be connected to external computing resources through serial communications links and modem connections. Contemporary documentation suggests that software development and support services were available through Lear Siegler facilities, though the underlying host systems and software infrastructure have not survived.

The implementation documented here is therefore not a restoration of original Lear Siegler software. Instead, it is an independent reconstruction developed from surviving documentation, firmware analysis, ROM reverse engineering, and observed hardware behavior.

### Preservation Goals

This project exists for four purposes:

* Preservation of historically significant ADM-series software development techniques.
* Creation of new software for surviving ADM-31 hardware.
* Documentation of the Motorola MC6800-based ADM architecture.
* Reconstruction of a development environment that otherwise appears to have disappeared from the historical record.

Where original implementation details were unavailable, behavior was reconstructed to match surviving firmware and hardware as closely as practical.

### Authenticity Statement

This project contains no known proprietary Lear Siegler source code.

All source code, tools, documentation, and supporting utilities were independently developed through analysis of publicly available documentation, firmware behavior, and original software engineering work.

Any similarities to historical software systems result from efforts to reproduce documented functionality and operator workflows.

### Open Source License

Copyright (c) 2026 Mickey White Lawless

Released under the MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---
# ADM-31 Development Toolchain — Reference Manual

**Lear Siegler ADM-31 terminal · Motorola MC6800 · plugin-ROM development**

This manual documents the two-tool workflow used to write, assemble, and test
6800 plugin-ROM software for the ADM-31:

- **`acp6800`** — a Motorola-6800 two-pass assembler with an ADM-style
  interactive front end (the "ACP / ASSEDIT" program development system).
- **`adm31emu`** — a functional ADM-31 emulator that runs assembled plugin
  ROMs against the real firmware ROMs, with a curses 80×24 display and a
  keyboard mapped onto the ADM-31 key matrix.

It also documents the **ADM-31 memory map**, the **I/O registers**, the
**firmware entry points** plugins rely on, and the conventions the source
files in this project follow.

---

## 1. The big picture

A plugin ROM lives in **ROM socket A**, mapped at **`$E000–$E7FF`** (2 KB). The
firmware (ROMs B/C/D) boots, and when the operator triggers the plugin
(`ESC '` on real hardware), the firmware dispatches into the plugin via a fixed
launch vector at **`$E03C`**. A plugin is recognized by the two-byte signature
**`"TJ"` (`$54 $4A`) at `$E000–$E001`**.

```
   source.asm ──▶  acp6800  ──▶  source.BIN  (raw 2 KB image, burn to 2716)
                    (assemble)     source.S19  (Motorola S-record)
                                   source.LST  (listing with addresses)
                                        │
                                        ▼
                                   adm31emu  ──▶  run & test on screen
                                   (+ ROM B/C/D firmware images)
```

The same `.BIN` that runs in `adm31emu` is what gets burned to a 2716 EPROM and
plugged into the real terminal, so emulator fidelity matters: a program verified
in `adm31emu` should behave identically on hardware.

---

## 2. The ADM-31 memory map

This is the address space the MC6800 sees. It is the single most important
reference for plugin work; every label and `EQU` in the source files derives
from it.

| Range            | Size   | Contents                                            |
|------------------|--------|-----------------------------------------------------|
| `$0000–$003F`    | 64 B   | Hardware/firmware **stack** area                    |
| `$0040–$013F`    | —      | General zero-page / scratch RAM                     |
| `$0140–$0147`    | 8 B    | Firmware serial **transmit buffer**                 |
| `$0148–$03FF`    | —      | Firmware serial **receive buffer** / general RAM    |
| `$0000–$03FF`    | **1 KB** | **Total on-board RAM**                            |
| `$7000`          | 1 B    | **HALT / VSYNC strobe** (retrace bit; poll target)  |
| `$7800`          | 1 B    | **PIA1 Peripheral Reg A** — keyboard scan/strobe    |
| `$7802`          | 1 B    | **PIA1 Peripheral Reg B** — SHIFT (bit 7) / CTRL (bit 6) |
| `$7900`          | 1 B    | Bank-select register `SW_BNK2`                      |
| `$7A00`          | 1 B    | **ACIA** status/control                             |
| `$7A01`          | 1 B    | **ACIA** data (serial RX/TX)                        |
| `$7B00`          | 1 B    | `PERROM / ANSPER`                                   |
| `$7C00`          | 1 B    | `PRNTER` (printer)                                  |
| `$7D00`          | 1 B    | Bank-select register `SW_BNK3`                      |
| `$7E00`          | 1 B    | Bank-select register `SW_BNK1`                      |
| `$7F00`          | 1 B    | **VTAC** (video timing) base; `$7F06`, `$7F0C` are register offsets |
| `$7000–$7FFF`    | 4 KB   | **I/O page** (decoded by chip-select signals)       |
| `$8000–$88FF`    | 2.25 KB| **CRTRAM** — 80×24 character display RAM            |
| `$E000–$E7FF`    | 2 KB   | **ROM A** — plugin slot (your code)                 |
| `$E800–$EFFF`    | 2 KB   | **ROM B** (ROM67) — firmware                        |
| `$F000–$F7FF`    | 2 KB   | **ROM C** (ROM66) — firmware                        |
| `$F800–$FFFF`    | 2 KB   | **ROM D** (ROM65) — firmware, holds reset/IRQ vectors |

### 2.1 Key fixed addresses

| Address | Meaning                                                              |
|---------|---------------------------------------------------------------------|
| `$E000` | Plugin signature byte 1 — must be `$54` (`'T'`)                      |
| `$E001` | Plugin signature byte 2 — must be `$4A` (`'J'`)                      |
| `$E03C` | **Plugin launch vector** — firmware `JMP`s here to start the plugin |
| `$FFFE` | RESET vector → `$E800` (firmware entry)                              |
| `$FFF8` | IRQ vector → `$ED83` (firmware IRQ handler)                          |
| `$EA1A` | Firmware **keycode table**: 79 entries × `{unshifted, shifted}` ASCII |

### 2.2 CRTRAM (the display)

CRTRAM is a flat 80×24 character buffer beginning at **`$8000`**. Row *r*,
column *c* is at `$8000 + r*80 + c`. The high bit of each byte is an attribute
(intensity/blink); mask with `& $7F` to get the glyph. The video hardware scans
CRTRAM continuously and independently of the CPU, so writing a character makes
it appear without any further action.

**Write protocol** (from the Rubout/Shuttle ROMs): a write to the HALT strobe
must precede the store, e.g.

```asm
        STAA    $7000          ; HALT/VSYNC strobe (synchronize)
        NOP
        STAA    0,X            ; store glyph into CRTRAM at X
```

### 2.3 Keyboard (PIA1)

The keyboard is an 87-key matrix read through PIA1. The protocol is **poll by
scan position**:

1. The MPU writes a **scan count** (the matrix position to test) to `$7800`.
   Low 4 bits select a column via a 4-to-16 decoder; high 3 bits select a row
   via an 8-to-1 mux.
2. If the key at that position is held, **STROBE** comes back as **bit 7** of
   `$7800` (firmware tests it with `BMI`/`BPL`).
3. SHIFT is `$7802` **bit 7**; CTRL is `$7802` **bit 6**.

To translate a scan to ASCII, index the firmware table at `$EA1A`:
`ascii = table[scan*2 + (shift ? 1 : 0)]`.

> **Important:** games poll the matrix **by scan position**, not by ASCII. Two
> different keys can produce the same ASCII (e.g. the arrow cluster sends the
> same control codes as Ctrl-H/J/K/L). When repointing a key, change the
> **scan** the program polls — see §7.

### 2.4 The ADM-31 arrow / function key cluster

Scans `$50–$57` are the function/arrow cluster. The arrow keys send the classic
terminal cursor control codes:

| Scan  | ASCII | Key            |
|-------|-------|----------------|
| `$54` | `$08` | ← cursor LEFT  |
| `$52` | `$0A` | ↓ cursor DOWN  |
| `$53` | `$0B` | ↑ cursor UP    |
| `$55` | `$0C` | → cursor RIGHT |

Other useful scans found in game ROMs: `$40` and `$09` (function keys, non-ASCII
codes `$90`/`$9E`), `$4B` (CLEAR), `$4F` (numpad ENTER, distinct from main
RETURN at scan 43 though both decode to CR), `$42` (`X`), `$75` (SPACE), `$29`
(`[`).

---

## 3. Firmware entry points used by plugins

Plugins can call into the firmware ROMs rather than re-implementing I/O. The
ones in active use:

| Symbol   | Address | Description                                                       |
|----------|---------|-------------------------------------------------------------------|
| `DSPMSG` | `$F6BB` | Display a string block. `B` = byte count, `(MSGPTR/$B3)` = source, `(MSGLOC/$B1)` = CRTRAM destination. (a.k.a. `SNDCHR` block copy) |
| `RCVCHR` | `$F740` | Blocking ACIA read (returns a received character)                 |
| `$F0DA`  | `$F0DA` | firmware sysCall                                                  |
| `$F5F8`  | `$F5F8` | firmware moveBall (used by Rubout)                                |

`DSPMSG` calling convention as seen in the ROMs:

```asm
        LDX     #SCREEN_DEST
        STX     $B1            ; MSGLOC
        LDAB    #COUNT
        LDX     #STRING
        STX     $B3            ; MSGPTR
        JSR     $F6BB          ; DSPMSG
```

Common zero-page variables: `MSGLOC = $B1`, `MSGPTR = $B3`; ball/paddle/timer
state in Rubout at `$16,$17,$F0–$FF`.

---

## 4. `acp6800` — the assembler

`acp6800` is a self-contained MC6800 assembler with an ADM-style interactive
menu ("6800 PROGRAM DEVELOPMENT SYSTEM", reports version 1.3). It does two
passes and emits three files.

### 4.1 Building it

```sh
cc -O2 -o acp6800 acp6800.c          # any C89 compiler; Turbo C large model on DOS
```

### 4.2 Running it — the interactive menu

Launching `./acp6800` prints a banner and a menu:

```
1    SOURCE FILE EDITOR.
2    ASSEMBLE PROGRAM.
3    SHOW THE ASSEMBLER OUTPUT FILE ON THE TERMINAL
4    END
```

- **1** — line-based source editor (`ASSEDIT`): create / append / edit /
  duplicate / shrink / merge source files.
- **2** — assemble a source file.
- **3** — dump the most recent `.LST` to the terminal.
- **4** — exit. (Typing `BYE` at the prompt also disconnects.)

### 4.3 The assemble flow (menu option 2)

Option 2 prompts in this order:

1. **Source file name** (e.g. `MYGAME.ASM`).
2. After pass 1 it prints `LAST ADDRESS USED IS xxxx` and `ERROR COUNT = n`.
3. **`PRINT LABEL LIST (Y) ?`** — `Y` appends the symbol table to the listing,
   `N` to skip.
4. **`CONTINUE WITH ASSEMBLY (Y) ?`** — `Y` runs pass 2 and writes output,
   `N` aborts.
5. **`PAD BINARY TO SIZE (0=none, 2048=2K ROM, other):`** — pad the `.BIN`
   out to the given size with **`$FF`** (EPROM blank value). Use `2048` for a
   full 2 KB ROM image, or `0` to leave it unpadded.

### 4.4 Driving it from a script (non-interactive)

Pipe the menu answers on stdin. The canonical one-liner to assemble and pad to
2 KB:

```sh
printf '2\nMYGAME.ASM\nN\nY\n2048\n4\n' | ./acp6800
#         │  │          │ │  │     └ menu 4 = exit
#         │  │          │ │  └ pad size (2048, or 0 for none)
#         │  │          │ └ continue with assembly = Y
#         │  │          └ print label list = N
#         │  └ source file
#         └ menu 2 = assemble
```

### 4.5 Output files

For source `BASE.ASM`, the assembler writes:

| File       | Contents                                                       |
|------------|----------------------------------------------------------------|
| `BASE.BIN` | Raw binary image (anchored at the lowest code address)         |
| `BASE.S19` | Motorola S-record object file                                  |
| `BASE.LST` | Assembly listing: `ADDR  CODE  LINE  SOURCE STATEMENT`, optional label list, and a summary |

> **Filename caveat:** the output base name is derived from the source name and
> is **truncated at the first underscore**. `SHUTTLE_A.ASM` produces
> `SHUTTLE_.BIN`. Avoid underscores if you want predictable names, or just look
> for the `BINARY ... WRITTEN TO <name>` line in the output.

### 4.6 Syntax and directives

`acp6800` uses the **modern Motorola dialect**: `LDAA`/`STAA`/`PSHA` (not the
old `LDA A` spaced form).

**Directives:**

| Directive | Alias | Meaning                                            |
|-----------|-------|----------------------------------------------------|
| `ORG`     |       | Set assembly origin. Gaps between `ORG`s are filled with **`$00`** in the `.BIN` (not `$FF`). |
| `EQU`     |       | Define a constant / label value                    |
| `FCB`     | `DB`  | Define byte(s): comma-separated 8-bit values       |
| `FDB`     | `DW`  | Define word(s): comma-separated 16-bit values (big-endian) |
| `FCC`     |       | Define an ASCII string: `FCC "text"`. A single source line emits at most **64 object bytes** (`OBJMAX`), so keep each `FCC` (and each `FCB`/`FDB` list) under that — split longer strings across multiple `FCC` lines. |
| `RMB`     |       | Reserve memory bytes (no object output)            |
| `END`     |       | End of source                                      |
| `CPU`     |       | Accepted but unimplemented — emits one harmless `INSTRUCTION NOT FOUND - CPU` error you can ignore. |

**Operand forms supported:**

| Form              | Example          | Mode                |
|-------------------|------------------|---------------------|
| Immediate         | `LDAA #$50`      | immediate (8-bit)   |
| Immediate (char)  | `LDAA #'A`       | immediate, ASCII    |
| Immediate (16-bit)| `LDX #$8000`     | immediate (16-bit)  |
| Direct (zero page)| `LDAA $20`       | direct              |
| Extended          | `STAA $8027`     | extended            |
| Indexed           | `STAA 0,X`       | indexed `n,X`       |
| Relative          | `BNE LABEL`      | branch              |
| Label + offset    | `LDX #TBL+4`     | symbol arithmetic   |

The assembler auto-selects **direct vs extended** based on whether the operand
fits in `$FF`. Comment lines start with `*` or `;`.

**Addressing modes the engine models** (`M_INH`, `M_IMM`, `M_DIR`, `M_IND`,
`M_EXT`, `M_REL`) cover the full standard MC6800 set.

### 4.7 Instruction set coverage

The opcode table (`optab[]`) contains **111 mnemonics** — the complete standard
MC6800 set including both accumulator forms and all inter-register ops:

```
ABA  ADCA ADCB ADDA ADDB ANDA ANDB ASL  ASLA ASLB ASR  ASRA ASRB
BCC  BCS  BEQ  BGE  BGT  BHI  BITA BITB BLE  BLS  BLT  BMI  BNE  BPL
BRA  BSR  BVC  BVS  CBA  CLC  CLI  CLR  CLRA CLRB CLV  CMPA CMPB COM
COMA COMB CPX  DAA  DEC  DECA DECB DES  DEX  EORA EORB INC  INCA INCB
INS  INX  JMP  JSR  LDAA LDAB LDS  LDX  LSR  LSRA LSRB LSL  LSLA LSLB
NEG  NEGA NEGB NOP  ORAA ORAB PSHA PSHB PULA PULB ROL  ROLA ROLB ROR
RORA RORB RTI  RTS  SBA  SBCA SBCB SEC  SEI  SEV  STAA STAB STS  STX
SUBA SUBB SWI  TAB  TAP  TBA  TPA  TST  TSTA TSTB TSX  TXS  WAI
```

(`LSL`/`LSLA`/`LSLB` are accepted as aliases of `ASL`/`ASLA`/`ASLB`.)

### 4.8 Limits

| Constant   | Value | Meaning                          |
|------------|-------|----------------------------------|
| `MAXLINES` | 3000  | source records per file          |
| `LINELEN`  | 128   | characters per source line       |
| `MAXSYM`   | 2000  | symbol table entries             |
| `OBJMAX`   | 64    | object bytes emitted per line (caps `FCC`/`FCB`/`FDB`) |

---

## 5. `adm31emu` — the emulator

A **functional** (not cycle-exact) ADM-31 emulator. It runs a full MC6800 core
against the real firmware ROMs, renders CRTRAM with curses, and maps the host
keyboard onto the ADM-31 key matrix. What is *not* modeled: VTAC video timing,
exact IRQ cadence, and cycle counts — none of which are needed to run and test
plugin programs.

### 5.1 Building it

```sh
cc -O2 -o adm31emu adm31emu.c -lncurses      # interactive curses TUI
cc -O2 -DHEADLESS -o adm31test adm31emu.c    # headless self-test (no curses)
```

> On a fresh Linux box you may need the ncurses dev headers:
> `apt install libncurses-dev`.

### 5.2 Command line

```
adm31emu --romA <plugin.bin> --romB <rom67.bin> \
         --romC <rom65.bin>  --romD <rom66.bin> [--boot firmware|plugin]
```

| Flag                | Loads at | Meaning                                              |
|---------------------|----------|------------------------------------------------------|
| `--romA <file>`     | `$E000`  | Plugin ROM (your assembled `.BIN`)                   |
| `--romB <file>`     | `$E800`  | Firmware ROM B (ROM67)                               |
| `--romC <file>`     | `$F000`  | Firmware ROM C (ROM66)                               |
| `--romD <file>`     | `$F800`  | Firmware ROM D (ROM65)                               |
| `--plugin <file>`   | `$E000`  | Run a plugin alone                                   |
| `--boot firmware\|plugin` | —  | Boot through the firmware, or jump straight to the plugin |
| `--rom file@E000`   | given    | Load a file at an explicit hex address               |
| `--org <hex>`       | —        | Override the start PC                                |
| `--sp <hex>`        | —        | Override the initial stack pointer                   |

**Typical invocation** (boot firmware, then launch a game plugin):

```sh
./adm31emu --romA shuttle.bin --romB ROM67.bin \
           --romC ROM66.bin   --romD ROM65.bin  --boot game
```

> Note the firmware ROM filenames map to sockets, **not** to letter: `ROM67`→B
> (`$E800`), `ROM66`→C (`$F000`), `ROM65`→D (`$F800`). The `--boot` step runs
> the firmware to initialize the hardware, then pushes a fake return frame and
> jumps to the plugin launch vector `$E03C`, exactly as the real `ESC '`
> dispatch does.

### 5.3 The display and status line

The TUI renders the 80×24 CRTRAM live (glyphs masked to 7 bits). A status line
shows the CPU state:

```
PC=xxxx A=xx B=xx X=xxxx SP=xxxx CC=xx  [Enter=start  ESC-q quit]
```

If the CPU executes an instruction the core cannot decode, it halts and prints:

```
CPU HALTED: illegal/unimplemented opcode ($xx at $xxxx)  (press q)
```

### 5.4 Keyboard mapping (host → ADM-31 matrix)

| Host key            | ADM-31 action                | Scan / mechanism                  |
|---------------------|------------------------------|-----------------------------------|
| Letters/digits/sym  | same ASCII                   | looked up in the `$EA1A` table    |
| **Return / Enter**  | numpad ENTER line            | scan `$4F` (decodes to CR; what CINT polls) |
| **Backspace**       | BS                           | `$08`                             |
| **← → ↑ ↓ arrows**  | ADM-31 cursor keys           | scans `$54 / $55 / $53 / $52`     |
| **Space**           | (game-dependent; e.g. fire)  | mapped to scan `$40` in game builds |
| **ESC**             | ESC to the matrix            | `$1B`                             |
| **ESC then `q`**    | **quit the emulator**        | —                                 |

Two helpers in the code make this work:

- `kbd_press_ascii(ch)` — finds the scan whose table entry equals `ch` (tries
  unshifted, then shifted, then CTRL for control chars).
- `kbd_press_scan(scan)` — presses a matrix position **directly**, bypassing the
  ASCII table. This is required for the arrow/function keys, whose ASCII codes
  collide with control characters. A pressed key is held for ~20000 instruction
  steps (`kbd_hold`) then auto-released, which satisfies firmware debounce.

The keyboard table `kbd_tbl[79][2]` is a copy of the firmware `$EA1A` table
(`{unshifted, shifted}` per scan).

### 5.5 I/O emulation details

| Address     | Read behavior                                   | Write behavior                  |
|-------------|-------------------------------------------------|---------------------------------|
| `$7000`     | VSYNC strobe — toggling retrace bit for poll waits | latched                      |
| `$7800`     | scan readback: bit 7 = STROBE if held key's scan matches the last value written; low bits echo the scan | latches the scan count the MPU selects |
| `$7802`     | SHIFT on bit 7, CTRL on bit 6                    | latched                         |
| `$7A00`     | ACIA status (RDRF when host key queued)          | control                         |
| `$7A01`     | ACIA data (reading clears RDRF)                  | transmit (to host)              |
| `$7F00…`    | VTAC / bank registers                            | latched (returned on read)      |

Host keystrokes are also pushed into an ACIA receive queue (`rxq`), so firmware
routines that read via `RCVCHR`/`$F740` get input too — both the matrix-poll and
serial paths work.

### 5.6 Illegal-opcode handling

The core implements the full documented MC6800 instruction set. One
**undocumented** opcode is implemented deliberately:

- **`$00`** executes as a **1-byte NOP**. On real NMOS 6800 silicon `$00` is a
  no-op (it is *not* one of the lock-up/"HCF" codes). Shuttle Attack branches
  into a `SUBA #$E7 / $00 / TST $07,X` sequence and depends on this. All other
  undecoded opcodes still halt loudly so they can be examined rather than
  silently skipped.

### 5.7 Headless mode

Compiling with `-DHEADLESS` replaces the curses front end with a `main()` you
can script for self-tests: load ROMs, boot, inject keystrokes via
`kbd_press_scan`/`kbd_press_ascii`, run a batch of `step()`s, and dump CRTRAM.
This is how every fix in this project was regression-tested (e.g. "press X →
PC reaches the game-start path", "fire spawns a `'-'` missile and the score
increments"). It is the recommended way to verify a patch before burning a ROM.

---

## 6. Source-file conventions

The hand-written and disassembled `.ASM` files in this project share a layout:

```asm
        CPU     6800                    ; harmless; one ignorable error

; ---- ADM-31 hardware ----
HALT            EQU     $7000
PIA1            EQU     $7800
CRTRAM          EQU     $8000
KBDTAB          EQU     $EA1A           ; firmware keycode table

        ORG     $E000
        FCB     $54,$4A                 ; "TJ" plugin signature

        ORG     $E03C
        JMP     COLDST                  ; firmware dispatch enters here
COLDST  ...                             ; your code
```

Conventions:

- **Signature first.** `$E000` must be `$54,$4A`.
- **Launch vector at `$E03C`.** The firmware jumps here; put a `JMP` to your
  real entry point. (Some ROMs place `01 01 01` filler at `$E03C` then the real
  `JMP` at `$E03F` — both patterns work as long as `$E03C` is reachable code.)
- **`$FF` fill is data.** Uninitialized EPROM reads as `$FF`. Because `acp6800`
  fills `ORG` gaps with `$00`, those regions must be declared explicitly as
  `FCB $FF,...` to stay byte-exact with an original ROM.
- **Strings** are `FCC "..."` (≤ 64 chars each), printed via `DSPMSG` with an
  explicit length count — so editing a string **must preserve its byte length**
  (pad with spaces) unless you also adjust the count and everything downstream.
- **Symbolic targets.** Branch/jump targets use labels so the assembler
  recomputes addresses; this is what makes edits like string changes safe.

---

## 7. Worked example: repointing a "start" key

This is the recurring task — a game's prompt says "press X" but the code polls a
key you don't have on a Mac. The fix has two parts, done in the **source**, and
verified in the **emulator**.

**1. Find the poll.** Search the binary for `LDAA #imm ; STAA $7800` followed by
`TST $7800` / `BPL`/`BMI`. The immediate is the scan being polled.

```asm
L_E74D  LDAA    #$4B            ; polls scan $4B = CLEAR
        STAA    PIA1
        LDAA    PIA1
        BMI     L_E759          ; pressed -> start the game at $E759
```

**2. Repoint it.** Change the immediate to the scan of the key you want — e.g.
`$42` for `X`:

```asm
L_E74D  LDAA    #$42            ; now polls scan $42 = X
```

**3. Make the prompt truthful**, keeping the field length:

```asm
MSG_PRESS  FCC  "Press X for game    "   ; 20 bytes, padded — same length as original
```

**4. Reassemble and verify** the only bytes that changed are the prompt text and
the one scan byte, then run it in `adm31emu` and confirm the key starts the
game. (In this project that produced exactly 13 changed bytes for Rubout and
a clean boot showing "Press X for game".)

> The same recipe maps movement/fire keys: find each `STAA $7800` poll, read the
> scan, and either repoint it in the ROM or — cleaner — map the host key to that
> scan in `adm31emu` via `kbd_press_scan`, leaving the ROM untouched.

---

## 8. Quick reference card

**Assemble + pad to 2 KB:**
```sh
printf '2\nGAME.ASM\nN\nY\n2048\n4\n' | ./acp6800
```

**Run in the emulator:**
```sh
./adm31emu --romA GAME.BIN --romB ROM67.bin --romC ROM66.bin --romD ROM65.bin --boot game
```

**Build the tools:**
```sh
cc -O2 -o acp6800 acp6800.c
cc -O2 -o adm31emu adm31emu.c -lncurses
cc -O2 -DHEADLESS -o adm31test adm31emu.c
```

**Verify a disassembly is byte-exact** (Python):
```python
a = open('orig.bin','rb').read()
b = open('GAME.BIN','rb').read()
print('IDENTICAL' if a == b else f'{sum(x!=y for x,y in zip(a,b))} diffs')
```

**Essential addresses:** plugin `$E000–$E7FF` · signature `$E000`=`TJ` · launch
`$E03C` · RAM `$0000–$03FF` · stack `$0000–$003F` · PIA1 `$7800`/`$7802` · HALT
`$7000` · CRTRAM `$8000` (row*80+col) · ACIA `$7A00/$7A01` · VTAC `$7F00` ·
keycode table `$EA1A` · `DSPMSG` `$F6BB` · `RCVCHR` `$F740`.

**Keyboard:** poll by **scan**, not ASCII · STROBE = `$7800` bit 7 · SHIFT =
`$7802` bit 7 · CTRL = `$7802` bit 6 · arrows `$52`–`$55` · CLEAR `$4B` · numpad
ENTER `$4F` · SPACE `$75` · `X` `$42` · `[` `$29`.

---

*Document covers `acp6800.c` (v1.3) and `adm31emu.c` as built in this project.
Hardware facts are from the ADM-31 Table 4-1 chip-select map and verified
against the firmware ROMs and the Rubout / Shuttle Attack / CINT plugin ROMs.*
