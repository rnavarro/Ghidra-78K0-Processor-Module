# Changes

## Unreleased

### Silent wrong code

Three constructors produced incorrect p-code without reporting anything. They
decode normally and show no `UNIMPLEMENTED` marker, so the listing looks correct
and the decompiler returns a plausible but wrong result.

- `MOV1 <short-direct addr>.bit, CY` stored `(saddr | mask)`. Writing a 0 left the
  bit set, because the OR could never clear it. Now a read-modify-write,
  `(saddr & ~mask) | (mask * CY)`.

- `MOV1 <0xFF00-page short-direct addr>.bit, CY` had its entire body commented out.
  It decoded to an empty instruction. Now implemented.

- `ROL4 [HL]` had the two nibbles exchanged on the store. The correct operation is
  `(HL)7-4 <- (HL)3-0` and `(HL)3-0 <- A3-0`, which is
  `*HL = ((hl & 0x0F) << 4) | (alo & 0x0F)`. The previous form matched real
  hardware in 4096 of 65536 cases; the corrected form matches in 65536 of 65536.

`ROR4 [HL]` was checked at the same time and is correct in the original.

### Previously unimplemented

38 constructors were declared `unimpl`, which truncates control flow at every
occurrence. All 38 now have semantics.

- `CALLF`, `CALLT`, `RETB`, `RETI`, `SEL`
- `MOV1`, `AND1`, `OR1`, `XOR1` (all forms)
- `ROL4`, `ROR4`
- `BRK`
- `ADJBA`, `ADJBS`

`ADJBA` and `ADJBS` are not described in the 78K0/KC2 user's manual beyond a
summary row: it gives no condition table. Their implementations were derived from
an emulator whose behaviour was captured from a physical uPD78F0831Y and checked
against 1024 cases each.

The listing text for `AND1`, `OR1` and `XOR1` was also reordered to the manual's
`CY, <source>` form. Their previous stubs printed the operands the other way
round. Encodings are unchanged; only the displayed operand order differs.

### Verification

The implementations were checked by executing the compiled `.sla` through
Ghidra's p-code emulator and comparing against the hardware-validated emulator:

| Instruction | Cases | Agreement |
|---|---|---|
| `ADJBA`, `ADJBS` | 2048 | 2048 |
| `ROL4`, `ROR4` | 131072 | 131072 |

### Known limitations

- `SEL RBn` does not redirect the register bank. Sleigh has no register-bank
  model, so the instruction records the new RBS bits in PSW but subsequent
  register references still read bank 0.
- `ROL4` and `ROR4` on a `0xFF00`-page operand raise an exception on real
  hardware. Sleigh cannot express that restriction, so both decode normally.
