// Trend Stress Compass Community — Harmony Algo | harmonyalgo.com
// Copyright (c) 2026 Harmony Algo. Licensed under Mozilla Public License 2.0.
// Compiled with MetaEditor; consult VALIDATION.txt for actual chart-test scope.
// Port of approved TradingView script etULm2Vi; no cross-feed equality claim.
#property copyright "Harmony Algo"
#property link "https://harmonyalgo.com"
#property description "Block-deletion trend sensitivity. Premium products at harmonyalgo.com are for TradingView."
#property indicator_chart_window
#property indicator_buffers 19
#property indicator_plots 16
#property indicator_label1 "Full-fit endpoint"
#property indicator_type1 DRAW_COLOR_LINE
#property indicator_color1 C'1,130,8',C'209,34,8',C'127,73,222'
#property indicator_width1 2
#property indicator_label2 "Deletion endpoint low"
#property indicator_type2 DRAW_LINE
#property indicator_color2 C'127,73,222'
#property indicator_label3 "Deletion endpoint high"
#property indicator_type3 DRAW_LINE
#property indicator_color3 C'127,73,222'
#property indicator_label4 "Fit sensitivity (not forecast)"
#property indicator_type4 DRAW_FILLING
#property indicator_color4 C'30,20,45'
#property indicator_label5 "Up"
#property indicator_type5 DRAW_ARROW
#property indicator_color5 C'1,130,8'
#property indicator_width5 2
#property indicator_label6 "Down"
#property indicator_type6 DRAW_ARROW
#property indicator_color6 C'209,34,8'
#property indicator_width6 2
#property indicator_label7 "Support lost"
#property indicator_type7 DRAW_ARROW
#property indicator_color7 C'127,73,222'

input int BarsPerSegment=12; // six segments, 4..40 bars each
input double MinimumRetainedMoveATR=1.5; // >=0.5
input double LossThresholdATR=0.6; // 0..0.9 and below entry
input int ConfirmedCloses=3; // 1..8
input bool ShowSummary=true;
input int RetainedDirectionMarkers=500; // 20..500
input bool EnablePopupAlerts=false; // local terminal; no historical alert replay

double Fit[],FitColor[],Lower[],Upper[],FillLow[],FillHigh[],UpMark[],DownMark[],LossMark[];
double PriorATR[],FullMove[],MinimumMove[],MaximumMove[],State[],Event[],UpEvent[],DownEvent[],LossEvent[],ATR[];
datetime lastOpen=0;
string prefix;

// Harmony Algo | harmonyalgo.com — branding independent of calculations.
void Caption(const string key,const string text,const int x,const int y,const int size,const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
{
   string name=prefix+key;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrSilver);
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
   Caption("brand","Harmony Algo",w/2,h/2-12,14,ANCHOR_CENTER);
   Caption("cta","Explore premium indicators at harmonyalgo.com",w/2,h/2+12,10,ANCHOR_CENTER);
}
void Panel(const int k)
{
   if(!ShowSummary){ObjectDelete(0,prefix+"panelbrand");ObjectDelete(0,prefix+"panel");return;}
   string text="Warming up";
   if(k>=0 && FullMove[k]!=EMPTY_VALUE)
   {
      double weakest=FullMove[k]>=0 ? MinimumMove[k] : -MaximumMove[k];
      text=(State[k]>0 ? "Up supported" : State[k]<0 ? "Down supported" : "Mixed / influenced")+
         " | Full "+DoubleToString(FullMove[k],2)+" ATR | Weakest "+DoubleToString(weakest,2)+" ATR";
   }
   Caption("panelbrand","Harmony Algo | harmonyalgo.com",12,22,10);
   Caption("panel",text,12,40,10);
}
int OnInit()
{
   if(BarsPerSegment<4 || BarsPerSegment>40 || MinimumRetainedMoveATR<0.5 ||
      LossThresholdATR<0 || LossThresholdATR>0.9 || LossThresholdATR>=MinimumRetainedMoveATR ||
      ConfirmedCloses<1 || ConfirmedCloses>8 || RetainedDirectionMarkers<20 || RetainedDirectionMarkers>500)
      return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,Fit,INDICATOR_DATA);SetIndexBuffer(1,FitColor,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,Lower,INDICATOR_DATA);SetIndexBuffer(3,Upper,INDICATOR_DATA);
   SetIndexBuffer(4,FillLow,INDICATOR_DATA);SetIndexBuffer(5,FillHigh,INDICATOR_DATA);
   SetIndexBuffer(6,UpMark,INDICATOR_DATA);SetIndexBuffer(7,DownMark,INDICATOR_DATA);SetIndexBuffer(8,LossMark,INDICATOR_DATA);
   SetIndexBuffer(9,PriorATR,INDICATOR_DATA);SetIndexBuffer(10,FullMove,INDICATOR_DATA);
   SetIndexBuffer(11,MinimumMove,INDICATOR_DATA);SetIndexBuffer(12,MaximumMove,INDICATOR_DATA);
   SetIndexBuffer(13,State,INDICATOR_DATA);SetIndexBuffer(14,Event,INDICATOR_DATA);
   SetIndexBuffer(15,UpEvent,INDICATOR_DATA);SetIndexBuffer(16,DownEvent,INDICATOR_DATA);SetIndexBuffer(17,LossEvent,INDICATOR_DATA);
   SetIndexBuffer(18,ATR,INDICATOR_CALCULATIONS);
   string labels[]={"Prior ATR used","Full move / prior ATR","Minimum deletion move / prior ATR","Maximum deletion move / prior ATR","Confirmed state","Confirmed event","Up event","Down event","Loss event"};
   for(int p=7;p<16;p++){PlotIndexSetInteger(p,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetString(p,PLOT_LABEL,labels[p-7]);}
   for(int p=0;p<16;p++)PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetInteger(4,PLOT_ARROW,233);PlotIndexSetInteger(5,PLOT_ARROW,234);PlotIndexSetInteger(6,PLOT_ARROW,159);
   IndicatorSetString(INDICATOR_SHORTNAME,"Trend Stress Compass Community [Harmony Algo]");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   prefix="TSC_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+"_";
   Branding();return INIT_SUCCEEDED;
}

// Harmony Algo | harmonyalgo.com — chronological full recalculation on new bars.
// Pine-style ATR: true range, initial SMA(21), then Wilder RMA; use previous bar.
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
   ArraySetAsSeries(time,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
   if(rates_total<2)return 0;
   if(prev_calculated==rates_total && lastOpen==time[rates_total-1])return rates_total;
   bool notify=prev_calculated>0 && lastOpen>0 && time[rates_total-1]>lastOpen;
   lastOpen=time[rates_total-1];
   int n=6*BarsPerSegment,st=0,uc=0,dc=0,lc=0;
   double trsum=0,fit=EMPTY_VALUE,lo=EMPTY_VALUE,hi=EMPTY_VALUE,unit=EMPTY_VALUE;
   double full=EMPTY_VALUE,mn=EMPTY_VALUE,mx=EMPTY_VALUE;
   int markers[];ArrayResize(markers,0);
   for(int i=0;i<rates_total;i++)
   {
      UpMark[i]=DownMark[i]=LossMark[i]=EMPTY_VALUE;
      UpEvent[i]=DownEvent[i]=LossEvent[i]=Event[i]=0;
      double tr=i==0 ? high[i]-low[i] : MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1])));
      if(i<21)trsum+=tr;
      ATR[i]=i<20 ? EMPTY_VALUE : i==20 ? trsum/21.0 : (ATR[i-1]*20.0+tr)/21.0;
      if(i<rates_total-1) // unfinished bar always holds last committed values
      {
         bool ready=i>=n-1 && i>0 && ATR[i-1]!=EMPTY_VALUE && ATR[i-1]>0;
         if(ready)
         {
            unit=ATR[i-1];double origin=close[i-n+1];
            double sx=n*(n-1.0)/2.0,sxx=n*(n-1.0)*(2.0*n-1.0)/6.0,sy=0,sxy=0;
            double by[6],bxy[6];ArrayInitialize(by,0);ArrayInitialize(bxy,0);
            for(int x=0;x<n;x++)
            {
               double y=close[i-n+1+x]-origin;int b=x/BarsPerSegment;
               sy+=y;sxy+=x*y;by[b]+=y;bxy[b]+=x*y;
            }
            double slope=(sxy-sx*sy/n)/(sxx-sx*sx/n);
            fit=origin+sy/n+slope*(n-1-sx/n);full=slope*(n-1)/unit;
            lo=hi=fit;mn=EMPTY_VALUE;mx=-EMPTY_VALUE;
            for(int b=0;b<6;b++)
            {
               double a=b*BarsPerSegment,z=a+BarsPerSegment-1;
               double bx=BarsPerSegment*(a+z)/2.0;
               double bx2=z*(z+1)*(2*z+1)/6.0-(a-1)*a*(2*a-1)/6.0;
               double m=n-BarsPerSegment,rx=sx-bx,ry=sy-by[b],rxy=sxy-bxy[b];
               double rs=(rxy-rx*ry/m)/(sxx-bx2-rx*rx/m);
               double ep=origin+ry/m+rs*(n-1-rx/m),move=rs*(n-1)/unit;
               lo=MathMin(lo,ep);hi=MathMax(hi,ep);mn=MathMin(mn,move);mx=MathMax(mx,move);
            }
            uc=full>=2.0 && mn>=MinimumRetainedMoveATR ? MathMin(uc+1,ConfirmedCloses) : 0;
            dc=full<=-2.0 && mx<=-MinimumRetainedMoveATR ? MathMin(dc+1,ConfirmedCloses) : 0;
            bool losing=st==1 ? mn<=LossThresholdATR : st==-1 ? mx>=-LossThresholdATR : false;
            lc=losing ? MathMin(lc+1,ConfirmedCloses) : 0;
            if(uc>=ConfirmedCloses && st!=1){st=1;UpEvent[i]=1;Event[i]=1;lc=0;}
            else if(dc>=ConfirmedCloses && st!=-1){st=-1;DownEvent[i]=1;Event[i]=-1;lc=0;}
            else if(lc>=ConfirmedCloses && st!=0){st=0;LossEvent[i]=1;Event[i]=2;lc=0;}
            if(UpEvent[i]>0)UpMark[i]=low[i]-unit*0.30;
            if(DownEvent[i]>0)DownMark[i]=high[i]+unit*0.30;
            if(LossEvent[i]>0)LossMark[i]=low[i]-unit*0.10;
            if(UpEvent[i]>0 || DownEvent[i]>0){int k=ArraySize(markers);ArrayResize(markers,k+1,512);markers[k]=i;}
         }
         else
         {
            st=uc=dc=lc=0;fit=lo=hi=unit=full=mn=mx=EMPTY_VALUE;
         }
      }
      Fit[i]=fit;FitColor[i]=st==1 ? 0 : st==-1 ? 1 : 2;
      Lower[i]=FillLow[i]=lo;Upper[i]=FillHigh[i]=hi;
      PriorATR[i]=unit;FullMove[i]=full;MinimumMove[i]=mn;MaximumMove[i]=mx;State[i]=st;
   }
   // Arrow placements replace Pine labels; diagnostic events retain all history.
   for(int j=0;j<ArraySize(markers)-RetainedDirectionMarkers;j++){UpMark[markers[j]]=EMPTY_VALUE;DownMark[markers[j]]=EMPTY_VALUE;}
   int k=rates_total-2;
   if(EnablePopupAlerts && notify)
   {
      if(UpEvent[k]>0)Alert("Trend Stress: Up support confirmed on ",_Symbol," ",EnumToString(_Period));
      if(DownEvent[k]>0)Alert("Trend Stress: Down support confirmed on ",_Symbol," ",EnumToString(_Period));
      if(LossEvent[k]>0)Alert("Trend Stress: Directional support lost on ",_Symbol," ",EnumToString(_Period));
   }
   Branding();Panel(k);return rates_total;
}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){if(id==CHARTEVENT_CHART_CHANGE)Branding();}
void OnDeinit(const int reason){ObjectsDeleteAll(0,prefix);}
