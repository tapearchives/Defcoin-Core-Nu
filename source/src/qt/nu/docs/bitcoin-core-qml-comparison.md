# Bitcoin Core QML Comparison Notes

This is an investigation report only. No Bitcoin Core QML source code is copied
into Defcoin Core Nu in this pass.

Reference reviewed: `bitcoin-core/gui-qml` at local checkout `cc049e7`.
Baseline compared against: Litecoin Core / Defcoin Core v0.21.5.5 Qt.

## Executive Summary

Bitcoin Core QML is useful to Defcoin Core Nu as an architecture reference, not
as a drop-in code source. Its strongest ideas are typed C++ models exposed to
QML, proxy-model sorting, event-driven model refresh, explicit keyboard focus
behavior, reusable focus/tooltip controls, and native model objects for peers,
logs, wallets, coins, and traffic. Nu currently uses a lighter separate-process
RPC bridge, so directly copying their model stack would require a larger
backend integration change.

## Backend Integration

Bitcoin Core QML creates `interfaces::Init`, `interfaces::Node`, and
`interfaces::Chain` directly through `interfaces::MakeGuiInit`. That gives the
QML app typed access to node and wallet interfaces without JSON-RPC. Litecoin
Core v0.21.5.5 Qt uses the classic Qt Widgets GUI with client and wallet models
attached directly to node/wallet interfaces.

Nu is intentionally different: it starts or connects to a local `defcoind` and
talks through JSON-RPC. This keeps the Nu frontend separated from consensus,
wallet storage, private-key handling, and peer networking. The tradeoff is that
Nu must add careful startup diagnostics, backend runtime bundling, RPC error
handling, and local model caching.

Nu keeps the separate-process model for this release.

## Frontend Architecture

Bitcoin Core QML splits reusable controls, components, app pages, and C++
models cleanly:

- `qml/controls`: base controls such as focus borders, buttons, text fields,
  icons, and navigation.
- `qml/components`: larger wallet/node components such as fee selection,
  network indicators, storage settings, traffic graphs, and tooltips.
- `qml/models`: C++ models for activity, peers, logs, wallets, options,
  coins, transactions, and traffic.
- `qml/pages`: route-level pages for node, wallet, onboarding, and settings.

Nu already mirrors the first part of this split with `Components`, `Shell`,
`Theme`, and `Views`.

## Models And Tables

Bitcoin Core QML's `PeerListModel` is a `QAbstractListModel` that refreshes
from `interfaces::Node::getNodesStats`. It resets only when the peer count or
peer order changes, and otherwise emits `dataChanged`. `PeerListSortProxy`
sorts by raw peer fields, not formatted display strings.

Nu now has typed sort functions and font-metrics column sizing, but rows are
still QML arrays from RPC results.

## Peers

Bitcoin Core QML separates the peer list from peer details. The list is compact
and sortable; details are a model object created from the selected peer's stats.
It also includes disconnect and ban operations on the node model.

Nu currently keeps the peer view table-first and does not reintroduce the
inspector pane. That matches the current Nu design goal.

## Network Traffic

Bitcoin Core QML uses a `NetworkTrafficTower` model and graph components. It
tracks total bytes and smoothed rates in C++ rather than asking QML to derive
all graph state. Nu samples `getnettotals` and avoids repeated zero samples.

## Debug Log

Bitcoin Core QML has a `DebugLogModel` that reads and filters the log off the
UI path using concurrent work and a watcher. Nu currently tails `debug.log`
through `NuRpcService` and preserves cursor focus in QML.

Recommendation: port the concept, not the code. A Nu log model should watch the
file, load only the relevant tail/current-launch window, and append new lines
without resetting text selection or scroll position.

## Wallet And Send Flow

Bitcoin Core QML contains wallet models, recipient models, transaction review,
fee preview, coin selection, backups, wallet creation/import, and external
signer flows. Litecoin Core v0.21.5.5 Qt exposes similar wallet functions
through mature Widgets dialogs.

Nu exposes the core safe flows directly: send, receive, activity, backup,
encrypt, change passphrase, sign/verify message, and PSBT load/sign/finalize.

## Accessibility And Focus

Bitcoin Core QML explicitly sets `Qt::TabFocusAllControls`. Nu already sets
focus policies and tooltips on controls, but should also set this application
style hint at startup. This is a low-risk concept worth adopting because it
helps keyboard users and makes tooltip-on-focus behavior discoverable.

## Help Flow

Bitcoin Core QML focuses on in-app pages and settings rather than a native OS
help book. Nu 26.5.5o keeps release information in About and Build Notes.

## Why Reference Bitcoin Core QML If No Code Is Copied?

The project is a useful proof that a Bitcoin-family full-node wallet can be
organized around Qt Quick, reusable controls, typed C++ models, and a cleaner
model/view separation. Referencing it is still valid because Nu follows those
architectural lessons while keeping Defcoin's separate-process backend boundary
for this release.
