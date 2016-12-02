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
input double i_Lots         =1;
input int opt_len = 200;
input bool type_fuzzy = False;
input int iMA_len_0 =3;
input int iMA_len_1 =5;
input int iMA_len_2 =8;
input int iMA_len_3 =12;
input int iMA_len_4 =15;
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

//------------------------------------------------functions
int get_opt_ima()
{
      //return iMA_len_1;

   int opt_index = (int)iCustom(NULL,0,"my_ind/IMA_opter/my_IMA_opt", opt_len,type_fuzzy,iMA_len_0,iMA_len_1,iMA_len_2,iMA_len_3,iMA_len_4, 0,0);
   switch(opt_index)
   {
      case 1: return iMA_len_0;
      case 2: return iMA_len_1;
      case 3: return iMA_len_2;
      case 4: return iMA_len_3;
      case 5: return iMA_len_4;
      default: return 0;
   }
}
void    close_positions()
{
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS)==false) continue; 
      if(OrderType()==OP_BUY) 
         OrderClose(OrderTicket(),OrderLots(),Bid,3);
      else if(OrderType()==OP_SELL)
         OrderClose(OrderTicket(),OrderLots(),Ask,3);
   }
}
double lots_in_order()
{  //positive for buy orders, negative for sell
   //returns sum of lots of all orders, current and pending
   double lots =0;
   for(int order=0; order<OrdersTotal(); order++)
   {
      if(OrderSelect(order,SELECT_BY_POS)==false) continue; 
      if((OrderType()==OP_BUY) || (OrderType()==OP_BUYLIMIT) || (OrderType()==OP_BUYSTOP))
          lots += OrderLots();
      else
          lots -= OrderLots();
   }
   return lots;
}

void positions_check(int ima)
{
   double sig = iCustom(NULL,0,"my_ind/IMA_opter/my_IMA_siggen", type_fuzzy,ima, 0,0);
   double current_lots = lots_in_order();
   
//   report_ints(ima,(int)10*sig,(int)10*current_lots);

   if(sig*current_lots>0)
   {
//      report_string("nothing");
      return;
   }
   if(current_lots!=0)
   {
      close_positions();
//      report_string("close positions");
      return;
   }
//   report_string("go trade");
//   report_ints(ima,(int)10*sig,(int)10*current_lots);
   if(sig>0)
      OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, 0, 1000);//,"normal buy",4321,0, clrGreenYellow);
   if(sig<0)
      OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, 1000, 0);//,"normal sell",1234,0, clrGreenYellow);
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

   int opt_iMA_len = get_opt_ima();
   if(opt_iMA_len == 0)
   {
//      report_string("no positions");
      close_positions();
   }
   else 
   {
      positions_check(opt_iMA_len);
//      report_string("positions check");
//      BreakPoint();
   }
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
