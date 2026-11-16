# Price Rank Shift — Harmony Algo Community

Compare two blocks of closes to identify broad price relocation and later loss of ordering.

The default comparison uses two separate blocks of 20 closes. Pairwise ordering produces a signed rank effect; direction also requires a median displacement of at least 0.50 prior ATR and three confirming closes. A weaker ordering threshold governs neutralization.

The two median lines roll forward. They are not fixed support or stop levels. Within-block ordering is ignored, so an Up state can persist during a pullback. Rank effect is descriptive, not forecast probability or statistical significance.

## Installation

TradingView: open `PriceRankShift-Community.txt` (or `.pine`), copy the entire source into Pine Editor, save and Add to chart. [Clean original publication](https://www.tradingview.com/script/GuHXtwsO-Price-Rank-Shift-Harmony-Algo/).

MetaTrader 5: File → Open Data Folder → MQL5 → Indicators. Copy `PriceRankShift-Community-MT5.ex5` there, refresh Navigator and attach it to a standard candle chart. `.mq5` is the editable source; compile with MetaEditor if changing it. Popup alerts are off by default; enable them only when desired. No historical alert replay is intended.

## MT5 inputs

| Input | Default | Meaning |
| --- | --- | --- |
| ClosesPerBlock | 20 | 8 to 40 |
| DirectionalRankEffect | 0.70 | 0.55 to 0.95 |
| LossOfOrderingThreshold | 0.20 | 0 to 0.50 |
| ConfirmingCloses | 3 | 1 to 8 |
| MinimumMedianGapATR | 0.50 | 0 to 3 |
| ShowStatePanel | true | Show State Panel |
| UpColor | C'1,130,8' | Up Color |
| DownColor | C'209,34,8' | Down Color |
| NeutralColor | C'127,73,222' | Neutral Color |
| EnablePopupAlerts | false | local terminal alerts, only after a NEW closed bar |

## Timing, differences and limits

Signals commit on completed bars, so confirmation adds delay. Changing inputs or source history recalculates history. MT5 uses terminal chart objects and local popup alerts rather than TradingView labels and hosted alerts. Broker sessions, OHLC history and timezone can change results. Period Excursion requires a chart timeframe strictly below its reference period. Historical statistics are descriptive and can be sparse; no forecast probability, profitability or performance guarantee is offered.

MetaEditor build 6230 compiled the included MQ5 with zero errors and warnings. Actual MT5 tests used EURUSD/GBPUSD H1/H4 loaded 2024 broker sample history, not live markets. Independent selected-field/event checks passed; see VALIDATION.txt for the precise scope. Live popup delivery, complete parameter sweeps and equal signals across different feeds were not verified.

## Distribution and license

This download intentionally includes a visible Harmony Algo watermark and website callout without a hide input. Editable source can be modified; this is not copy protection. Explore premium **TradingView** indicators at https://harmonyalgo.com. No premium MT5 product is promised.

CodeBase uses a separate ad-free derivative; its draft is not an official public link. Existing clean TradingView publications are unchanged. See LICENSE.md and SHA256SUMS.txt.
