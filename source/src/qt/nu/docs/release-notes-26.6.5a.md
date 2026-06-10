# Defcoin Core Nu 26.6.5a Release Notes

26.6.5a is a focused UI and metrics fix after the 26.6.5 style/DOX baseline.

## Changes

- Reward Calculator `Use current values` now also fills the calculator hashrate
  from the running Nu-managed miner when a miner has reported hashrate.
- Mast status dots and metric labels now share vertical alignment so Network,
  Wallet, Mining State, and their status dots line up cleanly.
- Metrics Details is now one linked switch above the Metrics tabs. Traffic,
  Status, and Peers all follow the same Details state.
- Metrics Traffic simple view stays total sent/received. Details view now uses a
  stacked filled chart with distinct TCP, Fast Sync UDP, and Quick Clone UDP
  components for sent and received traffic.
- Traffic totals now expose Fast Sync UDP and Quick Clone UDP separately while
  keeping both inside the overall UDP and total traffic counts.
- Metrics Status rows now emphasize sync health: current block/tip/ETA, UDP vs
  Core/TCP block mix, recent rates, and UDP success/failure peer counts.
- Status row height estimation now handles explicit newline summaries and avoids
  unnecessary double-height rows for simple one-line rows.

## Cross-Build Notes

- Port the QML changes in `Components/NuTimelineGraph.qml`,
  `Views/NodeView.qml`, `Views/MiningView.qml`, `Shell/StatusStrip.qml`,
  `Components/NuStatusDot.qml`, `Components/NuMetricRow.qml`, and
  `Components/NuDataTable.qml`.
- Port the Nu service changes in `NuRpcService.h/.cpp` so `trafficSamples`
  contains `fastSyncUdpReceived` and `fastSyncUdpSent`, and QML properties expose
  formatted `trafficFastSyncUdpReceivedTotal` / `trafficFastSyncUdpSentTotal`.
- Keep Quick Clone traffic counted as UDP traffic; do not add Quick Clone as a
  fourth transport outside UDP.

## Verification

- `git diff --check`
- `qmllint` on touched QML files exits 0; it still reports known context-property
  warnings for `NuService` and the local `Defcoin.Nu` import path.
