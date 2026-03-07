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

## [0.1.0] - 2026-03-07

### Added

- Baseline workspace Formo (lexer/parser/resolver/typer/style/IR/backend web+desktop/CLI).
