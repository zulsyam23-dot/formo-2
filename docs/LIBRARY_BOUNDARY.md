# Library Boundary

Dokumen ini adalah kontrak arsitektur antara repository `formo` dan `formo-library-ecosystem`.

## Tujuan

- memastikan `formo` tetap fokus pada bahasa/proyek,
- memastikan compiler/runtime/tooling dikelola terpusat di library,
- mencegah duplikasi source lintas repository.

## Source of Truth

Source program Formo hanya berada di:
- `../formo-library-ecosystem/language-core/programs/*`
- `../formo-library-ecosystem/language-style/programs/*`
- `../formo-library-ecosystem/runtime-web/programs/*`
- `../formo-library-ecosystem/runtime-desktop/programs/*`
- `../formo-library-ecosystem/tooling/programs/*`

## Isi Repository `formo`

`formo` boleh berisi:
- source aplikasi bahasa: `main.fm`, `views/`, `styles/`
- extension editor lokal (syntax/icon `.fm` dan `.fs`): `.vscode/formo-local-extension/*`
- dokumen: `README.md`, `PRODUCTION_ROADMAP.md`, `CHANGELOG.md`, `docs/*`
- kontrak: `formo-ir.schema.json`, `fixtures/*`
- automasi: `.github/*`, `scripts/*`

`formo` tidak boleh berisi:
- source crate compiler/runtime/tooling,
- workspace Cargo untuk compiler/runtime/tooling,
- duplikasi source dari `formo-library-ecosystem`.

## Boundary Editor vs Library

- Highlighting warna + ikon file `.fm/.fs` dikelola lokal di repository `formo`.
- Compiler/runtime/CLI tetap hanya dari `formo-library-ecosystem`.
- Hindari menjalankan flycheck Rust ke root `formo` karena repo ini bukan Cargo workspace.

## Mekanisme Eksekusi

Semua command compiler/runtime/tooling harus memakai:

```bash
--manifest-path ../formo-library-ecosystem/Cargo.toml
```

Contoh:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- check --input main.fm
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target web --input main.fm --out dist
```

## Formo 2 Unified Mode

Mode terpadu Formo 2 di repo ini memakai:
- workspace gabungan: `formo2.code-workspace`,
- bootstrap aman: `scripts/formo2_bootstrap.ps1`,
- wrapper CLI: `scripts/formo2_cli.ps1` / `formo2.cmd`.

Prinsipnya tetap:
- source aplikasi ada di repo `formo`,
- source compiler/runtime/tooling tetap ada di repo `formo-library-ecosystem`,
- integrasi dilakukan lewat command boundary, bukan duplikasi source.

## Backend Opsional

- default: `backend-web` + `backend-desktop`
- web only:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli --no-default-features --features backend-web -- build --target web --input main.fm --out dist
```

- desktop only:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli --no-default-features --features backend-desktop -- build --target desktop --input main.fm --out dist
```

## Aturan Perubahan

Saat menambah/mengubah fitur compiler/runtime/tooling:
1. ubah source di `formo-library-ecosystem`,
2. update dokumentasi di `formo` bila berdampak ke pengguna,
3. verifikasi CI/checklist release tetap hijau.
