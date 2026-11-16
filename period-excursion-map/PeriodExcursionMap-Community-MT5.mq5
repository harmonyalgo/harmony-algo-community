// Period Excursion Map Community — Harmony Algo | harmonyalgo.com
// Original implementation by Iamalala; MT5 port by Harmony Algo.
// Mozilla Public License 2.0. Source and feed differences are documented in README.
#property copyright "Harmony Algo"
#property link "https://harmonyalgo.com"
#property description "Community price-analysis tool. Premium products at harmonyalgo.com are for TradingView."
#property indicator_chart_window
#property indicator_buffers 16
#property indicator_plots 14

enum ReferenceChoice{Daily=PERIOD_D1,Weekly=PERIOD_W1,Monthly=PERIOD_MN1};
input ReferenceChoice ReferencePeriod=Daily;
input int CompletedPeriodsInMemory=80;input int ReferenceATRLength=20;input int OuterPercentile=80;
input bool ShowContextPanel=true;input bool ShowEvents=true;
input color UpperColor=C'1,130,8';input color LowerColor=C'209,34,8';
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
int OnInit(){if(CompletedPeriodsInMemory<20||CompletedPeriodsInMemory>250||ReferenceATRLength<5||ReferenceATRLength>100||OuterPercentile<60||OuterPercentile>95)return INIT_PARAMETERS_INCORRECT;SetIndexBuffer(0,B0,INDICATOR_DATA);
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
PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(0,PLOT_LABEL,"Previous period close");PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrSilver);
PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(1,PLOT_LABEL,"Upper median");PlotIndexSetInteger(1,PLOT_LINE_COLOR,C'1,130,8');
PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(2,PLOT_LABEL,"Upper outer");PlotIndexSetInteger(2,PLOT_LINE_COLOR,C'1,130,8');
PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(3,PLOT_LABEL,"Lower median");PlotIndexSetInteger(3,PLOT_LINE_COLOR,C'209,34,8');
PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_LINE);PlotIndexSetString(4,PLOT_LABEL,"Lower outer");PlotIndexSetInteger(4,PLOT_LINE_COLOR,C'209,34,8');
PlotIndexSetInteger(5,PLOT_DRAW_TYPE,DRAW_FILLING);PlotIndexSetString(5,PLOT_LABEL,"Upper excursion zone");PlotIndexSetInteger(5,PLOT_LINE_COLOR,C'12,35,18');
PlotIndexSetInteger(6,PLOT_DRAW_TYPE,DRAW_FILLING);PlotIndexSetString(6,PLOT_LABEL,"Lower excursion zone");PlotIndexSetInteger(6,PLOT_LINE_COLOR,C'40,18,22');
PlotIndexSetInteger(7,PLOT_DRAW_TYPE,DRAW_ARROW);PlotIndexSetString(7,PLOT_LABEL,"Up outer event");PlotIndexSetInteger(7,PLOT_LINE_COLOR,C'1,130,8');PlotIndexSetInteger(7,PLOT_ARROW,233);
PlotIndexSetInteger(8,PLOT_DRAW_TYPE,DRAW_ARROW);PlotIndexSetString(8,PLOT_LABEL,"Down outer event");PlotIndexSetInteger(8,PLOT_LINE_COLOR,C'209,34,8');PlotIndexSetInteger(8,PLOT_ARROW,234);IndicatorSetString(INDICATOR_SHORTNAME,"Period Excursion Map Community [Harmony Algo]");IndicatorSetInteger(INDICATOR_DIGITS,_Digits);prefix="PeriodExcursionMap_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+"_";Brand();return INIT_SUCCEEDED;}int OnCalculate(const int total,const int previous,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
 ArraySetAsSeries(time,false);ArraySetAsSeries(open,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
 if(PeriodSeconds(_Period)>=PeriodSeconds((ENUM_TIMEFRAMES)ReferencePeriod))
 {
  // Unsupported chart: remain attached and explain, with no levels or events.
  // Same behavior in charts and the tester; no tester-detection branches.
  if(previous!=total){ArrayInitialize(B0,EMPTY_VALUE);ArrayInitialize(B1,EMPTY_VALUE);ArrayInitialize(B2,EMPTY_VALUE);ArrayInitialize(B3,EMPTY_VALUE);ArrayInitialize(B4,EMPTY_VALUE);ArrayInitialize(B5,EMPTY_VALUE);ArrayInitialize(B6,EMPTY_VALUE);ArrayInitialize(B7,EMPTY_VALUE);ArrayInitialize(B8,EMPTY_VALUE);ArrayInitialize(B9,EMPTY_VALUE);ArrayInitialize(B10,EMPTY_VALUE);ArrayInitialize(B11,EMPTY_VALUE);ArrayInitialize(B12,EMPTY_VALUE);ArrayInitialize(B13,EMPTY_VALUE);ArrayInitialize(B14,EMPTY_VALUE);ArrayInitialize(B15,0);}
  Text("timeframe_notice","Inactive: select a chart timeframe below "+EnumToString((ENUM_TIMEFRAMES)ReferencePeriod),12,78);
  Brand();return total;
 }
 if(total<2)return 0;if(previous==total && lastOpen==time[total-1])return total;
 bool notify=previous>0 && lastOpen>0 && time[total-1]>lastOpen;lastOpen=time[total-1];
 ObjectsDeleteAll(0,prefix);ArrayResize(marks,0);ArrayResize(maps,0);
ArrayInitialize(B0,EMPTY_VALUE);ArrayInitialize(B1,EMPTY_VALUE);ArrayInitialize(B2,EMPTY_VALUE);ArrayInitialize(B3,EMPTY_VALUE);ArrayInitialize(B4,EMPTY_VALUE);ArrayInitialize(B5,EMPTY_VALUE);ArrayInitialize(B6,EMPTY_VALUE);ArrayInitialize(B7,EMPTY_VALUE);ArrayInitialize(B8,EMPTY_VALUE);ArrayInitialize(B9,EMPTY_VALUE);ArrayInitialize(B10,EMPTY_VALUE);ArrayInitialize(B11,EMPTY_VALUE);ArrayInitialize(B12,EMPTY_VALUE);ArrayInitialize(B13,EMPTY_VALUE);ArrayInitialize(B14,EMPTY_VALUE);ArrayInitialize(B15,EMPTY_VALUE);
 MqlRates ref[];ArraySetAsSeries(ref,false);int rn=CopyRates(_Symbol,(ENUM_TIMEFRAMES)ReferencePeriod,0,10000,ref);
 if(rn<ReferenceATRLength+2)return 0;
 double ra[];ArrayResize(ra,rn);double trsum=0;
 for(int j=0;j<rn;j++){double tr=j==0?ref[j].high-ref[j].low:MathMax(ref[j].high-ref[j].low,MathMax(MathAbs(ref[j].high-ref[j-1].close),MathAbs(ref[j].low-ref[j-1].close)));if(j<ReferenceATRLength)trsum+=tr;ra[j]=j<ReferenceATRLength-1?EMPTY_VALUE:j==ReferenceATRLength-1?trsum/ReferenceATRLength:(ra[j-1]*(ReferenceATRLength-1)+tr)/ReferenceATRLength;}
 double us[],ds[],base=EMPTY_VALUE,u50=EMPTY_VALUE,uo=EMPTY_VALUE,d50=EMPTY_VALUE,dout=EMPTY_VALUE;
 bool upperSeen=false,lowerSeen=false;datetime periodStart=0;int samples=0;
 for(int i=0;i<total;i++)
 {
  int shift=iBarShift(_Symbol,(ENUM_TIMEFRAMES)ReferencePeriod,time[i],false),j=rn-1-shift;
  if(shift<0||j<0||j>=rn)continue;
  bool rollover=periodStart!=ref[j].time;
  if(rollover)
  {
   periodStart=ref[j].time;
   if(j>=2 && ra[j-2]!=EMPTY_VALUE && ra[j-2]>0){Push(us,MathMax(ref[j-1].high-ref[j-2].close,0)/ra[j-2],CompletedPeriodsInMemory);Push(ds,MathMax(ref[j-2].close-ref[j-1].low,0)/ra[j-2],CompletedPeriodsInMemory);}
   samples=ArraySize(us);base=u50=uo=d50=dout=EMPTY_VALUE;upperSeen=lowerSeen=false;
   if(samples>=20 && j>0 && ra[j-1]!=EMPTY_VALUE && ra[j-1]>0){base=ref[j-1].close;u50=base+Quantile(us,50,true)*ra[j-1];uo=base+Quantile(us,OuterPercentile,true)*ra[j-1];d50=base-Quantile(ds,50,true)*ra[j-1];dout=base-Quantile(ds,OuterPercentile,true)*ra[j-1];}
  }
  bool up=i<total-1 && base!=EMPTY_VALUE && !upperSeen && close[i]>uo;
  bool down=i<total-1 && base!=EMPTY_VALUE && !lowerSeen && close[i]<dout;
  if(up)upperSeen=true;if(down)lowerSeen=true;
  if(!rollover){B0[i]=base;B1[i]=u50;B2[i]=uo;B3[i]=d50;B4[i]=dout;B5[i]=u50;B6[i]=uo;B7[i]=d50;B8[i]=dout;}
  if(ShowEvents && up)B9[i]=high[i]+(high[i]-low[i])*0.3;if(ShowEvents && down)B10[i]=low[i]-(high[i]-low[i])*0.3;
  B11[i]=base;B12[i]=uo;B13[i]=dout;B14[i]=samples;B15[i]=up?1:down?-1:0;
 }
 if(base!=EMPTY_VALUE)
 {
  datetime end=periodStart+PeriodSeconds((ENUM_TIMEFRAMES)ReferencePeriod);
  if(ReferencePeriod==Monthly){MqlDateTime dt;TimeToStruct(periodStart,dt);dt.mon++;if(dt.mon>12){dt.mon=1;dt.year++;}end=StructToTime(dt);}
  Rail("activebase",periodStart,end,base,clrSilver,STYLE_SOLID);Rail("activeu50",periodStart,end,u50,UpperColor,STYLE_DOT);Rail("activeuo",periodStart,end,uo,UpperColor,STYLE_SOLID);Rail("actived50",periodStart,end,d50,LowerColor,STYLE_DOT);Rail("activedo",periodStart,end,dout,LowerColor,STYLE_SOLID);
 }
 if(ShowContextPanel){Text("panelbrand","Harmony Algo | harmonyalgo.com",12,22);Text("panel","Period Excursion | "+EnumToString((ENUM_TIMEFRAMES)ReferencePeriod)+" | P"+IntegerToString(OuterPercentile),12,40);Text("samples","Completed periods "+IntegerToString(samples)+" / "+IntegerToString(CompletedPeriodsInMemory)+" | Historical, not odds",12,58);}
 int k=total-2;if(notify && EnablePopupAlerts && B15[k]!=0)Alert("Period Excursion: first closing breach ",B15[k]>0?"upper":"lower"," ",_Symbol);

Brand();return total;
}