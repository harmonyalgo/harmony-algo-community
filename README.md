# Harmony Algo Community Indicators

Open-source chart tools for **TradingView (Pine Script)** and **MetaTrader 5 (MQL5)**. Each tool addresses a specific chart-analysis question, with documented calculations, settings and limitations.

## Indicator library

- [Breakout Acceptance Map](breakout-acceptance-map/): fixed-range breakout acceptance and retest lifecycle. TradingView Community Pine/TXT are compiled and checked; the MT5 source port is explicitly uncompiled and untested.

- [Pullback Recovery Map](pullback-recovery-map/): robust trend context with frozen pullback, closing recovery and guard-failure maps. Community Pine/TXT are compiled and checked; MT5 source is explicitly uncompiled and untested.

- [Trend Stress Compass](trend-stress-compass): Community Pine/TXT plus compiled and history-tested MT5 MQ5/EX5. See package validation scope.
- [Reversal Pressure](reversal-pressure): Community Pine/TXT plus compiled and history-tested MT5 MQ5/EX5. See package validation scope.
- [Intrinsic Trend Anatomy](intrinsic-trend-anatomy): Community Pine/TXT plus compiled and history-tested MT5 MQ5/EX5. See package validation scope.
- [Price Rank Shift](price-rank-shift): Community Pine/TXT plus compiled and history-tested MT5 MQ5/EX5. See package validation scope.
- [Target Race Map](target-race-map): Community Pine/TXT plus compiled and history-tested MT5 MQ5/EX5. See package validation scope.
- [Period Excursion Map](period-excursion-map): Community Pine/TXT plus compiled and history-tested MT5 MQ5/EX5. See package validation scope.

## What each package contains

- TradingView Community source in `.pine` and matching UTF-8 `.txt` format.
- An MQL5 Community source port when technically suitable. An `.ex5` binary is included only when compilation has been verified.
- A practical installation guide, input settings, signal timing, limitations, platform differences and separate test status.
- Real chart examples, labelled with the platform and context in which they were captured.

## Platforms and signals

Community tools may cover trend analysis, reversal context and chart overlays. Each indicator describes its own purpose; a trend tool is not automatically a reversal signal. Broker feeds, sessions, history and platform behavior can produce different readings. Cross-platform signal equality is not assumed. Uncompiled or untested sources are clearly identified.

These tools do not guarantee trading performance and are not complete execution strategies. Read each package guide before use.

## Harmony Algo

[Explore Harmony Algo](https://harmonyalgo.com). The existing premium product is for TradingView. This repository does not promise a premium MT5 product. Community branding is visible but editable in the source; it is not copy protection.

## Licensing

Follow the license and copyright notices included with each package. No premium or private product source is included in this repository.
