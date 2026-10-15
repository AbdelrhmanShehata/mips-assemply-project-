#!/usr/bin/env python3
"""
Assemble MIPS subset for the pipelined CPU in this project.

Usage:
    python asm2hex.py program.asm
    python asm2hex.py program.asm --vhdl
    python asm2hex.py program.asm -o imem_snippet.txt

Supports R/I/J instructions decoded by main_control.vhd (see README in --help).
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# --- registers -------------------------------------------------------------

REGISTERS: dict[str, int] = {
    "$0": 0,
    "$zero": 0,
    "$at": 1,
    "$v0": 2,
    "$v1": 3,
    "$a0": 4,
    "$a1": 5,
    "$a2": 6,
    "$a3": 7,
    "$t0": 8,
    "$t1": 9,
    "$t2": 10,
    "$t3": 11,
    "$t4": 12,
    "$t5": 13,
    "$t6": 14,
    "$t7": 15,
    "$s0": 16,
    "$s1": 17,
    "$s2": 18,
    "$s3": 19,
    "$s4": 20,
    "$s5": 21,
    "$s6": 22,
    "$s7": 23,
    "$t8": 24,
    "$t9": 25,
    "$k0": 26,
    "$k1": 27,
    "$gp": 28,
    "$sp": 29,
    "$fp": 30,
    "$s8": 30,
    "$ra": 31,
}

# --- opcodes / functs (match main_control.vhd + alu_control.vhd) ---------

OP_BEQ = 4
OP_BNE = 5
OP_ADDI = 8
OP_SLTI = 10
OP_ANDI = 12
OP_ORI = 13
OP_LUI = 15
OP_J = 2
OP_JAL = 3
OP_LW = 35
OP_SW = 43

FUNCT_ADD = 0x20
FUNCT_SUB = 0x22
FUNCT_AND = 0x24
FUNCT_OR = 0x25
FUNCT_XOR = 0x26
FUNCT_NOR = 0x27
FUNCT_SLT = 0x2A
FUNCT_JR = 0x08

R_TYPE_FUNCT = {
    "add": FUNCT_ADD,
    "sub": FUNCT_SUB,
    "and": FUNCT_AND,
    "or": FUNCT_OR,
    "xor": FUNCT_XOR,
    "nor": FUNCT_NOR,
    "slt": FUNCT_SLT,
}

I_TYPE_OPCODE = {
    "beq": OP_BEQ,
    "bne": OP_BNE,
    "addi": OP_ADDI,
    "slti": OP_SLTI,
    "andi": OP_ANDI,
    "ori": OP_ORI,
    "lui": OP_LUI,
    "lw": OP_LW,
    "sw": OP_SW,
}

J_TYPE_OPCODE = {
    "j": OP_J,
    "jal": OP_JAL,
}


class AsmError(Exception):
    pass


def parse_int(text: str) -> int:
    text = text.strip()
    if not text:
        raise AsmError("missing immediate")
    return int(text, 0)


def reg_num(name: str) -> int:
    name = name.strip().lower()
    if name.startswith("$") and name[1:].isdigit():
        n = int(name[1:])
        if 0 <= n <= 31:
            return n
    if name in REGISTERS:
        return REGISTERS[name]
    raise AsmError(f"unknown register: {name}")


def imm16(value: int) -> int:
    if not -0x8000 <= value <= 0xFFFF:
        raise AsmError(f"immediate out of 16-bit range: {value}")
    return value & 0xFFFF


def encode_r(rs: int, rt: int, rd: int, shamt: int, funct: int) -> int:
    return (rs << 21) | (rt << 16) | (rd << 11) | (shamt << 6) | funct


def encode_i(opcode: int, rs: int, rt: int, imm: int) -> int:
    return (opcode << 26) | (rs << 21) | (rt << 16) | imm16(imm)


def encode_j(opcode: int, word_index: int) -> int:
    if not 0 <= word_index < (1 << 26):
        raise AsmError(f"jump target word index out of range: {word_index}")
    return (opcode << 26) | (word_index & 0x03FFFFFF)


def strip_comment(line: str) -> str:
    if "#" in line:
        line = line[: line.index("#")]
    if "//" in line:
        line = line[: line.index("//")]
    return line.strip()


def split_operands(rest: str) -> list[str]:
    return [p.strip() for p in rest.split(",") if p.strip()]


def parse_mem_operand(text: str) -> tuple[int, int]:
    m = re.match(r"^\s*(-?\w+)\s*\(\s*(\$\w+)\s*\)\s*$", text, re.I)
    if not m:
        raise AsmError(f"expected offset(reg), got: {text}")
    return parse_int(m.group(1)), reg_num(m.group(2))


def preprocess_line(raw: str, line_no: int) -> tuple[str | None, str | None]:
    """Return (label, instruction_text) for one source line."""
    line = strip_comment(raw)
    if not line:
        return None, None

    label = None
    if ":" in line:
        before, after = line.split(":", 1)
        label = before.strip()
        if not label:
            raise AsmError(f"empty label on line {line_no}")
        if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", label):
            raise AsmError(f"invalid label '{label}' on line {line_no}")
        line = after.strip()
        if not line:
            return label, None

    return label, line


def expand_pseudo(mnemonic: str, ops: list[str], line_no: int) -> list[tuple[str, list[str]]]:
    if mnemonic == "nop":
        return [("add", ["$0", "$0", "$0"])]
    if mnemonic == "move":
        if len(ops) != 2:
            raise AsmError(f"move needs 2 operands on line {line_no}")
        return [("add", [ops[0], ops[1], "$0"])]
    if mnemonic == "li":
        if len(ops) != 2:
            raise AsmError(f"li needs 2 operands on line {line_no}")
        rt, imm = ops[0], parse_int(ops[1])
        if -0x8000 <= imm <= 0x7FFF:
            return [("addi", [rt, "$0", str(imm)])]
        hi = (imm >> 16) & 0xFFFF
        lo = imm & 0xFFFF
        if imm & 0x8000 and lo == 0:
            hi = (hi + 1) & 0xFFFF
        seq: list[tuple[str, list[str]]] = [("lui", [rt, str(hi)])]
        if lo != 0:
            seq.append(("ori", [rt, rt, str(lo)]))
        return seq
    return [(mnemonic, ops)]


def encode_instruction(
    mnemonic: str, ops: list[str], pc_word: int, labels: dict[str, int], line_no: int
) -> int:
    m = mnemonic.lower()

    if m in R_TYPE_FUNCT:
        if len(ops) != 3:
            raise AsmError(f"{m} needs 3 registers on line {line_no}")
        rd, rs, rt = reg_num(ops[0]), reg_num(ops[1]), reg_num(ops[2])
        return encode_r(rs, rt, rd, 0, R_TYPE_FUNCT[m])

    if m == "jr":
        if len(ops) != 1:
            raise AsmError(f"jr needs 1 register on line {line_no}")
        rs = reg_num(ops[0])
        return encode_r(rs, 0, 0, 0, FUNCT_JR)

    if m in I_TYPE_OPCODE:
        op = I_TYPE_OPCODE[m]
        if m in ("lw", "sw"):
            if len(ops) != 2:
                raise AsmError(f"{m} needs rt, offset(rs) on line {line_no}")
            rt = reg_num(ops[0])
            offset, rs = parse_mem_operand(ops[1])
            return encode_i(op, rs, rt, offset)
        if m == "lui":
            if len(ops) != 2:
                raise AsmError(f"lui needs rt, imm on line {line_no}")
            rt = reg_num(ops[0])
            imm = parse_int(ops[1]) & 0xFFFF
            return encode_i(op, 0, rt, imm)
        if m in ("beq", "bne"):
            if len(ops) != 3:
                raise AsmError(f"{m} needs rs, rt, label on line {line_no}")
            rs, rt = reg_num(ops[0]), reg_num(ops[1])
            target = resolve_branch(ops[2], pc_word, labels, line_no)
            return encode_i(op, rs, rt, target)
        # addi, slti, andi, ori
        if len(ops) != 3:
            raise AsmError(f"{m} needs rt, rs, imm on line {line_no}")
        rt, rs = reg_num(ops[0]), reg_num(ops[1])
        imm = parse_int(ops[2])
        return encode_i(op, rs, rt, imm)

    if m in J_TYPE_OPCODE:
        if len(ops) != 1:
            raise AsmError(f"{m} needs one target on line {line_no}")
        target = resolve_jump(ops[0], labels, line_no)
        return encode_j(J_TYPE_OPCODE[m], target)

    raise AsmError(f"unknown instruction '{mnemonic}' on line {line_no}")


def resolve_label(name: str, labels: dict[str, int], line_no: int) -> int:
    key = name.strip()
    if key not in labels:
        raise AsmError(f"undefined label '{key}' on line {line_no}")
    return labels[key]


def resolve_branch(text: str, branch_pc_word: int, labels: dict[str, int], line_no: int) -> int:
    text = text.strip()
    if text.isdigit() or (text.startswith("-") and text[1:].isdigit()):
        target = int(text)
    else:
        target = resolve_label(text, labels, line_no)
    offset = target - (branch_pc_word + 1)
    if not -0x8000 <= offset <= 0x7FFF:
        raise AsmError(
            f"branch offset {offset} out of range (line {line_no}); use j for far targets"
        )
    return offset


def resolve_jump(text: str, labels: dict[str, int], line_no: int) -> int:
    text = text.strip()
    if text.isdigit() or (text.startswith("-") and text[1:].isdigit()):
        return int(text)
    return resolve_label(text, labels, line_no)


def collect_program(lines: list[str]) -> tuple[list[tuple[int, str, list[str], str]], dict[str, int]]:
    """Pass 1: assign word indices and build label table."""
    labels: dict[str, int] = {}
    program: list[tuple[int, str, list[str], str]] = []
    pc = 0

    for line_no, raw in enumerate(lines, start=1):
        label, text = preprocess_line(raw, line_no)
        if label is not None:
            if label in labels:
                raise AsmError(f"duplicate label '{label}' on line {line_no}")
            labels[label] = pc

        if text is None:
            continue

        parts = text.split(None, 1)
        if len(parts) < 1:
            continue
        mnemonic = parts[0]
        rest = parts[1] if len(parts) > 1 else ""
        ops = split_operands(rest) if rest else []

        for real_m, real_ops in expand_pseudo(mnemonic, ops, line_no):
            program.append((line_no, real_m, real_ops, raw.rstrip()))
            pc += 1

    return program, labels


def assemble(source: str) -> list[tuple[int, str, int, str]]:
    lines = source.splitlines()
    program, labels = collect_program(lines)

    out: list[tuple[int, str, int, str]] = []
    for word_idx, (line_no, mnemonic, ops, raw) in enumerate(program):
        word = encode_instruction(mnemonic, ops, word_idx, labels, line_no)
        asm = format_asm(mnemonic, ops)
        out.append((word_idx, asm, word, raw))

    return out


def format_asm(mnemonic: str, ops: list[str]) -> str:
    m = mnemonic.lower()
    if m in ("lw", "sw") and len(ops) == 2:
        return f"{m} {ops[0]}, {ops[1]}"
    if ops:
        return f"{m} " + ", ".join(ops)
    return m


def format_hex_list(words: list[tuple[int, str, int, str]], mem_size: int = 64) -> str:
    lines = []
    for idx, asm, word, _ in words:
        lines.append(f"  {idx:2d} => x\"{word:08X}\",   -- {asm}")
    if len(words) < mem_size:
        lines.append("")
        lines.append(f"        others => x\"00000000\"  -- {mem_size - len(words)} unused words")
    return "\n".join(lines)


def format_vhdl(words: list[tuple[int, str, int, str]], mem_size: int = 64) -> str:
    body = format_hex_list(words, mem_size)
    return (
        "    constant mem : mem_array := (\n"
        f"{body}\n"
        "    );\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Assemble MIPS subset for this project's CPU."
    )
    parser.add_argument("asm_file", type=Path, help="input .asm file")
    parser.add_argument(
        "-o", "--output", type=Path, help="write result to file (default: stdout)"
    )
    parser.add_argument(
        "--vhdl",
        action="store_true",
        help="emit VHDL mem_array fragment (default: plain hex list)",
    )
    parser.add_argument(
        "--mem-size",
        type=int,
        default=64,
        help="IMEM depth for VHDL others padding (default: 64)",
    )
    args = parser.parse_args()

    try:
        source = args.asm_file.read_text(encoding="utf-8")
        words = assemble(source)
    except AsmError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except OSError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    if args.vhdl:
        text = format_vhdl(words, args.mem_size)
    else:
        text = format_hex_list(words, args.mem_size)

    if args.output:
        args.output.write_text(text + "\n", encoding="utf-8")
        print(f"Wrote {args.output}", file=sys.stderr)
    else:
        print(text)

    return 0


if __name__ == "__main__":
    sys.exit(main())
