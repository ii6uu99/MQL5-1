//+------------------------------------------------------------------+
//|                                            trading functions.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#define EXPERT_MAGIC 12345



input int iTrailDis = 20;
input int iStepDis = 5;
input int iTakeDis = 40;


struct TRADE
{

   double   dBidPrice;
   double   dAskPrice;
   double   dSL;
   double   dTP;
   ulong    position_ticket;
   string   sSymbol;
   int      iMagic;
   double dStepDis;
   double dTrailDis;
   MqlTradeRequest   mReq;
   MqlTradeResult    mRes;
   ENUM_POSITION_TYPE eType;
};


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Long(0);
   Sleep(2000);
   CloseTrade(0);
   Sleep(2000);
   CloseTrade(0);
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
/*---
   TrailingStop(0);  
   TrailingStop(1); 
 */ 
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
      
   
  }
//+------------------------------------------------------------------+


//---------------------------------------------------------------Place a Long Trade

TRADE trade[2];

void Long(int iTCount)
{

   ZeroMemory(trade[iTCount].mReq);
   ZeroMemory(trade[iTCount].mRes);  
   
   trade[iTCount].sSymbol = Symbol();
   trade[iTCount].dBidPrice = SymbolInfoDouble(trade[iTCount].sSymbol,SYMBOL_BID);
   trade[iTCount].dAskPrice = SymbolInfoDouble(trade[iTCount].sSymbol,SYMBOL_ASK);
   trade[iTCount].dTP = NormalizeDouble(trade[iTCount].dAskPrice+(iTakeDis*Point()),(int)SymbolInfoInteger(trade[iTCount].sSymbol,SYMBOL_DIGITS));
   trade[iTCount].dSL = NormalizeDouble(trade[iTCount].dAskPrice-(iTrailDis*Point()),(int)SymbolInfoInteger(trade[iTCount].sSymbol,SYMBOL_DIGITS));   
   
   
   trade[iTCount].mReq.action       = TRADE_ACTION_DEAL;
   trade[iTCount].mReq.symbol       = trade[iTCount].sSymbol;
   trade[iTCount].mReq.volume       = 1;
   trade[iTCount].mReq.price        = trade[iTCount].dAskPrice;
   trade[iTCount].mReq.sl           = trade[iTCount].dSL;
   trade[iTCount].mReq.tp           = trade[iTCount].dTP;
   trade[iTCount].mReq.deviation    = Point();
   trade[iTCount].mReq.type         = ORDER_TYPE_BUY;
   trade[iTCount].mReq.type_filling = ORDER_FILLING_IOC;
   trade[iTCount].mReq.magic        = EXPERT_MAGIC;   
   
   if(!OrderSend(trade[iTCount].mReq,trade[iTCount].mRes))
      PrintFormat("OrderSend error %d",GetLastError());
      
   else Print("Long");
   
   trade[iTCount].position_ticket = PositionGetTicket(iTCount);
   trade[iTCount].eType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
}
//---------------------------------------------------------------Place a Short Trade

void Short(int iTCount)
{

   ZeroMemory(trade[iTCount].mReq);
   ZeroMemory(trade[iTCount].mRes); 
   
   trade[iTCount].sSymbol = Symbol();
   trade[iTCount].dBidPrice = SymbolInfoDouble(trade[iTCount].sSymbol,SYMBOL_BID);
   trade[iTCount].dAskPrice = SymbolInfoDouble(trade[iTCount].sSymbol,SYMBOL_ASK);
   trade[iTCount].dTP = NormalizeDouble(trade[iTCount].dBidPrice-(iTakeDis*Point()),(int)SymbolInfoInteger(trade[iTCount].sSymbol,SYMBOL_DIGITS));
   trade[iTCount].dSL = NormalizeDouble(trade[iTCount].dBidPrice+(iTrailDis*Point()),(int)SymbolInfoInteger(trade[iTCount].sSymbol,SYMBOL_DIGITS));  
   
   
   trade[iTCount].mReq.action       = TRADE_ACTION_DEAL;
   trade[iTCount].mReq.symbol       = trade[iTCount].sSymbol;
   trade[iTCount].mReq.volume       = 1;
   trade[iTCount].mReq.price        = trade[iTCount].dBidPrice;
   trade[iTCount].mReq.sl           = trade[iTCount].dSL;
   trade[iTCount].mReq.tp           = trade[iTCount].dTP;
   trade[iTCount].mReq.deviation    = Point();
   trade[iTCount].mReq.type         = ORDER_TYPE_SELL;
   trade[iTCount].mReq.type_filling = ORDER_FILLING_IOC;
   trade[iTCount].mReq.magic        = EXPERT_MAGIC;
   
   if(!OrderSend(trade[iTCount].mReq,trade[iTCount].mRes))
      PrintFormat("OrderSend error %d",GetLastError());
      
   else Print("Short");
   
   trade[iTCount].position_ticket = PositionGetTicket(iTCount);
   trade[iTCount].eType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
}

void CloseTrade(int iTCount)
{

   ZeroMemory(trade[iTCount].mReq);
   ZeroMemory(trade[iTCount].mRes); 
   
   trade[iTCount].mReq.action = TRADE_ACTION_DEAL;
   trade[iTCount].mReq.position = trade[iTCount].position_ticket;
   trade[iTCount].mReq.symbol = trade[iTCount].sSymbol;
   trade[iTCount].mReq.volume       = 1;
   trade[iTCount].mReq.deviation    = Point();
   trade[iTCount].mReq.magic = EXPERT_MAGIC;
   
   
   if(trade[iTCount].eType == POSITION_TYPE_BUY)
   {
      trade[iTCount].mReq.price=SymbolInfoDouble(trade[iTCount].sSymbol,SYMBOL_BID);
      trade[iTCount].mReq.type =ORDER_TYPE_SELL;
   }
   else
   {
      trade[iTCount].mReq.price=SymbolInfoDouble(trade[iTCount].sSymbol,SYMBOL_ASK);
      trade[iTCount].mReq.type =ORDER_TYPE_BUY;
   }
   

   if(!OrderSend(trade[iTCount].mReq,trade[iTCount].mRes))
      PrintFormat("OrderSend error %d",GetLastError());


   if(trade[iTCount].eType == POSITION_TYPE_BUY)
   {
      Short(iTCount);
   }
   else Long(iTCount);
}

/*-------------------------------------------------------------Type of Trade
void PositionCheck()
{
   int iPos = PositionsTotal();
   int iC;
   
   for(iC = iPos; iC > 0  ; iC--)
   {
      
      PositionGetTicket(iC-1);
      trade[iC].iMagic = PositionGetInteger(POSITION_MAGIC);
      trade[iC].sSymbol = PositionGetString(POSITION_SYMBOL);
      trade[iC].position_ticket = PositionGetTicket(iC-1);
      if(trade[iC].iMagic == EXPERT_MAGIC)
      {
         int iOpType = PositionGetInteger(POSITION_TYPE);
         if(iOpType == 0) // long pos
         {            
            //bLong = true;
            MoveLongSL();
         }
         
         if(iOpType == 1) // short pos 
         {            
            //bShort = true;
            MoveShortSL();
         }
      }
   }
}

*/

//---------------------------------------------------------------------------- Move the Stop loss functions

void MoveSL(int iTCount)
{
   
   ZeroMemory(trade[iTCount].mReq);
   ZeroMemory(trade[iTCount].mRes);   
   
   trade[iTCount].mReq.action = TRADE_ACTION_SLTP;
   trade[iTCount].mReq.position = trade[iTCount].position_ticket;
   trade[iTCount].mReq.symbol = trade[iTCount].sSymbol;
   trade[iTCount].mReq.sl = trade[iTCount].dSL;
   trade[iTCount].mReq.tp = trade[iTCount].dTP;
   trade[iTCount].mReq.magic = trade[iTCount].iMagic;
   
   if(!OrderSend(trade[iTCount].mReq,trade[iTCount].mRes))
      PrintFormat("OrderSend error %d",GetLastError());
           
   else Print("Stops Edited");

}

//----------------------------------------------------------------------------------Trailing Stop Logic

void TrailingStop(int iTCount)
{
   
   trade[iTCount].dBidPrice = SymbolInfoDouble(trade[iTCount].sSymbol,SYMBOL_BID);
   
   trade[iTCount].dStepDis = iStepDis*Point();
   trade[iTCount].dTrailDis = iTrailDis*Point();
 
   if(trade[iTCount].dBidPrice > trade[iTCount].dSL)
   {
      //long
      if(trade[iTCount].dBidPrice >= (trade[iTCount].dSL + trade[iTCount].dStepDis + trade[iTCount].dTrailDis))
      {
         if(trade[iTCount].dBidPrice - trade[iTCount].dTrailDis > trade[iTCount].dSL + trade[iTCount].dStepDis)
         {
            trade[iTCount].dSL = trade[iTCount].dBidPrice - trade[iTCount].dTrailDis;
            Print("bid - trail");
         }
         else 
         {
            trade[iTCount].dSL = trade[iTCount].dSL + trade[iTCount].dStepDis;
            Print("stop + step");
         }
         MoveSL(iTCount);     
         Print("LongStops");
      }
   
   }
   
   else
   {
      //short
      trade[iTCount].dAskPrice = SymbolInfoDouble(trade[iTCount].sSymbol,SYMBOL_ASK);
      if(trade[iTCount].dAskPrice <= (trade[iTCount].dSL - trade[iTCount].dStepDis - trade[iTCount].dTrailDis))
      {
         if(trade[iTCount].dAskPrice + trade[iTCount].dTrailDis < trade[iTCount].dSL - trade[iTCount].dStepDis)
         {
            trade[iTCount].dSL = trade[iTCount].dAskPrice + trade[iTCount].dTrailDis;
            Print("ask + trail");
         }
         else 
         {
            trade[iTCount].dSL = trade[iTCount].dSL - trade[iTCount].dStepDis;
            Print("stop - step");
         }
         MoveSL(iTCount);  
         Print("ShortStops");
      }
   
   }   
      
}

