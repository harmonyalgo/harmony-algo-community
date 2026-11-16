# Intrinsic Trend Anatomy — Harmony Algo Community

Read event-based trend structure, pullback recovery and historically unusual excursions.

Three directional-change clocks operate on logarithmic closing prices at micro, structure and broad scales. A reversal of the structure clock confirms a structural direction change. Pullbacks freeze an anchor and scale, then compare their depth and accumulated path with earlier completed excursions.

Colored candles distinguish aligned structure from pullback or mixed scales. Trend, Resume and Stress labels appear when their closing conditions become known; they are not moved back to earlier extremes. Historical ranks require enough completed samples and are not reversal probabilities. The model is sensitive to available history and feed corrections.

## Installation

TradingView: open `IntrinsicTrendAnatomy-Community.txt` (or `.pine`), copy the entire source into Pine Editor, save and Add to chart. [Clean original publication](https://www.tradingview.com/script/dLZvY4Nn-Intrinsic-Trend-Anatomy-Harmony-Algo/).

MetaTrader 5: File → Open Data Folder → MQL5 → Indicators. Copy `IntrinsicTrendAnatomy-Community-MT5.ex5` there, refresh Navigator and attach it to a standard candle chart. `.mq5` is the editable source; compile with MetaEditor if changing it. Popup alerts are off by default; enable them only when desired. No historical alert replay is intended.

## MT5 inputs

| Input | Default | Meaning |
| --- | --- | --- |
| VolatilityReference | 30 | Volatility Reference |
| StructureDistanceATR | 3.0 | Structure Distance A T R |
| MicroStructureScale | 0.35 | Micro Structure Scale |
| BroadStructureScale | 2.0 | Broad Structure Scale |
| CompletedExcursionsRetained | 80 | Completed Excursions Retained |
| MinimumReferenceSamples | 12 | Minimum Reference Samples |
| ColorCandles | true | Color Candles |
| ShowBoundary | true | Show Boundary |
| ShowCorridor | true | Show Corridor |
| ShowEvents | true | Show Events |
| ShowPanel | true | Show Panel |
| UpColor | C'1,130,8' | Up Color |
| DownColor | C'209,34,8' | Down Color |
| MixedColor | C'127,73,222' | Mixed Color |
| EnablePopupAlerts | false | Enable Popup Alerts |

## Timing, differences and limits

Signals commit on completed bars, so confirmation adds delay. Changing inputs or source history recalculates history. MT5 uses terminal chart objects and local popup alerts rather than TradingView labels and hosted alerts. Broker sessions, OHLC history and timezone can change results. Colored candle overlays and committed events update at the next bar; current-bar overlay OHLC is not a live tick display. Period Excursion requires a chart timeframe strictly below its reference period. Historical statistics are descriptive and can be sparse; no forecast probability, profitability or performance guarantee is offered.

MetaEditor build 6230 compiled the included MQ5 with zero errors and warnings. Actual MT5 tests used EURUSD/GBPUSD H1/H4 loaded 2024 broker sample history, not live markets. Independent selected-field/event checks passed; see VALIDATION.txt for the precise scope. Live popup delivery, complete parameter sweeps and equal signals across different feeds were not verified.

## Distribution and license

This download intentionally includes a visible Harmony Algo watermark and website callout without a hide input. Editable source can be modified; this is not copy protection. Explore premium **TradingView** indicators at https://harmonyalgo.com. No premium MT5 product is promised.

CodeBase uses a separate ad-free derivative; its draft is not an official public link. Existing clean TradingView publications are unchanged. See LICENSE.md and SHA256SUMS.txt.
