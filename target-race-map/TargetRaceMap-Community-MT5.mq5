// Target Race Map Community — Harmony Algo | harmonyalgo.com
// Original implementation by Iamalala; MT5 port by Harmony Algo.
// Mozilla Public License 2.0. Source and feed differences are documented in README.
#property copyright "Harmony Algo"
#property link "https://harmonyalgo.com"
#property description "Community price-analysis tool. Premium products at harmonyalgo.com are for TradingView."
#property indicator_chart_window
#property indicator_buffers 34
#property indicator_plots 34

input int BreakoutLookback=32;input int ATRLength=14;input double BreakoutBufferATR=0.10;
input double BarrierDistanceATR=2.5;input int DeadlineBars=48;input int CooldownBars=8;
input int ResolvedRacesInMemory=400;input int MinimumSurvivingExamples=20;input double PositionTolerance=0.50;
input bool WeightSimilarPaths=false;input double VelocityWeightingWidth=0.15;
input int RecentMaps=6;input int HistoricalLabels=500;input bool ShowEvidencePanel=true;
enum EvidenceCorner{TopRight,TopLeft,BottomRight,BottomLeft};input EvidenceCorner PanelCorner=TopRight;
input bool ShowLabels=true;input bool EnablePopupAlerts=false;
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
double B26[];
double B27[];
double B28[];
double B29[];
double B30[];
double B31[];
double B32[];
double B33[];
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

struct PastRace{int side,duration,outcome;double path[101];};
double Velocity(double &path[],int age){int span=MathMin(age,3);return span>0?(path[age]-path[age-span])/span:0;}
void Cohort(PastRace &history[],int side,int age,double location,double velocity,double &out[])
{
 int n=0,survivors=0,total=ArraySize(history);double sw=0,sw2=0,u=0,d=0,t=0,a=0,u1=0,d1=0,u2=0,d2=0,bu=0,bd=0,bt=0,ba=0,ow=0,ow2=0,ou=0,od=0,nw=0,nw2=0,nu=0,nd=0;
 int k1=(int)MathCeil((DeadlineBars-age)/3.0),k2=(int)MathCeil(2.0*(DeadlineBars-age)/3.0);
 for(int j=0;j<total;j++)if(history[j].side==side && history[j].duration>age)
 {
  survivors++;if(MathAbs(history[j].path[age]-location)>PositionTolerance)continue;
  n++;int span=MathMin(age,3);double pv=span>0?(history[j].path[age]-history[j].path[age-span])/span:0;
  double diff=(pv-velocity)/VelocityWeightingWidth,w=WeightSimilarPaths?1/(1+diff*diff):1;
  int o=history[j].outcome,r=history[j].duration-age;sw+=w;sw2+=w*w;
  if(o==1){u+=w;bu++;if(r<=k1)u1+=w;if(r<=k2)u2+=w;}
  if(o==-1){d+=w;bd++;if(r<=k1)d1+=w;if(r<=k2)d2+=w;}
  if(o==2){t+=w;bt++;}if(o==3){a+=w;ba++;}
  if(j<(int)MathFloor(total/2.0)){ow+=w;ow2+=w*w;if(o==1)ou+=w;if(o==-1)od+=w;}
  else {nw+=w;nw2+=w*w;if(o==1)nu+=w;if(o==-1)nd+=w;}
 }
 double eff=sw2>0?sw*sw/sw2:0,oe=ow2>0?ow*ow/ow2:0,ne=nw2>0?nw*nw/nw2:0;
 int stability=oe>=10 && ne>=10?(MathMax(MathAbs(ou/ow-nu/nw),MathAbs(od/ow-nd/nw))<=0.15?1:-1):0;
 double den=sw>0?sw:1,bdn=n>0?n:1;ArrayResize(out,16);
 out[0]=n;out[1]=eff;out[2]=u/den;out[3]=d/den;out[4]=t/den;out[5]=a/den;out[6]=survivors;
 out[7]=u1/den;out[8]=d1/den;out[9]=u2/den;out[10]=d2/den;out[11]=stability;
 out[12]=bu/bdn;out[13]=bd/bdn;out[14]=bt/bdn;out[15]=ba/bdn;
}
double Mean(double &a[]){int n=ArraySize(a);if(!n)return EMPTY_VALUE;double s=0;for(int j=0;j<n;j++)s+=a[j];return s/n;}
datetime At(const datetime &time[],int i,int total){return i<total?time[i]:time[total-1]+(i-total+1)*PeriodSeconds(_Period);}
int OnInit(){if(BreakoutLookback<10||BreakoutLookback>200||ATRLength<5||ATRLength>100||BreakoutBufferATR<0||BreakoutBufferATR>2||BarrierDistanceATR<0.5||BarrierDistanceATR>5||DeadlineBars<8||DeadlineBars>100||CooldownBars<0||CooldownBars>50||ResolvedRacesInMemory<50||ResolvedRacesInMemory>600||MinimumSurvivingExamples<10||MinimumSurvivingExamples>100||PositionTolerance<0.15||PositionTolerance>1||VelocityWeightingWidth<0.05||VelocityWeightingWidth>0.5||RecentMaps<1||RecentMaps>165||HistoricalLabels<50||HistoricalLabels>500)return INIT_PARAMETERS_INCORRECT;SetIndexBuffer(0,B0,INDICATOR_DATA);
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
SetIndexBuffer(26,B26,INDICATOR_DATA);
SetIndexBuffer(27,B27,INDICATOR_DATA);
SetIndexBuffer(28,B28,INDICATOR_DATA);
SetIndexBuffer(29,B29,INDICATOR_DATA);
SetIndexBuffer(30,B30,INDICATOR_DATA);
SetIndexBuffer(31,B31,INDICATOR_DATA);
SetIndexBuffer(32,B32,INDICATOR_DATA);
SetIndexBuffer(33,B33,INDICATOR_DATA);
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
PlotIndexSetInteger(24,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(24,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(25,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(25,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(26,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(26,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(27,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(27,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(28,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(28,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(29,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(29,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(30,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(30,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(31,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(31,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(32,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(32,PLOT_EMPTY_VALUE,EMPTY_VALUE);
PlotIndexSetInteger(33,PLOT_DRAW_TYPE,DRAW_NONE);PlotIndexSetDouble(33,PLOT_EMPTY_VALUE,EMPTY_VALUE);IndicatorSetString(INDICATOR_SHORTNAME,"Target Race Map Community [Harmony Algo]");IndicatorSetInteger(INDICATOR_DIGITS,_Digits);prefix="TargetRaceMap_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+"_";Brand();return INIT_SUCCEEDED;}int OnCalculate(const int total,const int previous,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
 ArraySetAsSeries(time,false);ArraySetAsSeries(open,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
 if(total<2)return 0;if(previous==total && lastOpen==time[total-1])return total;
 bool notify=previous>0 && lastOpen>0 && time[total-1]>lastOpen;lastOpen=time[total-1];
 ObjectsDeleteAll(0,prefix);ArrayResize(marks,0);ArrayResize(maps,0);
ArrayInitialize(B0,EMPTY_VALUE);ArrayInitialize(B1,EMPTY_VALUE);ArrayInitialize(B2,EMPTY_VALUE);ArrayInitialize(B3,EMPTY_VALUE);ArrayInitialize(B4,EMPTY_VALUE);ArrayInitialize(B5,EMPTY_VALUE);ArrayInitialize(B6,EMPTY_VALUE);ArrayInitialize(B7,EMPTY_VALUE);ArrayInitialize(B8,EMPTY_VALUE);ArrayInitialize(B9,EMPTY_VALUE);ArrayInitialize(B10,EMPTY_VALUE);ArrayInitialize(B11,EMPTY_VALUE);ArrayInitialize(B12,EMPTY_VALUE);ArrayInitialize(B13,EMPTY_VALUE);ArrayInitialize(B14,EMPTY_VALUE);ArrayInitialize(B15,EMPTY_VALUE);ArrayInitialize(B16,EMPTY_VALUE);ArrayInitialize(B17,EMPTY_VALUE);ArrayInitialize(B18,EMPTY_VALUE);ArrayInitialize(B19,EMPTY_VALUE);ArrayInitialize(B20,EMPTY_VALUE);ArrayInitialize(B21,EMPTY_VALUE);ArrayInitialize(B22,EMPTY_VALUE);ArrayInitialize(B23,EMPTY_VALUE);ArrayInitialize(B24,EMPTY_VALUE);ArrayInitialize(B25,EMPTY_VALUE);ArrayInitialize(B26,EMPTY_VALUE);ArrayInitialize(B27,EMPTY_VALUE);ArrayInitialize(B28,EMPTY_VALUE);ArrayInitialize(B29,EMPTY_VALUE);ArrayInitialize(B30,EMPTY_VALUE);ArrayInitialize(B31,EMPTY_VALUE);ArrayInitialize(B32,EMPTY_VALUE);ArrayInitialize(B33,EMPTY_VALUE);
 PastRace history[];double path[],cohort[];ArrayResize(path,101);ArrayInitialize(path,0);ArrayResize(cohort,16);ArrayInitialize(cohort,0);
 double atr[],checkM[],checkB[],checkFav[],checkHit[];ArrayResize(atr,total);double trsum=0;
 bool active=false,strongIssued=false,evaluation=false;int side=0,start=-1,lastEnd=-100000,age=0,result=0,cancelled=0,run=0,forecastAge=0,predSide=0;
 double origin=EMPTY_VALUE,upper=EMPTY_VALUE,lower=EMPTY_VALUE,location=0,velocity=0,pred[4],baseline[4],predFav=0;
 string mapId="";int calibrationN=0,calibrationHits=0;
 for(int i=0;i<total;i++)
 {
  double tr=i==0?high[i]-low[i]:MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1])));
  if(i<ATRLength)trsum+=tr;atr[i]=i<ATRLength-1?EMPTY_VALUE:i==ATRLength-1?trsum/ATRLength:(atr[i-1]*(ATRLength-1)+tr)/ATRLength;
  bool newRace=false,strongUp=false,strongDown=false,candidate=false;int resolution=0;
  bool valid=MathIsValidNumber(open[i]) && MathIsValidNumber(high[i]) && MathIsValidNumber(low[i]) && MathIsValidNumber(close[i]) && high[i]>=MathMax(open[i],close[i]) && low[i]<=MathMin(open[i],close[i]) && high[i]>=low[i];
  double scale=i>0?atr[i-1]:EMPTY_VALUE;
  if(i<total-1)
  {
   bool was=active;
   if(was)
   {
    age=i-start;int observed=0;
    if(!valid)observed=4;else if(open[i]>=upper)observed=1;else if(open[i]<=lower)observed=-1;else if(high[i]>=upper && low[i]<=lower)observed=3;else if(high[i]>=upper)observed=1;else if(low[i]<=lower)observed=-1;else if(age>=DeadlineBars)observed=2;
    if(observed!=0)
    {
     active=false;result=resolution=observed;lastEnd=i;ObjectDelete(0,prefix+"m1");ObjectDelete(0,prefix+"m2");
     ObjectMove(0,prefix+mapId+"u",1,time[i],upper);ObjectMove(0,prefix+mapId+"d",1,time[i],lower);ObjectMove(0,prefix+mapId+"c",1,time[i],origin);ObjectMove(0,prefix+mapId+"box",1,time[i],lower);
     if(observed==4)cancelled++;
     else
     {
      if(evaluation){double bm=0,bb=0;for(int k=0;k<4;k++){int endpoint=k==0?1:k==1?-1:k==2?2:3;double actual=observed==endpoint?1:0;bm+=MathPow(pred[k]-actual,2);bb+=MathPow(baseline[k]-actual,2);}Push(checkM,bm,100);Push(checkB,bb,100);Push(checkFav,predFav,100);Push(checkHit,observed==predSide?1:0,100);}
      int n=ArraySize(history);if(n>=ResolvedRacesInMemory){for(int j=0;j<n-1;j++)history[j]=history[j+1];n--;ArrayResize(history,n);}
      ArrayResize(history,n+1);history[n].side=side;history[n].duration=age;history[n].outcome=observed;for(int j=0;j<age;j++)history[n].path[j]=path[j];
     }
     if(ShowLabels)Mark(time[i],observed==1?upper:observed==-1?lower:origin,observed==1?"UP first":observed==-1?"DOWN first":observed==2?"No hit":observed==3?"Both: unknown":"Data cancelled",observed==1?C'1,130,8':observed==-1?C'209,34,8':C'127,73,222',HistoricalLabels);
    }
    else
    {
     location=(close[i]-origin)/(upper-origin);path[age]=location;velocity=Velocity(path,age);Cohort(history,side,age,location,velocity,cohort);forecastAge=age;
     bool enough=cohort[0]>=MinimumSurvivingExamples && cohort[1]>=MinimumSurvivingExamples;
     if(age==MathMin(4,DeadlineBars-1) && enough){evaluation=true;for(int k=0;k<4;k++){pred[k]=cohort[2+k];baseline[k]=cohort[12+k];}predSide=cohort[2]>=cohort[3]?1:-1;predFav=MathMax(cohort[2],cohort[3]);}
     double favored=side==1?cohort[2]:cohort[3],opposite=side==1?cohort[3]:cohort[2];
     candidate=enough && cohort[1]>=40 && cohort[11]==1 && favored>=0.65 && favored-opposite>=0.20 && side*location>=0.10 && side*velocity>0;
     run=candidate?run+1:0;if(!strongIssued && run>=2){strongIssued=true;strongUp=side==1;strongDown=side==-1;if(ShowLabels)Mark(time[i],side==1?low[i]-0.25*scale:high[i]+0.25*scale,side==1?"Strong ▲":"Strong ▼",side==1?C'1,130,8':C'209,34,8',HistoricalLabels);}
    }
   }
   bool ready=valid && i>=BreakoutLookback && scale!=EMPTY_VALUE && scale>_Point;
   double ph=0,pl=EMPTY_VALUE;if(ready)for(int j=1;j<=BreakoutLookback;j++){ph=MathMax(ph,high[i-j]);pl=MathMin(pl,low[i-j]);}
   bool up=ready && close[i]>ph+BreakoutBufferATR*scale,down=ready && close[i]<pl-BreakoutBufferATR*scale;
   if(!was && i-lastEnd>CooldownBars && (up||down))
   {
    active=newRace=true;side=up?1:-1;start=i;age=result=forecastAge=run=0;origin=close[i];upper=origin+BarrierDistanceATR*scale;lower=origin-BarrierDistanceATR*scale;location=velocity=0;ArrayInitialize(path,0);strongIssued=evaluation=false;
    Cohort(history,side,0,0,0,cohort);mapId="map_"+IntegerToString(i)+"_";
    datetime end=At(time,start+DeadlineBars,total);
    Rail(mapId+"u",time[i],end,upper,C'1,130,8',STYLE_SOLID);Rail(mapId+"d",time[i],end,lower,C'209,34,8',STYLE_SOLID);Rail(mapId+"c",time[i],end,origin,clrSilver);
    string n=prefix+mapId+"box";ObjectCreate(0,n,OBJ_RECTANGLE,0,time[i],upper,end,lower);ObjectSetInteger(0,n,OBJPROP_COLOR,C'42,30,60');ObjectSetInteger(0,n,OBJPROP_FILL,false);ObjectSetInteger(0,n,OBJPROP_BACK,true);
    Keep(maps,prefix+mapId+"u",RecentMaps*4);Keep(maps,prefix+mapId+"d",RecentMaps*4);Keep(maps,prefix+mapId+"c",RecentMaps*4);Keep(maps,n,RecentMaps*4);
    if(ShowLabels)Mark(time[i],side==1?low[i]-0.25*scale:high[i]+0.25*scale,side==1?"▲":"▼",side==1?C'1,130,8':C'209,34,8',HistoricalLabels);
   }
   if(active)
   {
    datetime a=At(time,i+(int)MathCeil((DeadlineBars-age)/3.0),total),b=At(time,i+(int)MathCeil(2.0*(DeadlineBars-age)/3.0),total);
    if(ObjectFind(0,prefix+"m1")<0)ObjectCreate(0,prefix+"m1",OBJ_TREND,0,a,lower,a,upper);else{ObjectMove(0,prefix+"m1",0,a,lower);ObjectMove(0,prefix+"m1",1,a,upper);}
    if(ObjectFind(0,prefix+"m2")<0)ObjectCreate(0,prefix+"m2",OBJ_TREND,0,b,lower,b,upper);else{ObjectMove(0,prefix+"m2",0,b,lower);ObjectMove(0,prefix+"m2",1,b,upper);}
    ObjectSetInteger(0,prefix+"m1",OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,prefix+"m2",OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,prefix+"m1",OBJPROP_STYLE,STYLE_DOT);ObjectSetInteger(0,prefix+"m2",OBJPROP_STYLE,STYLE_DOT);
   }
  }
  calibrationN=calibrationHits=0;for(int j=0;j<ArraySize(checkFav);j++)if(checkFav[j]>=0.60){calibrationN++;calibrationHits+=(int)checkHit[j];}
  bool enough=cohort[0]>=MinimumSurvivingExamples && cohort[1]>=MinimumSurvivingExamples;
  B0[i]=upper;B1[i]=lower;B2[i]=active?side:0;B3[i]=age;B4[i]=result;B5[i]=cohort[0];B6[i]=enough?100*cohort[2]:EMPTY_VALUE;B7[i]=enough?100*cohort[3]:EMPTY_VALUE;B8[i]=enough?100*cohort[4]:EMPTY_VALUE;B9[i]=enough?100*cohort[5]:EMPTY_VALUE;
  B10[i]=cohort[6];B11[i]=location;B12[i]=newRace?side:0;B13[i]=resolution;B14[i]=cohort[1];B15[i]=velocity;B16[i]=enough?100*cohort[7]:EMPTY_VALUE;B17[i]=enough?100*cohort[8]:EMPTY_VALUE;B18[i]=enough?100*cohort[9]:EMPTY_VALUE;B19[i]=enough?100*cohort[10]:EMPTY_VALUE;
  B20[i]=cohort[11];B21[i]=strongUp?1:strongDown?-1:0;B22[i]=ArraySize(checkM);B23[i]=Mean(checkM);B24[i]=Mean(checkB);B25[i]=calibrationN;B26[i]=calibrationN>=20?100.0*calibrationHits/calibrationN:EMPTY_VALUE;B27[i]=candidate?1:0;B28[i]=forecastAge;
  B29[i]=cohort[12];B30[i]=cohort[13];B31[i]=cohort[14];B32[i]=cohort[15];B33[i]=cancelled;
 }
 if(ShowEvidencePanel)
 {
  int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),h=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);int x=PanelCorner==TopRight||PanelCorner==BottomRight?w-380:12,y=PanelCorner==BottomRight||PanelCorner==BottomLeft?h-170:22;
  Text("panelbrand","Harmony Algo | harmonyalgo.com",x,y);Text("state","Target Race | "+(active?"Active "+IntegerToString(DeadlineBars-age)+" bars left":"Latest result "+IntegerToString(result)),x,y+18);
  bool enough=cohort[0]>=MinimumSurvivingExamples && cohort[1]>=MinimumSurvivingExamples;
  Text("counts","N "+DoubleToString(cohort[0],0)+" | Eff "+DoubleToString(cohort[1],1)+" | "+(enough?(cohort[11]==1?"Stable":cohort[11]==-1?"Mixed":"Limited"):"LEARNING"),x,y+36);
  Text("rates","Deadline UP / DOWN: "+(enough?DoubleToString(100*cohort[2],0)+"% / "+DoubleToString(100*cohort[3],0)+"%":"-- / --"),x,y+54);
  Text("early","First milestone: "+(enough?DoubleToString(100*cohort[7],0)+"% / "+DoubleToString(100*cohort[8],0)+"%":"-- / --"),x,y+72);
  Text("later","Second milestone: "+(enough?DoubleToString(100*cohort[9],0)+"% / "+DoubleToString(100*cohort[10],0)+"%":"-- / --"),x,y+90);
  Text("other","No hit / Both: "+(enough?DoubleToString(100*cohort[4],0)+"% / "+DoubleToString(100*cohort[5],0)+"%":"-- / --"),x,y+108);
  Text("checks","Past checks N "+IntegerToString(calibrationN)+" | Brier "+DoubleToString(Mean(checkM),3),x,y+126);Text("limits","Past frequencies, not win rates | Evidence age "+IntegerToString(forecastAge),x,y+144);
 }
 int k=total-2;if(notify && EnablePopupAlerts){if(B12[k]!=0)Alert("Target Race: new closing race ",_Symbol);if(B13[k]!=0)Alert("Target Race: outcome ",(int)B13[k]," ",_Symbol);if(B21[k]!=0)Alert("Target Race: Strong ",B21[k]>0?"up":"down"," ",_Symbol);}

Brand();return total;
}