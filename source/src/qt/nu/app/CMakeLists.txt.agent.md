# CMakeLists.txt Agent Notes

## Purpose

Defines the Tahoe Nu Qt Quick app targets, bundle metadata, release label, Qt modules, assets, platform sources, and optional Explore app target.

## Nu Divergence

- Builds `DefcoinCoreNu` and optional `DefcoinCoreExplore` from the same Nu QML/C++ source base.
- Owns the visible Nu release label through `DEFCOIN_NU_RELEASE_NAME`.
- Sets macOS bundle identifiers, icon files, Info.plist, Qt module list, runtime assets, help assets, and Velopack update URL.

## Do Not Break

- Keep Nu and Explore bundle identifiers distinct.
- Do not change release labels without following the user's versioning rule.
- Do not add Qt modules that Lion cannot support unless the fallback is documented.
- Do not remove runtime assets used by QML views without searching the QML tree first.

## Verification

- `git diff --check`
- Configure and build the Nu app after build-graph edits.
- Check macOS Finder "Kind", bundle id, icon, and about/splash version after release metadata changes.
