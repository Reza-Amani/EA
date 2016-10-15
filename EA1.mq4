//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#include <WinUser32.mqh>
#include <debug_inc.mqh>
#property copyright   "reza"
#property link        ""
#property description "base foundation"

//#define MAGICMA  20131111
//--- Inputs
input double Lots          =1;
input double level_1 =10;
input double level_2 =30;

/////////////////////////global variables
int state_machine = 0;
int prev_zone = 0;
int tick_cnt = 0;
double temp;
/////////////////////////functions
void report_ints(int p1, int p2, int p3)
{
   if (!IsVisualMode())
      return(0);
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
      return(0);
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
      return(0);
   
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
///////////////////////////////trend-related funcs
double default_lots_for_zone(int zone)
{  //returns desired lots for given zone
   if(zone<=-2)
      return -3;
   if(zone==-1)
      return -1;
   if(zone==0)
      return 0;
   if(zone==1)
      return 1;
   if(zone>=2)
      return 2;
      
}

int determine_zone()
{
//  double indicator = iCustom(NULL,0,"my_ind/my_trending", 10, True,0,0);//!!
  double indicator = iCustom(NULL,0,"my_ind/my_trending", False, 10, True, 10, 0,0);//!!
  temp = indicator;
   logb("my_trending=",DoubleToStr(indicator,8)) ;
   if(indicator < -level_2)
      return -2;
   else   if(indicator < -level_1)
      return -1;
   else   if(indicator < +level_1)
      return 0;
   else   if(indicator < +level_2)
      return 1;
   else
      return 2;
}
///////////////////////
void close_or_sell(double lots_to_be_sold)
{  //first try to close buy (pending or real orders)
   //then sell the remaining lots
   double sold_lots =0;
   for(int order=OrdersTotal()-1; order>=0; order--)
   {
      if(OrderSelect(order,SELECT_BY_POS)==false) continue; 
      if((OrderType()==OP_BUY) || (OrderType()==OP_BUYLIMIT) || (OrderType()==OP_BUYSTOP))
      {
          sold_lots += OrderLots();
          OrderClose(OrderTicket(),OrderLots(),Bid,10,clrOrange); 
      }
   }
   if(sold_lots < lots_to_be_sold)
      OrderSend(Symbol(),OP_SELL, lots_to_be_sold-sold_lots, Bid, 3, 1000, 0,"comsell",4321,0, clrRed);
}

void close_or_buy(double lots_to_be_bought)
{  //first try to close sell (pending or real orders)
   //then buy the remaining lots
   double bought_lots =0;
   for(int order=OrdersTotal()-1; order>=0; order--)
   {
      if(OrderSelect(order,SELECT_BY_POS)==false) continue; 
      if((OrderType()==OP_SELL) || (OrderType()==OP_SELLLIMIT) || (OrderType()==OP_SELLSTOP))
      {
          bought_lots += OrderLots();
          OrderClose(OrderTicket(),OrderLots(),Ask,10,clrBlue); 
      }
   }
   if(bought_lots < lots_to_be_bought)
      OrderSend(Symbol(),OP_BUY, lots_to_be_bought-bought_lots, Ask, 3, 0, 1000,"combuy",4321,0, clrGreenYellow);
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

//                  logt1("Symbol() = ", Symbol()) ; // demo showing how to add paramters 
   if(Bars<60 || IsTradeAllowed()==false)
      return;
   //just wait for new bar
   static datetime Time0=0;
   static int new_bar_tick_cnt=0;
   if (Time0 == Time[0])
      return(0);
   if(new_bar_tick_cnt<1)
   {
      new_bar_tick_cnt++;
      return(0);
   }
   Time0 = Time[0];
   new_bar_tick_cnt=0;

//--- calculate open orders by current symbol
//BreakPoint();
   int zone = determine_zone();
   switch(state_machine)
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
//   report_ints(zone,state_machine,10000*iMA(NULL,0,14,0,MODE_SMA, PRICE_TYPICAL,0));//"my_ind/my_trending",10,True, 0,0));//10, True,0,0));
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