//+------------------------------------------------------------------+
//|                                               autotradericci.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#define EXPERT_MAGIC 12345

datetime dtLastTime;
double   input inpVol = 0.1;
double   dBuffer[];
string   sPositionSymbol = Symbol();
int iHandle = iCCI(Symbol(),PERIOD_CURRENT,14,PRICE_TYPICAL); //handle creation *tested as working*

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      SetIndexBuffer(0,dBuffer,INDICATOR_DATA);
      Print(iHandle);
         
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   CopyBuffer(iHandle,0,0,5,dBuffer); //When the buffer is copying in the values, it puts them in reverse order so iHandle[0] = dBuffer[4] so I have changed the logic to match this
   
   if(NewBarCheck())   
   {
      if(dBuffer[0]<dBuffer[1] && dBuffer[1]<-100 && dBuffer[2]>dBuffer[1] && dBuffer[3]>dBuffer[2])     
      {
         Print("Long");
         Long();
      }    
      if(dBuffer[0]>dBuffer[1] && dBuffer[1]>100 && dBuffer[2]<dBuffer[1] && dBuffer[3]<dBuffer[2])
      {
         Print("Short");
         Short();
      }
      if(dBuffer[4]>100)
         Print("OB: " + DoubleToString(dBuffer[4],2));
      if(dBuffer[4]<-100)
         Print("OS: " + DoubleToString(dBuffer[4],2));
      if(dBuffer[4]>dBuffer[3])
         Print("Up " + DoubleToString(dBuffer[3],2) + " " + DoubleToString(dBuffer[4],2));
      if(dBuffer[4]<dBuffer[3])
         Print("Down " + DoubleToString(dBuffer[3],2) + " " + DoubleToString(dBuffer[4],2));               
   }  
      
}
   

   
 
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool NewBarCheck()
{
   if(dtLastTime != iTime(NULL,PERIOD_M1,0))
   {
      //Print("NEW BAR");
      dtLastTime = iTime(NULL,PERIOD_M1,0);
      return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+

void Long()
{
   MqlTradeRequest   mReq;
   MqlTradeResult    mRes;
   ZeroMemory(mReq);
   ZeroMemory(mRes);
   
   mReq.action  = TRADE_ACTION_DEAL;
   mReq.symbol  = sPositionSymbol;
   mReq.volume  = inpVol;
   mReq.type    = ORDER_TYPE_BUY;
   mReq.price   = SymbolInfoDouble(sPositionSymbol, SYMBOL_ASK);
   mReq.magic   = EXPERT_MAGIC;
   
   if(!OrderSend(mReq,mRes))
      PrintFormat("OrderSend error %d",GetLastError());
   else Print("Long");

}

void Short()
{
   
   MqlTradeRequest   mReq;
   MqlTradeResult    mRes;
   ZeroMemory(mReq);
   ZeroMemory(mRes);
   
   mReq.action  = TRADE_ACTION_DEAL;
   mReq.symbol  = sPositionSymbol;
   mReq.volume  = inpVol;
   mReq.type    = ORDER_TYPE_SELL;
   mReq.price   = SymbolInfoDouble(sPositionSymbol, SYMBOL_BID);
   mReq.magic   = EXPERT_MAGIC;
   
   if(!OrderSend(mReq,mRes))
      PrintFormat("OrderSend error %d",GetLastError());
   else Print("Short");

}















//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  
  }