# AppFrame.qml Agent Notes

## Purpose

Owns the main Nu shell frame, route switching, left navigation placement, status strip area, and page loading.

## Nu Divergence

- Hides Advanced tools by default for new users while preserving advanced routes when enabled.
- Keeps wallet pages and advanced technical pages separated after Explorer/Forensics moved out.

## Do Not Break

- Keep route IDs aligned with `Main.qml`, `NavigationRail.qml`, and view file names.
- Do not put Explorer/Forensics back into Nu unless explicitly requested; those belong in Explore/ExpFor.
- Preserve enough width for the navigation rail and status mast at common Mac/Lion window sizes.

## Verification

- `git diff --check`
- Launch and switch through all visible routes with Advanced tools both off and on.
