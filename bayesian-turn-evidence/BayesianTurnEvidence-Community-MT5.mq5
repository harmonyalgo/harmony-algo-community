// Harmony Algo Community | harmonyalgo.com
// Copyright 2026 Harmony Algo. Mozilla Public License 2.0.
// Approved Pine SHA256: 0ee0bba8dec5ee4262b7b156d06d98294066a15a24ae0c79cea72fbf2752f2e5
// Conditional model evidence, not a probability of a profitable trade. No orders.
#property copyright "Harmony Algo"
#property link "https://harmonyalgo.com"
#property description "Closed-bar local Bayesian reversal attempts. Model evidence is not a win probability."
#property indicator_chart_window
#property indicator_buffers 24
#property indicator_plots 23
input int TrendContext=48;
input double ContextDisplacement=2.5;
input double TurnContinuationEvidence=3.0;
input double MaximumEntryDistance=1.75;
input bool ShowPreparationMarks=true;
input bool ShowEvidencePanel=true;
input bool EnablePopupAlerts=false; // no historical/attachment alerts
double Buy[],Sell[],PrepBuy[],PrepSell[],GuardLine[],ReclaimLine[],Fit[],Context[],PC[],PB[],PR[],Odds[],Phase[],Side[],Anchor[],Guard[],Reclaim[],Unit[],Events[],PriorATR[],Noise[],Effect[],PreparedAt[],ATR[];
color Bull=C'1,130,8',Bear=C'209,34,8';string prefix;datetime lastOpen=0;
double Score(double x,double m,double s){double z=(x-m)/s;return -3.0*MathLog(1.0+z*z/5.0);}
void Caption(string key,string text,int x,int y,int size,ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
{
 string name=prefix+key;if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_LABEL,0,0,0);
 ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
 ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
 ObjectSetInteger(0,name,OBJPROP_COLOR,C'113,125,143');ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
 ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
 ObjectSetString(0,name,OBJPROP_FONT,"Arial");ObjectSetString(0,name,OBJPROP_TEXT,text);
}
// BRANDING_BEGIN: Harmony Algo | harmonyalgo.com, independent of calculations.
void Branding()
{
 int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),h=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
 Caption("brand","Harmony Algo | harmonyalgo.com",w/2,h/2-18,10);
 Caption("cta","Explore premium indicators at harmonyalgo.com",w/2,h/2+12,8);
 ChartRedraw();
 string keys[]={"brand","cta"};for(int k=0;k<2;k++){string name=prefix+keys[k];int width=(int)ObjectGetInteger(0,name,OBJPROP_XSIZE);ObjectSetInteger(0,name,OBJPROP_XDISTANCE,MathMax(8,(w-width)/2));}
 if(ShowEvidencePanel)Caption("panelbrand","Harmony Algo | harmonyalgo.com",16,26,8);
}
// BRANDING_END
int OnInit()
{
 if(TrendContext<24||TrendContext>96||ContextDisplacement<1.5||ContextDisplacement>5||TurnContinuationEvidence<2||TurnContinuationEvidence>6||MaximumEntryDistance<1||MaximumEntryDistance>3)return INIT_PARAMETERS_INCORRECT;
 SetIndexBuffer(0,Buy,INDICATOR_DATA);SetIndexBuffer(1,Sell,INDICATOR_DATA);SetIndexBuffer(2,PrepBuy,INDICATOR_DATA);SetIndexBuffer(3,PrepSell,INDICATOR_DATA);
 SetIndexBuffer(4,GuardLine,INDICATOR_DATA);SetIndexBuffer(5,ReclaimLine,INDICATOR_DATA);SetIndexBuffer(6,Fit,INDICATOR_DATA);SetIndexBuffer(7,Context,INDICATOR_DATA);
 SetIndexBuffer(8,PC,INDICATOR_DATA);SetIndexBuffer(9,PB,INDICATOR_DATA);SetIndexBuffer(10,PR,INDICATOR_DATA);SetIndexBuffer(11,Odds,INDICATOR_DATA);
 SetIndexBuffer(12,Phase,INDICATOR_DATA);SetIndexBuffer(13,Side,INDICATOR_DATA);SetIndexBuffer(14,Anchor,INDICATOR_DATA);SetIndexBuffer(15,Guard,INDICATOR_DATA);
 SetIndexBuffer(16,Reclaim,INDICATOR_DATA);SetIndexBuffer(17,Unit,INDICATOR_DATA);SetIndexBuffer(18,Events,INDICATOR_DATA);SetIndexBuffer(19,PriorATR,INDICATOR_DATA);
 SetIndexBuffer(20,Noise,INDICATOR_DATA);SetIndexBuffer(21,Effect,INDICATOR_DATA);SetIndexBuffer(22,PreparedAt,INDICATOR_DATA);SetIndexBuffer(23,ATR,INDICATOR_CALCULATIONS);
 string names[]={"Buy confirmed","Sell confirmed","Buy preparation","Sell preparation","Frozen invalidation","Frozen reclaim","Context displacement","Independent context","Continuation model","Temporary response model","Reversal model","Turn continuation odds","Lifecycle","Attempt direction","Frozen extreme","Frozen guard","Frozen reclaim diagnostic","Frozen ATR","Event bits","Prior ATR","Prior noise","Prior effect","Preparation index"};
 for(int p=0;p<23;p++){
  PlotIndexSetString(p,PLOT_LABEL,names[p]);PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);
  PlotIndexSetInteger(p,PLOT_DRAW_TYPE,p<4?DRAW_ARROW:p<6?DRAW_LINE:DRAW_NONE);
  if(p<6)PlotIndexSetInteger(p,PLOT_LINE_COLOR,p==0||p==2?Bull:p==1||p==3?Bear:clrSlateGray);
  if(p<4)PlotIndexSetInteger(p,PLOT_ARROW,p==0?233:p==1?234:159);
  if(p<2)PlotIndexSetInteger(p,PLOT_LINE_WIDTH,2);
 }
 IndicatorSetString(INDICATOR_SHORTNAME,"Bayesian Turn Evidence Community [Harmony Algo]");IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
 prefix="BTE_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+"_";Branding();return INIT_SUCCEEDED;
}
// Harmony Algo | harmonyalgo.com: chronological closed-bar state machine.
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
 ArraySetAsSeries(time,false);ArraySetAsSeries(open,false);ArraySetAsSeries(high,false);ArraySetAsSeries(low,false);ArraySetAsSeries(close,false);
 if(rates_total<2)return 0;
 if(prev_calculated==rates_total&&lastOpen==time[rates_total-1])return rates_total;
 bool notify=prev_calculated>0&&lastOpen>0&&time[rates_total-1]>lastOpen;lastOpen=time[rates_total-1];
 int start=MathMax(0,rates_total-6000),context=0,phase=0,side=0,rising=0,falling=0,flat=0,reject=0,ended=-10000,started=0,confirmed=0;
 double anchor=EMPTY_VALUE,unit=EMPTY_VALUE,guard=EMPTY_VALUE,reclaim=EMPTY_VALUE,mu=0,scale=1,lc=MathLog(.5),lb=MathLog(.3),lr=MathLog(.2),pc=.5,pb=.3,pr=.2,odds=1,cv=EMPTY_VALUE,trsum=0;
 ObjectsDeleteAll(0,prefix+"signal_");int signalCount=0;
 for(int i=0;i<rates_total;i++){
  Buy[i]=Sell[i]=PrepBuy[i]=PrepSell[i]=GuardLine[i]=ReclaimLine[i]=EMPTY_VALUE;
  Fit[i]=Context[i]=PC[i]=PB[i]=PR[i]=Odds[i]=Phase[i]=Side[i]=Anchor[i]=Guard[i]=Reclaim[i]=Unit[i]=Events[i]=PriorATR[i]=Noise[i]=Effect[i]=PreparedAt[i]=ATR[i]=EMPTY_VALUE;
  if(i<start)continue;int j=i-start,ev=0;double fit=EMPTY_VALUE,noise=EMPTY_VALUE,effect=EMPTY_VALUE,prior=EMPTY_VALUE;
  double tr=j==0?high[i]-low[i]:MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1])));
  if(j<21)trsum+=tr;ATR[i]=j<20?EMPTY_VALUE:j==20?trsum/21.0:(ATR[i-1]*20+tr)/21.0;
  if(j>20)prior=ATR[i-1];
  if(j>=TrendContext&&prior!=EMPTY_VALUE&&prior>0){double mean=0,cov=0;for(int k=0;k<TrendContext;k++)mean+=close[i-TrendContext+k];mean/=TrendContext;
   for(int k=0;k<TrendContext;k++)cov+=(k-(TrendContext-1.0)/2)*(close[i-TrendContext+k]-mean);
   fit=cov/(TrendContext*(TrendContext*TrendContext-1.0)/12)*(TrendContext-1)/prior;
  }
  if(j>=33){double sum=0,ss=0,ab=0;for(int k=i-32;k<i;k++){double d=close[k]-close[k-1];sum+=d;ab+=MathAbs(d);}double mean=sum/32;
   for(int k=i-32;k<i;k++){double d=close[k]-close[k-1]-mean;ss+=d*d;}noise=MathSqrt(ss/32);effect=ab/32;
  }
  if(i<rates_total-1){cv=fit;bool valid=j>=96&&fit!=EMPTY_VALUE&&noise!=EMPTY_VALUE&&effect!=EMPTY_VALUE&&prior>0&&close[i]>0&&close[i-1]>0;
   if(valid){rising=fit>=ContextDisplacement?rising+1:0;falling=fit<=-ContextDisplacement?falling+1:0;flat=MathAbs(fit)<1?flat+1:0;
    if(rising>=2)context=1;else if(falling>=2)context=-1;else if(flat>=3)context=0;
    if(phase==2){if(side*(close[i]-guard)<0){ev|=64;phase=0;ended=j;}else if(j-confirmed>=32){ev|=128;phase=0;}}
    if(phase==1){int age=j-started;double x=side*(close[i]-close[i-1])/unit;
     lc+=Score(x,-mu,scale);lb+=Score(x,mu*MathExp(-age/3.0),scale);lr+=Score(x,mu,scale);
     double biggest=MathMax(lc,MathMax(lb,lr)),wc=MathExp(lc-biggest),wb=MathExp(lb-biggest),wr=MathExp(lr-biggest),total=wc+wb+wr;
     pc=wc/total;pb=wb/total;pr=wr/total;odds=MathExp(MathMin(30.0,MathMax(lb,lr)+MathLog(1+MathExp(-MathAbs(lb-lr)))-lc));
     double z=biggest+MathLog(total);lc-=z;lb-=z;lr-=z;reject=age>=2&&pc>.8?reject+1:0;double distance=side*(close[i]-anchor)/unit;
     if(side*(close[i]-guard)<0){ev|=16;phase=0;ended=j;}
     else if(age>=16||reject>=2||distance>MaximumEntryDistance){ev|=32;phase=0;ended=j;}
     else if(age>=1&&odds>=TurnContinuationEvidence&&side*(close[i]-reclaim)>0&&distance>=.5){ev|=side==1?4:8;phase=2;confirmed=j;ended=j;}
    }else if(j-ended>=12&&context!=0){int wanted=-context,ext=i;double old=wanted==1?low[i-12]:high[i-12];
     for(int k=i-1;k>i-12;k--)if(wanted==1?low[k]<low[ext]:high[k]>high[ext])ext=k;
     for(int k=i-13;k>=i-23;k--)old=wanted==1?MathMin(old,low[k]):MathMax(old,high[k]);
     double candidate=wanted==1?low[ext]:high[ext],retreat=wanted*(close[i]-candidate)/prior;bool extended=wanted==1?candidate<old:candidate>old;
     if(i-ext<=3&&extended&&retreat>=.35&&retreat<=1){side=wanted;anchor=candidate;unit=prior;guard=anchor-side*.15*unit;reclaim=side==1?MathMax(open[i],close[i]):MathMin(open[i],close[i]);
      mu=MathMax(.15,MathMin(.4,.65*effect/unit));scale=MathMax(.25,MathMin(1.25,noise/unit));lc=MathLog(.5);lb=MathLog(.3);lr=MathLog(.2);pc=.5;pb=.3;pr=.2;odds=1;phase=1;started=j;reject=0;ev|=side==1?1:2;
     }
    }
   }else{context=phase=rising=falling=flat=0;}
  }
  Fit[i]=cv;Context[i]=context;PC[i]=pc;PB[i]=pb;PR[i]=pr;Odds[i]=odds;Phase[i]=phase;Side[i]=side;Anchor[i]=anchor;Guard[i]=guard;Reclaim[i]=reclaim;Unit[i]=unit;Events[i]=ev;PriorATR[i]=prior;Noise[i]=noise;Effect[i]=effect;PreparedAt[i]=started;
  if(ShowPreparationMarks){if((ev&1)!=0)PrepBuy[i]=low[i]-.15*prior;if((ev&2)!=0)PrepSell[i]=high[i]+.15*prior;}
  if((ev&4)!=0)Buy[i]=low[i]-.3*prior;if((ev&8)!=0)Sell[i]=high[i]+.3*prior;
  if(phase>0&&(ev&3)==0)GuardLine[i]=guard;if(phase==1&&(ev&3)==0)ReclaimLine[i]=reclaim;
  if((ev&12)!=0){string key=prefix+"signal_"+IntegerToString(signalCount++);double y=side==1?Buy[i]:Sell[i];ObjectCreate(0,key,OBJ_TEXT,0,time[i],y);
   ObjectSetString(0,key,OBJPROP_TEXT,side==1?"Buy ▲":"Sell ▼");ObjectSetInteger(0,key,OBJPROP_COLOR,clrWhite);ObjectSetInteger(0,key,OBJPROP_ANCHOR,side==1?ANCHOR_UPPER:ANCHOR_LOWER);ObjectSetInteger(0,key,OBJPROP_FONTSIZE,9);ObjectSetInteger(0,key,OBJPROP_SELECTABLE,false);
  }
 }
 if(ShowEvidencePanel){Caption("panel","BAYESIAN TURN | "+(phase==1?"Preparing":phase==2?"Confirmed":"Waiting")+" | Turn / continuation "+DoubleToString(odds,1)+"x",16,54,8);Caption("limit","Model evidence only | Close confirmed",16,82,8);}
 else{ObjectDelete(0,prefix+"panel");ObjectDelete(0,prefix+"limit");}
 if(EnablePopupAlerts&&notify){int e=(int)Events[rates_total-2];string messages[]={"Buy preparation","Sell preparation","Buy confirmed","Sell confirmed","Preparation failed","Preparation cancelled","Confirmation invalidated"};for(int b=0;b<7;b++)if((e&(1<<b))!=0)Alert("Bayesian Turn Revised: ",messages[b]," on ",_Symbol," ",EnumToString(_Period)," ",TimeToString(time[rates_total-2]));}
 Branding();return rates_total;
}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){if(id==CHARTEVENT_CHART_CHANGE)Branding();}
void OnDeinit(const int reason){ObjectsDeleteAll(0,prefix);}
