# Target Race Map — Harmony Algo Community

Follow a closing breakout between fixed barriers and compare earlier surviving races.

A closing breakout of the prior 32-bar range starts a race to barriers 2.5 prior ATR above and below its origin, with a 48-bar deadline. Later bars distinguish upper first, lower first, expiry and ambiguous same-bar touches; observable opening gaps take priority.

Historical cohorts match breakout side, closed age and normalized price position. The current unresolved race cannot train its own evidence. Optional path weighting is off by default. Strong markers require additional sample, stability, progress and consecutive-close conditions. Endpoint frequencies, milestone summaries and retrospective checks are not win rates or guaranteed odds. Learning periods may show no supported estimates.

## Installation

TradingView: open `TargetRaceMap-Community.txt` (or `.pine`), copy the entire source into Pine Editor, save and Add to chart. [Clean original publication](https://www.tradingview.com/script/pSbfqdPf-Target-Race-Map-Harmony-Algo/).

MetaTrader 5: File → Open Data Folder → MQL5 → Indicators. Copy `TargetRaceMap-Community-MT5.ex5` there, refresh Navigator and attach it to a standard candle chart. `.mq5` is the editable source; compile with MetaEditor if changing it. Popup alerts are off by default; enable them only when desired. No historical alert replay is intended.

## MT5 inputs

| Input | Default | Meaning |
| --- | --- | --- |
| BreakoutLookback | 32 | Breakout Lookback |
| ATRLength | 14 | A T R Length |
| BreakoutBufferATR | 0.10 | Breakout Buffer A T R |
| BarrierDistanceATR | 2.5 | Barrier Distance A T R |
| DeadlineBars | 48 | Deadline Bars |
| CooldownBars | 8 | Cooldown Bars |
| ResolvedRacesInMemory | 400 | Resolved Races In Memory |
| MinimumSurvivingExamples | 20 | Minimum Surviving Examples |
| PositionTolerance | 0.50 | Position Tolerance |
| WeightSimilarPaths | false | Weight Similar Paths |
| VelocityWeightingWidth | 0.15 | Velocity Weighting Width |
| RecentMaps | 6 | Recent Maps |
| HistoricalLabels | 500 | Historical Labels |
| ShowEvidencePanel | true | Show Evidence Panel |
| PanelCorner | TopRight | Panel Corner |
| ShowLabels | true | Show Labels |
| EnablePopupAlerts | false | Enable Popup Alerts |

## Timing, differences and limits

Signals commit on completed bars, so confirmation adds delay. Changing inputs or source history recalculates history. MT5 uses terminal chart objects and local popup alerts rather than TradingView labels and hosted alerts. Broker sessions, OHLC history and timezone can change results. Period Excursion requires a chart timeframe strictly below its reference period. Historical statistics are descriptive and can be sparse; no forecast probability, profitability or performance guarantee is offered.

MetaEditor build 6230 compiled the included MQ5 with zero errors and warnings. Actual MT5 tests used EURUSD/GBPUSD H1/H4 loaded 2024 broker sample history, not live markets. Independent selected-field/event checks passed; see VALIDATION.txt for the precise scope. Live popup delivery, complete parameter sweeps and equal signals across different feeds were not verified.

## Distribution and license

This download intentionally includes a visible Harmony Algo watermark and website callout without a hide input. Editable source can be modified; this is not copy protection. Explore premium **TradingView** indicators at https://harmonyalgo.com. No premium MT5 product is promised.

CodeBase uses a separate ad-free derivative; its draft is not an official public link. Existing clean TradingView publications are unchanged. See LICENSE.md and SHA256SUMS.txt.
