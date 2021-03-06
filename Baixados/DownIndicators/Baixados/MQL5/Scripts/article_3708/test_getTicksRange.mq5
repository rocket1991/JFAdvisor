//+------------------------------------------------------------------+
//|                                           test_getTicksRange.mq5 |
//|                                                         Tapochun |
//|                           https://www.mql5.com/en/users/tapochun |
//+------------------------------------------------------------------+
#property copyright "Tapochun"
#property link      "https://www.mql5.com/en/users/tapochun"
#property version   "1.00"
#property script_show_inputs
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input datetime inpStartTime = D'2018.07.13 10:00:00';
input	int inpStartTimeMs = 0;
input datetime inpStopTime = D'2018.07.13 10:00:59';
input int inpStopTimeMs = 999;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
   {
	 //--- Reset the last error code
	 ResetLastError(); 
	 //---
	 MqlTick ticks[];
	 //--- When a request is performed
	 long startTime = ( inpStartTime )*1000 + inpStartTimeMs;
	 long stopTime = ( inpStopTime )*1000 + inpStopTimeMs;
	 //---
	 Print( __FUNCTION__,": Get history from "+GetMsToStringTime( startTime )+" to "+GetMsToStringTime( stopTime ) );
	 //--- Request tick history
	 //int copied = CopyTicks( _Symbol, ticks, COPY_TICKS_TRADE, from, 4000 );
	 int copied = CopyTicksRange( _Symbol, ticks, COPY_TICKS_TRADE, startTime, stopTime );
	 //--- Total volume
	 ulong sumVol = 0;
	 //---
	 long savedTime = 0;
	 string savedFlag = "";
	 //--- Check if data is received
	 if( GetLastError() == 0 )
	 	{
	 	 if( copied > 0 )
	 	 	{
	 	 	 //--- Ticks printout cycle
	 	 	 for( int i = 0; i < copied; i++ )
	 	 	 	{
		 	 	 //--- Get the tick flag
		 	 	 const string flag = GetTickStringFlag( ticks[ i ].flags );
		 	 	 Print( __FUNCTION__,": #",i," "+GetMsToStringTime( ticks[ i ].time_msc )+" "+flag );
		 	 	 //--- Compare the current time and direction with saved ones
		 	 	 if( savedTime == ticks[ i ].time_msc && flag != savedFlag )
		 	 	 	{
		 	 	 	 Print( __FUNCTION__,": DIFFERENT FLAGS IN A SINGLE MILLISECOND!" );
		 	 	 	 savedFlag = flag;
		 	 	 	}
		 	 	 else if( savedTime != ticks[ i ].time_msc )
		 	 	 	{
		 	 	 	 savedTime = ticks[ i ].time_msc;
		 	 	 	 savedFlag = flag;
		 	 	 	}
		 	 	 //--- Increase the total volume
		 	 	 sumVol += ticks[ i ].volume;
		 	 	}
		 	 //---
		 	 Print( __FUNCTION__,": total volume = ",sumVol );
	 	 	}
	 	 else
	 	   {
	 	    //--- Set the error comment
	 	    Comment( "ERROR #",_LastError,": received ",copied," ticks!" );
	 	   } 
	 	}
	 //else
	 //	{
	 //	 //--- Increase the error counter
 	//    ctr++;
 	//    //---
 	//    const string text = "ERROR #"+(string)_LastError+": received "+(string)copied+" ticks! ctr = "+(string)ctr;
 	//    //--- Set the error comment
 	//    Comment( text );
 	//    //---
 	//    Print( __FUNCTION__,": "+text+". from = "+GetMsToStringTime( from ) );
	 //	}
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
