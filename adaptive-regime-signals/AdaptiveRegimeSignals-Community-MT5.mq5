// Adaptive Regime Signals Community | Harmony Algo | harmonyalgo.com
// Copyright (c) 2026 Harmony Algo. Licensed under MPL-2.0.
#property copyright "Harmony Algo"
#property indicator_chart_window
#property indicator_buffers 11
#property indicator_plots 11
#property indicator_type1 DRAW_LINE
#property indicator_color1 C'144,100,216'
#property indicator_label1 "Range upper"
#property indicator_type2 DRAW_LINE
#property indicator_color2 C'144,100,216'
#property indicator_label2 "Range lower"
#property indicator_type3 DRAW_LINE
#property indicator_color3 C'84,148,166'
#property indicator_label3 "Trend guide"
#property indicator_type4 DRAW_ARROW
#property indicator_color4 C'1,130,8'
#property indicator_label4 "Range Buy"
#property indicator_type5 DRAW_ARROW
#property indicator_color5 C'209,34,8'
#property indicator_label5 "Range Sell"
#property indicator_type6 DRAW_ARROW
#property indicator_color6 C'1,130,8'
#property indicator_label6 "Trend Buy"
#property indicator_type7 DRAW_ARROW
#property indicator_color7 C'209,34,8'
#property indicator_label7 "Trend Sell"
#property indicator_type8 DRAW_NONE
#property indicator_label8 "Regime code"
#property indicator_type9 DRAW_NONE
#property indicator_label9 "Signal code"
#property indicator_type10 DRAW_NONE
#property indicator_label10 "Signal invalidation"
#property indicator_type11 DRAW_NONE
#property indicator_label11 "Signal reference objective"

input bool ShowRegimeGuides = true;
input bool ShowSignalInvalidation = true;
input bool ShowCurrentRegime = true;
input bool EnableTerminalAlerts = false;
input bool EnablePushNotifications = false;

const int RangeMode = 1, UpMode = 2, DownMode = -2;
const color BuyColor = C'1,130,8', SellColor = C'209,34,8', BandColor = C'144,100,216';

double UpperBand[], LowerBand[], TrendGuide[], RangeBuy[], RangeSell[], TrendBuy[], TrendSell[];
double RegimeCode[], SignalCode[], Invalidation[], Objective[];

struct PriceBar
{
   datetime time;
   double high, low, close, tr, atr, ema, lo, hi;
};
struct RegimeState
{
   int active, candidate, streak;
};

PriceBar localBars[], contextBars[];
int localModes[], contextModes[];
PriceBar prevRecord;
RegimeState localState;
ENUM_TIMEFRAMES contextTf = PERIOD_CURRENT;
bool intraday;
double tick;
int structureLength, swingBars, trendExpiry, rangeExpiry, cooldown;
int processed = 0, phase = 0, side = 0, started = -1, phaseAt = -1;
int lastSignal = -100, lastShock = -100, previousMode = 0;
int recentHighAt = -1, recentLowAt = -1, closingHighAt = -1, closingLowAt = -1;
double recentHigh = 0, recentLow = 0, closingHigh = 0, closingLow = 0;
double longGuard = 0, shortGuard = 0, edge = 0, limitPrice = 0, protectedSwing = 0, extreme = 0, threshold = 0, basis = 0;
bool longIntact = false, shortIntact = false, hasThreshold = false;
datetime firstTime = 0, lastHandled = 0;
string prefix;

double Quantile(const double &sorted[], int length, double fraction)
{
   double index = (length - 1) * fraction;
   int a = (int)index;
   return sorted[a] + (index - a) * (sorted[a + 1] - sorted[a]);
}

int ComputeBar(PriceBar &bars[], int i, datetime stamp, double high, double low, double close,
               int length, RegimeState &state)
{
   PriceBar bar;
   ZeroMemory(bar);
   bar.time = stamp;
   bar.high = high;
   bar.low = low;
   bar.close = close;
   bar.tr = i == 0 ? high - low : MathMax(high, bars[i-1].close) - MathMin(low, bars[i-1].close);
   bar.ema = i == 0 ? close : bars[i-1].ema + (close - bars[i-1].ema) * (2.0 / 21.0);
   if(i == 20)
   {
      bar.atr = bar.tr;
      for(int k=0; k<i; k++) bar.atr += bars[k].tr;
      bar.atr /= 21.0;
   }
   else if(i > 20)
      bar.atr = (bars[i-1].atr * 20.0 + bar.tr) / 21.0;
   bars[i] = bar;

   if(i < length || bar.atr < tick || i <= 20)
   {
      ZeroMemory(state);
      return 0;
   }
   double sorted[];
   ArrayResize(sorted,length);
   double travel = 0, numerator = 0, denominator = 0, ahead = 0, behind = 0;
   int half = length / 2;
   double meanIndex = (length - 1) * 0.5;
   for(int k=0; k<length; k++)
   {
      int j = i - length + 1 + k;
      double price = bars[j].close;
      sorted[k] = price;
      double weight = k - meanIndex;
      numerator += weight * (price - bars[i-length+1].close);
      denominator += weight * weight;
      travel += MathAbs(price - bars[j-1].close);
      if(k >= length-half) ahead += price;
      else if(k >= length-2*half) behind += price;
   }
   ArraySort(sorted);
   bar.lo = Quantile(sorted,length,.15);
   bar.hi = Quantile(sorted,length,.85);
   bars[i] = bar;
   double width = bar.hi - bar.lo;
   double efficiency = travel > 0 ? MathAbs(close-bars[i-length].close) / travel : 0;
   double displacement = numerator / denominator * (length - 1) / bar.atr;
   double shift = MathAbs(ahead-behind) / half;
   bool rangeEntry = efficiency <= .32 && MathAbs(displacement) <= 2.1 && width >= 1.8*bar.atr && shift <= width*.28;
   bool rangeHold = efficiency <= .43 && MathAbs(displacement) <= 3.0 && width >= 1.4*bar.atr && shift <= width*.39;
   int proposed = rangeEntry ? RangeMode : efficiency >= .24 && displacement >= 2.5 ? UpMode :
                  efficiency >= .24 && displacement <= -2.5 ? DownMode : 0;
   if(bar.tr > 4.0 * bars[i-1].atr)
      ZeroMemory(state);
   else if(state.active != 0)
   {
      bool holds = state.active == RangeMode ? rangeHold : efficiency >= .15 && (state.active > 0 ? displacement : -displacement) >= 1.25;
      if(!holds) ZeroMemory(state);
   }
   else
   {
      state.streak = proposed == 0 ? 0 : proposed == state.candidate ? state.streak+1 : 1;
      state.candidate = proposed;
      if(state.streak >= 2) state.active = proposed;
   }
   return state.active;
}

bool LoadContext(datetime start, datetime finish)
{
   if(!intraday) return true;
   MqlRates rates[];
   datetime history = start - (datetime)((long)PeriodSeconds(contextTf)*160);
   int n = CopyRates(_Symbol,contextTf,history,finish,rates);
   if(n < 35) return false;
   ArrayResize(contextBars,n);
   ArrayResize(contextModes,n);
   RegimeState state;
   ZeroMemory(state);
   for(int j=0; j<n; j++)
      contextModes[j] = ComputeBar(contextBars,j,rates[j].time,rates[j].high,rates[j].low,rates[j].close,30,state);
   return true;
}

int PreviousContext(datetime stamp)
{
   int a=0,b=ArraySize(contextBars);
   while(a<b)
   {
      int mid=(a+b)/2;
      if(contextBars[mid].time<=stamp) a=mid+1; else b=mid;
   }
   return a>=2 ? contextModes[a-2] : 0;
}

bool CompletedEdgeTests(int i, double lo, double hi)
{
   double width=hi-lo, zone=.16*width, departure=.32*width;
   int visited=0, lowTests=0, highTests=0;
   for(int k=i-structureLength; k<i; k++)
   {
      PriceBar b=localBars[k];
      if(visited==-1 && b.close>=lo+departure) {lowTests++;visited=0;}
      else if(visited==1 && b.close<=hi-departure) {highTests++;visited=0;}
      if(visited==0)
      {
         bool l=b.low<=lo+zone, h=b.high>=hi-zone;
         if(l!=h) visited=l?-1:1;
      }
   }
   return lowTests>=2 && highTests>=2;
}

bool Pivot(int i, int radius, int direction, bool closing, double &level)
{
   if(i<2*radius) return false;
   int mid=i-radius;
   double value=closing?localBars[mid].close:direction==1?localBars[mid].high:localBars[mid].low;
   for(int j=mid-radius;j<=i;j++)
   {
      if(j==mid) continue;
      double p=closing?localBars[j].close:direction==1?localBars[j].high:localBars[j].low;
      if(direction*(p-value)>0 || (j>mid && p==value)) return false;
   }
   level=value;
   return true;
}

void UpdateSwings(int i)
{
   double ph=0,pl=0,ch=0,cl=0;
   bool hasHigh=Pivot(i,swingBars,1,false,ph), hasLow=Pivot(i,swingBars,-1,false,pl);
   if(Pivot(i,1,1,true,ch)) {closingHigh=ch;closingHighAt=i;}
   if(Pivot(i,1,-1,true,cl)) {closingLow=cl;closingLowAt=i;}
   if(hasHigh)
   {
      longGuard=recentLow;
      longIntact=recentLowAt>=0;
      for(int j=i-swingBars;j<=i;j++) if(localBars[j].low<=longGuard) longIntact=false;
   }
   else if(localBars[i].low<=longGuard) longIntact=false;
   if(hasLow)
   {
      shortGuard=recentHigh;
      shortIntact=recentHighAt>=0;
      for(int j=i-swingBars;j<=i;j++) if(localBars[j].high>=shortGuard) shortIntact=false;
   }
   else if(localBars[i].high>=shortGuard) shortIntact=false;
   if(hasHigh) {recentHigh=ph;recentHighAt=i;}
   if(hasLow) {recentLow=pl;recentLowAt=i;}
}

bool RangeRoom(double entry, double guard)
{
   double risk=side*(entry-guard), room=side*(limitPrice-entry);
   return risk>=tick && room>=MathMax(.35*basis,.80*risk);
}

void Emit(int i, int signal, double guard, double goal)
{
   SignalCode[i]=signal;
   Invalidation[i]=guard;
   Objective[i]=goal;
   lastSignal=i;
}

void Advance(int i, int mode, PriceBar &b, PriceBar &prior)
{
   bool shock=b.tr>3.75*prior.atr;
   bool ready=i>structureLength && prior.atr>=tick && !shock;
   if(shock) lastShock=i;
   if(!ready || mode==0 || mode!=previousMode) {phase=0; return;}
   double adverse=side==1?b.low:b.high, favorable=side==1?b.high:b.low;
   if(phase==1)
   {
      if(i-phaseAt>rangeExpiry || side*(favorable-limitPrice)>=0) {phase=0;return;}
      extreme=side==1?MathMin(extreme,b.low):MathMax(extreme,b.high);
      if(side*(b.close-edge)>=.05*basis)
      {
         if(side*(b.close-edge)>=.10*basis && side*(b.close-prior.close)>=.25*basis)
         {
            double guard=extreme-side*.08*basis;
            if(RangeRoom(b.close,guard)) Emit(i,side,guard,limitPrice);
            phase=0;
         }
         else {threshold=b.close;phaseAt=i;phase=2;}
      }
      return;
   }
   if(phase==2)
   {
      double guard=extreme-side*.08*basis;
      if(side*(adverse-guard)<=0 || side*(favorable-limitPrice)>=0 || i-phaseAt>rangeExpiry) phase=0;
      else if(side*(b.close-threshold)>=.10*basis)
      {
         if(RangeRoom(b.close,guard)) Emit(i,side,guard,limitPrice);
         phase=0;
      }
      return;
   }
   if(phase==3)
   {
      if(side*(adverse-protectedSwing)<=0 || side*(favorable-limitPrice)>=0 || i-started>trendExpiry) {phase=0;return;}
      extreme=side==1?MathMin(extreme,b.low):MathMax(extreme,b.high);
      if(hasThreshold && side*(b.close-threshold)>=.05*basis)
      {
         double guard=extreme-side*.08*basis, risk=side*(b.close-guard), room=side*(limitPrice-b.close);
         if(risk>=tick && room>=MathMax(.30*basis,risk)) Emit(i,2*side,guard,limitPrice);
         phase=0;
      }
      else if(i-started>=2 && side*(prior.close-localBars[i-2].close)>0 && side*(b.close-prior.close)<0)
      {threshold=prior.close;hasThreshold=true;}
      return;
   }
   if(i-lastSignal<=cooldown || i-lastShock<=2) return;
   double unit=prior.atr, width=prior.hi-prior.lo;
   if(mode==RangeMode && width>=2.2*unit && width<=16.0*unit)
   {
      bool inside=prior.close>=prior.lo-.15*unit && prior.close<=prior.hi+.15*unit;
      bool sweepLow=b.low<=prior.lo-.13*unit, sweepHigh=b.high>=prior.hi+.13*unit;
      if(inside && sweepLow!=sweepHigh && CompletedEdgeTests(i,prior.lo,prior.hi))
      {
         side=sweepLow?1:-1;
         edge=sweepLow?prior.lo:prior.hi;
         limitPrice=(prior.lo+prior.hi)*.5;
         basis=unit;
         extreme=sweepLow?b.low:b.high;
         if(side*((side==1?b.high:b.low)-limitPrice)<0)
         {
            started=i;phaseAt=i;
            phase=side*(b.close-edge)>=.05*basis?2:1;
            threshold=b.close;
         }
      }
   }
   else if(MathAbs(mode)==2)
   {
      int direction=mode==UpMode?1:-1;
      double peak=direction==1?recentHigh:recentLow, guard=direction==1?longGuard:shortGuard;
      adverse=direction==1?b.low:b.high; favorable=direction==1?b.high:b.low;
      int recentAt=direction==1?recentHighAt:recentLowAt, age=i-recentAt;
      double impulse=direction*(peak-guard), depth=direction*(peak-adverse);
      bool intact=direction==1?longIntact:shortIntact;
      if(intact && recentAt>=0 && age<=structureLength && impulse>=1.8*unit && depth>=.60*unit &&
         depth<=.82*impulse && direction*(favorable-peak)<0 && direction*(b.close-prior.close)<0)
      {
         side=direction;protectedSwing=guard;limitPrice=peak;basis=unit;extreme=adverse;
         int closingAt=direction==1?closingHighAt:closingLowAt;
         double closingSwing=direction==1?closingHigh:closingLow;
         hasThreshold=closingAt>=0 && i-closingAt+1<age+swingBars &&
                      direction*(peak-closingSwing)>=.20*unit && direction*(closingSwing-b.close)>0;
         threshold=closingSwing;started=i;phase=3;
      }
   }
}

void ClearBar(int i)
{
   UpperBand[i]=EMPTY_VALUE;LowerBand[i]=EMPTY_VALUE;TrendGuide[i]=EMPTY_VALUE;
   RangeBuy[i]=EMPTY_VALUE;RangeSell[i]=EMPTY_VALUE;TrendBuy[i]=EMPTY_VALUE;TrendSell[i]=EMPTY_VALUE;
   RegimeCode[i]=0;SignalCode[i]=0;Invalidation[i]=EMPTY_VALUE;Objective[i]=EMPTY_VALUE;
}

string EventName(int signal)
{
   if(signal==1) return "Range Buy";
   if(signal==-1) return "Range Sell";
   if(signal==2) return "Trend Buy";
   return "Trend Sell";
}

void ChartLabel(string suffix,string label,int anchor,int x,int y,int size,color ink)
{
   string key=prefix+suffix;
   if(ObjectFind(0,key)<0 && !ObjectCreate(0,key,OBJ_LABEL,0,0,0)) return;
   ObjectSetInteger(0,key,OBJPROP_CORNER,anchor==ANCHOR_RIGHT_UPPER?CORNER_RIGHT_UPPER:CORNER_LEFT_UPPER);
   ObjectSetInteger(0,key,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,key,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,key,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,key,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,key,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,key,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,key,OBJPROP_HIDDEN,true);
   ObjectSetString(0,key,OBJPROP_TEXT,label);
}

void DrawStatus()
{
   string context=intraday?StringSubstr(EnumToString(contextTf),7)+" context":"Chart TF";
   string state=previousMode==RangeMode?"Range":previousMode==UpMode?"Uptrend":previousMode==DownMode?"Downtrend":"Waiting";
   color ink=(color)ChartGetInteger(0,CHART_COLOR_FOREGROUND);
   uint foreground=(uint)ink, background=(uint)ChartGetInteger(0,CHART_COLOR_BACKGROUND), blend=0;
   for(int shift=0;shift<24;shift+=8)
      blend|=((((foreground>>shift)&255)*3+((background>>shift)&255)*2)/5)<<shift;
   int x=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)/2;
   int y=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS)/2;
   ChartLabel("center", "Harmony Algo | harmonyalgo.com",ANCHOR_CENTER,x,y,12,(color)blend);
   ChartLabel("cta", "Explore premium indicators at harmonyalgo.com",ANCHOR_CENTER,x,y+19,9,(color)blend);
   ChartLabel("header", "Harmony Algo | harmonyalgo.com",ANCHOR_RIGHT_UPPER,10,15,9,ink);
   if(ShowCurrentRegime) ChartLabel("status",state+" | "+context,ANCHOR_RIGHT_UPPER,10,32,9,ink);
}

void DrawSignal(int i,int total)
{
   int signal=(int)SignalCode[i];
   if(signal==0 || total-i>3000) return;
   PriceBar bar=localBars[i];
   color ink=signal>0?BuyColor:SellColor;
   string name=prefix+"label"+(string)(long)bar.time;
   double p=signal>0?bar.low-.42*bar.atr:bar.high+.42*bar.atr;
   if(ObjectFind(0,name)<0 && ObjectCreate(0,name,OBJ_TEXT,0,bar.time,p))
   {
      ObjectSetString(0,name,OBJPROP_TEXT,EventName(signal));
      ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,signal>0?ANCHOR_UPPER:ANCHOR_LOWER);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   }
   if(!ShowSignalInvalidation) return;
   string line=prefix+"guard"+(string)(long)bar.time;
   datetime end=bar.time+(datetime)((long)PeriodSeconds()*cooldown);
   if(ObjectFind(0,line)<0 && ObjectCreate(0,line,OBJ_TREND,0,bar.time,Invalidation[i],end,Invalidation[i]))
   {
      ObjectSetInteger(0,line,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(0,line,OBJPROP_RAY_LEFT,false);
      ObjectSetInteger(0,line,OBJPROP_COLOR,ink);
      ObjectSetInteger(0,line,OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(0,line,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,line,OBJPROP_HIDDEN,true);
   }
}

void Reset()
{
   processed=0;previousMode=0;phase=0;lastShock=-100;lastSignal=-100;
   recentHighAt=-1;recentLowAt=-1;closingHighAt=-1;closingLowAt=-1;
   recentHigh=0;recentLow=0;closingHigh=0;closingLow=0;
   longIntact=false;shortIntact=false;
   ZeroMemory(localState);
   ObjectsDeleteAll(0,prefix);
}

int OnInit()
{
   prefix="ARS_"+IntegerToString(GetMicrosecondCount())+"_";
   IndicatorSetString(INDICATOR_SHORTNAME,"Adaptive Regime Signals Community");
   tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0) tick=_Point;
   int seconds=PeriodSeconds();
   intraday=seconds>0 && seconds<86400;
   if(intraday) contextTf=seconds<300?PERIOD_M15:seconds<=900?PERIOD_H1:seconds<=3600?PERIOD_H4:PERIOD_D1;
   structureLength=intraday?(seconds<=900?44:40):_Period==PERIOD_D1?34:_Period==PERIOD_W1?28:24;
   swingBars=intraday?2:1;
   trendExpiry=intraday?13:_Period==PERIOD_D1?9:7;
   rangeExpiry=intraday?5:_Period==PERIOD_D1?4:3;
   cooldown=intraday?8:_Period==PERIOD_D1?5:3;
   SetIndexBuffer(0,UpperBand,INDICATOR_DATA);SetIndexBuffer(1,LowerBand,INDICATOR_DATA);
   SetIndexBuffer(2,TrendGuide,INDICATOR_DATA);SetIndexBuffer(3,RangeBuy,INDICATOR_DATA);
   SetIndexBuffer(4,RangeSell,INDICATOR_DATA);SetIndexBuffer(5,TrendBuy,INDICATOR_DATA);
   SetIndexBuffer(6,TrendSell,INDICATOR_DATA);SetIndexBuffer(7,RegimeCode,INDICATOR_DATA);
   SetIndexBuffer(8,SignalCode,INDICATOR_DATA);SetIndexBuffer(9,Invalidation,INDICATOR_DATA);
   SetIndexBuffer(10,Objective,INDICATOR_DATA);
   for(int i=0;i<11;i++) PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetInteger(3,PLOT_ARROW,217);PlotIndexSetInteger(4,PLOT_ARROW,218);
   PlotIndexSetInteger(5,PLOT_ARROW,233);PlotIndexSetInteger(6,PLOT_ARROW,234);
   return INIT_SUCCEEDED;
}

int OnCalculate(const int total,const int prev,const datetime &time[],const double &open[],
                const double &high[],const double &low[],const double &close[],
                const long &ticks[],const long &volume[],const int &spread[])
{
   if(total<structureLength+4) return 0;
   ArraySetAsSeries(time,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
   bool reset=prev==0 || time[0]!=firstTime || processed>total-1;
   if(!reset && processed==total-1) return total;
   if(!LoadContext(time[0],time[total-1])) return prev;
   if(reset) {Reset();firstTime=time[0];}
   ArrayResize(localBars,total,512);ArrayResize(localModes,total,512);
   for(int i=processed;i<total-1;i++)
   {
      ClearBar(i);
      localModes[i]=ComputeBar(localBars,i,time[i],high[i],low[i],close[i],structureLength,localState);
      UpdateSwings(i);
      if(i==0) continue;
      PriceBar old=localBars[i-1],now=localBars[i];
      int context=intraday?PreviousContext(now.time):localModes[i-1];
      int mode=intraday && context==0 && localModes[i-1]==RangeMode?RangeMode:context;
      RegimeCode[i]=mode;
      if(ShowRegimeGuides && mode==RangeMode && old.hi>old.lo) {UpperBand[i]=old.hi;LowerBand[i]=old.lo;}
      if(ShowRegimeGuides && MathAbs(mode)==2) TrendGuide[i]=old.ema;
      Advance(i,mode,now,old);
      previousMode=mode;
      int event=(int)SignalCode[i];
      if(event==1) RangeBuy[i]=now.low-.20*old.atr;
      else if(event==-1) RangeSell[i]=now.high+.20*old.atr;
      else if(event==2) TrendBuy[i]=now.low-.20*old.atr;
      else if(event==-2) TrendSell[i]=now.high+.20*old.atr;
      if(event!=0) DrawSignal(i,total);
   }
   processed=total-1;
   ClearBar(total-1);
   RegimeCode[total-1]=previousMode;
   DrawStatus();
   datetime newest=time[total-2];
   int event=(int)SignalCode[total-2];
   if(!reset && newest>lastHandled && event!=0 && (EnableTerminalAlerts || EnablePushNotifications))
   {
      string message=EventName(event)+" | "+_Symbol+" "+EnumToString(_Period)+" | "+DoubleToString(close[total-2],_Digits);
      if(EnableTerminalAlerts) Alert(message);
      if(EnablePushNotifications) SendNotification(message);
   }
   lastHandled=newest;
   return total;
}

void OnChartEvent(const int id,const long &l,const double &d,const string &s)
{
   if(id==CHARTEVENT_CHART_CHANGE) DrawStatus();
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,prefix);
}
