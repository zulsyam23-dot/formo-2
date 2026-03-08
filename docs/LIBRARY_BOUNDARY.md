# Library Boundary

Update: 2026-03-08

Dokumen ini adalah kontrak arsitektur antara repository `formo` dan `formo-library-ecosystem`.

## Tujuan

- memastikan `formo` tetap fokus pada source aplikasi bahasa,
- memastikan compiler/runtime/tooling tetap terpusat di library ecosystem,
- mencegah duplikasi source lintas repository.

## Snapshot Library Saat Ini

Di `../formo-library-ecosystem`, domain yang ada saat ini:
- aktif: `language-core`, `language-style`, `runtime-web`, `runtime-desktop`, `tooling`,
- bootstrap: `ai-interop`, `knowledge-pack`.

Workspace Cargo aktif saat ini berisi crate:
- `formo-lexer`, `formo-parser`, `formo-logic`, `formo-resolver`, `formo-typer`, `formo-ir`,
- `formo-style`,
- `formo-backend-web`, `formo-backend-desktop`,
- `formo-cli`.

## Source of Truth

Source implementasi compiler/runtime/tooling hanya berada di:
- `../formo-library-ecosystem/language-core/programs/*`
- `../formo-library-ecosystem/language-style/programs/*`
- `../formo-library-ecosystem/runtime-web/programs/*`
- `../formo-library-ecosystem/runtime-desktop/programs/*`
- `../formo-library-ecosystem/tooling/programs/*`

Kontrak AI dan knowledge operasional library berada di:
- `../formo-library-ecosystem/ai-interop/*`
- `../formo-library-ecosystem/knowledge-pack/*`

## Isi Repository `formo`

`formo` boleh berisi:
- source aplikasi bahasa: `main.fm`, `views/`, `styles/`, `logic/` (`.fl`),
- extension editor lokal (`.fm`, `.fs`, `.fl`): `.vscode/formo-local-extension/*`,
- dokumen: `README.md`, `PRODUCTION_ROADMAP.md`, `CHANGELOG.md`, `docs/*`,
- kontrak aplikasi: `formo-ir.schema.json`, `fixtures/*`,
- automasi dan wrapper boundary: `.github/*`, `scripts/*`, `formo2.cmd`, `open-formo.cmd`.

`formo` tidak boleh berisi:
- source crate compiler/runtime/tooling,
- workspace Cargo compiler/runtime/tooling,
- duplikasi source dari `formo-library-ecosystem`.

## Boundary Eksekusi

Jalankan compiler/runtime/tooling dari repo `formo` dengan salah satu pola:
- wrapper aman (direkomendasikan): `.\formo2.cmd <args>`,
- command langsung Cargo:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- <args>
```

Catatan implementasi saat ini:
- bootstrap dan wrapper menetapkan `CARGO_TARGET_DIR=target/cargo-shared` agar cache build tetap lokal di repo `formo`,
- `formo` bukan Cargo workspace, jadi Rust analyzer/flycheck diarahkan ke `../formo-library-ecosystem/Cargo.toml`.

## Parity Wajib FL (Web vs Desktop)

Gate parity resmi saat ini:

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\ci_verify_logic_parity.ps1
```

Script ini menjalankan:
- `formo logic --rt-manifest-out target/parity/fl-runtime-contract.json`,
- build desktop dengan `--strict-parity` sebagai baseline,
- build web mengikuti baseline desktop,
- output laporan `target/parity/parity-report.json`.

## Formo 2 Unified Mode

Mode terpadu Formo 2 di repo ini memakai:
- workspace gabungan: `formo2.code-workspace`,
- bootstrap aman: `scripts/formo2_bootstrap.ps1`,
- wrapper CLI: `scripts/formo2_cli.ps1` / `formo2.cmd`.

Prinsip tetap:
- source aplikasi ada di repo `formo`,
- source compiler/runtime/tooling tetap di repo `formo-library-ecosystem`,
- integrasi dilakukan lewat command boundary, bukan copy source.

## Backend Opsional

- default feature `formo-cli`: `backend-web` + `backend-desktop`,
- web only:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli --no-default-features --features backend-web -- build --target web --input main.fm --out dist
```

- desktop only:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli --no-default-features --features backend-desktop -- build --target desktop --input main.fm --out dist
```

## Aturan Perubahan

Saat menambah atau mengubah fitur compiler/runtime/tooling:
1. ubah source di `formo-library-ecosystem`,
2. update dokumentasi di `formo` jika ada dampak pengguna,
3. verifikasi command boundary, parity gate, dan checklist release tetap hijau.
