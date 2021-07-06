//+------------------------------------------------------------------+
//|                                                           PP.mq5 |
//|                        Copyright 2020,                Dan White. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#define EXPERT_MAGIC 12345

datetime dtLastTime;

MqlRates    mqRates[];
MqlRates    mqClose[];
MqlRates    mqPrev[];
MqlTick     mqTick;
MqlDateTime dtTimeCurrent; 

string   sPositionSymbol = Symbol();
string   sArray[];
bool     bLong = false;
bool     bShort = false;
bool     bWorkHour[];
bool     bTime = false;
int      iTicketLong = 0;
int      iTicketShort = 0;
double   dTakeProfit;
double   dStopLoss;
//Momentum
MqlTick        mqCurrent;
double         dMomementum;
double         dTickMo[];

//Volume
MqlTick        mqVolume;
long           lVolume[];

//input variables
input double            inpVol = 1;
input int               iTakeProfit = 5;
input int               iStopLoss = 5;
input double            dZoneVar = 0;
input string            sHours = "9,10,11,12,13,14,15,16,17";
input bool              inpbOneTrade = true; 
input bool              inpbReverse = true;
input ENUM_TIMEFRAMES   inpeTimePeriod = PERIOD_D1;
input bool              inpbVolThresh = true;
input bool              inpbMomThresh = true;
input int               iPrice = 20;
input double            dThreshhold = 0.1;
input int               iVolThresh = 30;
input bool              bNoLongOnR = true;
input bool              bNoShortOnS = true;
input bool              bMidBarTrade = true;


//Levels
enum LEVELS {S4,S3,S2,S1,PP,R1,R2,R3,R4};
double dRange;


//level structure
struct LEVEL
{
   double   dLevels;
   bool     bAllowLong;
   bool     bAllowShort;
};

LEVEL dLevel[9];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   SymbolInfoTick(sPositionSymbol, mqCurrent);
   ArraySetAsSeries(dTickMo,true);   
   ArrayResize(dTickMo,iPrice);
   dTickMo[0] = mqCurrent.bid;
   
   
   ArraySetAsSeries(lVolume,true);
   
   PositionCheck();
   
   
   for(int iC = 0; iC < 9; iC++)
   {
      dLevel[iC].bAllowLong = true; 
      dLevel[iC].bAllowShort = true;
   }
      
   if(bNoLongOnR)
   {
      dLevel[R3].bAllowLong = false;
      dLevel[R4].bAllowLong = false;
   }
   
   if(bNoShortOnS)
   {
      dLevel[S3].bAllowShort = false;
      dLevel[S4].bAllowShort = false;
   }  
//---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{   
//---  set PP every hour 
   if(NewBarCheck())
   {
      CopyRates(sPositionSymbol,inpeTimePeriod,1,1,mqRates);
      
      dRange = mqRates[0].high - mqRates[0].low;
      dLevel[PP].dLevels = (mqRates[0].high + mqRates[0].close + mqRates[0].low)/3;
      dLevel[R1].dLevels = ((dLevel[PP].dLevels*2) - mqRates[0].low);
      dLevel[R2].dLevels = (dLevel[PP].dLevels + dRange);
      dLevel[R3].dLevels = (dLevel[R1].dLevels + dRange);
      dLevel[R4].dLevels = (dLevel[R2].dLevels + dRange);
      dLevel[S1].dLevels = ((dLevel[PP].dLevels*2) - mqRates[0].high);
      dLevel[S2].dLevels = (dLevel[PP].dLevels - dRange);
      dLevel[S3].dLevels = (dLevel[S1].dLevels - dRange);
      dLevel[S4].dLevels = (dLevel[S2].dLevels - dRange);
      
             
   }
   if(NewBarCheckTime())
      bTime();
      
   //get price data symbolinfotick
   SymbolInfoTick(sPositionSymbol,mqTick); 
   double dPrice = mqTick.bid;
   
   // check momentum indicator
   Momentum();
   
 
 
   if(NewBarCheckCurrent())
   {
      PositionCheck();
      CopyRates(sPositionSymbol,PERIOD_CURRENT,0,2,mqClose);
      for(int iC = 0; iC < 9; iC++)
      {
         int      iDigits = (int)SymbolInfoInteger(sPositionSymbol,SYMBOL_DIGITS);
         double   dBid = SymbolInfoDouble(sPositionSymbol,SYMBOL_BID);
         double   dAsk = SymbolInfoDouble(sPositionSymbol,SYMBOL_ASK);
         
         if(mqClose[1].close > dLevel[iC].dLevels && mqClose[1].open < (dLevel[iC].dLevels - dZoneVar) && !bLong && bTime() && bThreshholdL() && bVolThresh() && dLevel[iC].bAllowLong)
         {
            if(iC != 9)
            {
               dTakeProfit = dLevel[iC+1].dLevels;
               dStopLoss = dLevel[iC-1].dLevels;
            }
            else
            {              
               double dLTP = iTakeProfit*SymbolInfoDouble(sPositionSymbol,SYMBOL_POINT);
               double dLSL = iStopLoss*SymbolInfoDouble(sPositionSymbol,SYMBOL_POINT);  
               dStopLoss = NormalizeDouble(dBid-dLSL,iDigits);
               dTakeProfit = NormalizeDouble(dBid+dLTP,iDigits); 
            }
            
            if((inpbOneTrade && !bShort) || !inpbOneTrade)  
               Long();
                            
            else if(inpbReverse && bShort)
            {
               CloseShort(iTicketShort);
               Long();
               
            }
         }
         
         
         if(mqClose[1].close < dLevel[iC].dLevels && mqClose[1].open > (dLevel[iC].dLevels + dZoneVar) && !bShort && bTime() && bThreshholdS() && bVolThresh() && dLevel[iC].bAllowShort)
         {
            if(iC != 0)
            {
               dTakeProfit = NormalizeDouble(dLevel[iC-1].dLevels,iDigits); 
               dStopLoss = NormalizeDouble(dLevel[iC+1].dLevels,iDigits);
            }
            else 
            {    
               double dSTP = iTakeProfit*SymbolInfoDouble(sPositionSymbol,SYMBOL_POINT);
               double dSSL = iStopLoss*SymbolInfoDouble(sPositionSymbol,SYMBOL_POINT);  
               dTakeProfit = NormalizeDouble(dBid-dSTP,iDigits);
               dStopLoss = NormalizeDouble(dBid+dSSL,iDigits); 
            }
            
            if((inpbOneTrade && !bLong) || !inpbOneTrade)  
               Short();
            else if(inpbReverse && bLong)
            {
               CloseLong(iTicketLong);
               Short();
               
            }
         }
      }  
   }  
}

 

//---
bool NewBarCheck()
{
   if(dtLastTime != iTime(NULL,inpeTimePeriod,0))
   {
      dtLastTime = iTime(NULL,inpeTimePeriod,0);
      return(true);
   }
   return(false);
}

//---
bool NewBarCheckCurrent()
{
   if(!bMidBarTrade)
   {
      if(dtLastTime != iTime(NULL,PERIOD_CURRENT,0))
      {
         dtLastTime = iTime(NULL,PERIOD_CURRENT,0);
         return(true);
      }
      return(false);
   }
   else return true;
}

bool NewBarCheckTime()
{
   if(dtLastTime != iTime(NULL,PERIOD_H1,0))
   {
      dtLastTime = iTime(NULL,PERIOD_H1,0);
      return(true);
   }
   return(false);
}

bool bVolThresh()
{
   if(inpbVolThresh)
   {
      int iVol = CopyTickVolume(sPositionSymbol, PERIOD_CURRENT, 0, 2, lVolume); 
      if(lVolume[0] > iVolThresh)
         return true;
      else return false;
   }
   else return true;
}
//---
bool bTime()
{
   TimeCurrent(dtTimeCurrent); 
   ArrayResize(bWorkHour,24);
   ArrayFill(bWorkHour,0,24,false);
   
   string sSep = ",";
   ushort uSep = StringGetCharacter(sSep,0);
   StringSplit(sHours,uSep,sArray);
   
   for(int iC = 0; iC < ArraySize(sArray) ; iC++)
      bWorkHour[StringToInteger(sArray[iC])] = true;   
   
   if(bWorkHour[dtTimeCurrent.hour] == true)
      return(true);
   else return(false);
      
   Print("Trading " + bTime);
}

//---
bool bThreshholdS()
{   
   if(inpbMomThresh)
   {
      Momentum();
      if(dMomementum < -dThreshhold)
         return true;
      else return false;
   }
   else return true;
}
//---
bool bThreshholdL()
{
   if(inpbMomThresh)
   {
      Momentum();   
      if(dMomementum > dThreshhold)
         return true;
      else return false;
   }
   else return true;
}
//---



void Momentum()
{
   SymbolInfoTick(sPositionSymbol, mqCurrent);
     
   for(int iC = iPrice - 1; iC > 0; iC--)
      dTickMo[iC] = dTickMo[iC - 1];
   
   dTickMo[0] = mqCurrent.bid;
   dMomementum = (dTickMo[iPrice - 1] - dTickMo[0])*100;
   
   if(dTickMo[iPrice - 1] == 0)
      dMomementum = 0;
   
   Comment(DoubleToString(dMomementum,4));
     
}
//---




void Long()
{
   MqlTradeRequest   mReq;
   MqlTradeResult    mRes;
   ZeroMemory(mReq);
   ZeroMemory(mRes);
   
   int      iStopLevel = (int)SymbolInfoInteger(sPositionSymbol,SYMBOL_TRADE_STOPS_LEVEL);

   mReq.action  = TRADE_ACTION_DEAL;
   mReq.symbol  = sPositionSymbol;
   mReq.volume  = inpVol;
   mReq.type    = ORDER_TYPE_BUY;
   mReq.price   = SymbolInfoDouble(sPositionSymbol, SYMBOL_ASK);
   mReq.magic   = EXPERT_MAGIC;   
   
  
   mReq.tp      = dTakeProfit;
   mReq.sl      = dStopLoss;
   
   
   if(!OrderSend(mReq,mRes))
      PrintFormat("OrderSend error %d",GetLastError());
   

}
//---
void Short()
{
   MqlTradeRequest   mReq;
   MqlTradeResult    mRes;
   ZeroMemory(mReq);
   ZeroMemory(mRes);
   
   int      iStopLevel = (int)SymbolInfoInteger(sPositionSymbol,SYMBOL_TRADE_STOPS_LEVEL);
       
   mReq.action  = TRADE_ACTION_DEAL;
   mReq.symbol  = sPositionSymbol;
   mReq.volume  = inpVol;
   mReq.type    = ORDER_TYPE_SELL;
   mReq.price   = SymbolInfoDouble(sPositionSymbol, SYMBOL_BID);
   mReq.magic   = EXPERT_MAGIC;
     
   
   mReq.tp      = dTakeProfit;  
   mReq.sl      = dStopLoss;
   
   
   if(!OrderSend(mReq,mRes))
      PrintFormat("OrderSend error %d",GetLastError());
   
}
//---

void CloseLong(int iTicket)
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
   mReq.position = iTicket;

   
   if(!OrderSend(mReq,mRes))
      PrintFormat("OrderSend error %d",GetLastError());
   
}


void CloseShort(int iTicket)
{
   MqlTradeRequest   mReq;
   MqlTradeResult    mRes;
   ZeroMemory(mReq);
   ZeroMemory(mRes);
   

       
   mReq.action  = TRADE_ACTION_DEAL;
   mReq.symbol  = sPositionSymbol;
   mReq.volume  = inpVol;
   mReq.type    = ORDER_TYPE_BUY;
   mReq.price   = SymbolInfoDouble(sPositionSymbol, SYMBOL_BID);
   mReq.magic   = EXPERT_MAGIC;
   mReq.position = iTicket;

   
   if(!OrderSend(mReq,mRes))
      PrintFormat("OrderSend error %d",GetLastError());
   
}

//---



//-----------------------------------
void PositionCheck()
{
   int iPos = PositionsTotal();
   int iC;
   bLong = false;
   bShort = false;
   iTicketLong = 0;
   iTicketShort = 0;
   
   for(iC = iPos-1; iC >= 0  ; iC--)
   {
      PositionGetTicket(iC);
      int iMagic = PositionGetInteger(POSITION_MAGIC);
      string sSymbol = PositionGetString(POSITION_SYMBOL);
      
      if(iMagic == EXPERT_MAGIC && sSymbol == Symbol())
      {
         int iOpType = PositionGetInteger(POSITION_TYPE);

         switch (iOpType)
         {
            case POSITION_TYPE_BUY:
               bLong = true;
               iTicketLong = PositionGetInteger(POSITION_TICKET);
               break;
            case POSITION_TYPE_SELL:
               bShort = true;
               iTicketShort = PositionGetInteger(POSITION_TICKET);
               break;
            default:
               break;
          }
      } 
   }
   return;
}





//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Comment(" ");
  }
//+------------------------------------------------------------------+