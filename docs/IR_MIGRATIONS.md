# IR Migration Notes

Dokumen ini mencatat perubahan kontrak `Formo IR` antar versi.

## Version 0.3.0 (Locked)

- Schema ID: `https://formo.dev/schema/ir/0.3.0`
- `irVersion` wajib `0.3.0`
- Struktur root:
  - required: `entry`, `target`, `components`, `nodes`, `styles`
  - optional: `tokens`, `diagnostics`
- Enforcement:
  - konstanta versi di crate `formo-ir`,
  - golden fixtures `fixtures/ir/*.ir.json`,
  - contract tests di `../formo-library-ecosystem/language-core/programs/formo-ir/tests/contract.rs`.

## Migration Policy

- `0.3.x -> 0.3.y`: tidak boleh ada perubahan struktur JSON.
- `0.3.x -> 0.4.0`: perubahan breaking diperbolehkan dengan migration entry baru.

## Template Entry Baru

Saat menambah versi baru, gunakan format:

- `Version X.Y.Z`
- ringkasan perubahan field/semantik
- status kompatibilitas (`backward-compatible` / `breaking`)
- langkah migrasi minimal untuk consumer
