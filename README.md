# Formo

Formo adalah bahasa deklaratif untuk UI lintas target.

Root repository ini (`formo`) berfungsi sebagai:
- source bahasa aplikasi (`.fm`, `.fs`),
- dokumentasi produk,
- kontrak IR dan fixture.

Semua source program compiler/runtime/tooling berada di repository library terpisah:
- `C:\Users\PC\Documents\formo-library-ecosystem`
- GitHub: `https://github.com/zulsyam23-dot/formo-library-ecosystem`

## Arsitektur 0.2 (Library-First)

- `formo` fokus ke bahasa/proyek.
- `formo-library-ecosystem` fokus ke implementasi compiler/runtime/tooling.
- Semua eksekusi CLI dilakukan via `--manifest-path ../formo-library-ecosystem/Cargo.toml`.
- Backend `web` dan `desktop` bersifat opsional (feature-gated di `formo-cli`).

## Quick Start

0. Bootstrap Formo 2 (aman + terstruktur):

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\formo2_bootstrap.ps1
```

Command ini akan:
- validasi `../formo-library-ecosystem/Cargo.toml`,
- sinkron extension Formo lokal ke `.vscode/.extensions`,
- hapus extension Formo global lama (anti-bentrok),
- jalankan `formo-cli check` untuk smoke test.

1. Buka workspace Formo 2:

```bash
.\open-formo.cmd
```

Perintah ini akan membuka [formo2.code-workspace](formo2.code-workspace) dengan local extension dir.

Dengan model ini, saat folder repo `formo` dihapus, extension lokal ikut hilang otomatis.

2. Jalankan CLI Formo 2 (wrapper aman):

```bash
.\formo2.cmd check --input main.fm
.\formo2.cmd build --target web --input main.fm --out dist
```

3. Validasi workspace library:

```bash
cargo check --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace
```

4. Validasi source Formo:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- check --input main.fm
```

5. Build web:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target web --input main.fm --out dist
```

6. Build desktop:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target desktop --input main.fm --out dist
```

## Command Reference (Ringkas)

- Help:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- help
```

- Diagnose:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- diagnose --input main.fm --json
```

- Format:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- fmt --input main.fm
```

- Benchmark:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- bench --input main.fm --iterations 12 --warmup 3 --nodes 1000 --out dist-ci/bench/benchmark.json --json-pretty
```

- Backend opsional (web only):

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli --no-default-features --features backend-web -- build --target web --input main.fm --out dist-web
```

- Backend opsional (desktop only):

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli --no-default-features --features backend-desktop -- build --target desktop --input main.fm --out dist-desktop
```

## Dokumentasi Utama

- Panduan penggunaan: `docs/PANDUAN_PENGGUNAAN.md`
- Boundary formo vs library: `docs/LIBRARY_BOUNDARY.md`
- Roadmap produksi: `PRODUCTION_ROADMAP.md`
- Checklist rilis: `docs/RELEASE_CHECKLIST.md`
- IR compatibility: `docs/IR_COMPATIBILITY.md`
- IR migrations: `docs/IR_MIGRATIONS.md`

## Status

Status aktif saat ini adalah fokus `Formo 0.2.0` dengan arsitektur library-first.
