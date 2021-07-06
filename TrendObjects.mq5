//+------------------------------------------------------------------+
//|                                                 TrendObjects.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


struct TREND
{
   bool     bMove;
   string   sLname;
   string   sHname;
   datetime dtHtime;
   datetime dtLtime;
   double   dHighest;
   double   dLowest;
   double   dRange;
   double   dRangeint;
};

TREND Ttrend[2];

MqlTick  MTick;


input double inpdRangeThresh = 0.0003;
input double inpdRangeintThresh = 0.0001;
bool bRange = false;
bool bCreateH = false;
bool bCreateL = false;
bool bRedCyan = false;





//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   SymbolInfoTick(Symbol(),MTick);
   
   for(int iC = 0; iC < 2; iC++)
   {
      Ttrend[iC].sHname = "High" + (iC+1);
      Ttrend[iC].sLname = "Low" + (iC+1);
   }
   
   Ttrend[0].dHighest = MTick.bid;
   Ttrend[0].dLowest =  MTick.bid;
   Ttrend[0].dtHtime = MTick.time;
   Ttrend[0].dtLtime = MTick.time;
   
   ObjectCreate(0,Ttrend[0].sHname,OBJ_ARROW_DOWN,0,Ttrend[0].dtHtime,Ttrend[0].dHighest);
   ObjectCreate(0,Ttrend[0].sLname,OBJ_ARROW_UP,0,Ttrend[0].dtLtime,Ttrend[0].dLowest);
    
   ObjectSetInteger(0,Ttrend[0].sHname,OBJPROP_COLOR,clrBlue);
   ObjectSetInteger(0,Ttrend[0].sLname,OBJPROP_COLOR,clrRed);
   ObjectSetInteger(0,Ttrend[0].sHname,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   ObjectSetInteger(0,Ttrend[0].sLname,OBJPROP_ANCHOR,ANCHOR_TOP);
 
 
 
 
 
 
 
   
//---
   return(INIT_SUCCEEDED);
}





//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   SymbolInfoTick(Symbol(),MTick);

   if(Ttrend[0].dHighest < MTick.bid) // Moves High 1
   {
      Ttrend[0].dHighest = MTick.bid;
      Ttrend[0].dtHtime = MTick.time;
      Ttrend[0].dRange = Ttrend[0].dHighest - Ttrend[0].dLowest;
      ObjectMove(0,Ttrend[0].sHname,0,MTick.time,Ttrend[0].dHighest);
      ChartRedraw(0);
    
   } 
 
   if(Ttrend[0].dLowest > MTick.bid && !bRedCyan) // moves Low 1
   {
      Ttrend[0].dLowest = MTick.bid;
      Ttrend[0].dtLtime = MTick.time;
      Ttrend[0].dRange = Ttrend[0].dHighest - Ttrend[0].dLowest;
      
      ObjectMove(0,Ttrend[0].sLname,0,MTick.time,Ttrend[0].dLowest);
      ChartRedraw(0);
      
   }
  
   
   
   if(Ttrend[0].dRange > inpdRangeThresh && Ttrend[0].dtHtime < Ttrend[0].dtLtime)
   {
     
      if(!bCreateH) // creates High 2
      {
         Ttrend[1].dHighest = MTick.bid;
         Ttrend[1].dtHtime = MTick.time;         
         ObjectCreate(0,Ttrend[1].sHname,OBJ_ARROW_DOWN,0,Ttrend[1].dtHtime,Ttrend[1].dHighest);
         ObjectSetInteger(0,Ttrend[1].sHname,OBJPROP_COLOR,clrCyan);
         ObjectSetInteger(0,Ttrend[1].sHname,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
         bCreateH = true;
      }
     
      if(!bCreateL && Ttrend[0].dRangeint > inpdRangeintThresh)    //creates Low 2
      {  
         Ttrend[1].dLowest =  MTick.bid;
         Ttrend[1].dtLtime = MTick.time;
         
         ObjectCreate(0,Ttrend[1].sLname,OBJ_ARROW_UP,0,Ttrend[1].dtLtime,Ttrend[1].dLowest);
         ObjectSetInteger(0,Ttrend[1].sLname,OBJPROP_COLOR,clrMagenta);
         ObjectSetInteger(0,Ttrend[1].sLname,OBJPROP_ANCHOR,ANCHOR_TOP);
         bCreateL = true;
         bRedCyan = true;
      }
        
      if(Ttrend[1].dHighest < MTick.bid && bCreateH) // moves High 2
      {
         Ttrend[1].dHighest = MTick.bid;
         Ttrend[1].dtHtime = MTick.time;
         Ttrend[1].dRange = Ttrend[1].dHighest - Ttrend[1].dLowest;
         Ttrend[0].dRangeint = Ttrend[1].dHighest - Ttrend[0].dLowest;
         ObjectMove(0,Ttrend[1].sHname,0,MTick.time,Ttrend[1].dHighest);
         ChartRedraw(0);
        
       
      } 
       
      if(Ttrend[1].dLowest > MTick.bid && bCreateL) //moves Low 2
      {
         Ttrend[1].dLowest = MTick.bid;
         Ttrend[1].dtLtime = MTick.time;
         Ttrend[1].dRange = Ttrend[1].dHighest - Ttrend[1].dLowest;
         ObjectMove(0,Ttrend[1].sLname,0,MTick.time,Ttrend[1].dLowest);
         ChartRedraw(0);
         
      }
      
      
      
   }


//---   
}



//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   ObjectDelete(0,Ttrend[0].sHname);
   ObjectDelete(0,Ttrend[0].sLname);
   ObjectDelete(0,Ttrend[1].sHname);
   ObjectDelete(0,Ttrend[1].sLname);
   
}
//+------------------------------------------------------------------+