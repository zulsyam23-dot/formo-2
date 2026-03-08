# Formo

Formo adalah bahasa deklaratif untuk UI lintas target.

Root repository ini (`formo`) berfungsi sebagai:
- source bahasa aplikasi (`.fm`, `.fs`, `.fl`),
- dokumentasi produk,
- kontrak IR dan fixture.

Semua source program compiler/runtime/tooling berada di repository library terpisah:
- GitHub: `https://github.com/zulsyam23-dot/formo-library-ecosystem`

Tidak wajib clone manual. Wrapper Formo 2 akan mencari library otomatis, lalu fallback auto-download ZIP ke:
- `.formo/formo-library-ecosystem` (di dalam repo ini)

## Arsitektur 0.2 (Library-First)

- `formo` fokus ke bahasa/proyek (`fm` + `fs` + `fl`).
- `formo-library-ecosystem` fokus ke implementasi compiler/runtime/tooling.
- Semua eksekusi CLI lewat wrapper `.\formo2.cmd` (manifest path di-resolve otomatis).
- Backend `web` dan `desktop` bersifat opsional (feature-gated di `formo-cli`).

### Layer Bahasa Formo 2

- `FM` (UI): deklarasi komponen/view.
- `FS` (Style): deklarasi token/style.
- `FL` (Logic): deklarasi state/event/action lintas web-desktop.
- `FL` menjadi source logika tunggal. Build `web` dan `desktop` wajib lulus parity gate yang sama.

Struktur OOP rekomendasi untuk `FL`:

```text
logic/
  controllers/
  services/
  contracts/
  platform/
```

## Quick Start

0. Buka folder/repo Formo di VS Code.

Support editor untuk `.fm`, `.fs`, `.fl` sekarang disiapkan otomatis saat folder dibuka
(task `formo:auto-enable-editor-support`), tanpa setup manual PowerShell.

1. Buka workspace Formo 2:

```bash
.\open-formo.cmd
```

Perintah ini akan membuka [formo2.code-workspace](formo2.code-workspace) dengan local extension dir.

Dengan model ini, saat folder repo `formo` dihapus, extension lokal ikut hilang otomatis.

Opsional, jika ingin bootstrap penuh (check manifest + smoke test CLI):

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\formo2_bootstrap.ps1
```

2. Jalankan CLI Formo 2 (wrapper aman, auto-resolve library path):

```bash
.\formo2.cmd check --input main.fm
.\formo2.cmd build --target web --input main.fm --out dist
.\formo2.cmd parity
.\formo2.cmd where-library
```

Pada run pertama, jika library belum ada, wrapper akan auto-download snapshot `formo-library-ecosystem`.
Jalankan health check lokal:

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\formo2_doctor.ps1
```

3. Validasi parity logika FL (JS dan Rust seragam):

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\ci_verify_logic_parity.ps1
```

Script ini akan:
- validasi `logic/controllers/app_controller.fl`,
- generate runtime contract `.fl`,
- build `desktop` dengan `--strict-parity` sebagai baseline,
- lalu build `web` agar mengikuti baseline desktop.

4. Validasi workspace library:

```bash
cargo check --manifest-path ../formo-library-ecosystem/Cargo.toml --workspace
```

5. Validasi source Formo:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- check --input main.fm
```

6. Build desktop:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target desktop --input main.fm --out dist
```

Artifact desktop sekarang juga menyediakan folder `readable/` berisi JSON terpecah agar audit manusia/AI lebih mudah.

7. Build web:

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target web --input main.fm --out dist
```

Artifact web sekarang juga menyediakan `runtime/app/*.js` (split runtime source) selain `app.js` bundle.

## Command Reference (Ringkas)

- Help:

```bash
.\\formo2.cmd help
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- help
```

- Diagnose:

```bash
.\\formo2.cmd diagnose --input main.fm --json
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

- Logic parity contract (`.fl`):

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- logic --input logic/controllers/app_controller.fl --json-pretty --rt-manifest-out target/parity/fl-runtime-contract.json
```

- Build parity ketat (wajib seragam lintas target):

```bash
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target desktop --input main.fm --out dist --strict-parity
cargo run --manifest-path ../formo-library-ecosystem/Cargo.toml -p formo-cli -- build --target web --input main.fm --out dist
```

## Dokumentasi Utama

- Panduan penggunaan: `docs/PANDUAN_PENGGUNAAN.md`
- Boundary formo vs library: `docs/LIBRARY_BOUNDARY.md`
- Formo logic layer (`.fl`): `docs/FORMO_LOGIC_LAYER.md`
- Roadmap produksi: `PRODUCTION_ROADMAP.md`
- Checklist rilis: `docs/RELEASE_CHECKLIST.md`
- IR compatibility: `docs/IR_COMPATIBILITY.md`
- IR migrations: `docs/IR_MIGRATIONS.md`

## Resolver Safety Knobs

- `FORMO_LIBRARY_MANIFEST`: path absolut/relatif langsung ke `Cargo.toml` library.
- `FORMO_LIBRARY_ROOT`: path root library (manifest diasumsikan di `<root>/Cargo.toml`).
- `FORMO_LIBRARY_AUTO_INSTALL=0`: nonaktifkan auto-download ZIP library.
- `FORMO_LIBRARY_ZIP_URL`: override URL ZIP source library.
- `FORMO_LIBRARY_ZIP_SHA256`: verifikasi hash ZIP (opsional, direkomendasikan untuk CI/offline mirror).
- `FORMO_LIBRARY_ALLOW_UNTRUSTED_URL=1`: izinkan host URL non-GitHub (gunakan hanya di jaringan internal tepercaya).

## Status

Status aktif saat ini adalah fokus `Formo 0.2.0` dengan arsitektur library-first.
