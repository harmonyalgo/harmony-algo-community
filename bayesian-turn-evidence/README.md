# Bayesian Turn Evidence [Harmony Algo]

A local reversal-attempt map with separate preparation, closing confirmation and frozen invalidation. Model odds are conditional evidence, not a win probability.

[Clean TradingView publication](https://www.tradingview.com/script/DWcNyPkH-Bayesian-Turn-Evidence-Revised-Harmony-Algo/), published 17 November 2026 at 09:06:33 UTC by Iamalala.

## Reading the chart

A small circle prepares an attempt after a fresh 12-bar extension and retreat against the independent trend context. The extreme, prior ATR and body-reclaim reference freeze. Closing returns compare continuation, temporary response and sustained reversal under prespecified Student-t models. Buy/Sell requires countertrend evidence, body reclaim and displacement; it stays on the actual confirmation candle. Failed, expired or overextended preparations cancel. A confirmed guard lasts until closing invalidation, retirement or a later attempt.

Defaults: 48 prior closes for trend context; 2.5 ATR context displacement; 3x turn/continuation evidence; maximum 1.75 ATR entry distance. ATR uses 21 bars. Preparations live at most 16 bars; guards retire after 32; attempts have a 12-bar cooldown. The calculation window is the last 6,000 bars with a 96-bar warmup. Use standard time-based candles.

## Installation

TradingView: paste the complete Community TXT or Pine file into a new Pine Editor indicator, save and add to chart. Do not combine it with the clean script on the same chart.

MT5: copy the Community MQ5/EX5 to MQL5/Indicators, refresh Navigator and attach to a standard chart. Popup alerts are off by default; when enabled, the seven event categories are evaluated on a newly closed bar. Attachment and history loading send no historical alerts. No orders are placed.

## Validation and limits

Pine: native compilation and four market/timeframe checks; 23,996 closed bars matched the independent model. The separate Community source matched all 40 native columns over 5,999 closed BTC4h bars, including seven alert conditions.

MT5: MetaEditor build 6230, zero errors/warnings. Actual EURUSD and GBPUSD H1/H4 cached charts were tested for both clean and branded derivatives: 318,016 numerical/state/event comparisons passed, plus 1,499 growing-history calls and an open-candle mutation/reset check. These are implementation checks, not predictive validation. The terminal was offline; live ticks and actual popup/server alert delivery were not verified.

No general accuracy or profitability improvement has been demonstrated. Broker prices, sessions, history origin and corrected data can change signals. MT5 uses arrows/text and lines instead of Pine label boxes and translucent fills; its optional popup alerts replace TradingView alert-condition selection. Exact cross-feed signal equality is not claimed. Frozen guards are descriptive, not broker stop orders. The open-bar price chart can move while model state waits for closing confirmation.

## Community and license

Visible Community branding is editable source code, not copy protection. [Harmony Algo](https://harmonyalgo.com) offers premium products for TradingView; no premium MT5 product is promised. Original implementation, copyright 2026 Harmony Algo; Mozilla Public License 2.0. See LICENSE.md and SHA256SUMS.txt. CodeBase uses a separate advertising-free MT5 derivative and is not included here as a branded download.
