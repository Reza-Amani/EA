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
input double i_Lots         =1;
input int      pattern_len=5;
input double   correlation_thresh=93;
//////////////////////////////parameters
//----macros
#define _min_hit 5
#define _MAX_ALPHA 2.5
#define _max_len  25
//----globals
//double alpha_H1[100],alpha_L1[100],alpha_H2[100],alpha_L2[100];
//int sister_bar_no[100];
string logstr="";
int no_of_hits_p0=0;
int no_of_hits_pthresh=0;
int no_of_output_lines=0;

double patternH[_max_len];
double patternL[_max_len];
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
void check_opening()
{
    FileWrite(filehandle,Open[0],High[0],High[1],High[2]);

//---
/*
   int history_size=min(Bars,history_start)-100; 
   int number_of_hits,no_of_b1_higher,no_of_b2_higher;
   double corrH,corrL,corrS;
   double aH,aL;
   double temp_reading;
   while(!FileIsEnding(in_filehandle)) 
   {
      temp_reading=FileReadNumber(in_filehandle); //returns zero for non-numbers
      if(temp_reading==11111)
      {
         for(int i=0;i<pattern_len;i++)
            patternH[i]=FileReadNumber(in_filehandle);
         for(int i=0;i<pattern_len;i++)
            patternL[i]=FileReadNumber(in_filehandle);
         for(int i=0;i<pattern_len;i++)
            patternS[i]=patternH[i]-patternL[i];
            
            
         number_of_hits = 0;
         no_of_b1_higher=0;
         no_of_b2_higher=0;
         for(int i=history_end;i<history_size;i++)
           {
            corrH = correlation_array(patternH,0,High,i,pattern_len);
            corrL = correlation_array(patternL,0,Low,i,pattern_len);
            corrS = correlation_bar_size_array(patternS,i,pattern_len);
            if( (corrH>correlation_thresh) &&
                (corrL>correlation_thresh) &&
                (corrS>correlation_thresh) )
              {
               //saving alpha's for next 2 bars
               aH=alpha(High[i], Low[i], High[i-1]);
               aL=alpha(High[i], Low[i], Low[i-1]);
               aH=min(aH,_MAX_ALPHA);
               aL=max(aL,-_MAX_ALPHA);
               alpha_H1[number_of_hits] = aH;
               alpha_L1[number_of_hits] = aL;
               aH=alpha(High[i], Low[i], High[i-2]);
               aL=alpha(High[i], Low[i], Low[i-2]);
               aH=min(aH,_MAX_ALPHA);
               aL=max(aL,-_MAX_ALPHA);
               alpha_H2[number_of_hits] = aH;
               alpha_L2[number_of_hits] = aL;
               sister_bar_no[number_of_hits]=i;
   
               if((High[i-1]+Low[i-1])/2>(High[i]+Low[i])/2)
                  no_of_b1_higher++;
               if((High[i-2]+Low[i-2])/2>(High[i]+Low[i])/2)
                  no_of_b2_higher++;
   
               number_of_hits++;
               if(number_of_hits>=100)
                  break;
              }
           }  //end of search for sisters
           FileWrite(out_filehandle,patternH[0],number_of_hits,no_of_b1_higher,no_of_b2_higher,(int)(100*no_of_b1_higher/max(number_of_hits,1)));
           
           show_log_plus("Hinput=",patternH[0]," Hits=",number_of_hits," %%b1higher=",100*no_of_b1_higher/max(number_of_hits,1)," %%b2higher=",100*no_of_b2_higher/max(number_of_hits,1));
            
         }
         
         
     }
















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
}

void manage_sltp()
{
/*   if(OrderSelect(0,SELECT_BY_POS)==false)   //assuming that maximum 1 order may exist
      return;
   if(OrderType()==OP_BUY)
   {  //buy trade
      new_tp = ceiling_high;
      if(OrderStopLoss() > floor_med)
         new_sl = OrderStopLoss();
      else
         new_sl = floor_med;
      OrderModify(OrderTicket(),OrderOpenPrice(),new_sl,new_tp,0);
   }
   else
   {  //sell trade
      new_tp = floor_low;
      if(OrderStopLoss() < ceiling_med)
         new_sl = OrderStopLoss();
      else
         new_sl = ceiling_med;
      OrderModify(OrderTicket(),OrderOpenPrice(),new_sl,new_tp,0);
   }
*/   
}

void check_closing()
{
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
   
   if(lots_in_order()==0)
      check_opening();
   else
   {
      manage_sltp();
      check_closing();
   }
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
/////////////////////////////////////////////////////////////////////////
