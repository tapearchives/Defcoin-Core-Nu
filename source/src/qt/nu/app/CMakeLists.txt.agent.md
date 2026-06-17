# CMakeLists.txt Agent Notes

## Purpose

Defines the Tahoe Nu Qt Quick app targets, bundle metadata, release label, Qt modules, assets, platform sources, and optional Explore app target.

## Nu Divergence

- Builds `DefcoinCoreNu` and optional `DefcoinCoreExplore` from the same Nu QML/C++ source base.
- Owns the visible Nu release label through `DEFCOIN_NU_RELEASE_NAME`.
- Sets macOS bundle identifiers, icon files, Info.plist, Qt module list, runtime assets, help assets, and Velopack update URL.
- Bundles Atkinson Hyperlegible Mono TTFs and license text as runtime assets so
  paper-wallet key strings and mono UI fields render consistently without a
  host-system font dependency.
- Includes Qt PrintSupport because Nu's Paper Wallet route opens the native print dialog.
- Windows runtime packaging must copy `Qt6PrintSupport.dll` with the other Qt DLLs; `windeployqt` has not been a reliable sole source for this module in cross-builds.
- Windows cross builds must resolve OpenSSL from a target MinGW prefix through `DEFCOIN_NU_OPENSSL_ROOT` or the auto-detected `toolchains/openssl/win64`; host Homebrew/OpenSSL paths are fatal because paper-wallet BIP38 and entropy helpers link crypto symbols directly.
- Links the local Core `secp256k1-zkp` static library and `crypto/ripemd160.cpp` into the Nu/Explore app targets so paper-wallet address derivation stays local and never needs descriptor RPC calls with a WIF.
- The Nu wallet resource target copies the shared QML tree, then prunes source-only `.agent.md` companions and Explore-only QML screens. Explore keeps the full shared QML tree through `DefcoinCoreExploreResources`.

## Do Not Break

- Keep Nu and Explore bundle identifiers distinct.
- Do not change release labels without following the user's versioning rule.
- Do not add Qt modules that Lion cannot support unless the fallback is documented.
- Do not remove runtime assets used by QML views without searching the QML tree first.
- Do not drop bundled font files from `DEFCOIN_NU_RUNTIME_ASSET_FILES` unless
  `main.cpp` font registration and QML font tokens are updated at the same time.
- Do not ship source-only `.agent.md` companions or Explore-only routes in the Nu wallet app bundle.
- Do not let paper-wallet generation silently build without local secp256k1 support; if the library is missing, the app path must fail closed and the build output should make the missing dependency obvious.
- Do not allow Windows builds to fall back to host OpenSSL. If `DEFCOIN_NU_OPENSSL_ROOT` is missing, build a MinGW OpenSSL prefix first.

## Verification

- `git diff --check`
- Configure and build the Nu app after build-graph edits.
- Check macOS Finder "Kind", bundle id, icon, and about/splash version after release metadata changes.
