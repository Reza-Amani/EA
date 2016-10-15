//+------------------------------------------------------------------+
//|                                                     EA2peaks.mq4 |
//|                                                             Reza |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Reza"
#property link      ""
#property version   "1.00"
#property strict

#define _peaks_array_size 20
//--- Inputs
input double Lots          =1;
/////////////////////////global variables
int state_machine = 0;
double peaks_price_array[_peaks_array_size];
int peaks_bar_array[_peaks_array_size];
double bottoms_price_array[_peaks_array_size];
int bottoms_bar_array[_peaks_array_size];
int peaks_array_index = 0;
/////////////////////////functions
void peaks_arrays_append(double peak_price, int peak_bar)
{
   for(int i=_peaks_array_size-1; i>0; i--)
   {
      peaks_price_array[i] = peaks_price_array[i-1];
      peaks_bar_array[i] = peaks_bar_array[i-1];
   }
   peaks_price_array[0] = peak_price;
   peaks_bar_array[0] = peak_bar;
}
void bottoms_arrays_append(double bottoms_price, int bottoms_bar)
{
   for(int i=_peaks_array_size-1; i>0; i--)
   {
      bottoms_price_array[i] = bottoms_price_array[i-1];
      bottoms_bar_array[i] = bottoms_bar_array[i-1];
   }
   bottoms_price_array[0] = bottoms_price;
   bottoms_bar_array[0] = bottoms_bar;
}
void shift_bar_arrays()
{
   for(int i=_peaks_array_size-1; i>=0; i--)
   {
      peaks_bar_array[i]++;
      bottoms_bar_array[i]++;
   }
}
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {   
  
   if(Bars<5 || IsTradeAllowed()==false)
      return;
   //just wait for new bar
   static datetime Time0=0;
   static int arrow_cnt=0;
   if (Time0 == Time[0])
      return;
   Time0 = Time[0];



//--- calculate open orders by current symbol
//BreakPoint();
//   int zone = determine_zone();
/*   switch(state_machine)
   {
      case 0: //start, wait for zone == 0 
         report_string("state 0");
         if(zone == 0)
            state_machine = 1;
            break;
      case 1:    
         report_string("state 1");
         double lots_in_need = default_lots_for_zone(zone)-lots_in_order();
         if( lots_in_need != 0 )
         {  //need to buy/sell
            if( lots_in_need >0)
               close_or_buy(lots_in_need);
//               OrderSend(Symbol(),OP_BUY, lots_in_need, Ask, 3, 0, 1000,"comment",1234,0, clrBlue);
            else
               close_or_sell(-lots_in_need);
//               OrderSend(Symbol(),OP_SELL, -lots_in_need, Bid, 3, 1000, 0,"comsell",4321,0, clrRed);
         }
         break;
   }
   prev_zone = zone;    
   report_ints(zone,state_machine,(int)temp);//10000*iCustom(NULL,0,"my_ind/my_trending",10,True, 0,2));//10, True,0,0));
*/
//   report_ints(zone,state_machine,10000*iMA(NULL,0,14,0,MODE_SMA, PRICE_TYPICAL,0));//"my_ind/my_trending",10,True, 0,0));//10, True,0,0));
//   ObjectCreate("Horizontal line",OBJ_HLINE,0,D'2004.02.20 12:30', Close[1]/* 1.0045 */);   
   arrow_cnt+=2;
   ObjectCreate(IntegerToString(arrow_cnt),OBJ_ARROW_THUMB_DOWN,0,Time[1], High[1]/* 1.0045 */);   
   ObjectCreate(IntegerToString(arrow_cnt+1),OBJ_ARROW_THUMB_UP,0,Time[1], Low[1]/* 1.0045 */);   
  }
//+------------------------------------------------------------------+
