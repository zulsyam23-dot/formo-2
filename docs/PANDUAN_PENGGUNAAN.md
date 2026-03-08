# Panduan Penggunaan Formo

Update: 2026-03-07

Dokumen ini menjelaskan cara pakai Formo dalam model `0.2` (library-first), dari validasi source sampai build artifact.

## 1) Model Repository

- Root `formo` menyimpan source bahasa aplikasi (`.fm`, `.fs`) + dokumentasi + kontrak.
- Source compiler/runtime/tooling berada di `../formo-library-ecosystem`.
- Semua command CLI menggunakan:
  - `--manifest-path ../formo-library-ecosystem/Cargo.toml`

## 2) Prasyarat

- Rust stable terpasang.
- Cargo tersedia di PATH.
- Folder `formo` dan `formo-library-ecosystem` berada dalam parent direktori yang sama.

Verifikasi:

```bash
cargo check --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace
```

## 3) Struktur Proyek Formo

```text
.
|- main.fm
|- views/
|  |- header.fm
|- styles/
|  |- base.fs
|- fixtures/
|- docs/
```

## 4) Quick Start

1. Check:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- check --input main.fm
```

2. Diagnose:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- diagnose --input main.fm --json
```

3. Build web:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target web --input main.fm --out dist
```

4. Build desktop:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target desktop --input main.fm --out dist
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
```

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

Desktop (`--target desktop`):
- `index.html`
- `app.css`
- `app.js`
- `desktop-bridge.js`
- `app.ir.json`

Multi (`--target multi`):
- `out/web/*`
- `out/desktop/*`

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
