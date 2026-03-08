# Changelog

Semua perubahan penting proyek ini dicatat di file ini.

Format mengikuti prinsip [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
dan versi mengikuti [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- CI lint/test/smoke/benchmark/readme-examples/fuzz-parser.
- Command `formo bench` untuk baseline compile/render.
- Contract tests IR + golden fixtures + policy/migration docs.
- Parser recovery API (`parse_with_recovery`) dan multi-diagnostic parser di `diagnose` JSON/LSP.
- Desktop backend bundle webview (`index.html`, `app.css`, `app.js`, `desktop-bridge.js`, `app.ir.json`).
- Dokumen boundary `docs/LIBRARY_BOUNDARY.md` untuk mode arsitektur library-first.
- Refresh dokumentasi utama (`README`, roadmap, panduan penggunaan, release checklist) ke format library-first yang konsisten.
- Script parity gate `scripts/ci_verify_logic_parity.ps1` untuk menyamakan perilaku logika JS vs Rust dari source `.fl`.

### Changed

- Fokus rilis diarahkan ke `formo 0.2.0` dengan model library-first.
- Root `formo` tidak lagi menyimpan source crate/workspace Cargo; eksekusi melalui `formo-library-ecosystem`.
- Command CLI, CI, dan release checklist memakai `--manifest-path ../formo-library-ecosystem/Cargo.toml`.
- Wrapper command sekarang memakai `CARGO_TARGET_DIR=target/cargo-shared` agar cache/build tetap lokal repo `formo`.

## [0.1.0] - 2026-03-07

### Added

- Baseline workspace Formo (lexer/parser/resolver/typer/style/IR/backend web+desktop/CLI).
