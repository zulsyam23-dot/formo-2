# Panduan Penggunaan Formo (Lengkap)

Update: 2026-03-07

Dokumen ini fokus ke cara pakai Formo dari nol sampai siap dipakai di workflow tim.
Roadmap produksi ada di `PRODUCTION_ROADMAP.md`.

## 1) Gambaran Singkat

Formo adalah bahasa deklaratif untuk UI lintas target:

- Web: output `index.html`, `app.css`, `app.js`
- Desktop (saat ini): output bundle webview + `desktop-bridge.js` + `app.ir.json`

Pipeline compile:

`lexer -> parser -> resolver -> typer -> style -> lowering IR -> backend`

## 2) Prasyarat

- Rust toolchain stable
- Cargo tersedia di PATH
- Workspace Formo terbuka di root project

Verifikasi cepat:

```bash
cargo check --workspace
```

## 3) Quick Start (5 Menit)

1. Validasi source:

```bash
cargo run -p formo-cli -- check --input main.fm
```

2. Lihat diagnostik detail:

```bash
cargo run -p formo-cli -- diagnose --input main.fm
```

3. Build target web:

```bash
cargo run -p formo-cli -- build --target web --input main.fm --out dist
```

4. Build target desktop bundle:

```bash
cargo run -p formo-cli -- build --target desktop --input main.fm --out dist
```

5. Build multi-target:

```bash
cargo run -p formo-cli -- build --target multi --input main.fm --out dist
```

## 4) Struktur Proyek yang Disarankan

```text
.
|- main.fm
|- views/
|  |- header.fm
|- styles/
|  |- base.fs
|- dist/                 # output build
|- crates/               # source compiler/runtime
|- docs/
|  |- PANDUAN_PENGGUNAAN.md
```

Contoh import lintas file:

```fm
import "views/header.fm" as Header;
import "styles/base.fs" as Base;
```

## 5) Bahasa Formo `.fm`

## 5.1 Import

Hanya ekstensi `.fm` dan `.fs` yang diterima:

```fm
import "views/header.fm" as Header;
import "styles/base.fs" as Base;
```

Catatan:

- Alias import dalam satu file harus unik.
- Resolver akan menolak siklus import.

## 5.2 Deklarasi Komponen

```fm
component Header(title: string, subtitle?: string) {
  <Column>
    <Text value=title/>
    <If when=subtitle>
      <Text value=subtitle/>
    </If>
  </Column>
}
```

Aturan utama:

- Tiap `component` wajib tepat 1 root node.
- Nama node wajib diawali huruf kapital.

## 5.3 Built-in Node (ringkas)

- Layout: `Window`, `Page`, `Row`, `Column`, `Stack`, `Card`, `Scroll`, `Spacer`
- Konten: `Text`, `Image`
- Input/interaksi: `Button`, `Input`, `Checkbox`, `Switch`, `Modal`
- Kontrol alur: `If`, `For`, `Slot`

## 5.4 Control Flow

`If`:

```fm
<If when=showModal>
  <Text value="Modal aktif"/>
</If>
```

`For`:

```fm
<For each=[{name: "A"}, {name: "B"}] as=item>
  <Text value=item.name/>
</For>
```

`Slot` untuk konten dari call-site:

```fm
component Frame(title: string) {
  <Column>
    <Text value=title/>
    <Slot/>
  </Column>
}
```

## 5.5 Nilai Attribute

Didukung:

- `string`, `bool`, `int`, `float`
- identifier
- list literal
- object literal

Contoh:

```fm
<Text value="Halo"/>
<Checkbox checked=true/>
<Text value=item.tags.0/>
<For each=[1, 2, 3] as=item>
  <Text value=item/>
</For>
```

## 5.6 Path Access

- Field: `item.profile.title`
- Index array: `item.tags.0`, `item.matrix.1.2`

## 5.7 Komponen Kustom + Slot

Pemanggilan:

```fm
<Header title="Halo">
  <Text value="Isi slot"/>
</Header>
```

Komponen target:

```fm
component Header(title: string) {
  <Column>
    <Text value=title/>
    <Slot/>
  </Column>
}
```

## 6) Bahasa Style `.fs`

## 6.1 Token

```fs
token {
  color.accent = #0A84FF;
  radius.md = 12dp;
  text.body = 16px;
}
```

Referensi token:

- `token(color.accent)`
- `token(color.accent, #3366ff)` (fallback)

## 6.2 Style Rule

```fs
style BodyText {
  color: token(color.accent);
  font-size: token(text.body);
}
```

Dengan part:

```fs
style Modal:panel {
  padding: 16dp;
}
```

Catatan:

- Property divalidasi lewat allowlist CSS Formo.
- Custom property `--*` diperbolehkan.
- Duplicate `style id` lintas file ditolak.
- Token yang tidak pernah dipakai akan gagal compile (`E1304`).

## 7) Referensi Command CLI

Binary utama:

```bash
cargo run -p formo-cli -- <command> [options]
```

## 7.1 `check`

Validasi pipeline compile.

Sintaks:

```bash
formo check [input|--input file] [--json] [--json-pretty] [--json-schema] [--watch]
```

Default:

- input: `main.fm`

Contoh:

```bash
cargo run -p formo-cli -- check main.fm
cargo run -p formo-cli -- check --input main.fm --json
cargo run -p formo-cli -- check --input main.fm --watch
```

## 7.2 `diagnose`

Diagnostik detail + statistik IR; mendukung format JSON/LSP-like.

Sintaks:

```bash
formo diagnose [input|--input file] [--json] [--json-pretty] [--json-schema] [--lsp] [--watch]
```

Catatan:

- Mode ini memanfaatkan parser recovery (`parse_with_recovery`) untuk mengirim beberapa syntax error sekaligus.
- `--lsp` mengubah payload menjadi `documents[].diagnostics[]`.

Contoh:

```bash
cargo run -p formo-cli -- diagnose --input main.fm
cargo run -p formo-cli -- diagnose --input main.fm --json
cargo run -p formo-cli -- diagnose --input main.fm --lsp
```

## 7.3 `lsp`

Adapter ringan JSON-RPC `textDocument/publishDiagnostics`.

Sintaks:

```bash
formo lsp [input|--input file] [--watch]
```

Contoh:

```bash
cargo run -p formo-cli -- lsp --input main.fm
cargo run -p formo-cli -- lsp --input main.fm --watch
```

## 7.4 `fmt`

Formatter source `.fm`.

Sintaks:

```bash
formo fmt [input|--input file] [--check] [--stdout]
```

Contoh:

```bash
cargo run -p formo-cli -- fmt --input main.fm
cargo run -p formo-cli -- fmt --input main.fm --check
cargo run -p formo-cli -- fmt --input main.fm --stdout
```

## 7.5 `doctor`

Health-check environment dan pipeline.

Sintaks:

```bash
formo doctor [input|--input file] [--json] [--json-pretty] [--json-schema]
```

Contoh:

```bash
cargo run -p formo-cli -- doctor --input main.fm
cargo run -p formo-cli -- doctor --input main.fm --json-schema
```

## 7.6 `bench`

Benchmark compile-time + simulasi first-render.

Sintaks:

```bash
formo bench [--input file] [--iterations N] [--warmup N] [--nodes N] [--out file] [--json-pretty] [--max-compile-p95-ms N] [--max-first-render-p95-ms N]
```

Default:

- `input=main.fm`
- `iterations=20`
- `warmup=3`
- `nodes=1000`
- `out=dist-ci/bench/benchmark.json`

Contoh baseline:

```bash
cargo run -p formo-cli -- bench --input main.fm --iterations 12 --warmup 3 --nodes 1000 --out dist-ci/bench/benchmark.json --json-pretty
```

Contoh dengan budget gate:

```bash
cargo run -p formo-cli -- bench --input main.fm --iterations 12 --warmup 3 --nodes 1000 --out dist-ci/bench/benchmark.json --json-pretty --max-compile-p95-ms 120 --max-first-render-p95-ms 10
```

Perilaku budget:

- Jika lewat budget: `ok: true`, exit code `0`
- Jika melampaui budget: report tetap ditulis (`ok: false`), exit code non-zero

## 7.7 `build`

Generate output final target.

Sintaks:

```bash
formo build [--target web|desktop|multi] [--input file] [--out dir] [--watch] [--prod]
```

Default:

- `target=web`
- `input=main.fm`
- `out=dist`

Contoh:

```bash
cargo run -p formo-cli -- build --target web --input main.fm --out dist
cargo run -p formo-cli -- build --target desktop --input main.fm --out dist
cargo run -p formo-cli -- build --target multi --input main.fm --out dist
cargo run -p formo-cli -- build --target web --input main.fm --out dist --watch
cargo run -p formo-cli -- build --target web --input main.fm --out dist --prod
```

Catatan `--prod`:

- Minify `app.js` + `app.css` untuk target web.
- Pada target `multi`, minify hanya untuk subfolder `web`.
- Target desktop saat ini tidak memakai minify production flag.

## 8) Mode Watch

`--watch` tersedia di:

- `check`
- `diagnose`
- `build`
- `lsp`

Perilaku:

- polling setiap ~400ms
- memantau perubahan file `.fm`/`.fs`
- direktori yang di-skip: `.git`, `target`, `dist`, `dist2`, `node_modules`, `.idea`, `.vscode`

## 9) Output Build per Target

## 9.1 Web (`--target web`)

Output:

- `index.html`
- `app.css`
- `app.js`

## 9.2 Desktop (`--target desktop`)

Output:

- `index.html`
- `app.css`
- `app.js`
- `desktop-bridge.js`
- `app.ir.json`

## 9.3 Multi (`--target multi`)

Output:

- `out/web/*` (bundle web)
- `out/desktop/*` (bundle desktop)

## 10) JSON Output dan Schema

Schema id:

- check: `https://formo.dev/schema/check-result/1`
- diagnose: `https://formo.dev/schema/diagnose-result/1`
- doctor: `https://formo.dev/schema/doctor-result/1`

Aktifkan metadata schema:

```bash
cargo run -p formo-cli -- check --input main.fm --json-schema
```

## 11) Error Stage dan Kode

Klasifikasi stage utama:

- `parser` (`E11xx`)
- `resolver` (`E12xx`)
- `style` (`E13xx`)
- `lowering` (`E14xx`)
- `typer` (`E2xxx`)
- fallback: `pipeline`

Format error utama:

`code file:line:col message`

## 12) Integrasi LSP Ringan

Perintah:

```bash
cargo run -p formo-cli -- lsp --input main.fm --watch
```

Output STDOUT berupa satu baris JSON-RPC per dokumen:

- `jsonrpc: "2.0"`
- `method: "textDocument/publishDiagnostics"`
- `params: { uri, diagnostics[] }`

Ini bisa dibaca plugin editor custom sebagai adapter diagnostik awal.

## 13) Integrasi Host Desktop (Bridge)

Desktop bundle menyediakan `desktop-bridge.js` yang mengekspos:

- `window.formoDesktopHost.invokeAction(...)` (diisi host aplikasi desktop)
- `window.formoDesktop.setStatePatch(...)`
- `window.formoDesktop.replaceState(...)`

Contoh kontrak minimal host:

```js
window.formoDesktopHost = {
  invokeAction(evt) {
    // evt.name, evt.payload, evt.nodeId, evt.nodeName, evt.scope, evt.state
  }
};
```

## 14) CI Workflow yang Disarankan

Urutan praktis:

1. `cargo check --workspace`
2. `cargo clippy --workspace --all-targets -- -D warnings`
3. `cargo test --workspace`
4. smoke build web/desktop
5. `bench` + budget threshold

Repository ini sudah punya baseline workflow di `.github/workflows/ci.yml`.

## 15) Troubleshooting Cepat

`input file not found`

- Pastikan path `--input` benar dari current directory.

`unsupported target`

- Gunakan hanya `web`, `desktop`, atau `multi`.

`unknown style ...`

- Pastikan style id ada di file `.fs` yang di-import.

`cyclic import detected`

- Putus loop import antar file `.fm`.

`unterminated ...` / syntax error parser

- Gunakan `diagnose --json` atau `diagnose --lsp` untuk lokasi error lebih detail.

## 16) Batasan Saat Ini

- Parser belum mendukung text bebas di antara tag; gunakan `<Text value="..."/>`.
- Desktop masih berupa bundle webview (packaging executable lintas OS masih tahap roadmap).
- Benchmark first-render saat ini berbasis simulasi traversal IR, bukan browser perf test penuh.

## 17) Referensi Dokumen Terkait

- `README.md`
- `PRODUCTION_ROADMAP.md`
- `docs/IR_COMPATIBILITY.md`
- `docs/IR_MIGRATIONS.md`
- `docs/RELEASE_CHECKLIST.md`
