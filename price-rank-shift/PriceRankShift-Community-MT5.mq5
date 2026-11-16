// Price Rank Shift Community — Harmony Algo | harmonyalgo.com
// Copyright (c) 2026 Harmony Algo. Mozilla Public License 2.0.
// Compiled with MetaEditor; consult VALIDATION.txt for actual chart-test scope.
// Based on the approved TradingView Price Rank Shift, GuHXtwsO.
#property copyright "Harmony Algo"
#property link "https://harmonyalgo.com"
#property description "Closed-bar rank relocation. Premium indicators at harmonyalgo.com are for TradingView."
#property indicator_chart_window
#property indicator_buffers 19
#property indicator_plots 16
#property indicator_label1 "Earlier block median"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrSilver
#property indicator_label2 "Recent block median"
#property indicator_type2 DRAW_COLOR_LINE
#property indicator_color2 C'1,130,8',C'209,34,8',C'127,73,222'
#property indicator_width2 2
#property indicator_label3 "Median relocation"
#property indicator_type3 DRAW_FILLING
#property indicator_color3 C'25,20,30'
#property indicator_label4 "Up"
#property indicator_type4 DRAW_ARROW
#property indicator_color4 C'1,130,8'
#property indicator_width4 2
#property indicator_label5 "Down"
#property indicator_type5 DRAW_ARROW
#property indicator_color5 C'209,34,8'
#property indicator_width5 2
#property indicator_label6 "Ordering lost"
#property indicator_type6 DRAW_ARROW
#property indicator_color6 C'127,73,222'

input int ClosesPerBlock=20; // 8 to 40
input double DirectionalRankEffect=0.70; // 0.55 to 0.95
input double LossOfOrderingThreshold=0.20; // 0 to 0.50
input int ConfirmingCloses=3; // 1 to 8
input double MinimumMedianGapATR=0.50; // 0 to 3
input bool ShowStatePanel=true;
input color UpColor=C'1,130,8';
input color DownColor=C'209,34,8';
input color NeutralColor=C'127,73,222';
input bool EnablePopupAlerts=false; // local terminal alerts, only after a NEW closed bar

double Earlier[],Recent[],RecentColor[],FillEarlier[],FillRecent[];
double UpMark[],DownMark[],NeutralMark[],Effect[],Gap[],PriorATR[],State[];
double UpCount[],DownCount[],WeakCount[],UpEvent[],DownEvent[],NeutralEvent[],ATR[];
string prefix="";
datetime lastOpen=0;

void Caption(const string key,const string text,const int x,const int y,const color c,const int size,const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
{
   string name=prefix+key;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetString(0,name,OBJPROP_TEXT,text);
}
void Branding()
{
   int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   int h=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   Caption("brand","Harmony Algo | harmonyalgo.com",w/2,h/2-h/8-12,clrSilver,12,ANCHOR_CENTER);
   Caption("cta","Explore premium indicators at harmonyalgo.com",w/2,h/2-h/8+10,clrSilver,10,ANCHOR_CENTER);
}
void Panel(const int i)
{
   if(!ShowStatePanel) { ObjectDelete(0,prefix+"panel"); ObjectDelete(0,prefix+"panelbrand"); return; }
   string v="Warming up";
   color c=NeutralColor;
   if(i>=0 && Effect[i]!=EMPTY_VALUE)
   {
      v=(State[i]>0 ? "Up" : State[i]<0 ? "Down" : "Neutral")+
        " | Rank effect "+DoubleToString(Effect[i],2)+" | Median gap / ATR "+DoubleToString(Gap[i],2);
      c=(State[i]>0 ? UpColor : State[i]<0 ? DownColor : NeutralColor);
   }
   Caption("panelbrand","Harmony Algo | harmonyalgo.com",12,22,clrSilver,10);
   Caption("panel",v,12,40,c,10);
}
double Median(double &a[])
{
   ArraySort(a);
   int n=ArraySize(a);
   return n%2==1 ? a[n/2] : (a[n/2-1]+a[n/2])/2.0;
}
int OnInit()
{
   if(ClosesPerBlock<8 || ClosesPerBlock>40 || DirectionalRankEffect<0.55 || DirectionalRankEffect>0.95 ||
      LossOfOrderingThreshold<0 || LossOfOrderingThreshold>0.50 || ConfirmingCloses<1 || ConfirmingCloses>8 ||
      MinimumMedianGapATR<0 || MinimumMedianGapATR>3) return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,Earlier,INDICATOR_DATA);SetIndexBuffer(1,Recent,INDICATOR_DATA);
   SetIndexBuffer(2,RecentColor,INDICATOR_COLOR_INDEX);SetIndexBuffer(3,FillEarlier,INDICATOR_DATA);
   SetIndexBuffer(4,FillRecent,INDICATOR_DATA);SetIndexBuffer(5,UpMark,INDICATOR_DATA);
   SetIndexBuffer(6,DownMark,INDICATOR_DATA);SetIndexBuffer(7,NeutralMark,INDICATOR_DATA);
   SetIndexBuffer(8,Effect,INDICATOR_DATA);SetIndexBuffer(9,Gap,INDICATOR_DATA);
   SetIndexBuffer(10,PriorATR,INDICATOR_DATA);SetIndexBuffer(11,State,INDICATOR_DATA);
   SetIndexBuffer(12,UpCount,INDICATOR_DATA);SetIndexBuffer(13,DownCount,INDICATOR_DATA);
   SetIndexBuffer(14,WeakCount,INDICATOR_DATA);SetIndexBuffer(15,UpEvent,INDICATOR_DATA);
   SetIndexBuffer(16,DownEvent,INDICATOR_DATA);SetIndexBuffer(17,NeutralEvent,INDICATOR_DATA);
   SetIndexBuffer(18,ATR,INDICATOR_CALCULATIONS);
   string names[]={"Rank effect","Median gap / ATR","Prior ATR used","State","Up persistence","Down persistence","Weak persistence","Up event","Down event","Neutral event"};
   for(int p=6;p<16;p++){PlotIndexSetInteger(p,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetString(p,PLOT_LABEL,names[p-6]);}
   for(int p=0;p<16;p++)PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetInteger(1,PLOT_LINE_COLOR,0,UpColor);PlotIndexSetInteger(1,PLOT_LINE_COLOR,1,DownColor);PlotIndexSetInteger(1,PLOT_LINE_COLOR,2,NeutralColor);
   PlotIndexSetInteger(3,PLOT_ARROW,233);PlotIndexSetInteger(4,PLOT_ARROW,234);PlotIndexSetInteger(5,PLOT_ARROW,159);
   PlotIndexSetInteger(3,PLOT_LINE_COLOR,UpColor);PlotIndexSetInteger(4,PLOT_LINE_COLOR,DownColor);PlotIndexSetInteger(5,PLOT_LINE_COLOR,NeutralColor);
   IndicatorSetString(INDICATOR_SHORTNAME,"Price Rank Shift Community [Harmony Algo]");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   prefix="PRS_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+"_";
   Branding(); return INIT_SUCCEEDED;
}
// Harmony Algo | harmonyalgo.com — closed-bar model; prior ATR uses Pine-style RMA seed.
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
   ArraySetAsSeries(time,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
   if(rates_total<2) return 0;
   if(prev_calculated==rates_total && time[rates_total-1]==lastOpen) return rates_total;
   bool alertNew=prev_calculated>0 && lastOpen>0 && time[rates_total-1]>lastOpen;
   lastOpen=time[rates_total-1];
   int st=0,uc=0,dc=0,wc=0;
   double effect=EMPTY_VALUE,nmed=EMPTY_VALUE,omed=EMPTY_VALUE,gap=EMPTY_VALUE,used=EMPTY_VALUE,trsum=0;
   double newer[],older[];ArrayResize(newer,ClosesPerBlock);ArrayResize(older,ClosesPerBlock);
   int arrows[];ArrayResize(arrows,0);
   for(int i=0;i<rates_total;i++)
   {
      UpMark[i]=DownMark[i]=NeutralMark[i]=EMPTY_VALUE;
      UpEvent[i]=DownEvent[i]=NeutralEvent[i]=0;
      double tr=i==0 ? high[i]-low[i] : MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1])));
      if(i<21)trsum+=tr;
      ATR[i]=i<20 ? EMPTY_VALUE : i==20 ? trsum/21.0 : (ATR[i-1]*20.0+tr)/21.0;
      bool closed=i<rates_total-1;
      bool ready=i>=2*ClosesPerBlock-1 && i>0 && ATR[i-1]!=EMPTY_VALUE && ATR[i-1]>0;
      if(closed && ready)
      {
         double score=0;
         for(int a=0;a<ClosesPerBlock;a++)
         {
            newer[a]=close[i-a];older[a]=close[i-ClosesPerBlock-a];
            for(int b=ClosesPerBlock;b<2*ClosesPerBlock;b++) score+=close[i-a]>close[i-b] ? 1 : close[i-a]<close[i-b] ? -1 : 0;
         }
         effect=score/(ClosesPerBlock*ClosesPerBlock);nmed=Median(newer);omed=Median(older);
         used=ATR[i-1];gap=(nmed-omed)/used;
         uc=effect>=DirectionalRankEffect && gap>=MinimumMedianGapATR ? MathMin(uc+1,ConfirmingCloses) : 0;
         dc=effect<=-DirectionalRankEffect && gap<=-MinimumMedianGapATR ? MathMin(dc+1,ConfirmingCloses) : 0;
         wc=st!=0 && st*effect<=LossOfOrderingThreshold ? MathMin(wc+1,ConfirmingCloses) : 0;
         int next=st;
         if(uc>=ConfirmingCloses)next=1;else if(dc>=ConfirmingCloses)next=-1;else if(wc>=ConfirmingCloses)next=0;
         UpEvent[i]=(next==1 && st!=1) ? 1 : 0;DownEvent[i]=(next==-1 && st!=-1) ? 1 : 0;NeutralEvent[i]=(next==0 && st!=0) ? 1 : 0;
         if(next!=st)wc=0;st=next;
         if(UpEvent[i]>0)UpMark[i]=low[i]-used*0.30;
         if(DownEvent[i]>0)DownMark[i]=high[i]+used*0.30;
         if(NeutralEvent[i]>0)NeutralMark[i]=high[i]+used*0.10;
         if(UpEvent[i]>0 || DownEvent[i]>0){int n=ArraySize(arrows);ArrayResize(arrows,n+1,512);arrows[n]=i;}
      }
      Earlier[i]=omed;Recent[i]=nmed;RecentColor[i]=st>0 ? 0 : st<0 ? 1 : 2;
      FillEarlier[i]=omed;FillRecent[i]=nmed;Effect[i]=effect;Gap[i]=gap;PriorATR[i]=used;
      State[i]=st;UpCount[i]=uc;DownCount[i]=dc;WeakCount[i]=wc;
   }
   // Match Pine's 500 directional-label retention; diagnostics retain all events.
   for(int j=0;j<ArraySize(arrows)-500;j++){UpMark[arrows[j]]=EMPTY_VALUE;DownMark[arrows[j]]=EMPTY_VALUE;}
   int k=rates_total-2;
   if(EnablePopupAlerts && alertNew)
   {
      if(UpEvent[k]>0)Alert("Confirmed upward price-rank shift on ",_Symbol," ",EnumToString(_Period));
      if(DownEvent[k]>0)Alert("Confirmed downward price-rank shift on ",_Symbol," ",EnumToString(_Period));
      if(NeutralEvent[k]>0)Alert("Directional price ordering lost on ",_Symbol," ",EnumToString(_Period));
   }
   Branding();Panel(k);return rates_total;
}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){if(id==CHARTEVENT_CHART_CHANGE)Branding();}
void OnDeinit(const int reason){ObjectsDeleteAll(0,prefix);}
