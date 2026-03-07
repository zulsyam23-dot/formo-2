# IR Migration Notes

Dokumen ini mencatat perubahan kontrak `Formo IR` lintas versi schema.

## Version 0.3.0 (Locked)

- Schema ID: `https://formo.dev/schema/ir/0.3.0`
- `irVersion` wajib bernilai `0.3.0`
- Struktur utama:
  - root: `entry`, `target`, `components`, `nodes`, `styles`
  - opsional: `tokens`, `diagnostics`
- Contract enforcement:
  - crate `formo-ir` mengekspos konstanta `IR_VERSION` + `IR_SCHEMA_ID`
  - golden fixtures ada di `fixtures/ir/*.ir.json`
  - test kontrak ada di `crates/formo-ir/tests/contract.rs`

## Migration Policy

- Dari `0.3.x` ke `0.3.y` (patch): tidak ada perubahan struktur JSON.
- Dari `0.3.x` ke `0.4.0` (major): boleh ada perubahan breaking, wajib disertai migration notes baru di dokumen ini.

## Future Entries

Tambahkan section baru per versi berikut format:

- `Version X.Y.Z`
- ringkasan perubahan field/semantik
- status kompatibilitas backward/forward
- langkah migrasi minimal
