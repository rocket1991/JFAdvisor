//+------------------------------------------------------------------+
//|                                                   EA-defines.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property strict

#include <Trade\\Trade.mqh>
#include "CModule.mqh"

class CTradeMod: public CModule {
public:
   double dBaseLot;
   
   double dProfit;
   
   double dStop;
   
   long   lMagic;
   
   void Sell();
   void Buy();
};

void CTradeMod::Sell()
{
  CTrade Trade;
  
  Trade.SetExpertMagicNumber(lMagic);
  
  double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
  
  Trade.Sell(dBaseLot,NULL,0,ask + dStop,ask - dProfit);
} 

void CTradeMod::Buy()
{
  CTrade Trade;
  Trade.SetExpertMagicNumber(lMagic);
  double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
  Trade.Buy(dBaseLot,NULL,0,bid - dStop,bid + dProfit);
} 


