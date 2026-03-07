# Formo Production Roadmap

Dokumen ini adalah checklist teknis untuk naik dari prototype ke level pengembangan aplikasi/web profesional.

## Snapshot Progress (Update 2026-03-07)

- Compiler pipeline dasar: aktif.
- CLI (`check`, `diagnose`, `fmt`, `doctor`, `build`) + output JSON/watch: aktif.
- Payload error JSON sudah punya metadata terstruktur (`stage` + `errorMeta`) untuk fondasi integrasi editor.
- Baseline output LSP-like tersedia via `diagnose --lsp` (`documents[].diagnostics[]`).
- Adapter Language Server ringan tersedia via `formo lsp` (publish `textDocument/publishDiagnostics`).
- Resolver sekarang menolak alias import duplikat dan menampilkan siklus import dengan path ringkas.
- Negative test coverage parser+typer sudah lewat 30 skenario error.
- Parser/resolver/typer error utama sudah distandardkan ke format `code file:line:col message`.
- Style/lowering error utama juga sudah distandardkan ke format code file:line:col message.
- Typer sudah punya integration test lintas file (.fm + .fs) untuk validasi kontrak antar module.
- Registry terpusat untuk error code typer sudah tersedia dan bisa di-query.
- Kontrak typer untuk path `field/index` pada `list/object` sudah distabilkan dengan test tambahan.
- Kontrak JSON `stage + errorMeta.code` untuk error style (`E13xx`) dan lowering (`E14xx`) sudah tercakup integration test CLI.
- Refactor `formo-cli` ke modul kecil: selesai.
- Style engine sekarang memvalidasi property CSS via allowlist dan punya snapshot test output deterministik.
- Style engine mendukung fallback token/theme (`token(a, fallback)`) dan deteksi token tidak terpakai.
- Runtime web sudah punya minimal keyed update untuk `For` berbasis state list (mengurangi full re-render pada kasus aman).
- Runtime web kini punya error boundary action/event dan baseline accessibility modal (`aria-*`, `Esc`, focus trap).
- Build web sekarang mendukung mode production (`build --prod`) dengan minify `app.js` + `app.css`.
- Desktop backend sekarang menghasilkan bundle webview (`index.html`, `app.js`, `app.css`) + `desktop-bridge.js` + `app.ir.json`.
- CI pipeline kini dipisah jadi `lint` + `test` (Linux/Windows) + `smoke build` web/desktop + upload artifact.
- Baseline benchmark pipeline tersedia via `formo bench` + artifact CI (`benchmark.json`) untuk compile-time dan simulasi first-render web.
- `formo bench` kini mendukung perf budget gate (`--max-compile-p95-ms`, `--max-first-render-p95-ms`) dan dipakai di CI untuk target 1k node.
- Job CI `readme-examples` kini menjalankan command contoh README non-`--watch` dan verifikasi artifact output.
- Guard `no-panic` untuk input invalid sudah ditambah via integration test CLI lintas command (`check/diagnose/doctor/build/bench`).
- Kontrak IR kini dikunci via konstanta crate (`IR_VERSION`, `IR_SCHEMA_ID`), migration notes, dan golden contract tests.
- Lexer kini mendukung komentar (`//`, `/*...*/`), escape string, dan diagnostic lokasi presisi (`E1000`-`E1004`).
- Model `formo-ir` kini dipisah ke modul publik (`public`) dan internal (`internal`) untuk pondasi scaling.
- Parser fuzzing (`cargo-fuzz`) kini tersedia dengan target `parser_parse` + CI smoke (Ubuntu nightly).
- Parser kini punya mode recovery (`parse_with_recovery`) untuk lanjut scan top-level item setelah syntax error awal.
- `diagnose` kini memakai recovery parser untuk mode parser-failure agar multi syntax error bisa dikirim sebagai diagnostics JSON/LSP.
- Release flow kini punya checklist eksplisit (`docs/RELEASE_CHECKLIST.md`) + `CHANGELOG.md` + CI `release-readiness`.
- Runtime web: usable untuk prototype.
- Runtime desktop: mulai usable via webview bundle (native renderer final masih pending).

## Target Tahap

- `Alpha Stabil`: compiler+runtime konsisten, cukup untuk proyek internal.
- `Beta Publik`: siap dipakai tim eksternal dengan dokumentasi dan tooling jelas.
- `Release 1.0`: stabilitas API bahasa/IR dijaga, ada jaminan kompatibilitas.

## Gate Kualitas (Wajib Hijau)

- [x] `cargo check` dan semua test pass di CI (Linux + Windows).
- [x] Semua contoh di `README.md` bisa dibuild otomatis di CI.
- [x] Tidak ada panic pada input invalid (harus jadi diagnostic error).
- [x] Ada benchmark minimal untuk compile time dan runtime render.

## Checklist per Module

### 1) Frontend Compiler (Lexer/Parser/Resolver/Typer)

- [x] `crates/formo-lexer/src/lib.rs`
  - [x] tokenisasi robust (komentar, escape, error lokasi presisi).
- [x] `crates/formo-parser/src/lib.rs`
  - [x] parser recovery (lanjut parse walau ada syntax error).
  - [x] parser fuzz test (`cargo-fuzz`) untuk hardening.
- [x] `crates/formo-resolver/src/lib.rs`
  - [x] import alias tervalidasi ketat (reject duplicate alias dalam satu module).
  - [x] diagnostic siklus import lebih informatif (path ringkas).
- [x] `crates/formo-typer/src/*`
  - [x] stabilkan contract type untuk `list/object` dan field/index path.
  - [x] tambah integration tests lintas file (`.fm` + `.fs`), bukan hanya unit.
  - [x] pisahkan error codes jadi registry terpusat.

Definition of done:
- [x] Minimal 30 skenario error (negative tests) parser + typer.
- [x] Format error konsisten: `code file:line:col message`.

### 2) Style Engine

- [x] `crates/formo-style/src/lib.rs`
  - [x] validasi property CSS yang diizinkan.
  - [x] fallback token/theme dan deteksi token tak terpakai.
  - [x] snapshot test output style untuk cegah regression.

Definition of done:
- [x] Style compile deterministik (output stabil untuk input sama).

### 3) IR Contract

- [x] `formo-ir.schema.json`
  - [x] lock versi schema + changelog migrasi.
  - [x] validasi terhadap contoh IR golden files.
- [x] `crates/formo-ir/src/lib.rs`
  - [x] pisahkan model IR publik vs internal jika perlu.

Definition of done:
- [x] Compatibility policy: minor backward-compatible, major breaking.

### 4) CLI & Developer Experience

- [x] `crates/formo-cli` telah dipisah ke modul (`args`, `pipeline`, `output`, `json_output`, `diagnose`, `lowering/*`).
- [x] subcommand `diagnose`.
- [x] subcommand `fmt`.
- [x] subcommand `doctor`.
- [x] opsi `--watch` untuk dev loop.
- [x] output JSON (`--json`) untuk integrasi editor/tooling.
- [x] diagnostic berwarna pada output terminal.

Definition of done:
- [x] Bisa dipakai sebagai backend Language Server ringan.

### 5) Web Runtime

- [ ] `crates/formo-backend-web/src/lib.rs`
  - [x] kurangi full re-render (minimal keyed update untuk list).
  - [x] event system lebih aman dan konsisten (error boundary action).
  - [x] accessibility baseline (`aria-*`, keyboard modal, focus trap).
  - [x] mode production bundle (minified JS/CSS).
  - [x] perf budget CI untuk benchmark 1k node (p95 compile/render).

Definition of done:
- [ ] Demo app kompleks tetap responsif dengan 1k node render.

### 6) Desktop Runtime

- [ ] `crates/formo-backend-desktop/src/lib.rs`
  - [x] implement renderer desktop nyata (bukan hanya dump IR JSON).
  - [x] adapter event/state parity dengan web runtime.
  - [ ] packaging executable lintas OS (minimal Windows + Linux).

Definition of done:
- [ ] 1 source `.fm` menghasilkan web+desktop dengan behavior interaktif setara.

### 7) QA, CI, Release

- [x] Tambah pipeline CI:
  - [x] lint + test + build artifacts.
  - [x] smoke test sample app.
- [x] Tambah benchmark pipeline:
  - [x] compile time.
  - [x] web runtime first render.
- [x] Tambah release checklist:
  - [x] semver tag.
  - [x] changelog.
  - [x] migration notes.

## Urutan Eksekusi Rekomendasi (Pragmatis)

1. Stabilkan compiler diagnostics + test coverage.
2. Matangkan runtime web (perf + accessibility).
3. Bangun desktop renderer real.
4. Kunci IR/API compatibility policy.
5. Lengkapi tooling CLI + CI release flow.

## Fokus Berikutnya (2-3 Sprint)

1. Tambah negative tests parser/typer + standardisasi format diagnostic.
2. Tingkatkan runtime web agar tidak full re-render untuk list besar.
3. Definisikan policy versi schema IR dan siapkan golden test.
4. Integrasikan `formo lsp` ke plugin/editor target (VS Code/Neovim) sebagai layer diagnostics awal.

## Status Saat Ini (Ringkas)

- Compiler pipeline: `jalan`.
- Runtime web: `cukup untuk prototype`.
- Runtime desktop: `mulai usable via webview bundle` (packaging executable lintas OS masih pending).
- Tooling profesional (CI, benchmark, LSP, fuzz parser, release checklist): `cukup matang`.

