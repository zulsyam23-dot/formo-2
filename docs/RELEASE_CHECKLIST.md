# Release Checklist

Checklist ini dipakai sebelum membuat rilis resmi.

## 1. Semver Tag

- Pilih versi rilis sesuai semver (`MAJOR.MINOR.PATCH`).
- Buat git tag dengan format `vX.Y.Z`.
- Pastikan tag menunjuk commit yang sudah lulus CI.

Contoh:

```bash
git tag v0.2.0
git push origin v0.2.0
```

## 2. Changelog

- Pindahkan item dari section `## [Unreleased]` di `CHANGELOG.md` ke section versi baru.
- Tambahkan tanggal rilis format `YYYY-MM-DD`.
- Pastikan perubahan breaking diberi catatan yang jelas.

## 3. Migration Notes

- Update `docs/IR_MIGRATIONS.md` bila ada perubahan kontrak IR/API.
- Pastikan `docs/IR_COMPATIBILITY.md` masih akurat.
- Jika ada breaking change, sertakan langkah migrasi minimal.

## 4. Quality Gate

- CI hijau pada branch rilis:
  - lint
  - test
  - fuzz-parser
  - smoke
  - benchmark
  - readme-examples
  - release-readiness

## 5. Final Validation

- `cargo test --workspace`
- `cargo clippy --workspace --all-targets -- -D warnings`
- Pastikan artefak build web/desktop dapat dihasilkan dari `main.fm`.
