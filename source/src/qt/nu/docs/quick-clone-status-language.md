# Quick Clone Status Language

Quick Clone is the user-facing name for DCOL / Direct Copy Over LAN. Keep the
status line short, action-oriented, and clear about whether Nu is idle,
supplying data, or receiving data.

## 1. Waiting And Listening For Quick Clone Requests

- `Quick Clone off.`
- `Quick Clone not requested (chain within 98% of tip). Responder listening on LAN.`
- `Quick Clone not requested. Responder awaiting LAN request.`
- `Quick Clone waiting for UDP socket.`
- `Quick Clone waiting for backend RPC.`
- `Quick Clone waiting for LAN Nu beacons.`
- `Quick Clone waiting for a LAN source to answer UDP.`
- `Quick Clone probing LAN source <host>.`
- `Quick Clone listening on LAN; Core P2P sync is active.`
- `Quick Clone listening on LAN; Core P2P sync is resuming.`
- `Quick Clone caught up to LAN source <host> at block <height>.`

## 2. Supplying A Clone

- `Quick Clone responder awaiting request.`
- `Quick Clone supplying blockchain on LAN.`
- `Quick Clone supplying block <height> to <host>.`
- `Quick Clone supplying blockchain on LAN to <n> receiver(s).`
- `Quick Clone supply paused: source tip changed; preparing a fresh manifest.`
- `Quick Clone finishing supply: momentarily isolating from WAN for final snapshot.`
- `Quick Clone supply complete; Core networking is resuming.`
- `Quick Clone supply cancelled by user.`
- `Quick Clone supply stopped: receiver went offline.`

## 3. Receiving A Clone

- `Quick Clone armed. Nu will use LAN sources only after request; wallet data is never copied.`
- `Quick Clone found LAN source <host>; waiting for Core peer selection before requesting blocks.`
- `Quick Clone asking Core to reserve the next missing block from <host>.`
- `Quick Clone receiving blockchain over LAN.`
- `Quick Clone receiving blockchain over LAN: requesting reserved block <height> from <host>.`
- `Quick Clone receiving blockchain over LAN from <n> source(s).`
- `Quick Clone skipped LAN block <height> because Core already has it; trying the next missing block.`
- `Quick Clone skipped already-known LAN block <height>; reserving the next missing block.`
- `Quick Clone marked <host> offline after missing chunks for block <height>; trying another LAN source if available.`
- `Quick Clone block <height> was not accepted (<reason>); LAN copy is paused for the next retry.`
- `Quick Clone received block <height> through Core.`
- `Quick Clone receiving final snapshot; ordinary P2P sync is paused.`
- `Quick Clone installing verified public chain snapshot.`
- `Quick Clone complete; Core networking is resuming.`
- `Quick Clone cancelled by user; normal sync continues.`
