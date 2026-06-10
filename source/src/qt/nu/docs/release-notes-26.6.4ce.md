# Defcoin Core Nu 26.6.4ce Release Notes

Date: 2026-06-09

## Metrics Traffic Graph

- Expanded Metrics > Traffic from total sent/received lines to total, TCP, UDP,
  and Quick Clone subset series.
- Kept total received/sent in the existing graph colors and made protocol
  breakouts line-style based:
  - solid: total traffic
  - dashed: TCP
  - dotted: UDP
  - dot-dash: Quick Clone subset
- Quick Clone traffic is counted as part of UDP and total traffic, not added a
  second time.
- Added Quick Clone totals to the tight footer grid beside TCP, UDP, and total
  traffic.
- Extended the hover tooltip and traffic CSV export with TCP, UDP, and Quick
  Clone received/sent rates.

## Metrics Status

- Added live Quick Clone copy-rate telemetry to the Quick Clone status row.
- The row now reports live total/in/out rate, average rate over observed clone
  activity, total bytes received/sent, and received/sent packet counts.

## Porting Notes

- Lion, Catalina, and Windows builds need the same `trafficSamples` keys:
  `received`, `sent`, `tcpReceived`, `tcpSent`, `udpReceived`, `udpSent`,
  `quickCloneReceived`, and `quickCloneSent`.
- Quick Clone bytes are a UDP subset. Do not add Quick Clone to total traffic
  separately.
