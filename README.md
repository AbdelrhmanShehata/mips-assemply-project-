[readme_md.md](https://github.com/user-attachments/files/33730556/readme_md.md)
# ⚡ 32-Bit 5-Stage Pipelined MIPS Processor in VHDL

A fully functional, 32-bit pipelined MIPS processor implemented in VHDL, featuring comprehensive pipeline hazard handling (forwarding, load-use stalls, and branch flushes) and a companion Python Assembler (`asm2hex.py`). Designed, simulated, and verified using ModelSim.

---

## 🏗️ Architecture & Pipeline Stages

The CPU implements the classic 5-stage RISC pipeline architecture connected via 4 intermediate pipeline registers:

1. **IF (Instruction Fetch):** Fetches 32-bit instructions from a 64-word instruction ROM (`imem.vhd`) and increments the PC ($PC + 4$). Supports synchronous stalls.
2. **ID (Instruction Decode):** Decodes opcodes and funct fields, reads source registers from the 32-entry register file, performs sign/zero extension on immediates, and calculates branch/jump targets.
3. **EX (Execute):** Executes arithmetic and logical operations via a 7-operation ALU, evaluates branch conditions, resolves `jr`, and shifts `lui`.
4. **MEM (Memory Access):** Reads (`lw`) and writes (`sw`) 32-bit words to synchronous data memory (`dmem.vhd`).
5. **WB (Write Back):** Writes ALU results or memory data back into the destination register (`$rd` or `$rt`), and saves return addresses for `jal`.

```
[ IF ] ---> IF/ID ---> [ ID ] ---> ID/EX ---> [ EX ] ---> EX/MEM ---> [ MEM ] ---> MEM/WB ---> [ WB ]
                          ^                      |                         |
                          |-- Hazard Detection --|--- Forwarding Unit -----|
```

---

## 🛡️ Hazard Handling & Resolution

* **Data Forwarding (RAW Hazards):** `EX/MEM` and `MEM/WB` forwarding paths feed intermediate results directly back to ALU inputs to eliminate data hazards without introducing pipeline bubbles.
* **Load-Use Hazards:** The `hazard_detection.vhd` unit detects when an instruction depends on a prior load, freezing the PC and `IF/ID` register for 1 cycle while inserting a `NOP` bubble into `ID/EX`.
* **Control Hazards:** Taken branches (`beq`, `bne`) and jumps (`j`, `jal`, `jr`) trigger a pipeline flush, discarding the two instructions fetched after the jump (2-cycle penalty).

---

## 📋 Supported Instruction Set Architecture (19 Instructions)

| Type | Instructions | Details |
| :--- | :--- | :--- |
| **R-Type** | `add`, `sub`, `and`, `or`, `xor`, `nor`, `slt`, `jr` | 6-bit `funct` field, writes to `$rd` |
| **I-Type** | `addi`, `slti`, `andi`, `ori`, `lui`, `lw`, `sw`, `beq`, `bne` | 16-bit signed/zero-extended immediate, writes to `$rt` |
| **J-Type** | `j`, `jal` | 26-bit jump target address; `jal` writes $PC+4$ to `$ra` (`$31`) |

---

## 🐍 Python Assembler (`asm2hex.py`)

A custom two-pass assembler that translates MIPS assembly source code (`.asm`) directly into machine code:
* **Pass 1:** Scans instructions and constructs a symbol table for labels.
* **Pass 2:** Resolves register aliases and relative label offsets, packing fields into 32-bit binary/hex machine words.
* **Pseudo-operations:** Transparently expands `nop`, `move`, and `li`.

### Assembler Usage:
```bash
# Generate hex words to stdout
python asm2hex.py program.asm

# Generate VHDL-ready mem_array constants for imem.vhd
python asm2hex.py program.asm --vhdl
```

---

## 🧪 Simulation Workflow (ModelSim)

1. Write MIPS assembly source code (`program.asm`).
2. Run `asm2hex.py --vhdl` to generate instruction words.
3. Update instruction memory (`imem.vhd`) with the generated array constants.
4. Compile all VHDL entities and testbench (`tb.vhd`) in **ModelSim**.
5. Run simulation and inspect waveforms for register writeback, pipeline registers, memory access, and PC flow.

---

## 📁 Repository Structure

```
├── src/
│   ├── TopLevel.vhd          # Top-level structural entity (mips_pipeline)
│   ├── pc_reg.vhd            # Program counter with stall logic
│   ├── imem.vhd              # Instruction ROM (64 words)
│   ├── ifid.vhd              # IF/ID pipeline register
│   ├── idiex.vhd             # ID/EX pipeline register
│   ├── ieximem.vhd           # EX/MEM pipeline register
│   ├── imemiwb.vhd           # MEM/WB pipeline register
│   ├── reg_file.vhd          # 32x32-bit register file
│   ├── alu.vhd               # 7-operation arithmetic logic unit
│   ├── alu_control.vhd       # ALU control unit
│   ├── main_control.vhd      # Main instruction decoder (13 signals)
│   ├── dmem.vhd              # Synchronous data memory
│   ├── forwarding_unit.vhd   # Hazard bypass & forwarding logic
│   └── hazard_detection.vhd  # Load-use stall & branch flush unit
├── sim/
│   └── tb.vhd                # Testbench for cycle-accurate simulation
├── tools/
│   └── asm2hex.py            # Two-pass Python assembler
├── docs/
│   └── MIPS_Pipeline_Report.pdf # Comprehensive technical report
└── README.md
```
