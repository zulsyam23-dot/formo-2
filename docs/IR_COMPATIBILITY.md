# IR Compatibility Policy

Dokumen ini menetapkan kebijakan kompatibilitas kontrak `Formo IR`.

## Prinsip Versi

- Patch/minor yang kompatibel: consumer valid pada versi sebelumnya tetap valid.
- Major (breaking): diperbolehkan hanya dengan migration notes eksplisit.

## Source of Truth

- Schema JSON: `formo-ir.schema.json`
- Konstanta crate: `formo_ir::IR_VERSION`, `formo_ir::IR_SCHEMA_ID`
- Golden fixtures: `fixtures/ir/*.ir.json`
- Contract tests: `../formo-library-ecosystem/language-core/programs/formo-ir/tests/contract.rs`

## Aturan Perubahan IR

Setiap perubahan kontrak IR wajib:
1. update `formo-ir.schema.json` (`$id`/field terkait),
2. update konstanta versi di `formo-ir` crate,
3. update/tambah golden fixture,
4. tambah catatan migrasi di `docs/IR_MIGRATIONS.md`,
5. pastikan test IR dan CI hijau.

## Definisi Kompatibilitas

Perubahan dianggap kompatibel jika:
- tidak menghapus field required existing,
- tidak mengubah tipe field existing secara incompatible,
- tidak mengubah semantik field existing secara silent.

Jika salah satu dilanggar, perlakukan sebagai breaking change.
