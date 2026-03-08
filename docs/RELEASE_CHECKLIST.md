# Release Checklist

Checklist ini dipakai sebelum membuat rilis resmi Formo.

## 1) Semver dan Tag

- tentukan versi `MAJOR.MINOR.PATCH`,
- buat tag `vX.Y.Z`,
- pastikan tag menunjuk commit yang lulus CI.

Contoh:

```bash
git tag v0.2.0
git push origin v0.2.0
```

## 2) Changelog

- pindahkan item dari `## [Unreleased]` ke section versi baru,
- tambahkan tanggal rilis (`YYYY-MM-DD`),
- tandai breaking change secara eksplisit.

## 3) Migration Notes

- update `docs/IR_MIGRATIONS.md` bila ada perubahan IR,
- pastikan `docs/IR_COMPATIBILITY.md` tetap akurat,
- sertakan langkah migrasi untuk perubahan breaking.

## 4) Quality Gate

CI branch rilis wajib hijau:
- lint
- test
- fuzz-parser
- smoke
- benchmark
- readme-examples
- release-readiness

## 5) Final Validation

```bash
cargo check --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace
cargo clippy --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace --all-targets -- -D warnings
cargo test --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace
```

Pastikan build `web` dan `desktop` dari `main.fm` berhasil.

## 6) Gate Khusus Formo 0.2 (Library-First)

- root `formo` tidak memiliki source crate compiler/runtime/tooling,
- command dokumentasi konsisten memakai `--manifest-path ../formo-library-ecosystem/Cargo.toml`,
- `docs/LIBRARY_BOUNDARY.md` konsisten dengan implementasi aktual,
- `formo-library-ecosystem` branch `main` sudah ter-push.
