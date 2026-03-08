# Formo Production Roadmap

Dokumen ini menjadi acuan eksekusi teknis menuju rilis `Formo 0.2.0`.

## Scope 0.2.0

Formo 0.2.0 menegaskan model `library-first`:
- `formo` fokus bahasa/proyek,
- compiler/runtime/tooling berada di `formo-library-ecosystem`.

## Objective

1. Kontrak arsitektur `formo` vs `library` stabil.
2. Mekanisme build/check/CI konsisten via `--manifest-path`.
3. Runtime web/desktop siap dipanggil sebagai dependency opsional.
4. Dokumentasi release siap untuk tag `v0.2.0`.

## Status Milestone 0.2.0

- [x] Source crate Rust dipusatkan di `../formo-library-ecosystem/*/programs/`.
- [x] Root `formo` tidak menyimpan workspace Cargo.
- [x] Command operasional memakai `--manifest-path ../formo-library-ecosystem/Cargo.toml`.
- [x] Backend `web`/`desktop` opsional via feature.
- [x] CI dan script utama sudah diselaraskan ke mode library-first.
- [x] Dokumentasi boundary tersedia (`docs/LIBRARY_BOUNDARY.md`).
- [ ] Final release note + tag `v0.2.0`.

## Quality Gate

Wajib hijau sebelum release:
- `cargo check --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace`
- `cargo clippy --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace --all-targets -- -D warnings`
- `cargo test --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace`
- CI pipeline (lint/test/fuzz-parser/smoke/benchmark/readme-examples/release-readiness)

## Workstream Prioritas

### 1) Language Core

Path:
- `../formo-library-ecosystem/language-core/programs/*`

Target:
- stabilitas parser/resolver/typer,
- konsistensi format error,
- maintain kontrak IR.

### 2) Style System

Path:
- `../formo-library-ecosystem/language-style/programs/formo-style`

Target:
- output style deterministik,
- validasi allowlist property,
- jaga contract token/style.

### 3) Runtime Web

Path:
- `../formo-library-ecosystem/runtime-web/programs/formo-backend-web`

Target:
- performa list render,
- baseline aksesibilitas,
- kestabilan output production.

### 4) Runtime Desktop

Path:
- `../formo-library-ecosystem/runtime-desktop/programs/formo-backend-desktop`

Target:
- parity perilaku dengan web runtime,
- stabilitas bridge state/action,
- roadmap packaging executable lintas OS.

### 5) Tooling

Path:
- `../formo-library-ecosystem/tooling/programs/formo-cli`

Target:
- DX command (`check/diagnose/fmt/doctor/build/bench/lsp`),
- format output JSON/LSP stabil,
- feature-gated backend tetap terjaga.

## Risiko Utama

1. Drift dokumentasi vs implementasi library-first.
2. Regressi runtime saat optimasi web/desktop.
3. Perubahan IR tanpa migration note yang memadai.

Mitigasi:
- review dokumen boundary/release checklist pada setiap PR,
- pertahankan CI gate penuh,
- wajib update `IR_MIGRATIONS.md` untuk perubahan kontrak.

## Definition of Done (0.2.0)

Release `v0.2.0` dianggap selesai jika:
- quality gate hijau,
- changelog dan release checklist lengkap,
- boundary `formo` vs `library` terverifikasi,
- repo library sudah sinkron di GitHub.
