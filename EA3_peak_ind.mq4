//+------------------------------------------------------------------+
//|                                                my_3_peak_ind.mq4 |
//|                                                             Reza |
//|                                                                  |
//+------------------------------------------------------------------+
#include <WinUser32.mqh>
#property copyright "Reza"
#property link      ""
#property version   "1.00"
#property strict
///////////////////////////////inputs
//--- Inputs
input double i_Lots         =0.1;
//input double i_tp_sl_factor =1;
input double iTP_factor =1;
input double iSL_factor =1;
input double i_filtered_q_thresh =1.5;
input double i_order_thresh =0.9;
input double i_filtered_clearance_thresh =1.5;
///////////////////////////////debug
void report_ints(int p1, int p2, int p3)
{
   if (!IsVisualMode())
      return;
   string Comm="";
   Comm=Comm+p1+"\n";
   Comm=Comm+p2+"\n";
   Comm=Comm+p3+"\n";
   
   Comment(Comm);
   keybd_event(19,0,0,0);
   Sleep(10);
   keybd_event(19,0,2,0);
}
void report_string(string str)
{
   if (!IsVisualMode())
      return;
   Comment(str);
   keybd_event(19,0,0,0);
   Sleep(10);
   keybd_event(19,0,2,0);
}
void BreakPoint()
{
   //It is expecting, that this function should work
   //only in tester
   if (!IsVisualMode())
      return;
   
   //Preparing a data for printing
   //Comment() function is used as 
   //it give quite clear visualisation
   string Comm="";
   Comm=Comm+"Bid="+Bid+"\n";
   Comm=Comm+"Ask="+Ask+"\n";
   
   Comment(Comm);
   
   //Press/release Pause button
   //19 is a Virtual Key code of "Pause" button
   //Sleep() is needed, because of the probability
   //to misprocess too quick pressing/releasing
   //of the button
   keybd_event(19,0,0,0);
   Sleep(10);
   keybd_event(19,0,2,0);
}
///////////////////////////////////////////////////////////
double max(double v1, double v2=-1, double v3=-1, double v4=-1, double v5=-1, double v6=-1)
{
   double result = v1;
   if(v2>result)  result=v2;
   if(v3>result)  result=v3;
   if(v4>result)  result=v4;
   if(v5>result)  result=v5;
   if(v6>result)  result=v6;
   return result;
}
double min(double v1, double v2=1000, double v3=1000, double v4=1000, double v5=1000, double v6=1000)
{
   double result = v1;
   if(v2<result)  result=v2;
   if(v3<result)  result=v3;
   if(v4<result)  result=v4;
   if(v5<result)  result=v5;
   if(v6<result)  result=v6;
   return result;
}
////////////////////////////////////////////////////////////
void calculate_TP_SL_buy(double &_sl, double &_tp)
{
   double average_bar_size = (High[1]-Low[1] + High[2]-Low[2] + High[3]-Low[3] + High[4]-Low[4] + High[5]-Low[5])/5; 
   if(iSL_factor==0)
      _sl = min(Low[1],Low[2],Low[3]);
   else
      _sl = Open[0]-average_bar_size*iSL_factor;
   _tp = Open[0]+average_bar_size*iTP_factor;
}
void calculate_TP_SL_sell(double &_sl, double &_tp)
{
   double average_bar_size = (High[1]-Low[1] + High[2]-Low[2] + High[3]-Low[3] + High[4]-Low[4] + High[5]-Low[5])/5; 
   if(iSL_factor==0)
      _sl = max(High[1],High[2],High[3]);
   else
      _sl = Open[0]+average_bar_size*iSL_factor;
   _tp = Open[0]-average_bar_size*iTP_factor;
}
//------------------------------------------------functions
void new_position_check()
{

   double ind_peak_at2 = iCustom(NULL,0,"my_ind/my_peaks", 3,2);
   double ind_peak_at3 = iCustom(NULL,0,"my_ind/my_peaks", 3,3);
   double ind_order = iCustom(NULL,0,"my_ind/my_peaks", 0,0);
   double ind_filtered_quality = iCustom(NULL,0,"my_ind/my_peaks", 2,0);
   double ind_filtered_clearance = iCustom(NULL,0,"my_ind/my_peaks", 5,0);
//   report_ints(ind_peak_at2,ind_peak_at3,ind_order);//10000*iCustom(NULL,0,"my_ind/my_trending",10,True, 0,2));//10, True,0,0));
   double sl,tp;
   if(ind_filtered_clearance>i_filtered_clearance_thresh)
      if(ind_filtered_quality>i_filtered_q_thresh) //chart is generaly well-behaved
      {
         if(ind_order>i_order_thresh)   //order zone suitable for buy
         {
            calculate_TP_SL_buy(sl, tp);
            if(ind_peak_at2<0)   
//               OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, sl, tp,"normal buy",4321,0, clrGreenYellow);
               OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, tp, sl,"normal buy",4321,0, clrGreenYellow);   //insane trade!
            if(ind_peak_at3<0)
               if((High[2]<High[1])&&(Low[2]<Low[1])&&(Open[2]<Open[1]))
//                 OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, sl, tp,"normal buy",4321,0, clrGreenYellow);
                     OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, tp, sl,"normal buy",4321,0, clrGreenYellow);   //insane trade!
         }
         if(ind_order<-i_order_thresh)   //order zone suitable for sell
         {
            calculate_TP_SL_sell(sl, tp);
            if(ind_peak_at2>0)
//               OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, sl, tp,"normal sell",4321,0, clrGreenYellow);
               OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, tp, sl,"normal buy",4321,0, clrGreenYellow);//insane trade!
            if(ind_peak_at3>0)
               if((High[2]<High[1])&&(Low[2]<Low[1])&&(Open[2]<Open[1]))
//                 OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, sl, tp,"normal sell",4321,0, clrGreenYellow);
                   OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, tp, sl,"normal buy",4321,0, clrGreenYellow);  //insane trade!
         }  
      }       

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(Bars<110 || IsTradeAllowed()==false)
      return;
   //just wait for new bar
   static datetime Time0=0;

   if (Time0 == Time[0])
      return;
   Time0 = Time[0];

   new_position_check();
  }
//------------------------------------------default functions
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
  }
double OnTester()
  {
   double ret=0.0;
   return(ret);
  }
