# IR Compatibility Policy

Kebijakan kompatibilitas kontrak `Formo IR`:

- Minor/Patch (`0.x.y`): backward-compatible untuk consumer yang valid terhadap schema versi sebelumnya.
- Major (`x.0.0`): boleh breaking changes, wajib:
  - bump `IR_VERSION`
  - bump schema `$id`
  - tambah catatan migrasi di `docs/IR_MIGRATIONS.md`

## Contract Sources of Truth

- Schema: `formo-ir.schema.json`
- Crate constants: `formo_ir::IR_VERSION`, `formo_ir::IR_SCHEMA_ID`
- Golden fixtures: `fixtures/ir/*.ir.json`
- Contract tests: `crates/formo-ir/tests/contract.rs`

## Release Checklist (IR)

Saat mengubah kontrak IR:

1. Update `formo-ir.schema.json` (`$id` dan/atau field schema).
2. Update konstanta crate di `crates/formo-ir/src/lib.rs`.
3. Update/ tambah golden fixture `fixtures/ir/*.ir.json`.
4. Tambah entry baru di `docs/IR_MIGRATIONS.md`.
5. Pastikan `cargo test -p formo-ir` dan CI hijau.
