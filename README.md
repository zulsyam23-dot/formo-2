# Formo Starter Workspace

Starter implementasi awal bahasa Formo (draft v0.3) untuk target web + desktop.

Roadmap menuju level profesional ada di `PRODUCTION_ROADMAP.md`.
Panduan penggunaan lengkap ada di `docs/PANDUAN_PENGGUNAAN.md`.

## Status Singkat (Update 2026-03-07)

- Pipeline compiler end-to-end sudah jalan: parse -> resolve -> type -> style -> IR -> backend.
- `formo-cli` sudah dipecah jadi modul kecil agar mudah dirawat.
- Build web sudah menghasilkan `index.html`, `app.css`, `app.js`.
- Build desktop sekarang menghasilkan bundle webview (`index.html`, `app.css`, `app.js`) + `desktop-bridge.js` + `app.ir.json` (native renderer final masih tahap berikutnya).

## CI Otomatis

Workflow: `.github/workflows/ci.yml`

- `lint` (Ubuntu): `cargo check --workspace` + `cargo clippy --workspace --all-targets -- -D warnings`.
- `test` (Linux + Windows): `cargo test --workspace`.
  - termasuk guard test untuk memastikan input invalid tidak memicu panic Rust.
- `fuzz-parser` (Ubuntu):
  - `cargo +nightly fuzz run parser_parse -- -max_total_time=20`
  - target hardening parser terhadap input acak.
- `smoke` (Linux + Windows):
  - `formo check` + `formo diagnose --json-schema`
  - `formo build` web (`--prod`) dan desktop
  - verifikasi artifact output (`index.html`, `app.css`, `app.js`, `desktop-bridge.js`, `app.ir.json`)
  - upload artifact `dist-ci` (runner Ubuntu).
- `benchmark` (Ubuntu):
  - `formo bench` untuk baseline compile-time + simulasi web first-render 1k item
  - output JSON artifact: `dist-ci/bench/benchmark.json`
- `readme-examples` (Ubuntu):
  - menjalankan command contoh README yang non-`--watch`
  - verifikasi output build (`web`, `desktop`, `multi`) + benchmark report
- `release-readiness` (Ubuntu):
  - validasi dokumen release (`CHANGELOG`, `RELEASE_CHECKLIST`, migration docs)
  - validasi format tag release opsional via env `RELEASE_TAG` (`vX.Y.Z`)

## Struktur Workspace

- `formo-ir.schema.json`: kontrak schema IR JSON.
- `docs/IR_COMPATIBILITY.md` + `docs/IR_MIGRATIONS.md`: policy kompatibilitas dan catatan migrasi kontrak IR.
- `docs/RELEASE_CHECKLIST.md` + `CHANGELOG.md`: checklist release dan catatan perubahan versi.
- `crates/formo-lexer`: lexer robust (komentar, escape string, diagnostic posisi presisi).
- `crates/formo-parser`: parser `.fm` ke AST.
- `crates/formo-resolver`: resolver import `.fm`/`.fs`, deteksi siklus, validasi origin komponen.
- `crates/formo-typer`: validasi struktur komponen, prop built-in/custom, dan semantic typing dasar.
- `crates/formo-style`: compiler style `.fs` ke `styles` + `tokens` IR.
- `crates/formo-ir`: model IR publik + model internal + trait backend.
- `crates/formo-backend-web`: emitter `index.html`, `app.css`, `app.js` + runtime DOM.
- `crates/formo-backend-desktop`: emitter bundle desktop webview + bridge host + `app.ir.json`.
- `crates/formo-cli`: command line utama (`check`, `diagnose`, `lsp`, `fmt`, `doctor`, `bench`, `build`).

## Struktur `formo-cli` (Refactor)

- `src/main.rs`: command dispatcher.
- `src/args.rs`: parsing argumen CLI.
- `src/diagnose.rs`: command `diagnose` (mode text/JSON).
- `src/lsp_bridge.rs`: adapter ringan untuk publish diagnostics model LSP.
- `src/fmt_cmd.rs`: formatter `.fm` (write/check/stdout).
- `src/json_output.rs`: helper output JSON + schema metadata.
- `src/lsp_output.rs`: builder payload diagnostic mode LSP (`diagnose --lsp`).
- `src/doctor.rs`: health-check proyek (preflight file + pipeline compile).
- `src/output.rs`: emitter ke target `web|desktop|multi`.
- `src/pipeline.rs`: pipeline compile terpadu.
- `src/error.rs`: tipe error CLI.
- `src/term.rs`: helper output terminal berwarna (auto-detect TTY / `NO_COLOR`).
- `src/watch.rs`: watch loop polling perubahan file `.fm`/`.fs`.
- `src/lowering/`:
  - `mod.rs`: entry lowering ke IR.
  - `node.rs`: lowering node umum.
  - `component.rs`: ekspansi custom component call.
  - `slot.rs`: lowering `<Slot/>` ke `Fragment`.
  - `attrs.rs`: lowering attribute + validasi style refs.
  - `style.rs`: parsing style refs + auto style map.
  - `values.rs`: resolver nilai + konversi ke value IR.

## Sintaks yang Sudah Didukung

- Import:
  - `import "path/file.fm" as Alias;`
  - `import "styles/base.fs" as Base;`
- Komponen:
  - `component Name(title: string, subtitle?: string) { ... }`
- Node XML-like:
  - `<Page> ... </Page>`
  - `<Text value="..."/>`
  - `<Header title="..."/>` (custom component call)
  - `<Header ...> ... </Header>` + `<Slot/>` pada komponen target
  - `<If when=showModal> ... </If>`
  - `<For each=["A","B"] as=item> ... </For>`
- Path data:
  - field access: `item.name`, `item.profile.title`
  - array index path: `item.tags.0`, `item.matrix.1.2`
- Nilai attribute:
  - string, bool, int, float
  - identifier
  - list literal: `["A", "B", 1, true]`
  - object literal: `{name: "A", active: true}`
- Attribute style:
  - `style=Heading`
  - `style="Heading,BodyText"`
- File style `.fs`:
  - `token { key = value; }`
  - `token(name)` untuk referensi token
  - `token(name, fallback)` untuk fallback token/theme
  - `style Name { key: value; }`
  - `style Name:part { key: value; }`
  - auto-apply selector root: `style Button { ... }` otomatis ke `<Button/>`
  - key declaration hanya menerima CSS property yang masuk allowlist Formo (plus custom property `--*`)

## Validasi Aktif

- Setiap `component` wajib punya tepat 1 root node.
- Nama node wajib diawali huruf kapital.
- Node harus built-in atau komponen yang terdaftar.
- Validasi prop komponen custom:
  - required prop
  - unknown prop
  - mismatch tipe dasar
- Built-in contract aktif untuk:
  - `Window`, `Page`, `Row`, `Column`, `Stack`, `Card`
  - `Text`, `Image`, `Button`, `Input`, `Checkbox`, `Switch`
  - `Scroll`, `Spacer`, `Modal`, `If`, `For`, `Slot`
- Semantic state/action dasar:
  - `Input.value` -> `state<string>`
  - `Input.onChange` -> `action<string>`
  - `Checkbox.checked`, `Switch.checked`, `Modal.open` -> `state<bool>`
  - `Button.onPress`, `Modal.onClose` -> `action<void>`
- Scope `For`:
  - alias `as=item` valid di child node
  - `itemIndex` tersedia otomatis (tipe `int`)
  - akses field/index ikut tervalidasi
- Import hanya menerima ekstensi `.fm` dan `.fs`.
- Alias import duplikat dalam satu file `.fm` akan ditolak oleh resolver.

## Menjalankan

```bash
cargo check
cargo run -p formo-cli -- help
cargo run -p formo-cli -- check main.fm
cargo run -p formo-cli -- check --input main.fm --json
cargo run -p formo-cli -- check --input main.fm --json-pretty
cargo run -p formo-cli -- check --input main.fm --json-schema
cargo run -p formo-cli -- check --input main.fm --watch
cargo run -p formo-cli -- diagnose --input main.fm --json
cargo run -p formo-cli -- diagnose --input main.fm --json-schema
cargo run -p formo-cli -- diagnose --input main.fm --lsp
cargo run -p formo-cli -- diagnose --input main.fm --watch
cargo run -p formo-cli -- lsp --input main.fm
cargo run -p formo-cli -- lsp --input main.fm --watch
cargo run -p formo-cli -- fmt --input main.fm
cargo run -p formo-cli -- fmt --input main.fm --check
cargo run -p formo-cli -- fmt --input main.fm --stdout
cargo run -p formo-cli -- doctor --input main.fm --json
cargo run -p formo-cli -- doctor --input main.fm --json-schema
cargo run -p formo-cli -- bench --input main.fm --iterations 12 --warmup 3 --nodes 1000 --out dist-ci/bench/benchmark.json --json-pretty
cargo run -p formo-cli -- bench --input main.fm --iterations 12 --warmup 3 --nodes 1000 --out dist-ci/bench/benchmark.json --json-pretty --max-compile-p95-ms 120 --max-first-render-p95-ms 10
cargo +nightly fuzz run parser_parse --manifest-path crates/formo-parser/fuzz/Cargo.toml -- -max_total_time=20
cargo run -p formo-cli -- build --target web --input main.fm --out dist
cargo run -p formo-cli -- build --target desktop --input main.fm --out dist
cargo run -p formo-cli -- build --target multi --input main.fm --out dist
cargo run -p formo-cli -- build --target web --input main.fm --out dist --watch
cargo run -p formo-cli -- build --target web --input main.fm --out dist --prod
```

## Catatan Implementasi

- `formo-lexer` menyediakan:
  - `lex(...)` untuk kompatibilitas lama (token-only)
  - `lex_with_diagnostics(...)` untuk token + diagnostic lexer (`E1000`-`E1004`)
  - komentar `//`, `/*...*/`, escape string (`\n`, `\t`, `\r`, `\\`, `\"`)
- Parser belum mendukung text bebas di antara tag. Gunakan `<Text value="..."/>`.
- `formo-parser` menyediakan `parse_with_recovery(...)` untuk mode best-effort parse + kumpulan diagnostic parser.
- Lowering IR mendukung ekspansi custom component dari entry `App`.
- Lowering `<Slot/>` memasukkan children call-site sebagai node `Fragment`.
- `style=<Ref>` tervalidasi terhadap style registry; typo style gagal saat compile.
- Duplicate `style id` lintas file `.fs` ditolak saat compile.
- Token `.fs` dilower ke `tokens` IR dan dipakai via `token(name)`.
- Token `.fs` yang tidak pernah dipakai di style akan gagal compile (`E1304`).
- Style compiler sudah punya snapshot test untuk menjaga output tetap deterministik.
- Unit `dp` dikonversi ke `px` pada output web.
- Runtime web:
  - state global: `window.formoState`
  - action handler: `window.formoActions`
  - runtime error boundary: `window.formoRuntimeErrors` + hook opsional `window.formoOnError(details)`
  - komponen interaktif (`Input`, `Checkbox`, `Switch`, `Modal`, `Button`) sudah dispatch action
  - update list pada `For each=<stateKey>` sekarang memakai keyed patch minimal (tanpa full re-render) saat key tersebut hanya dipakai sebagai sumber `For`
  - `Modal` sekarang punya baseline aksesibilitas: `role="dialog"`, `aria-modal`, close via `Esc`, dan trap fokus `Tab`
  - control-flow runtime:
    - `If` render child saat `when = true`
    - `For` render berulang dari `each` + alias `as`
    - field/index path dibaca dari scope runtime
- Runtime desktop:
  - output berisi `index.html`, `app.css`, `app.js`, `desktop-bridge.js`, `app.ir.json`
  - bridge host: `window.formoDesktopHost.invokeAction(...)` untuk adapter action ke host desktop
  - helper state bridge: `window.formoDesktop.setStatePatch(...)` dan `window.formoDesktop.replaceState(...)`
- CLI non-JSON sekarang punya diagnostic berwarna otomatis saat output ke terminal.
- `--watch` tersedia untuk `check`, `diagnose`, dan `build` (polling file `.fm`/`.fs`).
- `build --prod` minify asset web (`app.js` + `app.css`) untuk output production.
- `bench` menghasilkan baseline metrik:
  - `compileMs`: waktu compile pipeline dari fixture benchmark
  - `firstRenderMs`: simulasi biaya first-render traversal IR web
  - optional perf budget gate:
    - `--max-compile-p95-ms`
    - `--max-first-render-p95-ms`
    - jika budget gagal, file report tetap ditulis dengan `ok: false` lalu command exit non-zero
- JSON error untuk `check`/`diagnose`/`doctor` sekarang menyertakan:
  - `stage` (parser/resolver/style/lowering/typer/pipeline)
  - `errorMeta` terstruktur (`code`, `file`, `line`, `col`, `message`) bila tersedia
- `diagnose --lsp` menghasilkan payload `documents[].diagnostics[]` dengan format range/severity/code/message/source yang kompatibel untuk integrasi editor ringan.
- Untuk error parser, `diagnose` memakai mode recovery sehingga beberapa syntax error bisa muncul sekaligus di payload `diagnostics`/`documents[].diagnostics`.
- `lsp` command menghasilkan notifikasi JSON-RPC `textDocument/publishDiagnostics` per dokumen, cocok sebagai adapter ringan untuk plugin/editor.
- Diagnostic resolver untuk import cycle sekarang lebih ringkas (contoh `a.fm -> b.fm -> a.fm`).
- Error parser/resolver/style/lowering/typer utama sudah mengikuti format `code file:line:col message`.
- Kontrak IR dikunci lewat:
  - `formo_ir::IR_VERSION` + `formo_ir::IR_SCHEMA_ID`
  - golden fixtures `fixtures/ir/*.ir.json`
  - contract tests `crates/formo-ir/tests/contract.rs`
  - pemisahan model `formo_ir::public` dan `formo_ir::internal` (tetap re-export API utama di `formo_ir::*`)
- Parser fuzzing:
  - harness: `crates/formo-parser/fuzz/fuzz_targets/parser_parse.rs`
  - seed corpus: `crates/formo-parser/fuzz/corpus/parser_parse/`
  - catatan: run lokal di Windows bisa butuh runtime sanitizer tambahan; referensi utama tetap job CI Ubuntu.
