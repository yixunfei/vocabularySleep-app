# Advanced calculator CAS assets

This directory contains the pinned, offline JavaScript computer algebra
system (CAS) assets used by the advanced calculator. Runtime code must load
these local files; it must not download or execute a remote CAS bundle.

## Components

| Component | Version | License | Upstream |
| --- | --- | --- | --- |
| nerdamer-prime | 1.5.0 | MIT | <https://github.com/together-science/nerdamer-prime> |
| Algebrite | 1.4.0 | MIT | <https://github.com/davidedc/Algebrite> |
| fjs / QuickJS runtime | 3.3.0 | MIT | <https://github.com/fluttercandies/fjs> |
| calculator CAS core | protocol 1 | Project source | `calculator_cas_core.js` |
| calculator CAS advanced operations | protocol 1 | Project source | `calculator_cas_advanced.js` |
| calculator CAS dispatcher | protocol 1 | Project source | `calculator_cas_bridge.js` |

The upstream MIT notices for the two bundled engines are retained as
`LICENSE-nerdamer-prime.txt` and `LICENSE-algebrite.txt`. The `fjs` package
license is supplied by the pinned Pub dependency.

## SHA-256

| File | SHA-256 |
| --- | --- |
| `nerdamer-prime-1.5.0.min.js` | `3321e375b9cd36d1733c62b3c07b0c097bf4d336234ad9cfd06d9a8c780e9973` |
| `algebrite-1.4.0.browser.js` | `4c5d57e3263883d6b0f32a406d158695f4f8267e89ca2cdaced160f8c4f3b275` |
| `calculator_cas_core.js` | `ea0ebfdf4dca6f6a15e9bf46faad9ef91ff1fbfc048c892ede2648119c04cf18` |
| `calculator_cas_advanced.js` | `376ddc7f5e16705041de12e2a86e8e2e02dd385ff17d123bdda536963fafd659` |
| `calculator_cas_bridge.js` | `0e573fd99754872104892eb36151dea3e634da23618010c336bedc5b14e6a742` |
| `LICENSE-nerdamer-prime.txt` | `c9f52548869a0a2e63a7100055c54cebf36b9327c8fc2da7cf9ca8dddc2f1cca` |
| `LICENSE-algebrite.txt` | `a3a78132a70b31e2f70d1d521bd2def15db206a7ca30b0880f778d265e94e4f2` |

`manifest.json` is the machine-readable source/version/integrity record for
the third-party engine bundles. When an engine or the project-owned bridge is
changed, update the manifest, this table, the bridge tests, and the notices in
the same change.

## Runtime boundary

- Native Flutter platforms load the bundles in `fjs` 3.3.0 with no QuickJS
  built-ins, a 96 MiB memory limit, a 16 MiB GC threshold, and a 1 MiB stack.
- Requests cross the bridge as JSON. User expressions are passed to the CAS
  parsers as data and are never interpolated into JavaScript source.
- A serialized request is limited to 64 KB. Normal calculations have a
  four-second deadline; a timed-out or resource-exhausted engine is closed and
  recreated before a later request.
- Persistent CAS assignment syntax is rejected so one calculation cannot
  mutate another calculation's runtime state. Session `Ans`, `Mem`, named
  variables, and custom functions cross the bridge as validated request data;
  Nerdamer variables/functions are cleared after every request and Algebrite
  state is cleared before the next request.
- `DEG` changes only closed, direct numeric `evaluate` and `approximate`
  trigonometry. Symbolic calculus, transforms, limits, and Taylor series keep
  standard radian semantics.
- The web target does not currently host the native `fjs` runtime. Direct
  numeric expression evaluation falls back to the Dart numeric service;
  symbolic operations report that the engine is unavailable.

## Native build prerequisites

`fjs` 3.3.0 builds its Rust native asset through Cargokit. Its build command
explicitly uses `rustup run stable`, so a repository `rust-toolchain.toml` does
not select the compiler used by this dependency.

- Install Rust stable 1.95 or newer. Windows integration was verified with
  Rust stable 1.98.0.
- Windows also needs an x64 `libclang.dll`. Set `LIBCLANG_PATH` to the
  directory containing the DLL before the first native build. The verified
  setup used the signed NuGet package `libclang.runtime.win-x64` 22.1.8.
- Confirm the compiler selected by the plugin with
  `rustup run stable rustc --version`.
- Android and iOS still require their normal Flutter native toolchains and
  device-level validation; a Windows build does not validate those targets.

## Verification

```powershell
node tool/test_calculator_cas_bridge.mjs
flutter test integration_test/toolbox_calculator_cas_engine_test.dart -d windows
Get-FileHash assets/toolbox/calculator_cas/* -Algorithm SHA256
```
