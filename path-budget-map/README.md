# Path Budget Map

Compare cumulative price movement with previous trading days at the same bar number. The cyan path sums absolute log returns after the first bar opens. The purple band is the middle half of the matched history. The default uses up to 30 completed trading days and needs 12 matching observations.

Amber candles start at the third consecutive qualifying close and continue while the path stays above the upper quartile and at least 1.5 times its historical median. A diamond and alert condition mark only the first confirmation per trading day. The indicator describes activity without assigning a direction.

## Install

- **TradingView** — Open the Pine Editor, paste the complete Community TXT or Pine source and add it to a standard 15–60 minute chart. Select **Fast path** and **Once Per Bar Close** when creating an alert. [Clean public TradingView script](https://www.tradingview.com/script/Jr5nEeZC-Path-Budget-Map-Harmony-Algo/)
- **MetaTrader 5** — Follow the platform status in [Verification.txt](Verification.txt). Place the EX5 in `MQL5/Indicators`, refresh Navigator and attach it to an M15, M20, M30 or H1 candle chart. Enable terminal pop-up alerts in the indicator inputs if wanted.

MT5 shows the reference quartiles as lines and uses the broker's server date. A new bar confirms the preceding bar. Chart overlays color up to the most recent 5,000 bars. Sessions, feeds and available bars can change which readings appear on each platform.

[TradingView chart, AAPL 15m](PathBudgetMap-TradingView.png) · [MT5 chart, EURUSD M15](PathBudgetMap-MT5.png) · [MT5 chart, GBPUSD H1](PathBudgetMap-MT5-GBPUSD.png)

This Community package uses the MPL-2.0 terms in [LICENSE.md](LICENSE.md). Its source branding is editable. [Harmony Algo](https://harmonyalgo.com/) offers a separate premium indicator for TradingView.
