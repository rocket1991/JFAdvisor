//+------------------------------------------------------------------+
//|                                                test_tickPack.mq5 |
//|                                                         Tapochun |
//|                           https://www.mql5.com/en/users/tapochun |
//+------------------------------------------------------------------+
#property copyright "Tapochun"
#property link      "https://www.mql5.com/en/users/tapochun"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
//---
   return(INIT_SUCCEEDED);
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
   //--- Reset the last error code
	 ResetLastError(); 
	 //---
	 MqlTick ticks[];
	 //--- When a request is performed
	 static long from = ( TimeCurrent()-1 )*1000;
	 //--- Request tick history
	 int copied = CopyTicks( _Symbol, ticks, COPY_TICKS_TRADE, from, 4000 );
	 //--- Counter of errors in a row
	 static uint ctr = 0;
	 //--- Check if data is received
	 if( GetLastError() == 0 )
	 	{
	 	 if( copied > 0 )
	 	 	{
	 	 	 //--- Get the tick flag
	 	 	 const string flag = GetTickStringFlag( ticks[ copied-1 ].flags );
	 	 	 Print( __FUNCTION__,": Received ticks ",copied,". [0] = "+GetMsToStringTime( ticks[ 0 ].time_msc )+", [",copied-1,"] = "+GetMsToStringTime( ticks[ copied-1 ].time_msc )+" "+flag );
	 	 	 //--- Reset the error counter
	 	 	 ctr = 0;
	 	 	 //--- Reset the error comment
	 	 	 Comment( "" );
	 	 	 //--- Set the tick request moment
	 	 	 from = ticks[ ArraySize( ticks )-1 ].time_msc;
	 	 	 return( rates_total );
	 	 	}
	 	 else
	 	   {
	 	    //--- Increase the error counter
	 	    ctr++;
	 	    //--- Set the error comment
	 	    Comment( "ERROR #",_LastError,": received ",copied," ticks! ctr = ",ctr," "+GetMsToStringTime( from ) );
	 	    return( rates_total );
	 	   } 
	 	}
	 else
	 	{
	 	 //--- Increase the error counter
 	    ctr++;
 	    //---
 	    const string text = "ERROR #"+(string)_LastError+": received "+(string)copied+" ticks! ctr = "+(string)ctr;
 	    //--- Set the error comment
 	    Comment( text );
 	    //---
 	    Print( __FUNCTION__,": "+text+". from = "+GetMsToStringTime( from ) );
	 	}
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Get string value of the tick flag									      |
//+------------------------------------------------------------------+
string GetTickStringFlag( const uint flag )
	{
	if(( flag&TICK_FLAG_BUY)==TICK_FLAG_BUY && ( flag&TICK_FLAG_SELL)==TICK_FLAG_SELL) // If the tick is of both directions
		{
      Print(__FUNCTION__,": ERROR! Tick of unknown direction!");
      return( "WRONG_VALUE" );
      }
   else if(( flag&TICK_FLAG_BUY)==TICK_FLAG_BUY)   // In case of a buy tick
   	return( "FLAG_BUY" );
   else if(( flag&TICK_FLAG_SELL)==TICK_FLAG_SELL) // In case of a sell tick
   	return( "FLAG_SELL" );
   else                                                  // If it is not a trading tick
   	{
   	Print(__FUNCTION__,": ERROR! Not a trading tick!");
   	return( "WRONG_VALUE" );
      }
	}
//+------------------------------------------------------------------+
//| Get the time string from milliseconds 									|
//+------------------------------------------------------------------+
string GetMsToStringTime(const ulong ms)
  {
   return( TimeToString( ms/1000, TIME_DATE|TIME_SECONDS )+"."+string( ms%1000 ) );
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment( "" );
  }
