# common.qt.init.vcxproj Agent Notes

## Purpose

Defines shared Windows Qt paths, Qt include folders, Qt static library lists, plugin libraries, and generated-file paths.

## Nu Risk

- Hard-codes the static Qt 5.9.8 VS2019 path used by the Windows build.
- Qt library order and plugin libraries directly affect whether packaged Windows builds launch without missing DLL/library errors.

## Do Not Break

- Do not change `QtBaseDir`, generated-file paths, or static library lists without confirming the Windows builder has the matching Qt install.
- Keep Release and Debug Qt dependencies intentionally distinct.
- Nu QML app packaging is separate from this classic Qt project graph unless explicitly wired in.

## Verification

- `git diff --check`
- Windows Qt build and launch smoke test after Qt path/library changes.
