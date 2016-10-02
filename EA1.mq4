//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "reza"
#property link        ""
#property description "base foundation"

//#define MAGICMA  20131111
//--- Inputs
input double Lots          =0.1;
input double level_1 =15;
input double level_2 =30;

/////////////////////////global variables
int state_machine = 0;
int prev_zone = 0;
double default_lots_for_zone[3]={0,1,3};
/////////////////////////functions
int determine_zone()
{
   int trens_status = iCustom(NULL,0,"my_ind/my_trending", 10, True,0,0);
   if(trens_status < -level_2)
      return -2;
   else   if(trens_status < -level_1)
      return -1;
   else   if(trens_status < +level_1)
      return 0;
   else   if(trens_status < +level_2)
      return 1;
   else
      return 2;
}
///////////////////////relative number of lots in order
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
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<60 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   int zone = determine_zone();
   switch(state_machine)
   {
      case 0: //start, wait for zone == 0 
         if(zone == 0)
            state_machine = 1;
            break;
      case 1:    
         double lots_in_need = default_lots_for_zone[MathAbs(zone)] - lots_in_order();
         if( lots_in_need != 0 )
         {  //need to buy/sell
            if( lots_in_need >0)
               OrderSend(Symbol(),OP_BUY, lots_in_need, Ask, 3, 0, 1000,"comment",1234,0, clrBlue);
            else
               OrderSend(Symbol(),OP_SELL, -lots_in_need, Bid, 3, 1000, 0,"comsell",4321,0, clrRed);
         }
         break;
   }
   prev_zone = zone;    
//---
}
//+------------------------------------------------------------------+


//input double MaximumRisk   =0.02;
//input double DecreaseFactor=3;
//input int    MovingPeriod  =12;
//input int    MovingShift   =6;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
/*int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   double ma;
   int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//--- sell conditions
   if(Open[1]>ma && Close[1]<ma)
     {
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
      return;
     }
//--- buy conditions
   if(Open[1]<ma && Close[1]>ma)
     {
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   double ma;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(Open[1]<ma && Close[1]>ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(Open[1]>ma && Close[1]<ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                     CheckForClose();
//---
  }
//+------------------------------------------------------------------+
*/