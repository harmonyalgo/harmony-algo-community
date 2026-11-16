# Reversal Pressure — Harmony Algo Community

Separate an extended move, reversal preparation and later closing-price recovery.

A preparation starts when price is sufficiently far from the prior 63-close median, scaled by the greater of its interquartile spread and prior ATR. The center and volatility reference freeze at preparation. Recovery evidence must rebuild after a fresh adverse extreme; rejection or slowing pressure, a bounded rebound and a reclaim close are required for Buy or Sell confirmation. Strong prior directional movement raises the evidence requirement.

A preparation is not a confirmed entry. Fixed center and invalidation references track the later outcome. Confirmation adds delay, reversals can fail, and closing invalidation is not a broker stop order.

## Installation

TradingView: open `ReversalPressure-Community.txt` (or `.pine`), copy the entire source into Pine Editor, save and Add to chart. [Clean original publication](https://www.tradingview.com/script/580Cg0qT-Reversal-Pressure-Harmony-Algo/).

MetaTrader 5: File → Open Data Folder → MQL5 → Indicators. Copy `ReversalPressure-Community-MT5.ex5` there, refresh Navigator and attach it to a standard candle chart. `.mq5` is the editable source; compile with MetaEditor if changing it. Popup alerts are off by default; enable them only when desired. No historical alert replay is intended.

## MT5 inputs

| Input | Default | Meaning |
| --- | --- | --- |
| LocationWindow | 63 | Location Window |
| MinimumRobustExtension | 1.4 | Minimum Robust Extension |
| RecoveryEvidenceATR | 1.2 | Recovery Evidence A T R |
| PreparationLife | 24 | Preparation Life |
| ReferenceTrackingBars | 48 | Reference Tracking Bars |
| RecentReferencePairs | 6 | Recent Reference Pairs |
| ShowPreparation | true | Show Preparation |
| ShowStatusPanel | true | Show Status Panel |
| StatusCorner | TopRight | Status Corner |
| BuyColor | C'1,130,8' | Buy Color |
| SellColor | C'209,34,8' | Sell Color |
| EnablePopupAlerts | false | Enable Popup Alerts |

## Timing, differences and limits

Signals commit on completed bars, so confirmation adds delay. Changing inputs or source history recalculates history. MT5 uses terminal chart objects and local popup alerts rather than TradingView labels and hosted alerts. Broker sessions, OHLC history and timezone can change results. Pine Data Window RSI/extension benchmark diagnostics are not included; preparation, confirmation and reference-event calculations remain. Period Excursion requires a chart timeframe strictly below its reference period. Historical statistics are descriptive and can be sparse; no forecast probability, profitability or performance guarantee is offered.

MetaEditor build 6230 compiled the included MQ5 with zero errors and warnings. Actual MT5 tests used EURUSD/GBPUSD H1/H4 loaded 2024 broker sample history, not live markets. Independent selected-field/event checks passed; see VALIDATION.txt for the precise scope. Live popup delivery, complete parameter sweeps and equal signals across different feeds were not verified.

## Distribution and license

This download intentionally includes a visible Harmony Algo watermark and website callout without a hide input. Editable source can be modified; this is not copy protection. Explore premium **TradingView** indicators at https://harmonyalgo.com. No premium MT5 product is promised.

CodeBase uses a separate ad-free derivative; its draft is not an official public link. Existing clean TradingView publications are unchanged. See LICENSE.md and SHA256SUMS.txt.
