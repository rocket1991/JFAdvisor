//+------------------------------------------------------------------+
//|                                                    C3-PO-MVP.mq5 |
//|                                           Miqueias da S. Miranda |
//|                                             GITHUB AQUI          |
//+------------------------------------------------------------------+
#property copyright "Miqueias da S. Miranda"
#property version   "1.30"

#define     ACTION_LINE 0

#include       <Trade\\Trade.mqh>
#include       "..\\INCLUDES\\CV-ActionLines.mqh"
#include       "..\\INCLUDES\\CV-HLine.mqh"
#include       "..\\INCLUDES\\CV-TRADE.mqh"

double maxLine;
double minLine;


CVActionLine   precos[20];
CvHLine        lines[20];
CVCouter       contador;


MqlTick        ultimoTick;
int            passo;
bool init      = false;
input group   "Group"
input bool mostrar = false;

int linesPlot = 4;


//+------------------------------------------------------------------+
//| INICIALIZA OS DADOS INICIAIS                                     |
//+------------------------------------------------------------------+
int OnInit()
{

   contador.vazio       = true;
   contador.qtd         = 0;
   return INIT_SUCCEEDED;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   for(int i = 0; i < linesPlot; i++) {
      ObjectDelete(0, lines[i].GetName());
   }
}


//+------------------------------------------------------------------+
//|  FUNCAO PRINCIPAL DO PROGRAMA                                    |
//+------------------------------------------------------------------+
void OnTick()
{
   SymbolInfoTick(_Symbol, ultimoTick);
   int amp = 25;

   if(!init) {
      int range = 11;
      double price = ultimoTick.last;
      
      int i;
      for(i = 0; i < linesPlot; i++) {
         passo = (range - i);
         precos[i].active  = false;
         precos[i].name    = "Action-";
         precos[i].id      = i;
         precos[i].price   = price + (amp * passo);
      }
      init = true;
   }
   
   


   RenderLines(mostrar);

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RenderLines(bool visible)
{
   if(visible) {
      for(int i = 0; i < linesPlot; i++) {
         string name = precos[i].name + "-" + IntegerToString(i);
         lines[i].Load( name, precos[i].price, clrGray);
      }
   }
   
   
   
}

//+------------------------------------------------------------------+
