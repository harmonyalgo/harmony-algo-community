// Reversal Pressure Community — Harmony Algo | harmonyalgo.com
// Original implementation by Iamalala; MT5 port by Harmony Algo.
// Mozilla Public License 2.0. Source and feed differences are documented in README.
#property copyright "Harmony Algo"
#property link "https://harmonyalgo.com"
#property description "Community price-analysis tool. Premium products at harmonyalgo.com are for TradingView."
#property indicator_chart_window
#property indicator_buffers 24
#property indicator_plots 24

input int LocationWindow=63;
input double MinimumRobustExtension=1.4;
input double RecoveryEvidenceATR=1.2;
input int PreparationLife=24;
input int ReferenceTrackingBars=48;
input int RecentReferencePairs=6;
input bool ShowPreparation=true;
input bool ShowStatusPanel=true;
enum PanelCorner{TopRight,BottomRight,TopLeft,BottomLeft};
input PanelCorner StatusCorner=TopRight;
input color BuyColor=C'1,130,8';input color SellColor=C'209,34,8';
input bool EnablePopupAlerts=false;
double B0[];
double B1[];
double B2[];
double B3[];
double B4[];
double B5[];
double B6[];
double B7[];
double B8[];
double B9[];
double B10[];
double B11[];
double B12[];
double B13[];
double B14[];
double B15[];
double B16[];
double B17[];
double B18[];
double B19[];
double B20[];
double B21[];
double B22[];
double B23[];
string prefix;datetime lastOpen=0;
struct RecoveryCheckpoint {int phase,side,started,triggered,ended,lastSignal;double center,unit,extreme,evidence,required,invalidation,lastLong,lastShort;bool fatigue,guard,longLocked,shortLocked;string centerRail,stopRail;};
RecoveryCheckpoint saved;
double atr[];
int doneClosed=-1;
datetime firstHistory=0,closedStamp=0;

string marks[],maps[];
void Text(const string key,const string text,int x,int y,int size=10,ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
{
 string n=prefix+key;if(ObjectFind(0,n)<0)ObjectCreate(0,n,OBJ_LABEL,0,0,0);
 ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetInteger(0,n,OBJPROP_ANCHOR,anchor);
 ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
 ObjectSetInteger(0,n,OBJPROP_COLOR,clrSilver);ObjectSetInteger(0,n,OBJPROP_FONTSIZE,size);
 ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
 ObjectSetString(0,n,OBJPROP_FONT,"Arial");ObjectSetString(0,n,OBJPROP_TEXT,text);
}
void Brand()
{
 int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),h=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
 Text("brand","Harmony Algo | harmonyalgo.com",w/2,h/2-12,13,ANCHOR_CENTER);
 Text("cta","Explore premium indicators at harmonyalgo.com",w/2,h/2+12,10,ANCHOR_CENTER);
}
void Keep(string &queue[],string name,int limit)
{
 int n=ArraySize(queue);ArrayResize(queue,n+1);queue[n]=name;
 if(n>=limit){ObjectDelete(0,queue[0]);for(int k=0;k<n;k++)queue[k]=queue[k+1];ArrayResize(queue,n);}
}
void Mark(datetime when,double price,string caption,color shade,int limit=500)
{
 string n=prefix+"event_"+IntegerToString(when)+"_"+IntegerToString(ArraySize(marks));
 ObjectCreate(0,n,OBJ_TEXT,0,when,price);ObjectSetString(0,n,OBJPROP_TEXT,caption);
 ObjectSetInteger(0,n,OBJPROP_COLOR,shade);ObjectSetInteger(0,n,OBJPROP_FONTSIZE,9);
 ObjectSetInteger(0,n,OBJPROP_ANCHOR,ANCHOR_CENTER);ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
 Keep(marks,n,limit);
}
void Rail(string id,datetime a,datetime b,double price,color shade,ENUM_LINE_STYLE style=STYLE_DASH)
{
 string n=prefix+id;ObjectCreate(0,n,OBJ_TREND,0,a,price,b,price);
 ObjectSetInteger(0,n,OBJPROP_COLOR,shade);ObjectSetInteger(0,n,OBJPROP_STYLE,style);
 ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
}
double Quantile(double &values[],double percent,bool nearest=false)
{
 int n=ArraySize(values);if(n==0)return EMPTY_VALUE;
 double v[];ArrayCopy(v,values);ArraySort(v);
 if(nearest)return v[MathMax(0,(int)MathCeil(n*percent/100.0)-1)];
 double p=(n-1)*percent/100.0;int k=(int)MathFloor(p);
 return v[k]+(v[MathMin(k+1,n-1)]-v[k])*(p-k);
}
void Push(double &v[],double value,int limit){int n=ArraySize(v);ArrayResize(v,n+1);v[n]=value;if(n>=limit){for(int k=0;k<n;k++)v[k]=v[k+1];ArrayResize(v,n);}}
double Rank(double &v[],double value){int n=ArraySize(v);if(!n)return EMPTY_VALUE;double k=0;for(int j=0;j<n;j++)k+=v[j]<value?1:v[j]==value?0.5:0;return 100*k/n;}
void OnChartEvent(const int id,const long &l,const double &d,const string &s){if(id==CHARTEVENT_CHART_CHANGE)Brand();}
void OnDeinit(const int reason){ObjectsDeleteAll(0,prefix);}
int OnInit(){if(LocationWindow<31||LocationWindow>251||MinimumRobustExtension<0.8||MinimumRobustExtension>3||RecoveryEvidenceATR<0.6||RecoveryEvidenceATR>3||PreparationLife<8||PreparationLife>80||ReferenceTrackingBars<12||ReferenceTrackingBars>120||RecentReferencePairs<1||RecentReferencePairs>30)return INIT_PARAMETERS_INCORRECT;SetIndexBuffer(0,B0,INDICATOR_DATA);
SetIndexBuffer(1,B1,INDICATOR_DATA);
SetIndexBuffer(2,B2,INDICATOR_DATA);
SetIndexBuffer(3,B3,INDICATOR_DATA);
SetIndexBuffer(4,B4,INDICATOR_DATA);
SetIndexBuffer(5,B5,INDICATOR_DATA);
SetIndexBuffer(6,B6,INDICATOR_DATA);
SetIndexBuffer(7,B7,INDICATOR_DATA);
SetIndexBuffer(8,B8,INDICATOR_DATA);
SetIndexBuffer(9,B9,INDICATOR_DATA);
SetIndexBuffer(10,B10,INDICATOR_DATA);
SetIndexBuffer(11,B11,INDICATOR_DATA);
SetIndexBuffer(12,B12,INDICATOR_DATA);
SetIndexBuffer(13,B13,INDICATOR_DATA);
SetIndexBuffer(14,B14,INDICATOR_DATA);
SetIndexBuffer(15,B15,INDICATOR_DATA);
SetIndexBuffer(16,B16,INDICATOR_DATA);
SetIndexBuffer(17,B17,INDICATOR_DATA);
SetIndexBuffer(18,B18,INDICATOR_DATA);
SetIndexBuffer(19,B19,INDICATOR_DATA);
SetIndexBuffer(20,B20,INDICATOR_DATA);
SetIndexBuffer(21,B21,INDICATOR_DATA);
SetIndexBuffer(22,B22,INDICATOR_DATA);
SetIndexBuffer(23,B23,INDICATOR_DATA);
PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(5,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(6,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(7,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(8,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(9,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(10,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(11,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(12,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(12,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(13,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(13,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(14,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(14,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(15,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(15,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(16,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(16,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(17,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(17,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(18,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(18,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(19,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(19,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(20,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(20,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(21,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(21,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(22,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(22,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(23,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(23,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(0,PLOT_LABEL,"Preparation outer");PlotIndexSetInteger(0,PLOT_LINE_COLOR,C'1,130,8');
PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(1,PLOT_LABEL,"Preparation inner");PlotIndexSetInteger(1,PLOT_LINE_COLOR,C'127,73,222');
PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_ARROW);PlotIndexSetString(2,PLOT_LABEL,"Buy");PlotIndexSetInteger(2,PLOT_LINE_COLOR,C'1,130,8');PlotIndexSetInteger(2,PLOT_ARROW,233);
PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_ARROW);PlotIndexSetString(3,PLOT_LABEL,"Sell");PlotIndexSetInteger(3,PLOT_LINE_COLOR,C'209,34,8');PlotIndexSetInteger(3,PLOT_ARROW,234);
PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_ARROW);PlotIndexSetString(4,PLOT_LABEL,"Buy preparation");PlotIndexSetInteger(4,PLOT_LINE_COLOR,C'1,130,8');PlotIndexSetInteger(4,PLOT_ARROW,233);
PlotIndexSetInteger(5,PLOT_DRAW_TYPE,DRAW_ARROW);PlotIndexSetString(5,PLOT_LABEL,"Sell preparation");PlotIndexSetInteger(5,PLOT_LINE_COLOR,C'209,34,8');PlotIndexSetInteger(5,PLOT_ARROW,234);
PlotIndexSetInteger(6,PLOT_DRAW_TYPE,DRAW_ARROW);PlotIndexSetString(6,PLOT_LABEL,"Outcome");PlotIndexSetInteger(6,PLOT_LINE_COLOR,clrSilver);PlotIndexSetInteger(6,PLOT_ARROW,233);IndicatorSetString(INDICATOR_SHORTNAME,"Reversal Pressure Community [Harmony Algo]");IndicatorSetInteger(INDICATOR_DIGITS,_Digits);prefix="ReversalPressure_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+"_";Brand();return INIT_SUCCEEDED;}int OnCalculate(const int total,const int previous,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
 ArraySetAsSeries(time,false);ArraySetAsSeries(open,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
 if(total<2)return 0;bool reset=previous==0 || previous>total || doneClosed<0 || doneClosed>=total || firstHistory!=time[0] || closedStamp!=time[doneClosed];
 if(!reset && previous==total && lastOpen==time[total-1])return total;
 if(reset){doneClosed=-1;firstHistory=time[0];saved.phase=saved.side=0;saved.started=saved.triggered=saved.lastSignal=-1;saved.ended=-100000;saved.center=saved.unit=saved.extreme=saved.required=saved.invalidation=saved.lastLong=saved.lastShort=EMPTY_VALUE;saved.evidence=0;saved.fatigue=saved.guard=saved.longLocked=saved.shortLocked=false;saved.centerRail=saved.stopRail="";}
 int start=doneClosed+1;
 

 bool notify=previous>0 && lastOpen>0 && time[total-1]>lastOpen;lastOpen=time[total-1];
 if(reset){ObjectsDeleteAll(0,prefix);ArrayResize(marks,0);ArrayResize(maps,0);}

 ArrayResize(atr,total);
 int phase=saved.phase,side=saved.side,started=saved.started,triggered=saved.triggered,ended=saved.ended,lastSignal=saved.lastSignal;
 double center=saved.center,unit=saved.unit,extreme=saved.extreme,evidence=saved.evidence,required=saved.required,invalidation=saved.invalidation,lastLong=saved.lastLong,lastShort=saved.lastShort;
 bool fatigue=saved.fatigue,guard=saved.guard,longLocked=saved.longLocked,shortLocked=saved.shortLocked;
 string centerRail=saved.centerRail,stopRail=saved.stopRail;
 for(int i=start;i<total;i++)
 {
B0[i]=EMPTY_VALUE;B1[i]=EMPTY_VALUE;B2[i]=EMPTY_VALUE;B3[i]=EMPTY_VALUE;B4[i]=EMPTY_VALUE;B5[i]=EMPTY_VALUE;B6[i]=EMPTY_VALUE;B7[i]=EMPTY_VALUE;B8[i]=EMPTY_VALUE;B9[i]=EMPTY_VALUE;B10[i]=EMPTY_VALUE;B11[i]=EMPTY_VALUE;B12[i]=EMPTY_VALUE;B13[i]=EMPTY_VALUE;B14[i]=EMPTY_VALUE;B15[i]=EMPTY_VALUE;B16[i]=EMPTY_VALUE;B17[i]=EMPTY_VALUE;B18[i]=EMPTY_VALUE;B19[i]=EMPTY_VALUE;B20[i]=EMPTY_VALUE;B21[i]=EMPTY_VALUE;B22[i]=EMPTY_VALUE;B23[i]=EMPTY_VALUE;
  double tr=i==0?high[i]-low[i]:MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1])));
  double trsum=0;if(i==20){for(int q=0;q<=20;q++)trsum+=q==0?high[q]-low[q]:MathMax(high[q]-low[q],MathMax(MathAbs(high[q]-close[q-1]),MathAbs(low[q]-close[q-1])));}atr[i]=i<20?EMPTY_VALUE:i==20?trsum/21:(atr[i-1]*20+tr)/21;
  double median=EMPTY_VALUE,scale=EMPTY_VALUE,stretch=EMPTY_VALUE,efficiency=0;
  if(i>=LocationWindow && i>21 && atr[i-1]!=EMPTY_VALUE)
  {
   double xs[];ArrayResize(xs,LocationWindow);for(int k=0;k<LocationWindow;k++)xs[k]=close[i-1-k];
   median=Quantile(xs,50);scale=MathMax((Quantile(xs,75)-Quantile(xs,25))/1.349,MathMax(atr[i-1],_Point));stretch=(close[i]-median)/scale;
   double path=0;for(int k=1;k<=20;k++)path+=MathAbs(close[i-k]-close[i-k-1]);efficiency=path>0?MathAbs(close[i-1]-close[i-21])/path:0;
  }
  int arm=0,signal=0,end=0;
  if(i<total-1 && stretch!=EMPTY_VALUE && atr[i-1]>_Point)
  {
   if(stretch>-0.5 || (lastLong!=EMPTY_VALUE && low[i]<lastLong-2*atr[i-1]))longLocked=false;
   if(stretch<0.5 || (lastShort!=EMPTY_VALUE && high[i]>lastShort+2*atr[i-1]))shortLocked=false;
   int old=phase;
   if(old==2)
   {
    ObjectMove(0,prefix+centerRail,1,time[i],center);ObjectMove(0,prefix+stopRail,1,time[i],invalidation);
    bool failed=side*(close[i]-invalidation)<=0,recovered=side*(close[i]-center)>=0,stale=i-triggered>=ReferenceTrackingBars;
    if(failed||recovered||stale){end=failed?-1:recovered?1:2;phase=side=0;ended=i;}
   }
   else if(old==1)
   {
    bool newer=side==1?low[i]<extreme:high[i]>extreme;
    if(newer){extreme=side==1?low[i]:high[i];evidence=0;fatigue=false;}
    else evidence=MathMax(0,evidence+side*(close[i]-close[i-1])/unit-0.10);
    if(side==1)lastLong=extreme;else lastShort=extreme;
    double range=high[i]-low[i],tail=side==1?MathMin(open[i],close[i])-low[i]:high[i]-MathMax(open[i],close[i]);
    double location=range>0?(side==1?close[i]-low[i]:high[i]-close[i])/range:0;
    bool rejection=range>=0.5*unit && tail>=0.4*range && location>=0.65;
    double earlier=side*(close[i-8]-close[i-4])/(4*unit),latest=side*(close[i-4]-close[i])/(4*unit);
    fatigue=fatigue||rejection||(earlier>=0.08 && latest<0.6*earlier);
    double rebound=side*(close[i]-extreme)/unit;
    bool reclaim=side==1?close[i]>high[i-1] && close[i]>open[i]:close[i]<low[i-1] && close[i]<open[i];
    bool reached=side*(close[i]-center)>=0,expired=i-started>=PreparationLife;
    if(reached||expired){end=reached?4:3;phase=side=0;ended=i;}
    else if(!newer && fatigue && evidence>=required && rebound>=0.8 && rebound<=2.8 && reclaim)
    {
     signal=side;phase=2;triggered=i;invalidation=extreme-side*0.15*unit;
     Mark(time[i],side==1?low[i]-0.25*unit:high[i]+0.25*unit,side==1?"Buy ▲":"Sell ▼",side==1?BuyColor:SellColor);
     centerRail="center_"+IntegerToString(i);stopRail="stop_"+IntegerToString(i);
     Rail(centerRail,time[i],time[MathMin(i+1,total-1)],center,clrSilver,STYLE_DOT);
     Rail(stopRail,time[i],time[MathMin(i+1,total-1)],invalidation,side==1?BuyColor:SellColor);
     Keep(maps,prefix+centerRail,RecentReferencePairs*2);Keep(maps,prefix+stopRail,RecentReferencePairs*2);
    }
   }
   else if(i-ended>6)
   {
    int candidate=stretch<=-MinimumRobustExtension && !longLocked?1:stretch>=MinimumRobustExtension && !shortLocked?-1:0;
    if(candidate!=0){side=candidate;phase=1;started=i;center=median;unit=atr[i-1];extreme=side==1?low[i]:high[i];evidence=0;fatigue=false;invalidation=EMPTY_VALUE;
     guard=efficiency>=0.6 && side*(close[i-1]-close[i-21])<0;required=RecoveryEvidenceATR*(guard?1.35:1);arm=side;
     if(side==1){longLocked=true;lastLong=extreme;}else{shortLocked=true;lastShort=extreme;}}
   }
   if(phase==1){if(side==1)longLocked=true;else shortLocked=true;}
  }
  if(ShowPreparation && phase==1){B0[i]=extreme;B1[i]=extreme+side*0.25*unit;}
  if(signal==1)B2[i]=low[i]-0.25*unit;if(signal==-1)B3[i]=high[i]+0.25*unit;
  if(ShowPreparation && arm==1)B4[i]=low[i]-0.3*atr[i-1];if(ShowPreparation && arm==-1)B5[i]=high[i]+0.3*atr[i-1];
  if(end==-1||end==1||end==2)B6[i]=close[i];
  B7[i]=phase;B8[i]=side;B9[i]=stretch;B10[i]=center;B11[i]=unit;B12[i]=extreme;B13[i]=evidence;B14[i]=required;B15[i]=fatigue?1:0;B16[i]=invalidation;B17[i]=arm;B18[i]=signal;B19[i]=end;B20[i]=efficiency;B21[i]=i>0?atr[i-1]:EMPTY_VALUE;B22[i]=median;B23[i]=scale;
 }
 saved.phase=phase;saved.side=side;saved.started=started;saved.triggered=triggered;saved.ended=ended;saved.lastSignal=lastSignal;saved.center=center;saved.unit=unit;saved.extreme=extreme;saved.evidence=evidence;saved.required=required;saved.invalidation=invalidation;saved.lastLong=lastLong;saved.lastShort=lastShort;saved.fatigue=fatigue;saved.guard=guard;saved.longLocked=longLocked;saved.shortLocked=shortLocked;saved.centerRail=centerRail;saved.stopRail=stopRail;
 doneClosed=total-2;closedStamp=time[doneClosed];
 int k=total-2;
 if(ShowStatusPanel){int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),h=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);int x=StatusCorner==TopRight||StatusCorner==BottomRight?w-350:12,y=StatusCorner==BottomLeft||StatusCorner==BottomRight?h-100:22;
  Text("panelbrand","Harmony Algo | harmonyalgo.com",x,y);Text("panel","Reversal Pressure | Phase "+IntegerToString((int)B7[k])+" | Side "+IntegerToString((int)B8[k]),x,y+18);Text("evidence","Recovery "+DoubleToString(B13[k],2)+" / "+DoubleToString(B14[k],2)+" ATR",x,y+36);}
 if(notify && EnablePopupAlerts){if(B18[k]!=0)Alert("Reversal Pressure: ",B18[k]>0?"Buy reversal":"Sell reversal"," ",_Symbol);if(B17[k]!=0)Alert("Reversal Pressure: preparation ",_Symbol);if(B19[k]==-1)Alert("Reversal Pressure: closing invalidation ",_Symbol);}

Brand();return total;
}