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

//------------------------------------------------functions
void new_position_check()
{

   double ind_peaks0 = iCustom(NULL,0,"my_ind/my_peaks", 0,1);
   double ind_peak_at2 = iCustom(NULL,0,"my_ind/my_peaks", 3,2);
   double ind_peak_at3 = iCustom(NULL,0,"my_ind/my_peaks", 3,3);
//   report_ints(ind_peaks0,ind_peaks2,ind_peaks3);//10000*iCustom(NULL,0,"my_ind/my_trending",10,True, 0,2));//10, True,0,0));
   if(ind_peak_at2<0)
      OrderSend(Symbol(),OP_BUY, 0.1, Ask, 3, Low[2], Open[0]+(Open[0]-Low[2])*1,"normal buy",4321,0, clrGreenYellow);
//   if(ind_peak_at3<0)
//      if((High[2]<High[1])&&(Low[2]<Low[1])&&(Open[2]<Open[1]))
//        OrderSend(Symbol(),OP_BUY, 0.1, Ask, 3, Low[3], Open[0]+(Open[0]-Low[3])*0.5,"normal buy",4321,0, clrGreenYellow);

   if(ind_peak_at2>0)
      OrderSend(Symbol(),OP_SELL, 0.1, Bid, 3, High[2], Open[0]+(Open[0]-High[2])*1,"normal sell",4321,0, clrGreenYellow);
//   if(ind_peak_at3>0)
//      if((High[2]<High[1])&&(Low[2]<Low[1])&&(Open[2]<Open[1]))
//        OrderSend(Symbol(),OP_SELL, 0.1, Bid, 3, High[3], Open[0]+(Open[0]-High[3])*0.5,"normal sell",4321,0, clrGreenYellow);
         

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
