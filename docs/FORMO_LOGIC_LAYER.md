# Formo Logic Layer (FL)

Dokumen ini mendefinisikan layer logika deklaratif Formo 2.

## Tujuan

- menjembatani `.fm` (UI) dan `.fs` (style) dengan logika deklaratif,
- memisahkan logika lintas target (`web` dan `desktop`) secara tegas,
- menjaga struktur mudah dibaca manusia dan AI.

## Tipe File

- `.fm` = view/component declarative UI,
- `.fs` = token dan style declarative,
- `.fl` = declarative logic (event/state/action/platform).

## Struktur Folder OOP (Direkomendasikan)

```text
logic/
  controllers/
    app_controller.fl
  services/
    session_service.fl
  contracts/
    navigation_port.fl
  platform/
    web_adapter.fl
    desktop_adapter.fl
```

Makna OOP:
- `controllers` = orkestrasi event use-case,
- `services` = logika domain reusable,
- `contracts` = antarmuka perilaku lintas platform,
- `platform` = adapter implementasi target.

## DSL FL (Ringkas)

Kata kunci utama:
- `module`, `use`, `as`,
- `logic`, `service`, `contract`, `adapter`,
- `enum`, `struct`, `type`, `function`,
- `state`, `event`, `action`, `platform`,
- `call`, `set`, `emit`, `throw`, `break`, `continue`, `return`, `web`, `desktop`.
- kontrol logika standar: `if`, `for`, `while`, `match`, `try`, `catch`.

Pola event:

```text
event startApp {
  action call Runtime.trace;
  action call SessionService.bootstrap;
  action set isReady = true;
  if hasCachedSession {
    action emit "SESSION_RESTORED";
  }
  try {
    action throw "STARTUP_RETRY";
  }
  catch {
    action emit "STARTUP_RECOVERED";
  }
  platform desktop { action call DesktopAdapter.focusMainWindow; }
  platform web { action call WebAdapter.syncBrowserRoute activeRoute; }
}
```

## Aturan Kaku

- `fm` tidak menyimpan logika bisnis kompleks.
- `fl` tidak berisi deklarasi UI/Style.
- setiap aksi lintas platform harus dipecah ke blok `platform web` / `platform desktop`.
- nama file controller/service/adapter memakai snake_case, nama module/logic memakai PascalCase.
- nama `event` wajib lowerCamelCase.
- unit `logic` wajib punya minimal 1 global action per-event.
- unit `service` wajib platform-agnostic (tanpa `platform web/desktop`).
- unit `logic/service` dilarang direct call ke `Browser`/`Desktop`.
- unit `adapter` hanya boleh `action call`.
- jumlah aksi `platform web` dan `platform desktop` wajib simetris per-event.
- urutan blok platform wajib `desktop` dulu, lalu `web` (desktop-first baseline).
- untuk unit `logic`, aksi di dalam blok `platform` hanya boleh `action call`.
- untuk unit `logic/adapter`, aksi global wajib sebelum blok `platform`.
- untuk unit `logic/adapter`, blok `platform` tidak boleh interleaving (desktop -> web saja).
- `action break` dan `action continue` hanya valid di dalam `for`/`while`.
- `action return` wajib jadi aksi terakhir pada event.
- `action throw` hanya valid di dalam `try`/`catch`.
- deklarasi `function` wajib `lowerCamelCase` dan setiap parameter wajib bertipe (`name: Type`).
- blok `state` wajib berisi field `lowerCamelCase`, tiap field wajib bertipe dan wajib punya initializer.
- `action set` wajib menarget field yang sudah dideklarasikan di blok `state`, dengan format `action set nama = nilai;`.
- `action set` menolak mismatch literal dasar terhadap tipe field state (`bool/string/int/float`).
- pada expression RHS `action set`, referensi state harus berasal dari field `state` yang terdaftar dan tipe operand harus kompatibel.
- validasi tipe `action set` menggunakan inferensi expression dasar (`+ - * / %`, `== != < <= > >=`, `&& ||`).
- deklarasi `enum` wajib PascalCase, variant wajib PascalCase.
- deklarasi `struct` wajib PascalCase, field wajib lowerCamelCase dan bertipe (`field: Type`).
- deklarasi `type` alias wajib PascalCase (`type Name = Some.Type;`).

## Standar Parity JS vs Rust

Agar perilaku logika web (JS runtime) dan desktop (Rust runtime) selalu sama:

- `FL` adalah satu-satunya source of truth untuk algoritma aplikasi.
- blok global (`action call/set/emit` di luar `platform`) harus berisi aturan bisnis inti.
- blok `platform web/desktop` hanya untuk adapter I/O, bukan keputusan bisnis.
- hindari source nondeterministik di level logika (waktu acak, urutan map tanpa kontrak, side effect implisit).
- setiap perubahan `.fl` harus lolos parity gate sebelum merge.

Command parity gate:

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\ci_verify_logic_parity.ps1
```

Gate ini menjalankan dua tahap:
- `formo logic --rt-manifest-out` untuk kontrak runtime `.fl`,
- `formo build --target desktop --strict-parity` sebagai baseline,
- `formo build --target web` agar web mengikuti baseline desktop.
