# bundle_macos_backend_deps.sh Agent Notes

## Purpose

Bundles dynamic backend dependencies into the macOS Nu app and rewrites install names/rpaths where needed.

## Nu Risk

- Missing or incorrectly rewritten backend dependencies cause immediate launch failures or backend process failures after packaging.

## Do Not Break

- Do not copy wallet/datadir contents into the app bundle.
- Keep dependency filtering focused on binaries/libraries, not generated data.
- Preserve `@rpath`/`@loader_path` layout expected by `stage_macos_distribution.sh` and signing.

## Verification

- `git diff --check`
- Run packaging and use `otool -L` on bundled backend binaries.
