# Panduan Penggunaan Formo

Update: 2026-03-08

Dokumen ini menjelaskan cara pakai Formo dalam model `0.2` (library-first), dari validasi source sampai build artifact.

## 1) Model Repository

- Root `formo` menyimpan source bahasa aplikasi (`.fm`, `.fs`) + dokumentasi + kontrak.
- Source compiler/runtime/tooling berada di `formo-library-ecosystem` (auto-discover).
- Wrapper `.\formo2.cmd` otomatis mencari library pada:
  - `FORMO_LIBRARY_MANIFEST` / `FORMO_LIBRARY_ROOT` (jika diset),
  - sibling `../formo-library-ecosystem`,
  - local cache `.formo/formo-library-ecosystem` (auto-download ZIP bila belum ada).
- Cek library yang aktif dipakai wrapper:
  - `.\formo2.cmd where-library`

## 2) Prasyarat

- Rust stable terpasang.
- Cargo tersedia di PATH.
- Tidak wajib clone dua repo. Download repo `formo` saja tetap bisa dipakai.

Verifikasi:

```bash
.\formo2.cmd check --input main.fm
powershell -ExecutionPolicy Bypass -File .\scripts\formo2_doctor.ps1
```

## 3) Struktur Proyek Formo

```text
.
|- main.fm
|- views/
|  |- header.fm
|- styles/
|  |- base.fs
|- logic/
|  |- controllers/
|  |- services/
|  |- contracts/
|  |- platform/
|- fixtures/
|- docs/
```

## 4) Quick Start

1. Check:

```bash
.\formo2.cmd check --input main.fm
```

2. Diagnose:

```bash
.\formo2.cmd diagnose --input main.fm --json
```

3. Build desktop:

```bash
.\formo2.cmd build --target desktop --input main.fm --out dist --strict-parity
```

4. Build web:

```bash
.\formo2.cmd build --target web --input main.fm --out dist
```

5. Parity gate logika lintas web-desktop:

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\ci_verify_logic_parity.ps1
```

## 5) Bahasa Formo `.fm`

### 5.1 Import

```fm
import "views/header.fm" as Header;
import "styles/base.fs" as Base;
```

Aturan:
- hanya `.fm` dan `.fs`,
- alias import harus unik,
- siklus import ditolak.

### 5.2 Komponen

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

Aturan:
- setiap `component` wajib 1 root node,
- nama node diawali huruf kapital.

### 5.3 Built-in Node

- Layout: `Window`, `Page`, `Row`, `Column`, `Stack`, `Card`, `Scroll`, `Spacer`
- Konten: `Text`, `Image`
- Input: `Button`, `Input`, `Checkbox`, `Switch`, `Modal`
- Control flow: `If`, `For`, `Slot`

### 5.4 Nilai Attribute

Didukung:
- `string`, `bool`, `int`, `float`
- identifier
- list literal
- object literal

Contoh:

```fm
<Text value="Halo"/>
<Checkbox checked=true/>
<For each=[{name: "A"}, {name: "B"}] as=item>
  <Text value=item.name/>
</For>
```

## 6) Bahasa Style `.fs`

### 6.1 Token

```fs
token {
  color.accent = #0A84FF;
  radius.md = 12dp;
  text.body = 16px;
}
```

### 6.2 Style Rule

```fs
style BodyText {
  color: token(color.accent);
  font-size: token(text.body);
}
```

Catatan:
- style key divalidasi allowlist,
- duplicate style id ditolak,
- unused token akan gagal compile (`E1304`).

## 7) Command CLI

Semua command dijalankan dengan pola berikut:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- <command> [options]
```

### 7.1 check

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- check --input main.fm --json
```

### 7.2 diagnose

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- diagnose --input main.fm --lsp
```

### 7.3 lsp

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- lsp --input main.fm --watch
```

### 7.4 fmt

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- fmt --input main.fm --check
```

### 7.5 doctor

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- doctor --input main.fm --json-schema
```

### 7.6 bench

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- bench --input main.fm --iterations 12 --warmup 3 --nodes 1000 --out dist-ci/bench/benchmark.json --json-pretty --max-compile-p95-ms 120 --max-first-render-p95-ms 10
```

### 7.7 build

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target web --input main.fm --out dist
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target desktop --input main.fm --out dist
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target multi --input main.fm --out dist
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target desktop --input main.fm --out dist --strict-parity
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target web --input main.fm --out dist
```

### 7.8 logic

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- logic --input logic/controllers/app_controller.fl --json-pretty --rt-manifest-out target/parity/fl-runtime-contract.json
```

Aturan strict profile yang ditegakkan parser `.fl`:
- `event` harus lowerCamelCase,
- `logic` harus punya global action per-event,
- `service` tidak boleh punya blok platform,
- `logic/service` tidak boleh direct call `Browser`/`Desktop`,
- `adapter` hanya boleh `action call`,
- web/desktop action harus simetris per-event.
- urutan blok platform harus `desktop` lalu `web` (desktop-first baseline).
- pada unit `logic`, aksi dalam blok `platform` hanya boleh `action call`.
- pada unit `logic/adapter`, aksi global harus ditempatkan sebelum blok `platform`.
- pada unit `logic/adapter`, blok `platform` tidak boleh interleaving (desktop lalu web saja).
- kontrol logika standar tersedia di event: `if`, `for`, `while`, `match`.
- setiap blok `if/for/while/match` wajib berisi minimal satu `action`.
- kontrol error handling tersedia: `try`, `catch`, `action throw`.
- deklarasi `function`, `enum`, `struct`, `type` tersedia di level unit (`logic/service/adapter`).
- deklarasi `state` tersedia di level unit (`logic/service/adapter`) dengan field typed + initializer.
- setiap parameter `function` wajib bertipe (`param: Type`).
- field `struct` wajib bertipe (`field: Type`) dan nama field lowerCamelCase.
- field `state` wajib lowerCamelCase, wajib bertipe, dan wajib punya initializer literal.
- `action set` wajib menarget field yang sudah dideklarasikan di blok `state` dan wajib ditutup `;`.
- `action set` menolak mismatch literal dasar terhadap tipe field state (`bool/string/int/float`).
- pada expression RHS `action set`, referensi state harus berasal dari field `state` yang terdaftar dan tipe operand harus kompatibel.
- validasi tipe `action set` menggunakan inferensi expression dasar (`+ - * / %`, `== != < <= > >=`, `&& ||`).
- `action break`/`action continue` hanya boleh di dalam `for`/`while`.
- `action return` harus menjadi action terakhir di event.
- `action throw` hanya boleh di dalam `try`/`catch`.

Backend opsional:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli --no-default-features --features backend-web -- build --target web --input main.fm --out dist-web
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli --no-default-features --features backend-desktop -- build --target desktop --input main.fm --out dist-desktop
```

## 8) Output Build

Web (`--target web`):
- `index.html`
- `app.css`
- `app.js`
- `runtime/README.md`
- `runtime/app/*.js` (source runtime terpecah, mudah dibaca manusia/AI)

Desktop (`--target desktop`):
- `app.native.rs`
- `app.native.json`
- `app.ir.json`
- `native-app/*`
- `readable/README.md`
- `readable/native/*.json`
- `readable/ir/*.json`

Multi (`--target multi`):
- `web/index.html`
- `web/app.css`
- `web/app.js`
- `desktop/app.native.rs`
- `desktop/app.native.json`
- `desktop/app.ir.json`
- `desktop/native-app/*`

## 9) Diagnostik dan Error

Stage utama:
- `parser` (`E11xx`)
- `resolver` (`E12xx`)
- `style` (`E13xx`)
- `lowering` (`E14xx`)
- `typer` (`E2xxx`)
- fallback `pipeline`

Format error utama:
- `code file:line:col message`

## 10) CI Minimal

Jalankan sebelum merge:

```bash
cargo check --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace
cargo clippy --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace --all-targets -- -D warnings
cargo test --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace
```

## 11) Troubleshooting

`input file not found`
- pastikan path `--input` benar relatif terhadap direktori kerja.

`unsupported target`
- target valid hanya `web`, `desktop`, `multi`.

`strict parity failed (E7600)`
- ada parity warning lintas target. Jalankan `logic --rt-manifest-out` lalu cek unit/event yang belum parity-ready.

`unknown style ...`
- pastikan style id tersedia di file `.fs` yang di-import.

`cyclic import detected`
- putus loop import antar module `.fm`.

## 12) Referensi

- `README.md`
- `PRODUCTION_ROADMAP.md`
- `docs/LIBRARY_BOUNDARY.md`
- `docs/IR_COMPATIBILITY.md`
- `docs/IR_MIGRATIONS.md`
- `docs/RELEASE_CHECKLIST.md`
