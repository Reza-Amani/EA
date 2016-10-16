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
#define _look_for_top_state 1
#define _look_for_bottom_state 2
//--- Inputs
input double Lots          =1;
/////////////////////////global variables
int state_machine = 0;
int peak_detector_state_machine = _look_for_top_state;
double tops_price_array[_peaks_array_size]={1000};
int tops_bar_array[_peaks_array_size]={-1};
double bottoms_price_array[_peaks_array_size]={0};
int bottoms_bar_array[_peaks_array_size]={-1};
int peaks_array_index = 0;
int arrow_cnt=0;
/////////////////////////functions
void tops_arrays_append(double top_price, int top_bar)
{
   for(int i=_peaks_array_size-1; i>0; i--)
   {
      tops_price_array[i] = tops_price_array[i-1];
      tops_bar_array[i] = tops_bar_array[i-1];
   }
   tops_price_array[0] = top_price;
   tops_bar_array[0] = top_bar;
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
void increment_bar_arrays()
{
   for(int i=_peaks_array_size-1; i>=0; i--)
   {
      tops_bar_array[i]++;
      bottoms_bar_array[i]++;
   }
}
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

void peak_detector()
{
   switch(peak_detector_state_machine)
   {
      case _look_for_top_state:
         if(Low[1]<bottoms_price_array[0])  //disapproving last bottom because of a lower low taking over it
         {
            //TOCHECK: close potential buy, if it has not breached sl
            //NOTE: disapproved bottom is not going to be removed
            peak_detector_state_machine = _look_for_bottom_state;
         }
         else
         if(High[3]==max(High[1],High[2],High[3],High[4],High[5],High[6]))
         {
            tops_arrays_append(High[3],3);
            arrow_cnt++;
            ObjectCreate(IntegerToString(arrow_cnt),OBJ_ARROW_DOWN,0,Time[3], High[3]);   
            peak_detector_state_machine = _look_for_bottom_state;
         }
         break;
      case _look_for_bottom_state:
         if(High[1]>tops_price_array[0])  //disapproving last top because of a higher high taking over it
         {
            //TOCHECK: close potential sell, if it has not breached sl
            //NOTE: disapproved top is not going to be removed
            peak_detector_state_machine = _look_for_top_state;
         }
         else
         if(Low[3]==min(Low[1],Low[2],Low[3],Low[4],Low[5],Low[6]))
         {
            bottoms_arrays_append(Low[3],3);
            arrow_cnt++;
            ObjectCreate(IntegerToString(arrow_cnt),OBJ_ARROW_UP,0,Time[3], Low[3]);   
            peak_detector_state_machine = _look_for_top_state;
         }
         
         break;
   }

}

void new_position_check()
{
    if(bottoms_bar_array[0]==3)  //a new top just added
//      if(tops_bar_array[0]>3) //only if a newer top hasn't come up
//      if((High[1]>=High[2])&&(High[2]>=High[3]))
         OrderSend(Symbol(),OP_BUY, Lots, Ask, 3, Low[3], 2*Open[0]-Low[3],"combuy",4321,0, clrGreenYellow);
    if(tops_bar_array[0]==3)  //a new top just added
//      if(bottoms_bar_array[0]>3) //only if a newer top hasn't come up
//      if((Low[1]<=Low[2])&&(Low[2]<=Low[3]))
         OrderSend(Symbol(),OP_SELL, Lots, Bid, 3, High[3], 2*Open[0]-High[3],"comsell",4321,0, clrRed);
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

   if (Time0 == Time[0])
      return;
   Time0 = Time[0];

   increment_bar_arrays();
   peak_detector();
   if(OrdersTotal()==0)
      new_position_check();

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
//   arrow_cnt+=2;
//   ObjectCreate(IntegerToString(arrow_cnt),OBJ_ARROW_THUMB_DOWN,0,Time[1], High[1]/* 1.0045 */);   
//   ObjectCreate(IntegerToString(arrow_cnt+1),OBJ_ARROW_THUMB_UP,0,Time[1], Low[1]/* 1.0045 */);   
  }
//+------------------------------------------------------------------+
