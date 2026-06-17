# PaperWalletView.qml Agent Notes

## Purpose

Owns the Paper Wallet view used by Nu Wallet and, until replaced by a bulk workflow, Explore: staged paper-wallet setup, entropy capture, multi-address paper-wallet sheet controls, generated Defcoin address/private-key state, full-sheet preview, pop-out preview, print action, and clear controls.

## Nu Divergence

- After successful generation, the view offers to print a one-page foldable
  Letter paper-wallet sheet by default using the service-owned print renderer.
- The view uses a staged workflow: choose design, customize wallet count/printed
  amount/BIP38, collect entropy, generate keys, review/print, planned funding,
  and funding review. The right side is a persistent scaled sheet preview
  rather than a redundant two-QR utility preview.
- The view exposes liteaddress.org-style paper-wallet controls: Hide Art,
  addresses to generate, optional cosmetic printed amount, BIP38 encryption and
  passphrase, an off-by-default `Allow weak phrases?` override, Generate, Pop
  Out, and Print. Default generation is one wallet; a single run may generate
  up to 100 wallets. The funding stage is always visible and sends through a
  separate reviewed `sendmany` flow using only the generated public addresses
  and user-entered DFC amounts.
- The Design selector currently exposes only `Design 1 - Full sheet strips
  (single-sided)`. Designs 2-5 remain compiled into the print renderer for
  later polishing, but they must stay hidden from the user-facing selector until
  their text fit, duplex alignment, and hide-art variants are release-ready.
- The interactive GUI preview is a scaled sheet preview rendered by
  `NuService.paperWalletPreviewPageSources()`, which must reuse the same C++
  paper-wallet renderer as printing. Do not reintroduce an independent QML
  Canvas approximation for sheet artwork. Before generation it must use
  placeholders instead of fake keys/QR values. After generation it must render
  the actual selected design family and generated QR/address data, showing both
  front and back for double-sided designs. Preview refreshes are keyed by the
  selected design, page count, amount, BIP38 state, hide-art state, and generated
  entries; avoid timer/polling refreshes that redraw unchanged pages.
- Preview rendering is deferred and coalesced behind a loading indicator so
  entering Wallet > Paper Wallet responds immediately even when the selected
  print design is expensive to rasterize.
- The left staged workflow and the right sheet preview are independent scroll
  panes. The staged workflow owns vertical scrolling; the sheet preview owns
  its horizontal/vertical scrollbars and zoom controls so zoomed print pages can
  intentionally extend beyond the visible preview frame for inspection.
- The embedded preview should fit the rendered print page by available width so
  strip-style wallets remain readable; the pop-out preview is the place to fit
  the complete page for full-page review.
- Review/print may be opened before entropy is complete for alignment and
  two-sided pre-viz testing. Those pages must be clearly marked unusable until
  entropy and keys are generated.
- For new or changed paper-wallet layouts, prefer iterating with the lightweight
  preview/PDF render path first and inspect the generated page image before
  doing a full Nu rebuild.
- Entropy capture uses a deliberately higher target than the minimum key
  material requirement so users get a clear local-generation ceremony before
  the Generate button unlocks.
- The entropy panel must show progress and accept both pointer movement and
  keyboard randomness without stealing typed BIP38 passphrases or amount input.
  Entropy points stop accumulating once the visible target is reached. Entropy
  capture is opt-in: the view must not collect pointer or keyboard samples until
  the user presses Start Entropy Input. The former decorative hourglass
  animation is intentionally removed; use the progress bars and status copy as
  the reliable state indicator.
- `embedded: true` hides the route-level page header so the view can live inside Wallet > Paper Wallet without duplicate headings.

## Do Not Break

- Keep Nu focused on disposable single-sheet generation. Larger funding/bulk
  distribution workflows belong in Explore and should not share private-key
  persistence assumptions with this route. Nu may fund the generated public
  addresses through one reviewed active-wallet transaction, but bulk split,
  template import, and large distribution workflows belong in Explore.
- Do not write WIF/private-key material to files, settings, logs, temp QR images, or external URLs.
- Keep private-key copy behind the sensitive clipboard path and keep Clear wired to the service clear action.
- Do not auto-print after generation; the print offer must remain user-confirmed.
- Keep the view scrollable so staged controls and the sheet preview remain
  reachable in one route.
- Route/tab navigation prompts clear generated keys if the user leaves without
  clearing. Do not add extra clear controls into Review and Print.
- Keep the Generate action gated on the visible entropy target and, when BIP38
  is selected, a minimum 12-character passphrase unless the user explicitly
  enables the weak-phrase override.
- If a generated paper-wallet sheet already exists, customization changes may
  unlock `Regenerate Wallet Sheet` without forcing the user through entropy
  collection again. Preserve existing public addresses by reusing the in-memory
  secret material; only append new keys for an increased wallet count or
  re-encode existing private keys if BIP38 settings change.
- Keep the post-generation print offer user-controlled; generating a key must not automatically open a printer job without confirmation.
- Keep the self-test preview popout hooks focused on opening/closing the
  existing preview UI; they must not bypass the normal Clear/copy/print safety
  rules.
- Do not add Defcoin logo art to the utility preview pane. Branding belongs on
  the printed foldable sheet so the interactive tab stays focused on security
  state, key visibility, copy actions, and print controls.

## Verification

- `git diff --check`
- Build the Nu/Explore frontend after bridge or QML changes.
- For layout changes, render at least the affected design through the preview or
  `DEFCOIN_NU_PAPER_WALLET_PDF` self-test path and inspect the resulting image.
  Prefer `render_paper_wallet_previews.sh <app> <out> <count> <hide-art> <design>`
  for fast design-only checks.
- Launch Nu, open Wallet > Paper Wallet, generate with local entropy on a disposable backend, verify pop-out/print dialog opens, then Clear removes address/WIF/QR fields.
- Run Explore `--ui-self-test --allow-multiple` and verify the Paper Wallet
  route plus pop-out preview complete without a crash.
