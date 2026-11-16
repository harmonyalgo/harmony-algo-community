// Intrinsic Trend Anatomy Community — Harmony Algo | harmonyalgo.com
// Original implementation by Iamalala; MT5 port by Harmony Algo.
// Mozilla Public License 2.0. Source and feed differences are documented in README.
#property copyright "Harmony Algo"
#property link "https://harmonyalgo.com"
#property description "Community price-analysis tool. Premium products at harmonyalgo.com are for TradingView."
#property indicator_chart_window
#property indicator_buffers 26
#property indicator_plots 21

input int VolatilityReference=30;input double StructureDistanceATR=3.0;
input double MicroStructureScale=0.35;input double BroadStructureScale=2.0;
input int CompletedExcursionsRetained=80;input int MinimumReferenceSamples=12;
input bool ColorCandles=true;input bool ShowBoundary=true;input bool ShowCorridor=true;
input bool ShowEvents=true;input bool ShowPanel=true;
input color UpColor=C'1,130,8';input color DownColor=C'209,34,8';input color MixedColor=C'127,73,222';
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
double B24[];
double B25[];
string prefix;datetime lastOpen=0;
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

struct Clock{int direction;double extreme,threshold;};
bool Advance(Clock &c,double p,double seed)
{
 if(c.extreme==EMPTY_VALUE){c.extreme=p;c.threshold=seed;return false;}
 if(c.direction==0){if(MathAbs(p-c.extreme)>=c.threshold){c.direction=p>c.extreme?1:-1;c.extreme=p;c.threshold=seed;return true;}}
 else if(c.direction==1){if(p>c.extreme)c.extreme=p;else if(c.extreme-p>=c.threshold){c.direction=-1;c.extreme=p;c.threshold=seed;return true;}}
 else {if(p<c.extreme)c.extreme=p;else if(p-c.extreme>=c.threshold){c.direction=1;c.extreme=p;c.threshold=seed;return true;}}
 return false;
}
int OnInit(){if(VolatilityReference<5||VolatilityReference>100||StructureDistanceATR<1||StructureDistanceATR>10||MicroStructureScale<0.15||MicroStructureScale>0.75||BroadStructureScale<1.25||BroadStructureScale>4||CompletedExcursionsRetained<20||CompletedExcursionsRetained>200||MinimumReferenceSamples<8||MinimumReferenceSamples>20)return INIT_PARAMETERS_INCORRECT;SetIndexBuffer(0,B0,INDICATOR_DATA);
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
SetIndexBuffer(24,B24,INDICATOR_DATA);
SetIndexBuffer(25,B25,INDICATOR_DATA);
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
PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES);PlotIndexSetString(0,PLOT_LABEL,"Confirmed anatomy");PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrGray);
PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(1,PLOT_LABEL,"Structure boundary");PlotIndexSetInteger(1,PLOT_LINE_COLOR,C'1,130,8');
PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(2,PLOT_LABEL,"Historical pullback depth");PlotIndexSetInteger(2,PLOT_LINE_COLOR,C'127,73,222');
PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(3,PLOT_LABEL,"Pullback structure edge");PlotIndexSetInteger(3,PLOT_LINE_COLOR,C'127,73,222');
PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_FILLING);PlotIndexSetString(4,PLOT_LABEL,"Local pullback corridor");PlotIndexSetInteger(4,PLOT_LINE_COLOR,C'35,22,48');SetIndexBuffer(4,B4,INDICATOR_COLOR_INDEX);PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,6);PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,clrGray);PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,MixedColor);PlotIndexSetInteger(0,PLOT_LINE_COLOR,2,C'42,191,36');PlotIndexSetInteger(0,PLOT_LINE_COLOR,3,C'243,22,35');PlotIndexSetInteger(0,PLOT_LINE_COLOR,4,UpColor);PlotIndexSetInteger(0,PLOT_LINE_COLOR,5,DownColor);IndicatorSetString(INDICATOR_SHORTNAME,"Intrinsic Trend Anatomy Community [Harmony Algo]");IndicatorSetInteger(INDICATOR_DIGITS,_Digits);prefix="IntrinsicTrendAnatomy_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+"_";Brand();return INIT_SUCCEEDED;}int OnCalculate(const int total,const int previous,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
 ArraySetAsSeries(time,false);ArraySetAsSeries(open,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
 if(total<2)return 0;if(previous==total && lastOpen==time[total-1])return total;
 bool notify=previous>0 && lastOpen>0 && time[total-1]>lastOpen;lastOpen=time[total-1];
 ObjectsDeleteAll(0,prefix);ArrayResize(marks,0);ArrayResize(maps,0);
ArrayInitialize(B0,EMPTY_VALUE);ArrayInitialize(B1,EMPTY_VALUE);ArrayInitialize(B2,EMPTY_VALUE);ArrayInitialize(B3,EMPTY_VALUE);ArrayInitialize(B4,EMPTY_VALUE);ArrayInitialize(B5,EMPTY_VALUE);ArrayInitialize(B6,EMPTY_VALUE);ArrayInitialize(B7,EMPTY_VALUE);ArrayInitialize(B8,EMPTY_VALUE);ArrayInitialize(B9,EMPTY_VALUE);ArrayInitialize(B10,EMPTY_VALUE);ArrayInitialize(B11,EMPTY_VALUE);ArrayInitialize(B12,EMPTY_VALUE);ArrayInitialize(B13,EMPTY_VALUE);ArrayInitialize(B14,EMPTY_VALUE);ArrayInitialize(B15,EMPTY_VALUE);ArrayInitialize(B16,EMPTY_VALUE);ArrayInitialize(B17,EMPTY_VALUE);ArrayInitialize(B18,EMPTY_VALUE);ArrayInitialize(B19,EMPTY_VALUE);ArrayInitialize(B20,EMPTY_VALUE);ArrayInitialize(B21,EMPTY_VALUE);ArrayInitialize(B22,EMPTY_VALUE);ArrayInitialize(B23,EMPTY_VALUE);ArrayInitialize(B24,EMPTY_VALUE);ArrayInitialize(B25,EMPTY_VALUE);
 Clock micro,structure,broad;micro.direction=structure.direction=broad.direction=0;micro.extreme=structure.extreme=broad.extreme=EMPTY_VALUE;
 double dh[],ph[],dr[],pr[],atr[];ArrayResize(atr,total);double trsum=0;
 bool active=false,warned=false;double anchor=EMPTY_VALUE,scale=EMPTY_VALUE,maxDepth=0,path=0,depthRank=EMPTY_VALUE,pathRank=EMPTY_VALUE,corridor=EMPTY_VALUE;
 int recovered=0,failed=0;
 for(int i=0;i<total;i++)
 {
  double tr=i==0?high[i]-low[i]:MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1])));
  if(i<VolatilityReference)trsum+=tr;
  atr[i]=i<VolatilityReference-1?EMPTY_VALUE:i==VolatilityReference-1?trsum/VolatilityReference:(atr[i-1]*(VolatilityReference-1)+tr)/VolatilityReference;
  bool shiftUp=false,shiftDown=false,resumeUp=false,resumeDown=false,stress=false;
  if(i<total-1 && i>0 && close[i]>0 && close[i-1]>0 && atr[i-1]!=EMPTY_VALUE && atr[i-1]>0)
  {
   double p=MathLog(close[i]),seed=MathMax(MathLog(1+StructureDistanceATR*atr[i-1]/close[i-1]),0.000001);
   int old=structure.direction;Advance(micro,p,seed*MicroStructureScale);bool changed=Advance(structure,p,seed);Advance(broad,p,seed*BroadStructureScale);
   shiftUp=changed && structure.direction==1;shiftDown=changed && structure.direction==-1;
   if(active)
   {
    maxDepth=MathMax(maxDepth,MathMax(0,old*(anchor-p)/scale));path+=MathAbs(p-MathLog(close[i-1]))/scale;
    bool enough=ArraySize(dr)>=MinimumReferenceSamples;
    depthRank=enough?Rank(dr,maxDepth):EMPTY_VALUE;pathRank=enough?Rank(pr,path):EMPTY_VALUE;
    bool stressed=enough && (depthRank>=80 || (depthRank>=50 && pathRank>=90));
    bool done=old*(p-anchor)>=0;
    if(changed||done){Push(dh,maxDepth,CompletedExcursionsRetained);Push(ph,path,CompletedExcursionsRetained);if(changed)failed++;else{recovered++;resumeUp=old==1;resumeDown=old==-1;}active=false;warned=false;}
    else if(stressed && !warned){stress=true;warned=true;}
   }
   if(!active && !changed && structure.direction!=0)
   {
    double retracement=structure.direction*(structure.extreme-p)/structure.threshold;
    if(retracement>=0.20)
    {
     active=true;warned=false;anchor=structure.extreme;scale=structure.threshold;maxDepth=retracement;path=MathAbs(p-MathLog(close[i-1]))/scale;
     ArrayCopy(dr,dh);ArrayResize(dr,ArraySize(dh));ArrayCopy(pr,ph);ArrayResize(pr,ArraySize(ph));
     bool enough=ArraySize(dr)>=MinimumReferenceSamples;
     corridor=enough?MathMin(0.90,MathMax(0.20,Quantile(dr,70))):EMPTY_VALUE;
     depthRank=enough?Rank(dr,maxDepth):EMPTY_VALUE;pathRank=enough?Rank(pr,path):EMPTY_VALUE;
     if(enough && (depthRank>=80 || (depthRank>=50 && pathRank>=90))){stress=true;warned=true;}
    }
   }
  }
  bool initialized=structure.direction!=0,aligned=initialized && broad.direction==structure.direction,all=aligned && micro.direction==structure.direction;
  int shade=!initialized?0:active||!aligned?1:all?(structure.direction==1?2:3):(structure.direction==1?4:5);
  if(ColorCandles){B0[i]=open[i];B1[i]=high[i];B2[i]=low[i];B3[i]=close[i];B4[i]=shade;}
  double boundary=initialized?MathExp(structure.extreme-structure.direction*structure.threshold):EMPTY_VALUE;
  if(ShowBoundary && !shiftUp && !shiftDown)B5[i]=boundary;
  if(ShowCorridor && active && corridor!=EMPTY_VALUE){B6[i]=MathExp(anchor-structure.direction*scale*corridor);B7[i]=MathExp(anchor-structure.direction*scale);B8[i]=B6[i];B9[i]=B7[i];}
  double gap=(i>0 && atr[i-1]!=EMPTY_VALUE?atr[i-1]:high[i]-low[i])*1.05;
  if(ShowEvents){if(shiftUp)Mark(time[i],low[i]-gap,"Trend ▲",UpColor,150);if(shiftDown)Mark(time[i],high[i]+gap,"Trend ▼",DownColor,150);if(resumeUp)Mark(time[i],low[i]-gap,"Resume ▲",UpColor,150);if(resumeDown)Mark(time[i],high[i]+gap,"Resume ▼",DownColor,150);if(stress)Mark(time[i],structure.direction==1?high[i]+gap:low[i]-gap,"Stress",MixedColor,150);}
  B10[i]=active?depthRank:EMPTY_VALUE;B11[i]=active?pathRank:EMPTY_VALUE;B12[i]=ArraySize(dh);B13[i]=recovered;B14[i]=failed;
  B15[i]=shiftUp?1:0;B16[i]=shiftDown?1:0;B17[i]=resumeUp?1:0;B18[i]=resumeDown?1:0;B19[i]=stress?1:0;
  B20[i]=structure.direction;B21[i]=active?1:0;B22[i]=warned?1:0;B23[i]=boundary;B24[i]=micro.direction;B25[i]=broad.direction;
 }
 int k=total-2;
 if(ShowPanel){Text("panelbrand","Harmony Algo | harmonyalgo.com",12,22);Text("panel","Intrinsic anatomy | "+(structure.direction==1?"UP":structure.direction==-1?"DOWN":"Building")+" | "+(active?(warned?"Unusual pullback":"Pullback"):"Structure"),12,40);Text("ranks","Depth / path rank: "+(active && depthRank!=EMPTY_VALUE?DoubleToString(depthRank,0)+" / "+DoubleToString(pathRank,0):"-- / --")+" | Completed "+IntegerToString(ArraySize(dh)),12,58);}
 if(notify && EnablePopupAlerts){if(B15[k]>0)Alert("Intrinsic Anatomy: up structure ",_Symbol);if(B16[k]>0)Alert("Intrinsic Anatomy: down structure ",_Symbol);if(B17[k]>0||B18[k]>0)Alert("Intrinsic Anatomy: pullback recovered ",_Symbol);if(B19[k]>0)Alert("Intrinsic Anatomy: unusual pullback ",_Symbol);}

Brand();return total;
}