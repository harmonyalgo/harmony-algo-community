# Period Excursion Map — Harmony Algo Community

Map historical upper and lower excursions around the previous reference-period close.

The default reference is daily, with up to 80 completed periods in memory. Earlier high and low excursions are normalized by the volatility known at their start. Once at least 20 usable examples exist, median and outer-percentile levels freeze around the prior period close for the new period. Weekly and monthly references are also available.

Use a chart timeframe strictly below the reference period. Only the first confirmed close beyond each outer level creates its event in that period. These are historical context levels, not targets or coverage guarantees. Broker timezone, session boundaries and available higher-timeframe history can change the map.

## Installation

TradingView: open `PeriodExcursionMap-Community.txt` (or `.pine`), copy the entire source into Pine Editor, save and Add to chart. [Clean original publication](https://www.tradingview.com/script/YHqfB3Ej-Period-Excursion-Map-Harmony-Algo/).

MetaTrader 5: File → Open Data Folder → MQL5 → Indicators. Copy `PeriodExcursionMap-Community-MT5.ex5` there, refresh Navigator and attach it to a standard candle chart. `.mq5` is the editable source; compile with MetaEditor if changing it. Popup alerts are off by default; enable them only when desired. No historical alert replay is intended.

## MT5 inputs

| Input | Default | Meaning |
| --- | --- | --- |
| ReferencePeriod | Daily | Reference Period |
| CompletedPeriodsInMemory | 80 | Completed Periods In Memory |
| ReferenceATRLength | 20 | Reference A T R Length |
| OuterPercentile | 80 | Outer Percentile |
| ShowContextPanel | true | Show Context Panel |
| ShowEvents | true | Show Events |
| UpperColor | C'1,130,8' | Upper Color |
| LowerColor | C'209,34,8' | Lower Color |
| EnablePopupAlerts | false | Enable Popup Alerts |

## Timing, differences and limits

Signals commit on completed bars, so confirmation adds delay. Changing inputs or source history recalculates history. MT5 uses terminal chart objects and local popup alerts rather than TradingView labels and hosted alerts. Broker sessions, OHLC history and timezone can change results. Period Excursion requires a chart timeframe strictly below its reference period. Historical statistics are descriptive and can be sparse; no forecast probability, profitability or performance guarantee is offered.

MetaEditor build 6230 compiled the included MQ5 with zero errors and warnings. Actual MT5 tests used EURUSD/GBPUSD H1/H4 loaded 2024 broker sample history, not live markets. Independent selected-field/event checks passed; see VALIDATION.txt for the precise scope. Live popup delivery, complete parameter sweeps and equal signals across different feeds were not verified.

## Distribution and license

This download intentionally includes a visible Harmony Algo watermark and website callout without a hide input. Editable source can be modified; this is not copy protection. Explore premium **TradingView** indicators at https://harmonyalgo.com. No premium MT5 product is promised.

CodeBase uses a separate ad-free derivative; its draft is not an official public link. Existing clean TradingView publications are unchanged. See LICENSE.md and SHA256SUMS.txt.

## MT5 validation fix — 16 November 2026

On a chart period equal to or higher than the reference period, MT5 now remains attached in an explicit inactive state with a lower-timeframe notice, empty levels and zero events. It does not silently change the reference period. Supported-timeframe calculations and inputs are unchanged.

The updated native model matched all original exported fields on EURUSD/GBPUSD H1/H4 loaded sample history (12 cuts across the three tools). Stress/Reversal also passed native MQL5 growing-history and explicit-reset comparisons across 1,499 successive calls per tool. The calculation tests suppress graphics; actual indicator charts were tested separately. Period additionally passed native daily-chart attachment with empty levels and zero events. CodeBase server validation is separate and still pending.
