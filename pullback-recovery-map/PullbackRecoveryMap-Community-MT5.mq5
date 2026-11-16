// Pullback Recovery Map Community — Harmony Algo | harmonyalgo.com
// Copyright (c) 2026 Harmony Algo. Mozilla Public License 2.0.
// UNCOMPILED / UNTESTED MT5 SOURCE. No terminal or cross-feed equality claim.
// Approved Pine source: a421fbaaf406e925e3857160a9e748dca76c3e28a2184b26862a86d8f65d5a7e.
#property copyright "Harmony Algo"
#property link "https://harmonyalgo.com"
#property description "Closed-bar robust trend and frozen pullback recovery. Premium products are for TradingView."
#property indicator_chart_window
#property indicator_buffers 18
#property indicator_plots 17

input int BarsPerSegment=12;
input double TrendEntryScale=2.5;
input double TrendReleaseScale=0.8;
input double PullbackTriggerScale=0.5;
input double GuardDistanceScale=1.75;
input int MaximumTrackingBars=48;
input bool ShowSummary=true;
input int RetainedMaps=80;
input bool EnablePopupAlerts=false; // attach and history reload emit no alerts

double TrendUp[],TrendDown[],TrendMixed[],UpRecovery[],DownRecovery[],WatchMark[],FailMark[],EndMark[];
double MoveBuffer[],DirectionBuffer[],WatchingBuffer[],FrozenBase[],FrozenUnit[],FrozenGuard[],FrozenRecovery[],Events[],Sides[],ATR[];
color Bull=C'1,130,8',Bear=C'209,34,8',Neutral=C'127,73,222';
string prefix;
datetime lastOpen=0;
struct Map {int first,last,side,result;double baseline,guard,recovery;};
struct Mark {int bar,side,event;double y;};

double Mid(double &values[])
{
   ArraySort(values);int n=ArraySize(values);return (n%2==1)?values[n/2]:(values[n/2-1]+values[n/2])/2.0;
}
void Caption(const string key,const string text,const int x,const int y,const int size,const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
{
   string name=prefix+key;
   if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrSilver);ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");ObjectSetString(0,name,OBJPROP_TEXT,text);
}
// BRANDING_BEGIN — Harmony Algo | harmonyalgo.com. Calculations are independent.
void Branding()
{
   int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0),h=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   Caption("brand","Harmony Algo | harmonyalgo.com",w/2,h/2-12,14,ANCHOR_CENTER);
   Caption("cta","Explore premium indicators at harmonyalgo.com",w/2,h/2+12,10,ANCHOR_CENTER);
}
// BRANDING_END
int OnInit()
{
   if(BarsPerSegment<4||BarsPerSegment>30||TrendEntryScale<1||TrendReleaseScale<0||TrendReleaseScale>1||TrendReleaseScale>=TrendEntryScale||
      PullbackTriggerScale<0.25||PullbackTriggerScale>1||GuardDistanceScale<1.25||GuardDistanceScale>4||GuardDistanceScale<=PullbackTriggerScale||
      MaximumTrackingBars<8||MaximumTrackingBars>160||RetainedMaps<10||RetainedMaps>90)return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,TrendUp,INDICATOR_DATA);SetIndexBuffer(1,TrendDown,INDICATOR_DATA);SetIndexBuffer(2,TrendMixed,INDICATOR_DATA);
   SetIndexBuffer(3,UpRecovery,INDICATOR_DATA);SetIndexBuffer(4,DownRecovery,INDICATOR_DATA);SetIndexBuffer(5,WatchMark,INDICATOR_DATA);
   SetIndexBuffer(6,FailMark,INDICATOR_DATA);SetIndexBuffer(7,EndMark,INDICATOR_DATA);SetIndexBuffer(8,MoveBuffer,INDICATOR_DATA);
   SetIndexBuffer(9,DirectionBuffer,INDICATOR_DATA);SetIndexBuffer(10,WatchingBuffer,INDICATOR_DATA);SetIndexBuffer(11,FrozenBase,INDICATOR_DATA);
   SetIndexBuffer(12,FrozenUnit,INDICATOR_DATA);SetIndexBuffer(13,FrozenGuard,INDICATOR_DATA);SetIndexBuffer(14,FrozenRecovery,INDICATOR_DATA);
   SetIndexBuffer(15,Events,INDICATOR_DATA);SetIndexBuffer(16,Sides,INDICATOR_DATA);SetIndexBuffer(17,ATR,INDICATOR_CALCULATIONS);
   string names[]={"Up trend","Down trend","Mixed trend","Upward recovery","Downward recovery","Pullback watch","Frozen guard lost","Map ended","Trend move / scale","Direction","Watching","Frozen baseline","Frozen scale","Frozen guard","Frozen recovery","Event code","Event side"};
   for(int p=0;p<17;p++)
   {
      PlotIndexSetString(p,PLOT_LABEL,names[p]);PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      PlotIndexSetInteger(p,PLOT_DRAW_TYPE,p<3?DRAW_LINE:p<8?DRAW_ARROW:DRAW_NONE);
      if(p<8){color ink=(p==0||p==3)?Bull:(p==1||p==4)?Bear:(p==6||p==7)?clrGray:Neutral;PlotIndexSetInteger(p,PLOT_LINE_COLOR,ink);PlotIndexSetInteger(p,PLOT_LINE_WIDTH,p<5?2:1);}
      if(p>=3&&p<8)PlotIndexSetInteger(p,PLOT_ARROW,p==3?233:p==4?234:p==5?159:251);
   }
   IndicatorSetString(INDICATOR_SHORTNAME,"Pullback Recovery Map Community [Harmony Algo]");IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   prefix="PRM_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+"_";Branding();return INIT_SUCCEEDED;
}

// Harmony Algo | harmonyalgo.com — chronological confirmed-close calculation.
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
   ArraySetAsSeries(time,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
   if(rates_total<2)return 0;
   if(prev_calculated==rates_total&&lastOpen==time[rates_total-1])return rates_total;
   bool notify=prev_calculated>0&&lastOpen>0&&time[rates_total-1]>lastOpen;lastOpen=time[rates_total-1];
   int n=BarsPerSegment*8,dir=0,up=0,down=0,loss=0,dirAt=0,side=0,began=0,ended=-10000,bad=0,good=0;
   bool armed=false,watching=false;
   double baseline=EMPTY_VALUE,scale=EMPTY_VALUE,movement=EMPTY_VALUE,anchor=EMPTY_VALUE,unit=EMPTY_VALUE,guard=EMPTY_VALUE,recovery=EMPTY_VALUE,trsum=0;
   Map maps[];Mark marks[];
   for(int i=0;i<rates_total;i++)
   {
      TrendUp[i]=TrendDown[i]=TrendMixed[i]=UpRecovery[i]=DownRecovery[i]=WatchMark[i]=FailMark[i]=EndMark[i]=EMPTY_VALUE;
      int ev=0,es=0;
      double tr=i==0?high[i]-low[i]:MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1])));
      if(i<21)trsum+=tr;
      ATR[i]=i<20?EMPTY_VALUE:i==20?trsum/21.0:(ATR[i-1]*20+tr)/21.0;
      if(i<rates_total-1)
      {
         bool valid=i>=n&&ATR[i-1]!=EMPTY_VALUE&&ATR[i-1]>0;
         if(valid)
         {
            double means[8],slopes[28],intercepts[8],residuals[8],origin=close[i-n];
            for(int b=0;b<8;b++){double total=0;for(int k=0;k<BarsPerSegment;k++)total+=close[i-n+b*BarsPerSegment+k]-origin;means[b]=total/BarsPerSegment;}
            int k=0;for(int a=0;a<7;a++)for(int b=a+1;b<8;b++)slopes[k++]=(means[b]-means[a])/((b-a)*BarsPerSegment);
            double slope=Mid(slopes);
            for(int b=0;b<8;b++)intercepts[b]=means[b]-slope*(b*BarsPerSegment+(BarsPerSegment-1.0)/2.0);
            double intercept=Mid(intercepts);
            for(int b=0;b<8;b++)residuals[b]=MathAbs(means[b]-intercept-slope*(b*BarsPerSegment+(BarsPerSegment-1.0)/2.0));
            baseline=origin+intercept+slope*n;scale=MathMax(ATR[i-1],1.4826*Mid(residuals));movement=slope*(n-1)/scale;
            int old=dir;
            up=movement>=TrendEntryScale?up+1:0;down=movement<=-TrendEntryScale?down+1:0;loss=dir!=0&&dir*movement<=TrendReleaseScale?loss+1:0;
            if(up>=3)dir=1;else if(down>=3)dir=-1;else if(loss>=3)dir=0;
            if(dir!=old){dirAt=i;armed=false;loss=0;}
            if(watching)
            {
               es=side;bad=side*(close[i]-guard)<0?bad+1:0;good=side*(close[i]-recovery)>0?good+1:0;int age=i-began;
               if(bad>=2)ev=8;else if(dir!=side)ev=16;else if(age>=3&&good>=2)ev=side==1?2:4;else if(age>=MaximumTrackingBars)ev=16;
               int z=ArraySize(maps)-1;maps[z].last=i;
               if(ev!=0){maps[z].result=ev;watching=false;ended=i;armed=false;}
            }
            else if(dir!=0)
            {
               double distance=dir*(close[i]-baseline)/scale;
               if(distance>=0.5&&i-ended>12)armed=true;
               if(armed&&i-dirAt>=6&&i-ended>12&&distance<=-PullbackTriggerScale&&distance>=-GuardDistanceScale)
               {
                  watching=true;armed=false;side=dir;es=side;began=i;anchor=baseline;unit=scale;guard=anchor-side*GuardDistanceScale*unit;
                  recovery=side==1?MathMax(high[i],anchor+0.15*unit):MathMin(low[i],anchor-0.15*unit);bad=good=0;ev=1;
                  int z=ArraySize(maps);ArrayResize(maps,z+1,128);maps[z].first=maps[z].last=i;maps[z].side=side;maps[z].result=0;maps[z].baseline=anchor;maps[z].guard=guard;maps[z].recovery=recovery;
               }
            }
         }
         else
         {
            dir=0;up=down=loss=0;armed=false;baseline=scale=movement=EMPTY_VALUE;
            if(watching){es=side;ev=16;int z=ArraySize(maps)-1;maps[z].last=i;maps[z].result=16;watching=false;ended=i;}
         }
         if(ev!=0)
         {
            double spacing=scale==EMPTY_VALUE?(i>20?ATR[i-1]:_Point):scale;
            int z=ArraySize(marks);ArrayResize(marks,z+1,512);marks[z].bar=i;marks[z].side=es;marks[z].event=ev;marks[z].y=es==1?low[i]-0.3*spacing:high[i]+0.3*spacing;
            if(ev==1)WatchMark[i]=marks[z].y;else if(ev==2)UpRecovery[i]=marks[z].y;else if(ev==4)DownRecovery[i]=marks[z].y;else if(ev==8)FailMark[i]=marks[z].y;else EndMark[i]=marks[z].y;
         }
      }
      if(baseline!=EMPTY_VALUE){if(dir==1)TrendUp[i]=baseline;else if(dir==-1)TrendDown[i]=baseline;else TrendMixed[i]=baseline;}
      MoveBuffer[i]=movement;DirectionBuffer[i]=dir;WatchingBuffer[i]=watching?1:0;FrozenBase[i]=anchor;FrozenUnit[i]=unit;FrozenGuard[i]=guard;FrozenRecovery[i]=recovery;Events[i]=ev;Sides[i]=es;
   }
   ObjectsDeleteAll(0,prefix+"drawing_");
   for(int j=MathMax(0,ArraySize(maps)-RetainedMaps);j<ArraySize(maps);j++)
   {
      Map r=maps[j];color ink=r.result==8?clrGray:r.result==16?Neutral:r.side==1?Bull:Bear;string key=prefix+"drawing_map_"+IntegerToString(j);
      ObjectCreate(0,key,OBJ_RECTANGLE,0,time[r.first],MathMax(r.baseline,r.guard),time[r.last],MathMin(r.baseline,r.guard));ObjectSetInteger(0,key,OBJPROP_COLOR,ink);ObjectSetInteger(0,key,OBJPROP_FILL,false);ObjectSetInteger(0,key,OBJPROP_BACK,true);ObjectSetInteger(0,key,OBJPROP_SELECTABLE,false);
      key+="_recovery";ObjectCreate(0,key,OBJ_TREND,0,time[r.first],r.recovery,time[r.last],r.recovery);ObjectSetInteger(0,key,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,key,OBJPROP_STYLE,STYLE_DASH);ObjectSetInteger(0,key,OBJPROP_COLOR,ink);ObjectSetInteger(0,key,OBJPROP_SELECTABLE,false);
   }
   for(int j=0;j<ArraySize(marks);j++)
   {
      int i=marks[j].bar;
      if(j<ArraySize(marks)-400){UpRecovery[i]=DownRecovery[i]=WatchMark[i]=FailMark[i]=EndMark[i]=EMPTY_VALUE;continue;}
      int ev=marks[j].event;string text=ev==1?"Watch":ev==2?"Buy":ev==4?"Sell":ev==8?"Lost":"End";color ink=ev==2?Bull:ev==4?Bear:ev==1?Neutral:clrGray;
      string key=prefix+"drawing_label_"+IntegerToString(j);ObjectCreate(0,key,OBJ_TEXT,0,time[i],marks[j].y);ObjectSetString(0,key,OBJPROP_TEXT,text);ObjectSetInteger(0,key,OBJPROP_COLOR,ink);ObjectSetInteger(0,key,OBJPROP_FONTSIZE,8);ObjectSetInteger(0,key,OBJPROP_ANCHOR,marks[j].side==1?ANCHOR_LEFT_UPPER:ANCHOR_LEFT_LOWER);ObjectSetInteger(0,key,OBJPROP_SELECTABLE,false);
   }
   if(ShowSummary)
   {
      Caption("panelbrand","Harmony Algo | harmonyalgo.com",12,22,10);
      Caption("panel",(dir==1?"UP CONTEXT":dir==-1?"DOWN CONTEXT":"MIXED")+" | "+(watching?"WATCHING":"WAITING")+" | Move/scale "+DoubleToString(movement,2)+" | Not a forecast",12,40,10);
   }
   else{ObjectDelete(0,prefix+"panelbrand");ObjectDelete(0,prefix+"panel");}
   if(EnablePopupAlerts&&notify)
   {
      int e=(int)Events[rates_total-2];string msg=e==1?"Pullback watch":e==2?"Upward recovery":e==4?"Downward recovery":e==8?"Frozen guard lost":e==16?"Map ended":"";
      if(msg!="")Alert(msg," on ",_Symbol," ",EnumToString(_Period)," at closed bar ",TimeToString(time[rates_total-2]));
   }
   Branding();return rates_total;
}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){if(id==CHARTEVENT_CHART_CHANGE)Branding();}
void OnDeinit(const int reason){ObjectsDeleteAll(0,prefix);}
