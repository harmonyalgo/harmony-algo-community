# Trend Stress Compass — Harmony Algo Community

See whether a fitted trend survives the removal of different parts of its price history.

The default model fits a line to 72 closes, then repeats the fit after removing each of six 12-bar segments. Up or Down support needs three confirming closes and sufficient retained movement across the deletion fits. A separate loss threshold avoids treating every small change as a new trend.

The full-fit line and deletion envelope describe sensitivity to the chosen history. They are not a forecast band or confidence interval. A trend can remain supported during a pullback and can fail after confirmation.

## Installation

TradingView: open `TrendStressCompass-Community.txt` (or `.pine`), copy the entire source into Pine Editor, save and Add to chart. [Clean original publication](https://www.tradingview.com/script/etULm2Vi-Trend-Stress-Compass-Harmony-Algo/).

MetaTrader 5: File → Open Data Folder → MQL5 → Indicators. Copy `TrendStressCompass-Community-MT5.ex5` there, refresh Navigator and attach it to a standard candle chart. `.mq5` is the editable source; compile with MetaEditor if changing it. Popup alerts are off by default; enable them only when desired. No historical alert replay is intended.

## MT5 inputs

| Input | Default | Meaning |
| --- | --- | --- |
| BarsPerSegment | 12 | six segments, 4..40 bars each |
| MinimumRetainedMoveATR | 1.5 | >=0.5 |
| LossThresholdATR | 0.6 | 0..0.9 and below entry |
| ConfirmedCloses | 3 | 1..8 |
| ShowSummary | true | Show Summary |
| RetainedDirectionMarkers | 500 | 20..500 |
| EnablePopupAlerts | false | local terminal; no historical alert replay |

## Timing, differences and limits

Signals commit on completed bars, so confirmation adds delay. Changing inputs or source history recalculates history. MT5 uses terminal chart objects and local popup alerts rather than TradingView labels and hosted alerts. Broker sessions, OHLC history and timezone can change results. Period Excursion requires a chart timeframe strictly below its reference period. Historical statistics are descriptive and can be sparse; no forecast probability, profitability or performance guarantee is offered.

MetaEditor build 6230 compiled the included MQ5 with zero errors and warnings. Actual MT5 tests used EURUSD/GBPUSD H1/H4 loaded 2024 broker sample history, not live markets. Independent selected-field/event checks passed; see VALIDATION.txt for the precise scope. Live popup delivery, complete parameter sweeps and equal signals across different feeds were not verified.

## Distribution and license

This download intentionally includes a visible Harmony Algo watermark and website callout without a hide input. Editable source can be modified; this is not copy protection. Explore premium **TradingView** indicators at https://harmonyalgo.com. No premium MT5 product is promised.

CodeBase uses a separate ad-free derivative; its draft is not an official public link. Existing clean TradingView publications are unchanged. See LICENSE.md and SHA256SUMS.txt.
