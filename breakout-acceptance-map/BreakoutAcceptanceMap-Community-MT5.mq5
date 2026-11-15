// Breakout Acceptance Map Community — Harmony Algo | harmonyalgo.com
// Copyright (c) 2026 Harmony Algo. Mozilla Public License 2.0.
// UNCOMPILED / UNTESTED MT5 SOURCE. No cross-feed signal equality claim.
// Port of approved TradingView F4wMKWbW, source SHA256 719eadda0c905f5ad077a5470e3925630f4e225fb3c663efc5d60a9f0ee3dfd5.
#property copyright "Harmony Algo"
#property link "https://harmonyalgo.com"
#property description "Closed-bar breakout acceptance and retest lifecycle. Premium products are for TradingView."
#property indicator_chart_window
#property indicator_buffers 12
#property indicator_plots 11

input int ReferenceBars=64;
input int ATRLength=21;
input double MaximumRangeATR=8.0;
input double MaximumEfficiency=0.35;
input int ArmedLifetime=96;
input double BreakoutBufferATR=0.30;
input int AcceptanceCloses=3;
input int AcceptanceWindow=12;
input double RetestHalfWidthATR=0.25;
input double TravelBeforeRetestATR=1.25;
input int TrackingBars=128;
input int CooldownBars=12;
input int RangesRetained=12;
input bool ShowStages=true;
input bool ShowSummary=true;
input color BullColor=C'1,130,8';
input color BearColor=C'209,34,8';
input bool EnablePopupAlerts=false; // no historical alerts on attach

double UpAccepted[],DownAccepted[],UpHeld[],DownHeld[],Failed[],BreakMark[],RetestMark[];
double StateBuffer[],DirectionBuffer[],EventMask[],FrozenEdge[],ATR[];
datetime lastOpen=0;
string prefix;
color Neutral=C'130,144,166',Pending=C'218,172,76',Failure=C'230,125,54';
struct Region {datetime left,right;double top,bottom;color ink;};
struct Marker {int bar;double y;string text;color ink;};

void Caption(const string key,const string text,const int x,const int y,const int size,const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
{
   string name=prefix+key;
   if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrSilver);ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");ObjectSetString(0,name,OBJPROP_TEXT,text);
}
// BRANDING_BEGIN: Harmony Algo | harmonyalgo.com; no effect on calculations.
void Branding()
{
   int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0),h=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   Caption("brand","Harmony Algo | harmonyalgo.com",w/2,h/2-12,14,ANCHOR_CENTER);
   Caption("cta","Explore premium indicators at harmonyalgo.com",w/2,h/2+12,10,ANCHOR_CENTER);
}
// BRANDING_END
void AddRegion(Region &a[],const datetime t,const double top,const double bottom,const color ink)
{
   int k=ArraySize(a);ArrayResize(a,k+1,128);a[k].left=a[k].right=t;a[k].top=top;a[k].bottom=bottom;a[k].ink=ink;
}
void DrawRegion(const string key,const Region &r)
{
   string name=prefix+"drawing_"+key;
   ObjectCreate(0,name,OBJ_RECTANGLE,0,r.left,r.top,r.right,r.bottom);
   ObjectSetInteger(0,name,OBJPROP_COLOR,r.ink);ObjectSetInteger(0,name,OBJPROP_FILL,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}
int OnInit()
{
   if(ReferenceBars<16||ReferenceBars>240||ATRLength<5||ATRLength>100||MaximumRangeATR<2||MaximumRangeATR>15||
      MaximumEfficiency<0.05||MaximumEfficiency>0.8||ArmedLifetime<8||ArmedLifetime>300||
      BreakoutBufferATR<0.05||BreakoutBufferATR>1||AcceptanceCloses<2||AcceptanceCloses>6||AcceptanceWindow<6||AcceptanceWindow>40||
      RetestHalfWidthATR<0.15||RetestHalfWidthATR>0.75||TravelBeforeRetestATR<0.5||TravelBeforeRetestATR>3||
      TrackingBars<40||TrackingBars>240||CooldownBars<0||CooldownBars>50||RangesRetained<1||RangesRetained>80)return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,UpAccepted,INDICATOR_DATA);SetIndexBuffer(1,DownAccepted,INDICATOR_DATA);
   SetIndexBuffer(2,UpHeld,INDICATOR_DATA);SetIndexBuffer(3,DownHeld,INDICATOR_DATA);
   SetIndexBuffer(4,Failed,INDICATOR_DATA);SetIndexBuffer(5,BreakMark,INDICATOR_DATA);SetIndexBuffer(6,RetestMark,INDICATOR_DATA);
   SetIndexBuffer(7,StateBuffer,INDICATOR_DATA);SetIndexBuffer(8,DirectionBuffer,INDICATOR_DATA);
   SetIndexBuffer(9,EventMask,INDICATOR_DATA);SetIndexBuffer(10,FrozenEdge,INDICATOR_DATA);SetIndexBuffer(11,ATR,INDICATOR_CALCULATIONS);
   string names[]={"Bullish acceptance","Bearish acceptance","Bullish retest held","Bearish retest held","Failed","Breakout","Retest","State","Active direction","Event mask","Frozen edge"};
   int glyphs[]={233,234,233,234,251,117,159};
   for(int p=0;p<11;p++)
   {
      PlotIndexSetString(p,PLOT_LABEL,names[p]);PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      PlotIndexSetInteger(p,PLOT_DRAW_TYPE,p<7?DRAW_ARROW:DRAW_NONE);
      if(p<7){color ink=(p==0||p==2)?BullColor:(p==1||p==3)?BearColor:p==4?Failure:Pending;PlotIndexSetInteger(p,PLOT_LINE_COLOR,ink);PlotIndexSetInteger(p,PLOT_ARROW,glyphs[p]);PlotIndexSetInteger(p,PLOT_LINE_WIDTH,p<4?2:1);}
   }
   IndicatorSetString(INDICATOR_SHORTNAME,"Breakout Acceptance Map Community [Harmony Algo]");IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   prefix="BAM_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+"_";
   Branding();return INIT_SUCCEEDED;
}

// Harmony Algo | harmonyalgo.com — chronological closed-bar implementation.
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
   ArraySetAsSeries(time,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
   if(rates_total<2)return 0;
   if(prev_calculated==rates_total&&lastOpen==time[rates_total-1])return rates_total;
   bool notify=prev_calculated>0&&lastOpen>0&&time[rates_total-1]>lastOpen;lastOpen=time[rates_total-1];
   Region ranges[],edges[];Marker labels[];
   int state=0,side=0,armedAt=-1,started=-1,acceptedAt=-1,touchedAt=-1,lastEnd=-1000000000,held=0,inside=0;
   double hi=0,lo=0,unit=0,edge=0,peak=0,reclaim=0,trsum=0;
   string lastPhase="No completed range";
   int lastLabelAt=-1000000000;double lastLabelY=0;bool lastLabelBelow=false;
   for(int i=0;i<rates_total;i++)
   {
      UpAccepted[i]=DownAccepted[i]=UpHeld[i]=DownHeld[i]=Failed[i]=BreakMark[i]=RetestMark[i]=EMPTY_VALUE;
      EventMask[i]=0;
      double tr=i==0?high[i]-low[i]:MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1])));
      if(i<ATRLength)trsum+=tr;
      ATR[i]=i<ATRLength-1?EMPTY_VALUE:i==ATRLength-1?trsum/ATRLength:(ATR[i-1]*(ATRLength-1)+tr)/ATRLength;
      if(i<rates_total-1&&i>MathMax(ReferenceBars+1,ATRLength+1)&&ATR[i-1]>0&&ATR[i-1]!=EMPTY_VALUE)
      {
         double upper=high[i-ReferenceBars],lower=low[i-ReferenceBars],path=0;
         for(int j=i-ReferenceBars;j<i;j++){upper=MathMax(upper,high[j]);lower=MathMin(lower,low[j]);path+=MathAbs(close[j]-close[j-1]);}
         double efficiency=path>0?MathAbs(close[i-1]-close[i-ReferenceBars-1])/path:1.0;
         bool ready=upper>lower,compact=ready&&upper-lower>=2.5*ATR[i-1]&&upper-lower<=MaximumRangeATR*ATR[i-1]&&efficiency<=MaximumEfficiency;
         int ev=0;
         if(ready)
         {
            if(state==0)
            {
               if(compact&&close[i]>=lower&&close[i]<=upper&&i-lastEnd>CooldownBars)
               {
                  hi=upper;lo=lower;unit=ATR[i-1];armedAt=i;side=0;held=inside=0;state=1;
                  AddRegion(ranges,time[i],hi,lo,Neutral);
               }
            }
            else if(state==1)
            {
               ranges[ArraySize(ranges)-1].right=time[i];
               bool up=close[i]>hi+BreakoutBufferATR*unit,down=close[i]<lo-BreakoutBufferATR*unit;
               if(up||down)
               {
                  side=up?1:-1;edge=up?hi:lo;started=i;peak=up?high[i]:low[i];held=side*(close[i]-edge)>0.10*unit?1:0;
                  inside=0;state=2;ev=1;AddRegion(edges,time[i],edge+RetestHalfWidthATR*unit,edge-RetestHalfWidthATR*unit,Pending);
               }
               else if(i-armedAt>=ArmedLifetime){state=0;lastEnd=i;lastPhase="Range expired";}
            }
            else
            {
               int k=ArraySize(edges)-1;edges[k].right=time[i];int age=i-started+1;
               double distance=side*(close[i]-edge)/unit;inside=distance<-0.15?inside+1:0;
               bool failure=inside>=2||(side==1?close[i]<lo:close[i]>hi);
               if(failure){ev=16;lastPhase=state==2?"Breakout failed":"Acceptance failed";}
               else if(state==2)
               {
                  held=distance>0.10?held+1:0;
                  if(held>=AcceptanceCloses){ev=2;state=3;acceptedAt=i;lastPhase="Accepted";}
                  else if(age>=AcceptanceWindow){ev=32;lastPhase="Acceptance timed out";}
               }
               else if(state==3)
               {
                  bool travelled=side*(peak-edge)>=TravelBeforeRetestATR*unit;
                  bool intersects=low[i]<=edge+RetestHalfWidthATR*unit&&high[i]>=edge-RetestHalfWidthATR*unit;
                  if(i>acceptedAt&&travelled&&intersects){ev=4;state=4;touchedAt=i;reclaim=side==1?high[i]:low[i];lastPhase="Retest in progress";}
               }
               else if(state==4&&i>touchedAt&&side*(close[i]-reclaim)>0.05*unit&&distance>0.10){ev=8;state=5;lastPhase="Retest held";}
               if(!failure&&age>=TrackingBars){ev=32;lastPhase="Tracking ended";}
               peak=side==1?MathMax(peak,high[i]):MathMin(peak,low[i]);
               edges[k].ink=failure?Failure:ev==32?Neutral:(state==2||state==4)?Pending:side==1?BullColor:BearColor;
               if(ev==16||ev==32){state=0;lastEnd=i;held=inside=0;}
            }
         }
         EventMask[i]=ev;
         double spacing=MathMax(unit,_Point)*1.2;
         if(ShowStages&&ev==1)BreakMark[i]=side==1?low[i]-unit*0.2:high[i]+unit*0.2;
         if(ShowStages&&ev==4)RetestMark[i]=side==1?low[i]-unit*0.2:high[i]+unit*0.2;
         if(ev==2||ev==8||ev==16)
         {
            bool below=ev==16?side==-1:side==1;double y=below?low[i]-spacing:high[i]+spacing;
            if(i-lastLabelAt<=6&&below==lastLabelBelow)y=below?MathMin(y,lastLabelY-spacing):MathMax(y,lastLabelY+spacing);
            int n=ArraySize(labels);ArrayResize(labels,n+1,512);labels[n].bar=i;labels[n].y=y;
            labels[n].text=ev==16?"Failed":ev==8?"Held":"Accepted";labels[n].ink=ev==16?Failure:side==1?BullColor:BearColor;
            lastLabelAt=i;lastLabelY=y;lastLabelBelow=below;
            if(ev==2){if(side==1)UpAccepted[i]=y;else DownAccepted[i]=y;}
            if(ev==8){if(side==1)UpHeld[i]=y;else DownHeld[i]=y;}
            if(ev==16)Failed[i]=y;
         }
      }
      StateBuffer[i]=state;DirectionBuffer[i]=state>=2?side:0;FrozenEdge[i]=state>=2?edge:EMPTY_VALUE;
   }
   // Drawing objects are rebuilt only on new bars; full history calculation is intentional.
   ObjectsDeleteAll(0,prefix+"drawing_");
   for(int j=MathMax(0,ArraySize(ranges)-RangesRetained);j<ArraySize(ranges);j++)DrawRegion("range_"+IntegerToString(j),ranges[j]);
   for(int j=MathMax(0,ArraySize(edges)-RangesRetained);j<ArraySize(edges);j++)DrawRegion("edge_"+IntegerToString(j),edges[j]);
   for(int j=0;j<ArraySize(labels);j++)
   {
      int i=labels[j].bar;
      if(j<ArraySize(labels)-500){UpAccepted[i]=DownAccepted[i]=UpHeld[i]=DownHeld[i]=Failed[i]=EMPTY_VALUE;continue;}
      string name=prefix+"drawing_label_"+IntegerToString(j);
      ObjectCreate(0,name,OBJ_TEXT,0,time[i],labels[j].y);ObjectSetString(0,name,OBJPROP_TEXT,labels[j].text);
      ObjectSetInteger(0,name,OBJPROP_COLOR,labels[j].ink);ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   }
   if(ShowSummary)
   {
      Caption("panelbrand","Harmony Algo | harmonyalgo.com",12,22,10);
      string phase=state==0?"Searching":state==1?"Range armed":state==2?"Awaiting acceptance":state==3?"Accepted / watching":state==4?"Retest in progress":"Retest held / watching";
      Caption("panel",phase+" | Last: "+lastPhase,12,40,10);
   }
   else{ObjectDelete(0,prefix+"panelbrand");ObjectDelete(0,prefix+"panel");}
   int k=rates_total-2;
   if(EnablePopupAlerts&&notify)
   {
      int ev=(int)EventMask[k];string message=ev==1?"Breakout detected; acceptance pending":ev==2?(side==1?"Bullish acceptance":"Bearish acceptance"):ev==4?"Retest started":ev==8?(side==1?"Bullish retest held":"Bearish retest held"):ev==16?"Breakout or acceptance failed":ev==32?"Observation window ended":"";
      if(message!="")Alert(message," on ",_Symbol," ",EnumToString(_Period)," at ",DoubleToString(close[k],_Digits));
   }
   Branding();return rates_total;
}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){if(id==CHARTEVENT_CHART_CHANGE)Branding();}
void OnDeinit(const int reason){ObjectsDeleteAll(0,prefix);}
