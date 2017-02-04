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
input int MACD_fast_len = 13;
input bool use_ADX_confirm = True;
input int ADX_period = 20;
input int ADX_level = 22;
input bool use_RSI_enter = True;
input bool use_RSI_exit_30 = True;
input bool use_RSI_exit_double_drop = True;
input int RSI_len = 14;
input int RSI_enter_level = 50;

///////////////////////////////debug
//in order to debug, retrieve functions from EA5
///////////////////////////////////////////////////////////

//------------------------------------------------functions
void check_opening()
{
   double trend,RSI0,RSI1,RSI2;
   trend = iCustom(Symbol(), Period(),"my_ind/S2/S2trend", MACD_fast_len,use_ADX_confirm,
      ADX_period,ADX_level, 0, 0);
//   Comment("opening, sig= ",sig);
//   Comment("ADX,D+,D_ : = ",iADX(Symbol(), Period(), ADX_period, PRICE_OPEN, MODE_MAIN, 0)
//   ,iADX(Symbol(), Period(), ADX_period, PRICE_OPEN, MODE_PLUSDI, 0)
//   ,iADX(Symbol(), Period(), ADX_period, PRICE_OPEN, MODE_MINUSDI, 0));
   if( ! use_RSI_enter)
   {
      if(trend >= 6)  
         OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, 0, 1000);//,"normal buy",4321,0, clrGreenYellow);
      if(trend <= -6)  
         OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, 1000, 0);//,"normal sell",1234,0, clrGreenYellow);
   }
   else
   {
      RSI0 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 1);
      RSI1 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 2);
      RSI2 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 3);
      if(trend >= 3) //up trend
         if(RSI1<RSI_enter_level)
            if(RSI0>RSI1)
               OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, 0, 1000);//,"normal buy",4321,0, clrGreenYellow);
      if(trend <= -3) //down trend
         if(RSI1> 100-RSI_enter_level)
            if(RSI0<RSI1)
               OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, 1000, 0);//,"normal sell",1234,0, clrGreenYellow);
   }
}

void check_closing()
{
   double trend, RSI0, RSI1, RSI2;
   trend = iCustom(Symbol(), Period(),"my_ind/S2/S2trend", MACD_fast_len,use_ADX_confirm,
      ADX_period,ADX_level, 0, 0);
//   Comment("closing, sig= ",sig);
//   Comment("ADX,D+,D_ : = ",iADX(Symbol(), Period(), ADX_period, PRICE_OPEN, MODE_MAIN, 0)
//   ,iADX(Symbol(), Period(), ADX_period, PRICE_OPEN, MODE_PLUSDI, 0)
//   ,iADX(Symbol(), Period(), ADX_period, PRICE_OPEN, MODE_MINUSDI, 0));


   double current_lots = lots_in_order();
   
   if(current_lots>0)   //already bought
      if(trend <= 2)  
         close_positions();
   if(current_lots<0)   //already sold
      if(trend >= -2)  
         close_positions();
         
   if(use_RSI_exit_30)
   {
      RSI0 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 1);
      RSI1 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 2);
      RSI2 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 3);
      if(current_lots>0)   //already bought
         if( (RSI0<RSI1) && (RSI1<RSI2))  
            close_positions();
      if(current_lots<0)   //already sold
         if( (RSI0>RSI1) && (RSI1>RSI2))  
            close_positions();
   }
   
   if(use_RSI_exit_double_drop)
   {
      RSI0 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 1);
      RSI1 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 2);
      RSI2 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 3);
      if(current_lots>0)   //already bought
         if( (RSI1 > 70) && (RSI0<=70))  
            close_positions();
      if(current_lots<0)   //already sold
         if( (RSI1 < 30) && (RSI0>=30))  
            close_positions();
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
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if( /*Bars<110 ||*/ IsTradeAllowed()==false)
      return;
   //just wait for new bar
   static datetime Time0=0;

//!! only uncomment for tester in open p mode   if (Time0 == Time[0])
//      return;
   Time0 = Time[0];
   
   if(lots_in_order()==0)
      check_opening();
   else
      check_closing();
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
