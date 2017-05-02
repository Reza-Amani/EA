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
input int      pattern_len=5;
input double   correlation_thresh=93;
input int      history=20000;
input double i_Lots         =1;
//////////////////////////////parameters
//----macros
#define _min_hit 20
#define _MAX_ALPHA 2.5
#define _max_len  25
//----globals
double alpha_H1[100],alpha_L1[100],alpha_H2[100],alpha_L2[100];
string logstr="";
int no_of_hits_p0=0;
int no_of_hits_pthresh=0;
int no_of_output_lines=0;
int no_of_trades=0;
int trade_id=0;
int state=0;
int ticket_is_buy;
int history_size; 
int number_of_hits,no_of_b1_higher,no_of_b2_higher,no_of_l1_lower,no_of_h1_higher,no_of_l2_lower,no_of_h2_higher;
double ave_alphaH1,ave_alphaL1,ave_alphaH2,ave_alphaL2;
int b1_higher_pc,b2_higher_pc,h1_higher_pc,l1_lower_pc,h2_higher_pc,l2_lower_pc;
double patternS[_max_len];

int filehandle=FileOpen("./tradefiles/EAlog.csv",FILE_WRITE|FILE_CSV,',');
///////////////////////////////debug
//in order to debug, import functions from EA5
///////////////////////////////////////////////////////////
int OnInit()
  {
   add_log("EA started. ");
   if(filehandle<0)
     {
      Comment("file error");
      Print("Failed to open the file");
      Print("Error code ",GetLastError());
      return(INIT_FAILED);
     }
   add_log("file ok\r\n");
   return(INIT_SUCCEEDED);
  }

//------------------------------------------------functions
void open_ticket()
{
   history_size=min(Bars,history)-pattern_len-10; 
   double corrH,corrL,corrS;
//   double aH,aL;
   for(int i=1;i<pattern_len;i++)
      patternS[i-1]=High[i]-Low[i];
            
   number_of_hits = 0;
   no_of_b1_higher=0;
   no_of_b2_higher=0;
   no_of_h1_higher=0;
   no_of_l1_lower=0;
   no_of_h2_higher=0;
   no_of_l2_lower=0;
   
   for(int i=pattern_len;i<history_size;i++)
     {
      corrH = correlation_array(High,1,High,i,pattern_len);
      corrL = correlation_array(Low,1,Low,i,pattern_len);
      corrS = correlation_bar_size_array(patternS,i,pattern_len);
      if( (corrH>correlation_thresh) &&
          (corrL>correlation_thresh) &&
          (corrS>correlation_thresh) )
        {   //analysing found sister
            alpha_H1[number_of_hits] = alpha(High[i], Low[i], High[i-1]);
            alpha_L1[number_of_hits] = alpha(High[i], Low[i], Low[i-1]);
            alpha_H2[number_of_hits] = alpha(High[i], Low[i], High[i-2]);
            alpha_L2[number_of_hits] = alpha(High[i], Low[i], Low[i-2]);
   
            if((High[i-1]+Low[i-1])/2>(High[i]+Low[i])/2)
               no_of_b1_higher++;
            if((High[i-2]+Low[i-2])/2>(High[i]+Low[i])/2)
               no_of_b2_higher++;
            if(High[i-1]>High[i])
               no_of_h1_higher++;
            if(Low[i-1]<Low[i])
               no_of_l1_lower++;
            if(High[i-2]>High[i])
               no_of_h2_higher++;
            if(Low[i-2]<Low[i])
               no_of_l2_lower++;
            number_of_hits++;
            if(number_of_hits>=100)
               break;
         }
      }  //end of search for sisters
      if(number_of_hits>_min_hit)
      {
         no_of_output_lines++;
         ave_alphaH1 = array_ave(alpha_H1,number_of_hits);
         ave_alphaL1 = array_ave(alpha_L1,number_of_hits);
         ave_alphaH2 = array_ave(alpha_H2,number_of_hits);
         ave_alphaL2 = array_ave(alpha_L2,number_of_hits);
         b1_higher_pc=(int)100*no_of_b1_higher/number_of_hits;
         b2_higher_pc=(int)100*no_of_b2_higher/number_of_hits;
         h1_higher_pc=(int)100*no_of_h1_higher/number_of_hits;
         l1_lower_pc=(int)100*no_of_l1_lower/number_of_hits;
         h2_higher_pc=(int)100*no_of_h2_higher/number_of_hits;
         l2_lower_pc=(int)100*no_of_l2_lower/number_of_hits;

         if(b2_higher_pc>66)
         {
//            OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, price_fromalpha(High[1],Low[1],-0.5),price_fromalpha(High[1],Low[1],0.5));//,"normal buy",4321,0, clrGreenYellow);
            double enter_price = ND(price_fromalpha(High[1],Low[1],0));
            double sl = ND(price_fromalpha(High[1],Low[1],-0.5));
            double tp = ND(price_fromalpha(High[1],Low[1],+0.5));
            int result=OrderSend(Symbol(),OP_BUYLIMIT, i_Lots, enter_price, 3, sl, tp,NULL,++trade_id,0,clrAliceBlue);
//            int result=OrderSend(Symbol(),OP_BUYLIMIT, i_Lots, price_fromalpha(High[1],Low[1],0), 3, price_fromalpha(High[1],Low[1],-0.5),price_fromalpha(High[1],Low[1],0.5),NULL,++trade_id,0,clrAliceBlue);
            if(result < 0)
               Print("OrderSend Error: ", GetLastError());  //for print on screen:  Alert            ticket_is_buy=1;
            else
            {  
               ticket_is_buy=1;
               state = 1;
            }
         }
         else
         if(b2_higher_pc<33)
         {
//            OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, price_fromalpha(High[1],Low[1],+0.5),price_fromalpha(High[1],Low[1],-0.5));//,"normal sell",1234,0, clrGreenYellow);
            double enter_price = ND(price_fromalpha(High[1],Low[1],0));
            double sl = ND(price_fromalpha(High[1],Low[1],+0.5));
            double tp = ND(price_fromalpha(High[1],Low[1],-0.5));
            int result=OrderSend(Symbol(),OP_SELLLIMIT, i_Lots, enter_price, 3, sl, tp,NULL,++trade_id,0,clrDarkRed);
            if(result < 0)
               Print("OrderSend Error: ", GetLastError(),Ask,enter_price,sl,tp);  //for print on screen:  Alert            ticket_is_buy=1;
            else
            {  
               ticket_is_buy=-1;
               state = 1;
            }
         }
         else
         {  //no trade, just log
            FileWrite(filehandle,number_of_hits,"B1h",b1_higher_pc,"B2h",b2_higher_pc,
               "H1h",h1_higher_pc,"L1l",l1_lower_pc,"H2h",h2_higher_pc,"L2l",l2_lower_pc,
               "aH1",ave_alphaH1,"aL1",ave_alphaL1,"aH2",ave_alphaH2,"aL2",ave_alphaL2,"No trade",0);
//            show_log_plus("\r\n no of file entries:",no_of_output_lines,"-------Hits=",number_of_hits,"  b1 higher=",b1_higher_pc,"  b2 higher=",b2_higher_pc,"  H2 higher=",(int)(100*no_of_h2_higher/number_of_hits));
         }
      }
      
            
}















/*
   double trend,RSI0,RSI1,RSI2;
   double ceiling_high,ceiling_med,floor_med,floor_low;
   int RSI_thresh0,RSI_thresh1;


   if( ! use_RSI_enter)
   {
      if(trend >= 6)  
         OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, floor_low, ceiling_high);//,"normal buy",4321,0, clrGreenYellow);
      if(trend <= -6)  
         OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, ceiling_high, floor_low);//,"normal sell",1234,0, clrGreenYellow);
   }
   else
   {
      RSI0 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 1);
      RSI1 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 2);
      RSI2 = iCustom(Symbol(), Period(),"Market/Fast and smooth RSI", RSI_len, MODE_LWMA, PRICE_CLOSE, 0, 3);
      RSI_thresh0 = iCustom(Symbol(), Period(),"my_ind/S2/S2_RSI14thresh", MACD_fast_len,use_ADX_confirm,
         ADX_period,ADX_level,Thr_trend6,Thr_trend5,Thr_trend4,Thr_trend3,Thr_trend2,Thr_trend1, 0, 1);
      RSI_thresh1 = iCustom(Symbol(), Period(),"my_ind/S2/S2_RSI14thresh", MACD_fast_len,use_ADX_confirm,
         ADX_period,ADX_level,Thr_trend6,Thr_trend5,Thr_trend4,Thr_trend3,Thr_trend2,Thr_trend1, 0, 2);
      if(trend > 0) //up trend
         if(RSI1<RSI_thresh0)
            if(RSI0>RSI_thresh0)
               if(RSI_thresh1!=EMPTY_VALUE)   //excluding the first bar after zero trend
                  OrderSend(Symbol(),OP_BUY, i_Lots, Ask, 3, floor_low, ceiling_high);//,"normal buy",4321,0, clrGreenYellow);
      if(trend < 0) //down trend
         if(RSI1>RSI_thresh0)
            if(RSI0<RSI_thresh0)
               if(RSI_thresh1!=EMPTY_VALUE)   //excluding the first bar after zero trend
                  OrderSend(Symbol(),OP_SELL, i_Lots, Bid, 3, ceiling_high, floor_low);//,"normal sell",1234,0, clrGreenYellow);
   }
   */

void control_ticket()
{
   state = 2;
   if(OrderSelect(0,SELECT_BY_POS)==false)   //The order should have been executed and later closed
   {
      show_log_plus("order completed in one bar");
      return;
   }
   switch(OrderType())
   {
      case OP_BUYLIMIT:    //unmet limit orders
      case OP_SELLLIMIT:
         show_log_plus("unmet limit order");
         close_positions();
         break;
      case OP_BUY:         //executed, not closed order
      case OP_SELL:
         show_log_plus("executed order");
         break;
   }
   //      OrderModify(OrderTicket(),OrderOpenPrice(),new_sl,new_tp,0);
}

void close_ticket()
{
   state=0;
   int b2higher = 0;
   if(High[1]>High[3])
      b2higher++;
   else
      b2higher--;
   if(Low[1]>Low[3])
      b2higher++;
   else
      b2higher--;
   b2higher*=ticket_is_buy;
   FileWrite(filehandle,number_of_hits,"B1h",b1_higher_pc,"B2h",b2_higher_pc,
      "H1h",h1_higher_pc,"L1l",l1_lower_pc,"H2h",h2_higher_pc,"L2l",l2_lower_pc,
      "aH1",ave_alphaH1,"aL1",ave_alphaL1,"aH2",ave_alphaH2,"aL2",ave_alphaL2,"trade",1,b2higher);
   close_positions();
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

//!! only uncomment for tester in open p mode   
   if (Time0 == Time[0])
      return;
   Time0 = Time[0];
   
   switch(state)
   {
      case 0:
         open_ticket();  //still looking
         break;
      case 1:
         control_ticket();   //at the end of first bar, check the probable trade
         break;
      case 2:
         close_ticket();    //close ticket if there is still
         break;
         
   }
///   if(lots_in_order()==0)
//      manage_sltp();
//      check_closing();
  }
//------------------------------------------default functions
void OnDeinit(const int reason)
  {
   FileClose(filehandle);
   Print("Done");

  }
double OnTester()
  {
   double ret=0.0;
   return(ret);
  }
///////////////////////////////////////////////log functions
///////////////////////////////////////////////
void add_log(string str)
  {
   logstr+=str;
   Comment(logstr);
  }
void show_log_plus(string str)
  {
   Comment(logstr,str);
  }
void show_log_plus(int i)
  {
   Comment(logstr,i);
  }
void show_log_plus(string s1,int i1,string s2,int i2,string s3,int i3,string s4,int i4,string s5,int i5)
  {
   Comment(logstr,s1,i1,s2,i2,s3,i3,s4,i4,s5,i5);
  }
void show_log_plus(string s1,double d1,string s2,int i2,string s3,int i3,string s4,int i4)
  {
   Comment(logstr,s1,d1,s2,i2,s3,i3,s4,i4);
  }
void reset_log()
  {
   logstr="";
  }
/////////////////////////////////////////////////////////////correlation and alpha functions
/////////////////////////////////////////////////////////////////////////
double correlation_bar_size_array(const double &array1[],int pattern2,int _len)
  {  //pattern2 is the end indexe
//sigma(x-avgx)(y-avgy)/sqrt(sigma(x-avgx)2*sigma(y-avgy)2)
   double x,y;
   double avg1=0,avg2=0;
   int i;
   for(i=0; i<_len; i++)
     {
      x = array1[i];
      y = High[i+pattern2]-Low[i+pattern2];
      avg1 += x;
      avg2 += y;
     }
   avg1 /= _len;
   avg2 /= _len;

   double x_xby_yb=0,x_xb2=0,y_yb2=0;
   for(i=0; i<_len; i++)
     {
      x = array1[i];
      y = High[i+pattern2]-Low[i+pattern2];
      x_xby_yb+=(x-avg1)*(y-avg2);
      x_xb2 += (x-avg1)*(x-avg1);
      y_yb2 += (y-avg2)*(y-avg2);
     }

   if(x_xb2*y_yb2==0)
      return 0;

   return 100*x_xby_yb/MathSqrt(x_xb2 * y_yb2);

  }
//+---------------------------------------
double correlation_array(const double &array1[],int offset1,const double &array2[],int offset2,int _len)
  {
//sigma(x-avgx)(y-avgy)/sqrt(sigma(x-avgx)2*sigma(y-avgy)2)
   double x,y;
   double avg1=0,avg2=0;
   int i;
   for(i=0; i<_len; i++)
     {
      x = array1[i+offset1];
      y = array2[i+offset2];
      avg1 += x;
      avg2 += y;
     }
   avg1 /= _len;
   avg2 /= _len;

   double x_xby_yb=0,x_xb2=0,y_yb2=0;
   for(i=0; i<_len; i++)
     {
      x = array1[i+offset1];
      y = array2[i+offset2];
      x_xby_yb+=(x-avg1)*(y-avg2);
      x_xb2 += (x-avg1)*(x-avg1);
      y_yb2 += (y-avg2)*(y-avg2);
     }

   if(x_xb2*y_yb2==0)
      return 0;

   return 100*x_xby_yb/MathSqrt(x_xb2 * y_yb2);

  }
//+------------------------------------------------------------------+
double array_ave(double &array[],int size)
  {
   double result=0;
   if(size==0)
      return 0;
   for(int i=0; i<size; i++)
      result+=array[i];
   return result/size;
  }
//+------------------------------------------------------------------+
double price_fromalpha(double refH,double refL,double alpha)
  {
   return (refL+refH)/2 + alpha * (refH-refL);
  }
//+------------------------------------------------------------------+
double alpha(double refH,double refL,double in)
  {
   double result;
   if(refH==refL)
     {
      if(in==refL)
         return 0;
      if(in>refL)
         return _MAX_ALPHA;
      else
         return -_MAX_ALPHA;
     }
   else
     {
      result=(in-(refL+refH)/2)/(refH-refL);
      if(result>_MAX_ALPHA)
         result=_MAX_ALPHA;
      if(result<-_MAX_ALPHA)
         result=-_MAX_ALPHA;
      return result;
     }

  }

///////////////////////////////////////////////////////////////tools
///////////////////////////////////////////////////////////////
double max(double v1,double v2=-DBL_MAX,double v3=-DBL_MAX,double v4=-DBL_MAX,double v5=-DBL_MAX,double v6=-DBL_MAX)
  {
   double result=v1;
   if(v2>result)  result=v2;
   if(v3>result)  result=v3;
   if(v4>result)  result=v4;
   if(v5>result)  result=v5;
   if(v6>result)  result=v6;
   return result;
  }
//+-------------------------------------------------
double min(double v1,double v2=DBL_MAX,double v3=DBL_MAX,double v4=DBL_MAX,double v5=DBL_MAX,double v6=DBL_MAX)
  {
   double result=v1;
   if(v2<result)  result=v2;
   if(v3<result)  result=v3;
   if(v4<result)  result=v4;
   if(v5<result)  result=v5;
   if(v6<result)  result=v6;
   return result;
  }
//+-------------------------------------------------
double ND(double val)
{
   return(NormalizeDouble(val, Digits));
}