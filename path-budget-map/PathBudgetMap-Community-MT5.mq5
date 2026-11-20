// Path Budget Map Community | Harmony Algo | harmonyalgo.com
// Copyright (c) 2026 Harmony Algo. Licensed under MPL-2.0.
#property copyright "Harmony Algo"
#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots 9
#property indicator_type1 DRAW_LINE
#property indicator_color1 C'111,76,151'
#property indicator_label1 "Prior 25th percentile"
#property indicator_type2 DRAW_LINE
#property indicator_color2 C'111,76,151'
#property indicator_label2 "Prior 75th percentile"
#property indicator_type3 DRAW_LINE
#property indicator_color3 C'148,101,214'
#property indicator_label3 "Prior median"
#property indicator_type4 DRAW_LINE
#property indicator_color4 C'32,185,197'
#property indicator_width4 2
#property indicator_label4 "Path traveled"
#property indicator_type5 DRAW_ARROW
#property indicator_color5 C'233,167,55'
#property indicator_label5 "Fast path"
#property indicator_type6 DRAW_NONE
#property indicator_label6 "Path traveled (including first bar)"
#property indicator_type7 DRAW_NONE
#property indicator_label7 "Matching prior days"
#property indicator_type8 DRAW_NONE
#property indicator_label8 "Fast path event"
#property indicator_type9 DRAW_NONE
#property indicator_label9 "Confirmed fast path candle"

input int ReferenceTradingDays = 30;
input int MinimumMatchingDays = 12;
input bool EnableTerminalAlerts = false;

const int MaxBars = 96;
const int CandleHistory = 5000;
const color Amber = C'233,167,55';

double lowerBand[], upperBand[], medianLine[], pathLine[], eventMarker[];
double actualPath[], matchingDays[], fastEvent[], highlighted[];
double completedPaths[60][96], currentPath[96];
int completedLengths[60];
datetime firstTime = 0, lastClosedTime = 0;
int nextRow = 0, slot = 0, streak = 0, previousDay = -1, processed = 0;
double cumulative = 0.0;
bool fullDay = false, validDay = true, fired = false;
string objectPrefix;

int DayKey(const datetime value)
{
   MqlDateTime parts;
   TimeToStruct(value, parts);
   return parts.year * 1000 + parts.day_of_year;
}

double Quantile(const double &sample[], const double fraction)
{
   const double index = ArraySize(sample) * fraction - 0.5;
   const int left = (int)MathFloor(index);
   return sample[left] + (index - left) * (sample[left + 1] - sample[left]);
}

void ResetModel()
{
   ArrayInitialize(completedLengths, 0);
   nextRow = 0;
   slot = 0;
   streak = 0;
   previousDay = -1;
   processed = 0;
   cumulative = 0.0;
   fullDay = false;
   validDay = true;
   fired = false;
   lastClosedTime = 0;
   ObjectsDeleteAll(0, objectPrefix + "C", 0);
}

void BeginDay(const int index, const int day)
{
   if(fullDay && validDay && slot > 0 && slot <= MaxBars)
   {
      for(int k = 0; k < slot; k++)
         completedPaths[nextRow][k] = currentPath[k];
      completedLengths[nextRow] = slot;
      nextRow = (nextRow + 1) % ReferenceTradingDays;
   }
   previousDay = day;
   slot = 0;
   streak = 0;
   cumulative = 0.0;
   fullDay = index > 0;
   validDay = true;
   fired = false;
}

void ClearBar(const int index)
{
   lowerBand[index] = EMPTY_VALUE;
   upperBand[index] = EMPTY_VALUE;
   medianLine[index] = EMPTY_VALUE;
   pathLine[index] = EMPTY_VALUE;
   eventMarker[index] = EMPTY_VALUE;
   actualPath[index] = EMPTY_VALUE;
   matchingDays[index] = 0.0;
   fastEvent[index] = 0.0;
   highlighted[index] = 0.0;
}

void StyleCandleObject(const string name, const bool filled)
{
   ObjectSetInteger(0, name, OBJPROP_COLOR, Amber);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   if(filled)
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, "\n");
}

void PaintCandle(const datetime time, const double open, const double high,
                 const double low, const double close)
{
   const string name = objectPrefix + "C" + (string)(long)time;
   const int halfWidth = PeriodSeconds() / 4;
   const double bodyHigh = MathMax(open, close);
   const double bodyLow = MathMin(open, close);
   if(high > low && ObjectCreate(0, name + "W", OBJ_TREND, 0, time, high, time, low))
   {
      ObjectSetInteger(0, name + "W", OBJPROP_RAY_LEFT, false);
      ObjectSetInteger(0, name + "W", OBJPROP_RAY_RIGHT, false);
      StyleCandleObject(name + "W", false);
   }
   if(bodyHigh > bodyLow &&
      ObjectCreate(0, name + "B", OBJ_RECTANGLE, 0,
                   time - halfWidth, bodyHigh, time + halfWidth, bodyLow))
      StyleCandleObject(name + "B", true);
   else if(bodyHigh == bodyLow &&
           ObjectCreate(0, name + "B", OBJ_TREND, 0,
                        time - halfWidth, bodyHigh, time + halfWidth, bodyHigh))
   {
      ObjectSetInteger(0, name + "B", OBJPROP_RAY_LEFT, false);
      ObjectSetInteger(0, name + "B", OBJPROP_RAY_RIGHT, false);
      StyleCandleObject(name + "B", false);
   }
}

void RemoveCandle(const datetime time)
{
   const string name = objectPrefix + "C" + (string)(long)time;
   ObjectDelete(0, name + "W");
   ObjectDelete(0, name + "B");
}


void PutBrandLabel(const string suffix, const string text, const int x,
                   const int y, const int size)
{
   const string name = objectPrefix + suffix;
   if(ObjectFind(0, name) < 0 && !ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
      return;
   const uint fg = (uint)ChartGetInteger(0, CHART_COLOR_FOREGROUND);
   const uint bg = (uint)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
   uint ink = 0;
   for(int shift = 0; shift <= 16; shift += 8)
      ink |= (((fg >> shift & 255) * 3 + (bg >> shift & 255) * 2) / 5) << shift;
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_CENTER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, (color)ink);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, "\n");
}

void PositionBrand()
{
   const int width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   const int height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   PutBrandLabel("brand", "Harmony Algo | harmonyalgo.com", width / 2, height / 2 - 15, 11);
   PutBrandLabel("cta", "Explore premium indicators at harmonyalgo.com",
                 width / 2, height / 2 + 15, 9);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
      PositionBrand();
}

int OnInit()
{
   const int seconds = PeriodSeconds();
   if(seconds < 15 * 60 || seconds > 60 * 60)
   {
      Print("Use a standard M15, M20, M30 or H1 chart.");
      return INIT_FAILED;
   }
   if(ReferenceTradingDays < 15 || ReferenceTradingDays > 60 ||
      MinimumMatchingDays < 5 || MinimumMatchingDays > 15)
      return INIT_PARAMETERS_INCORRECT;

   objectPrefix = "PBM:" + (string)GetMicrosecondCount() + ":";
   IndicatorSetString(INDICATOR_SHORTNAME, "Path Budget Map Community");
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   SetIndexBuffer(0, lowerBand, INDICATOR_DATA);
   SetIndexBuffer(1, upperBand, INDICATOR_DATA);
   SetIndexBuffer(2, medianLine, INDICATOR_DATA);
   SetIndexBuffer(3, pathLine, INDICATOR_DATA);
   SetIndexBuffer(4, eventMarker, INDICATOR_DATA);
   SetIndexBuffer(5, actualPath, INDICATOR_DATA);
   SetIndexBuffer(6, matchingDays, INDICATOR_DATA);
   SetIndexBuffer(7, fastEvent, INDICATOR_DATA);
   SetIndexBuffer(8, highlighted, INDICATOR_DATA);
   for(int plot = 0; plot < 9; plot++)
      PlotIndexSetDouble(plot, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(4, PLOT_ARROW, 117);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(objectPrefix != "")
      ObjectsDeleteAll(0, objectPrefix, 0);
}

int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[], const double &high[],
                const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
   if(rates_total < 2)
      return 0;
   ArraySetAsSeries(time, false);
   ArraySetAsSeries(open, false);
   ArraySetAsSeries(high, false);
   ArraySetAsSeries(low, false);
   ArraySetAsSeries(close, false);

   const bool rebuild = prev_calculated == 0 || firstTime != time[0] ||
                        processed >= rates_total ||
                        (processed > 0 && time[processed - 1] != lastClosedTime);
   if(rebuild)
   {
      ResetModel();
      firstTime = time[0];
   }

   const int closed = rates_total - 1;
   double sample[];
   for(int index = processed; index < closed; index++)
   {
      ClearBar(index);
      const int day = DayKey(time[index]);
      const bool newDay = day != previousDay;
      if(newDay)
         BeginDay(index, day);

      const double prior = slot == 0 ? open[index] : close[index - 1];
      validDay = validDay && MathIsValidNumber(prior) && prior > 0.0 &&
                 MathIsValidNumber(close[index]) && close[index] > 0.0;
      if(fullDay && validDay && slot < MaxBars)
      {
         cumulative += 100.0 * MathAbs(MathLog(close[index] / prior));
         currentPath[slot] = cumulative;
         actualPath[index] = cumulative;
         if(!newDay)
            pathLine[index] = cumulative;

         ArrayResize(sample, ReferenceTradingDays);
         int count = 0;
         for(int row = 0; row < ReferenceTradingDays; row++)
            if(completedLengths[row] > slot)
               sample[count++] = completedPaths[row][slot];
         matchingDays[index] = count;

         bool fast = false;
         if(count >= MinimumMatchingDays)
         {
            ArrayResize(sample, count);
            ArraySort(sample);
            const double median = Quantile(sample, 0.50);
            const double upper = Quantile(sample, 0.75);
            if(!newDay)
            {
               lowerBand[index] = Quantile(sample, 0.25);
               upperBand[index] = upper;
               medianLine[index] = median;
            }
            fast = slot >= 3 && median > 0.0 && cumulative > upper &&
                   cumulative >= 1.5 * median;
         }
         streak = fast ? streak + 1 : 0;
         if(streak >= 3)
         {
            highlighted[index] = 1.0;
            if(index >= closed - CandleHistory)
               PaintCandle(time[index], open[index], high[index], low[index], close[index]);
         }
         if(streak == 3 && !fired)
         {
            fired = true;
            fastEvent[index] = 1.0;
            eventMarker[index] = cumulative;
            if(!rebuild && index == closed - 1 && EnableTerminalAlerts)
               Alert("Path Budget Map: unusually large cumulative path on ", _Symbol,
                     " (", EnumToString(_Period), ").");
         }
      }
      if(!rebuild && index >= CandleHistory && highlighted[index - CandleHistory] == 1.0)
         RemoveCandle(time[index - CandleHistory]);
      slot++;
   }
   processed = closed;
   lastClosedTime = time[closed - 1];
   ClearBar(closed);
   if(rebuild)
      PositionBrand();
   return rates_total;
}
