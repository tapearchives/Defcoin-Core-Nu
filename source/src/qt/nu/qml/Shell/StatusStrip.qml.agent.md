# StatusStrip.qml Agent Notes

## Purpose

Owns the mast/header status strip visible above Nu pages: network health, traffic rates, hashrate, difficulty, wallet state, sync state, peers, block height, and live mining state.

## Nu Divergence

- Uses a forced two-line status layout so `Network` and `Wallet` dots align vertically and `Sync` starts after the wallet indicator on line two.
- Gives each header metric a stable slot width so ordinary rate/value changes do not shift every following field.
- Keeps slower explanatory chain metrics such as average block spacing in Metrics instead of the mast, where they tend to crowd time-sensitive sync and block status.
- Persists learned normal-width header slots under `NuTables/statusHeaderSlots`; the existing Reset views action clears this key and restores first-launch defaults.
- Shows TX/RX as total bit rates, with Fast Sync UDP and Quick Clone UDP included in UDP totals through `NuRpcService`.
- Shows near-tip sync as `Catching up` instead of alternating transport names,
  and includes `Accepted/s` when the local miner is running.

## Do Not Break

- Do not return this header to a free-flowing single line; it caused visible bounce and misaligned status dots.
- Keep labels short enough for normal laptop-width windows. Long diagnostics belong in Metrics, not the mast.
- Keep compact-width behavior fixed; only normal-width slots should learn/persist, otherwise narrow windows become unstable.
- Keep the mining dot aligned to the same left column as Network/Wallet.

## Verification

- `git diff --check`
- Launch Nu and confirm `Network` and `Wallet` dots are vertically aligned, `Sync` is on the second line, and Difficulty/Block are not clipped at common window widths.
