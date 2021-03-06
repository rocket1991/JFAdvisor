//+------------------------------------------------------------------+
//|                                                Delta_article.mq5 |
//|                                                         Tapochun |
//|                           https://www.mql5.com/en/users/tapochun |
//+------------------------------------------------------------------+
#property copyright "Tapochun"
#property link      "https://www.mql5.com/en/users/tapochun"
#property version   "1.00"
#property indicator_separate_window
#property indicator_plots 3
#property indicator_buffers 4
//+------------------------------------------------------------------+
//| Include files                                                    |
//+------------------------------------------------------------------+
#include "Ticks_article.mqh"


//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
sinput    datetime         inpHistoryDate = D'00:00:00';  // History start time
sinput    color            inpColorUp = clrRoyalBlue;               // Buy delta color
sinput    color            inpColorDn = clrGray;                      // Sell delta color
sinput    uchar            inpDeltaWidth = 5;                        // Delta column width
sinput    bool             inpLog = false;                           // Keep the log?
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
//--- Indicator buffers
double bufDelta[];                  // Delta values
double bufDeltaColor[];             // Delta color values
double bufBuyVol[];                 // Buy volume on a candle
double bufSellVol[];                // Sell volume on a candle

//--- Object for working with ticks
CTicks _ticks(_Symbol, _Period, COPY_TICKS_TRADE, -1, -1, UINT_MAX, 0, inpLog);

//--- Repeated control parameters
bool _repeatedControl = false;   // Flag
int _controlNum = WRONG_VALUE;   // Candle index

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- Check the indicator input parameters
   if(!CheckInputParameters())
      return( INIT_PARAMETERS_INCORRECT );
//--- Set the indicator parameters
   if(!SetIndicatorParameters() )            // If unsuccessful
      return( INIT_PARAMETERS_INCORRECT );   // Exit
//---
   return( INIT_SUCCEEDED );
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//--- Check for the first launch (Verificando a primeira inicialização)
   if(prev_calculated > 0) { // If not the first launch (Se não for a primeira inicialização)
      //--- 1. Check the new bar formation
      if(rates_total > prev_calculated) { // In case of a new bar
         //--- Initialize the rates_total-1 buffer indices with empty values
         BuffersIndexInitialize(rates_total - 1, EMPTY_VALUE);
         //--- 2. Check if the volume on the rates_total-2 bar should be tracked
         if(_repeatedControl && _controlNum == rates_total - 2) {
            //--- 3. Performing a re-check
            RepeatedControl(_controlNum, time[_controlNum]);
         }
         //--- 4. Reset re-check values
         _repeatedControl = false;
         _controlNum = WRONG_VALUE;
      }
      //--- 5. Download new ticks
      if(!_ticks.GetTicks() )                  // If unsuccessful
         return( prev_calculated );            // Exit with the error
      //--- 6. Remember the time of the obtained history's last tick
      _ticks.SetFrom();
      //--- 7. Calculation
      CalculateCurrentBar(false, rates_total, time, volume);
   } else {                                    // If the first launch (Se for a primeira inicialização)
      
      //--- 1. Inicializamos os buffers de indicador com valores iniciais
      BuffersInitialize(EMPTY_VALUE);
      //--- 2. Reset the values of repeated control parameters
      //--- 2. (pt) Redefinimos os valores dos parâmetros de re-controle
      _repeatedControl = false;
      _controlNum = WRONG_VALUE;
      //--- 3. Redefinimos o tempo da barra na qual os ticks serão armazenados (pressionando o botão "atualizar")
      _ticks.SetTime(0);
      //--- 4. Definimos o momento para começar a carregar os ticks das barras formadas
      _ticks.SetFrom(inpHistoryDate);
      //--- 5. Verificamos o início do carregamento
      if(_ticks.GetFrom() <= 0)        // Se o momento não estiver definido
         return(0);                    // Saímos
      //--- 6. Definimos o fim do carregamento do histórico das barras formadas
      _ticks.SetTo(long(time[rates_total - 1]*MS_KOEF - 1));
      //--- 7. Carregamos o histórico das barras formadas
      if(!_ticks.GetTicksRange())             // Se não for bem-sucedido
         return(0);                           // Saíamos com erro
      //--- 8. Cálculo do histórico nas barras formadas
      CalculateHistoryBars(rates_total, time, volume);
      //--- 9. Redefinimos o tempo da barra na qual os ticks serão armazenados
      _ticks.SetTime(0);
      //--- 10. Definimos o momento para começar a carregar os ticks da última barra
      _ticks.SetFrom(long(time[rates_total - 1]*MS_KOEF));
      //--- 11. Definimos o momento para finalizar o carregamento dos ticks da última barra
      _ticks.SetTo(long(TimeCurrent()*MS_KOEF));
      //--- 12. Carregamos o histórico da barra atual
      if(!_ticks.GetTicksRange())             // Se não for bem-sucedido
         return(0);                           // Saíamos com erro
      //--- 13. Redefinimos o momento do fim da cópia
      _ticks.SetTo(ULONG_MAX);
      //--- 14. Lembramo-nos da hora do último tick do histórico recebido
      _ticks.SetFrom();
      //--- 15. Cálculo da barra atual
      CalculateCurrentBar(true, rates_total, time, volume);
      //--- 16. Definimos o número de ticks para cópias posteriores em tempo real
      _ticks.SetCount(4000);
   }
//---
   return( rates_total );
}


//+------------------------------------------------------------------+
//| Função para cálculo da vela atual                                |
//+------------------------------------------------------------------+
void CalculateCurrentBar(const bool firstLaunch,   // Sinalizador da primeira inicialização da função
                         const int rates_total,    // Número de barras contadas
                         const datetime& time[],   // Matriz de tempo de abertura de barras
                         const long& volume[]      // Matriz de valores do volume real
                        )
{
//--- Volumes totais
   static long sumVolBuy = 0;
   static long sumVolSell = 0;
//--- Número da barra para armazenar no buffer
   static int bNum = WRONG_VALUE;
   
//--- Verificamos o sinalizador da primeira inicialização
   if(firstLaunch) { // Se a primeira inicialização
      //--- Redefinimos os parâmetros estáticos
      sumVolBuy = 0;
      sumVolSell = 0;
      bNum = WRONG_VALUE;
   }
//--- Obtemos o número do penúltimo tick na matriz
   const int limit = _ticks.GetSize() - 1;
//--- Hora do tick 'limit'
   const ulong limitTime = _ticks.GetFrom();
//--- Ciclo para todos os ticks (excluindo o último)
   for(int i = 0; i < limit && !IsStopped(); i++) {
      //--- 1. Comparamos o tempo do tick i com o tempo do tick 'limit' (verificação da conclusão do ciclo)
      if( _ticks.GetTickTimeMs( i ) == limitTime )          // Se o tempo do tick for igual ao tempo do tick limite
         return;                                            // Saímos
      //--- 2. Verificamos se começou a se formar a vela que está ausente no gráfico.
      if(_ticks.GetTickTime(i) >= time[rates_total - 1] + PeriodSeconds()) {        // Se a vela se começou a se formar
         //--- Verificamos o log
         if(inpLog)
            Print(__FUNCTION__, ": ATTENTION! Future tick [" + GetMsToStringTime(_ticks.GetTickTimeMs(i)) + "]. Tick time " + TimeToString(_ticks.GetTickTime(i)) +
                  ", time[ rates_total-1 ]+PerSec() = " + TimeToString(time[rates_total - 1] + PeriodSeconds()));
         //--- 2.1. Definimos (corrigimos) a hora da próxima solicitação de ticks
         _ticks.SetFrom(_ticks.GetTickTimeMs(i));
         //--- Saimos
         return;
      }
      //--- 3. Definimos a vela em que são registrados os ticks.
      if(_ticks.IsNewCandle(i)) {                       // Se a próxima vela começar a se formar
         //--- 3.1. Verificamos se o número da vela formada (concluída) está registrado.
         if(bNum >= 0) { // Se o número estiver registrado
            //--- Verificamos se os valores de volume estão registrados
            if(sumVolBuy > 0 || sumVolSell > 0) { // Se todos os parâmetros estiverem registrados
               //--- 3.1.1. Controlamos o volume total da vela
               VolumeControl(true, bNum, volume[bNum], time[bNum], sumVolBuy, sumVolSell);
            }
         }
         //--- 3.2. Redefinimos os volumes da vela anterior
         sumVolBuy = 0;
         sumVolSell = 0;
         //--- 3.3. Lembramo-nos do número da vela atual
         bNum = rates_total - 1;
      }
      //--- 4. Adicionamos o volume no tick ao componente requerido
      AddVolToSum(_ticks.GetTick(i), sumVolBuy, sumVolSell);
      //--- 5. Colocamos os valores nos buffers
      DisplayValues(bNum, sumVolBuy, sumVolSell, __LINE__);
   }
}
//+------------------------------------------------------------------+
//| Function for calculating formed history bars                     |
//+------------------------------------------------------------------+
bool CalculateHistoryBars(const int rates_total,// Number of calculated bars
                          const datetime& time[],   // Array of bar open times
                          const long& volume[]      // Array of real volume values
                         )
{
//--- Total volumes
   long sumVolBuy = 0;
   long sumVolSell = 0;
//--- Bar index for writing to the buffer
   int bNum = WRONG_VALUE;
//--- Get the number of ticks in the array
   const int limit = _ticks.GetSize();
//--- Loop by all ticks
   for(int i = 0; i < limit && !IsStopped(); i++) {
      //--- Define the candle the ticks are saved to
      if(_ticks.IsNewCandle(i)) {                       // If the next candle starts forming
         //--- Check if the formed (complete) candle index is saved
         if(bNum >= 0) { // If the index is saved
            //--- Check if the volume values are saved
            if(sumVolBuy > 0 || sumVolSell > 0) { // If all parameters are saved
               //--- Manage the total candle volume
               VolumeControl(false, bNum, volume[bNum], time[bNum], sumVolBuy, sumVolSell);
            }
            //--- Enter the values into the buffers
            DisplayValues(bNum, sumVolBuy, sumVolSell, __LINE__);
         }
         //--- Reset the previous candle volumes
         sumVolBuy = 0;
         sumVolSell = 0;
         //--- Set the candle index according to its opening time
         bNum = _ticks.GetNumByTime(false);
         //--- Check if the index is correct
         if(bNum >= rates_total || bNum < 0) { // If the index is incorrect
            //--- Exit without calculating history
            return( false );
         }
      }
      //--- Add the volume on a tick to the necessary component
      AddVolToSum(_ticks.GetTick(i), sumVolBuy, sumVolSell);
   }
//--- Check if the volumes values of the last formed candle are saved
   if(sumVolBuy > 0 || sumVolSell > 0) { // If all parameters are saved
      //--- Manage the total candle volume
      VolumeControl(false, bNum, volume[bNum], time[bNum], sumVolBuy, sumVolSell);
   }
//--- Enter the values into the buffers
   DisplayValues(bNum, sumVolBuy, sumVolSell, __LINE__);
//--- Calculation complete
   return( true );
}
//+------------------------------------------------------------------+
//| Repeated volume control                                          |
//+------------------------------------------------------------------+
bool RepeatedControl(const int num,// Tracked candle index
                     const datetime time           // Candle open time
                    )
{
//--- Create an object for working with ticks
   CTicks cTicks(_Symbol, _Period, COPY_TICKS_TRADE, time * 1000, (time + PeriodSeconds()) * 1000 - 1);
//--- Download history
   if(!cTicks.GetTicksRange()) // If unsuccessful
      return(false);                                 // Exit with the error
//--- Delta recalculation and repeated control
   if( CandleRecalculation( cTicks, num, time ) )    // If the control is passed
      return( true );                                // Return 'true'
   else                                              // Otherwise
      return(false);                                 // Return 'false'
}
//+------------------------------------------------------------------+
//| num candle delta recalculation                                   |
//+------------------------------------------------------------------+

bool CandleRecalculation(const CTicks &ticks,      // Candle ticks
                         const int num,            // Candle index
                         const datetime time       // Candle time
                        )
{
   //--- Reference volume
   long controlVolume[1];
   //--- Get the volume reference value
   if(!GetVolumeData(_Symbol, _Period, time, 1, controlVolume))   // If no data are obtained
      return(false);                                              // Exit with the error
   //--- Get the index of the last tick in the array
   const int limit = ticks.GetSize() - 1;
   //--- Total volumes
   long sumVolBuy = 0;
   long sumVolSell = 0;
   //--- Loop on all ticks (including the last one)
   for(int i = 0; i <= limit; i++) {
      //--- Add the volume on a tick to the appropriate sum
      AddVolToSum(ticks.GetTick(i), sumVolBuy, sumVolSell);
   }
   //--- Display chart values
   DisplayValues(num, sumVolBuy, sumVolSell, __LINE__);
   //--- Repeated volume control
   if(controlVolume[0] != sumVolBuy + sumVolSell) { // If control is NOT passed
      //--- Check if the log is maintained
      if(inpLog)
         Print(__FUNCTION__, ": Repeated control " + TimeToString(time) + " NOT passed! (", controlVolume[0], " = ", sumVolBuy, " + ", sumVolSell, ")");
      //--- Return 'false'
      return( false );
   } else                                          // If the control is passed
      return( true );
}

//---

//+------------------------------------------------------------------+
//| Get rates data                                                   |
//+------------------------------------------------------------------+

bool GetVolumeData(const string symbol,// Symbol
                   const ENUM_TIMEFRAMES timeframe,// Timeframe
                   const datetime startTime,         // Copying start time
                   const int count,                  // Number of elements for copying
                   long &vol[]// Data receiver array (out)
                  )
{
   //--- Reset the last error code
   ResetLastError();
   //--- Copy data
   const int num = CopyRealVolume(symbol, timeframe, startTime, count, vol);
   //--- Check the number of copied elements
   if(num > 0) { // If data obtained
      //--- Check the error code
      if(GetLastError() == 0) // If there is no error
         return(true );                              // Return 'true'
      else {                                         // In case of an error
         Print(__FUNCTION__, ": ERROR #", GetLastError(), " when copying " + symbol + " data.");
         return(false);                              // Exit
      }
   } else {                                          // If no data obtained
      Print(__FUNCTION__, ": ERROR #", GetLastError(), ": Failed to obtain " + symbol + " volume data!");
      return(false);                                 // Exit with the error
   }
}

//---

//+------------------------------------------------------------------+
//| Display the indicator values                                     |
//+------------------------------------------------------------------+

void DisplayValues(const int index,                // Candle index
                   const long sumVolBuy,           // Total buy volume
                   const long sumVolSell,          // Total sell volume
                   const int line                  // Function call string index
                  )
{
   //--- Check if the candle index is correct
   if(index < 0) { // If the index is incorrect
      Print(__FUNCTION__, ": ERROR! Incorrect candle index '", index, "'");
      return;                                       // Exit
   }
   //--- Calculate delta
   const double delta = double(sumVolBuy - sumVolSell);
   //--- Enter the values into the buffers
   bufDelta[ index ] = delta;                      // Write delta value
   bufDeltaColor[ index ] = (delta > 0) ?  0 : 1;  // Write the value color
   bufBuyVol[ index ] = (double)sumVolBuy;         // Write the sum of buys
   bufSellVol[ index ] = (double)sumVolSell;       // Write the sum of sells
}

//---

//+------------------------------------------------------------------+
//| Adicionamos o volume do tick ao volume total                     |
//+------------------------------------------------------------------+
void AddVolToSum(const MqlTick &tick,        // Parâmetros do tick verificado
                 long& sumVolBuy,            // Volume total de compras (out)
                 long& sumVolSell           // Volume total de vendas (out)
                )
{
//--- Verificamos a direção do tick
   if(( tick.flags & TICK_FLAG_BUY) == TICK_FLAG_BUY && (tick.flags & TICK_FLAG_SELL) == TICK_FLAG_SELL) {
      // Se o tick estiver em ambos os sentidos
      // Print(__FUNCTION__, ": ERROR! Tick '" + GetMsToStringTime(tick.time_msc) + "' is of unknown direction!");
   } else if(( tick.flags & TICK_FLAG_BUY) == TICK_FLAG_BUY) // In case of a buy tick
      sumVolBuy += (long)tick.volume;
   else if(( tick.flags & TICK_FLAG_SELL) == TICK_FLAG_SELL) // In case of a sell tick
      sumVolSell += (long)tick.volume;
   else                                                  // If it is not a trading tick
      Print(__FUNCTION__, ": ERROR! Tick '" + GetMsToStringTime(tick.time_msc) + "' is not a trading one!");
}



//+------------------------------------------------------------------+
//| Volume control                                                   |
//+------------------------------------------------------------------+
void VolumeControl(const bool useControl,    // First launch flag
                   const int num,            // Tracked candle index
                   const long vol,           // Reference volume
                   const datetime time,      // Reference volume candle time
                   const long sumVolBuy,     // Total buys on the candle
                   const long sumVolSell     // Total sells on the candle
                  )
{
//--- Control
   if(vol == (sumVolBuy + sumVolSell)) // If control is passed
      return;                                // Exit
   else {                                    // Otherwise
      //--- Check if the log is maintained
      if(inpLog)
         Print(__FUNCTION__, ": ERROR! Candle control " + TimeToString(time) + " не пройден: ", vol, " != ", sumVolBuy, "+", sumVolSell);
      //--- Check the volume control necessity
      if(useControl) {
         //--- Repeated control
         if(RepeatedControl(num, time)) // If repeated control is passed
            return;                          // Exit
         //--- Set the repeated control flag on the next tick
         _repeatedControl = true;
         //--- Set the candle index for the repeated control
         _controlNum = num;
      }
   }
}





//+------------------------------------------------------------------+
//| Get the level color depending on the color ID                    |
//+------------------------------------------------------------------+
color GetLevelColor(const int id) // Color ID
{
//--- Return color depending on the ID
   switch(id) {
   case 0:
      return( inpColorUp );
   case 1:
      return( inpColorDn );
   default:
      Print(__FUNCTION__, ": ERROR! Unknown '", id, "' color ID");
      return( WRONG_VALUE );
   }
}



//+------------------------------------------------------------------+
//| Get the time string from milliseconds                            |
//+------------------------------------------------------------------+
string GetMsToStringTime(const ulong ms)
{
   return( TimeToString( ms / MS_KOEF, TIME_DATE | TIME_SECONDS ) + "." + string( ms % MS_KOEF ) );
}
//+------------------------------------------------------------------+
//| Set the indicator parameters                                     |
//+------------------------------------------------------------------+
bool SetIndicatorParameters()
{
//--- Buffer of colors for delta values
   color colors[2];
//--- Mark the color array
   colors[ 0 ] = inpColorUp;
   colors[ 1 ] = inpColorDn;
//--- Set the graphical series parameters
   SetPlotParametersColorHistogram(0, 0, bufDelta, bufDeltaColor, false, "DELTA " + _Symbol, colors, EMPTY_VALUE, inpDeltaWidth);
   SetPlotParametersNONE(1, 2, bufBuyVol, false, "Buy volume", EMPTY_VALUE);
   SetPlotParametersNONE(2, 3, bufSellVol, false, "Sell volume", EMPTY_VALUE);
//--- Short name in the subwindow
   IndicatorSetString(INDICATOR_SHORTNAME, "DELTA '" + _Symbol + "'");
//--- Set the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//--- If all is completed without errors
   return( true );
}
//+-------------------------------------------------------------------+
//| Graphical construction parameters: color histogram from the line 0|
//+-------------------------------------------------------------------+
void SetPlotParametersColorHistogram(const int plotIndex,// Graphical series index
                                     const int bufferNum,// The series' first buffer index
                                     double &value[],// Buffer of values
                                     double& clr[],                                 // Color buffer
                                     const bool asSeries,                           // Numbering flag as in time series
                                     const string label,                           // Series name
                                     const color& colors[],                        // Line colors
                                     const double emptyValue = EMPTY_VALUE,         // Series' empty values
                                     const int width = 0,                           // Line width
                                     const ENUM_LINE_STYLE style = STYLE_SOLID,      // Line style
                                     const int drawBegin = 0,                        // Number of bars that are not drawn
                                     const int shift = 0                         // Construction shift in bars
                                    )
{
//--- Bind the buffers
   SetIndexBuffer(bufferNum, value, INDICATOR_DATA);
   SetIndexBuffer(bufferNum + 1, clr, INDICATOR_COLOR_INDEX);
//--- Set the numbering order in the array buffers
   ArraySetAsSeries(value, asSeries);
   ArraySetAsSeries(clr, asSeries);
//--- Set the graphical construction type
   PlotIndexSetInteger(plotIndex, PLOT_DRAW_TYPE, DRAW_COLOR_HISTOGRAM);
//--- Set the graphical series name
   PlotIndexSetString(plotIndex, PLOT_LABEL, label);
//--- Set empty values in the buffers
   PlotIndexSetDouble(plotIndex, PLOT_EMPTY_VALUE, emptyValue);
//--- Set the number of indicator colors
   const int size = ArraySize(colors);
   PlotIndexSetInteger(plotIndex, PLOT_COLOR_INDEXES, size);
//--- Set the indicator colors
   for(int i = 0; i < size; i++)
      PlotIndexSetInteger(plotIndex, PLOT_LINE_COLOR, i, colors[i]);
//--- Set the line width
   PlotIndexSetInteger(plotIndex, PLOT_LINE_WIDTH, width);
//--- Set the line style
   PlotIndexSetInteger(plotIndex, PLOT_LINE_STYLE, style);
//--- Set the number of bars that are not drawn and values in DataWindow
   PlotIndexSetInteger(plotIndex, PLOT_DRAW_BEGIN, drawBegin);
//--- Set the graphical construction shift by time axis in bars
   PlotIndexSetInteger(plotIndex, PLOT_SHIFT, shift);
}
//+------------------------------------------------------------------+
//| Graphical construction parameters: no display                    |
//+------------------------------------------------------------------+
void SetPlotParametersNONE(const int plotIndex,// Graphical series index
                           const int bufferNum,// The series' first buffer index
                           double &value[],// Buffer of values
                           const bool asSeries,// Numbering flag as in time series
                           const string label,                        // Series name
                           const double emptyValue = EMPTY_VALUE      // Series' empty values
                          )
{
//--- Bind the buffers
   SetIndexBuffer(bufferNum, value, INDICATOR_DATA);
//--- Set the numbering order in the array buffers
   ArraySetAsSeries(value, asSeries);
//--- Set the graphical construction type
   PlotIndexSetInteger(plotIndex, PLOT_DRAW_TYPE, DRAW_NONE);
//--- Set the graphical series name
   PlotIndexSetString(plotIndex, PLOT_LABEL, label);
//--- Set empty values in the buffers
   PlotIndexSetDouble(plotIndex, PLOT_EMPTY_VALUE, emptyValue);
}
//+------------------------------------------------------------------+
//| Initialize the buffers' num index with 'value'                   |
//+------------------------------------------------------------------+
void BuffersIndexInitialize(const int num,// Initialization index
                            const double value      // Initialization value
                           )
{
   bufDelta[num] = value;
   bufDeltaColor[num] = value;
   bufBuyVol[num] = value;
   bufSellVol[num] = value;
}
//+------------------------------------------------------------------+
//| Initialize indicator buffers with initial values                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuffersInitialize(const double value) // Initialization value
{
   ArrayInitialize(bufDelta,        value);
   ArrayInitialize(bufDeltaColor,   value);
   ArrayInitialize(bufBuyVol,       value);
   ArrayInitialize(bufSellVol,      value);
}


//+------------------------------------------------------------------+
//| Check the indicator inputs                                       |
//+------------------------------------------------------------------+
bool CheckInputParameters()
{
//--- Time of the last quote for a symbol
   const datetime tm = (datetime)SymbolInfoInteger(_Symbol, SYMBOL_TIME);
//--- Compare the last quote time with copying start one
   if(tm < inpHistoryDate) {
      Print(__FUNCTION__, ": ERROR! Copying start time (" + TimeToString(inpHistoryDate, TIME_DATE | TIME_SECONDS) + ") > last quote time  (" + TimeToString(tm, TIME_DATE | TIME_SECONDS) + ")");
      return( false );
   }
//--- If all checks are passed
   return( true );
}
//+------------------------------------------------------------------+
