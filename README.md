# Ghidra NEC/Renesas 78K/0 Processor Module

A Ghidra 78K/0 Processor Module allowing Ghidra to disassemble and decompile NEC/Renesas 78K/0 binaries.

## Installation

Place the `78K0` folder into the Ghidra installation directory:

```
Ghidra/Processors/78K0
```

That is a supported install location for a distribution-form module. Restart Ghidra and the language appears in the language picker.

## Loading a Binary

When loading a Binary into Ghidra, select the "..." button next to the Language textbox, and select the `78K0` language.

![GhidraLoader](https://github.com/user-attachments/assets/9306000d-677c-48b3-bf22-29ec144fe570)

To begin disassembling, select the first instruction, right-click and select `Disassemble` (or press the 'D' key).

A raw firmware image has no entry points, so Ghidra has nothing to start from and will decode very little on its own. Seeding from a vector table or an external disassembler's entry list is usually necessary. See "Seeding a raw image" below.

## Building

### Standalone

```
make GHIDRA=/path/to/ghidra_12.1.4_PUBLIC
```

`make check` builds and then prints the warnings that are expected and benign, so a new one stands out.

Compiler options live in `78K0/data/sleighArgs.txt`, one per line. `-l` reports pattern conflicts as errors rather than warnings, which is why it is enabled; without it an ambiguous constructor decodes silently.

`78K0/data/buildLanguage.xml` is the Ant build that ships with Ghidra processor modules. It imports `../.antProperties.xml`, which the GhidraDev Eclipse plugin generates. That file is not in this repository, so the Ant build does not run from a standalone clone. The Makefile is the equivalent.

### Inside a Ghidra source tree

Copy the `78K0` directory to `Ghidra/Processors/78K0` in a Ghidra source checkout. `78K0/build.gradle` then applies `processorProject.gradle`, which is what an in-tree processor module uses, and what SleighDevTools pcodetest requires to run differential tests against a toolchain. It does nothing in a standalone clone because those gradle scripts are not present.

## Seeding a raw image

An 8-bit MCU image usually has no usable entry points. On a part where block 0 has been overwritten, not even the reset vector survives. Ghidra's Aggressive Instruction Finder will not run until roughly twenty functions exist, so the analysis stalls at nothing.

Two approaches that work:

1. **Seed from the vector table**, if it is intact. Read each vector, disassemble the target, and create a function there.
2. **Seed from an external disassembler's entry list.** If a disassembler already exists for the architecture that produces correct boundaries, use it to produce a list of addresses, then create functions at those addresses before analysis runs. This beats guessing an alignment.

`CreateFunctionCmd` is the API for the second case. Set the containing memory block executable first, because the module may map flash non-executable and both `disassemble()` and `CreateFunctionCmd` refuse a non-executable block without saying so.

## Validation

The instructions were checked by compiling the `.sla`, executing it through Ghidra's p-code emulator, and comparing each result against an emulator whose behaviour was captured from physical hardware.

`ghidra.app.emulator.EmulatorHelper` is deprecated for removal as of Ghidra 12.1. Use `ghidra.pcode.emu.PcodeEmulator`. A worked example ships with Ghidra at `Ghidra/Features/SystemEmulation/ghidra_scripts/StandAloneEmuExampleScript.java`.

## Known limitations

- `SEL RBn` writes the new RBS bits into PSW but does not redirect the register bank. Sleigh has no register-bank model, so register reads after a `SEL` still come from bank 0.
- `ROL4` and `ROR4` raise on a `0xFF00`-page operand on the part. Sleigh cannot express that restriction, so both decode normally here.

## License

GPL-3.0. See `LICENSE`.
