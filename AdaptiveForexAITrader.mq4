//+------------------------------------------------------------------+
//|                                       AdaptiveForexAITrader.mq4  |
//|                        Enhanced Adaptive Forex Trading Bot       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023"
#property link      ""
#property version   "1.00"
#property strict

// Input Parameters
input string  General_Settings    = "===== General Settings =====";
input int     MagicNumber         = 12345;                          // Magic number for orders
input double  RiskPercent         = 2.0;                            // Risk per trade (% of balance)
input double  MaxDailyRisk        = 6.0;                            // Maximum daily risk (% of balance)
input int     Slippage            = 3;                              // Allowed slippage in pips
input int     MaxSpread           = 5;                              // Maximum allowed spread in pips

input string  Trading_Settings    = "===== Trading Settings =====";
input bool    TradeOnNewBar       = true;                           // Only trade on new bar
input int     StopLoss            = 50;                             // Stop loss in pips
input int     TakeProfit          = 100;                            // Take profit in pips
input int     TrailingStop        = 30;                             // Trailing stop in pips
input int     TrailingStep        = 10;                             // Trailing step in pips
input bool    UseTrailingStop     = true;                           // Use trailing stop
input ENUM_TIMEFRAMES AnalysisTimeframe = PERIOD_H1;                // Timeframe for analysis

input string  Pairs_Settings      = "===== Trading Pairs =====";
input bool    Trade_EURUSD        = true;                           // Trade EURUSD
input bool    Trade_GBPUSD        = true;                           // Trade GBPUSD
input bool    Trade_USDJPY        = true;                           // Trade USDJPY
input bool    Trade_USDCHF        = true;                           // Trade USDCHF
input bool    Trade_AUDUSD        = true;                           // Trade AUDUSD
input bool    Trade_USDCAD        = true;                           // Trade USDCAD
input bool    Trade_NZDUSD        = true;                           // Trade NZDUSD
input bool    Trade_EURGBP        = true;                          // Trade EURGBP
input bool    Trade_EURJPY        = true;                          // Trade EURJPY
input bool    Trade_GBPJPY        = true;                          // Trade GBPJPY
input bool    Trade_XAUUSD        = true;                          // Trade XAUUSD

input string  Advanced_Settings   = "===== Advanced Features =====";
input bool    UseML               = true;                           // Use machine learning
input int     MLPeriod            = 14;                             // Period for ML indicators
input bool    UseMultiTimeframe   = true;                           // Use multi-timeframe analysis
input bool    UsePatternRecognition = true;                         // Use candlestick pattern recognition
input bool    UseSentimentAnalysis = true;                          // Use market sentiment analysis
input bool    UseVolatilityFilter = true;                           // Filter trades based on volatility
input bool    UseCorrelationFiltering = true;                       // Filter correlated pairs
input bool    UseAdvancedMoneyManagement = true;                    // Use advanced money management
input bool    UseEconomicCalendar = true;                           // Use economic calendar
input bool    AvoidNews           = true;                           // Avoid trading during news

input string  Adaptive_Settings   = "===== Adaptive Learning =====";
input bool    UseAdaptiveLearning = true;                           // Use adaptive learning
input double  LearningRate        = 0.05;                           // Learning rate (0.01-0.1)
input int     LearningPeriod      = 100;                            // Number of trades to learn from
input bool    SaveModelDaily      = true;                           // Save model weights daily


input bool    SaveModelDaily      = true;                           // Save model weights daily

// Custom structure for economic events
struct EconomicEvent
{
   datetime time;           // Event time
   string currency;         // Currency affected
   string event_name;       // Name of the event
   int importance;          // Importance level (1-3)
};


// Global variables
int g_magic_number;
string g_pairs[20];
int g_total_pairs = 0;
double g_indicator_weights[10];
double g_pair_correlation[20][20];
double g_market_sentiment[20];
double g_market_regime = 0;  // -1 (ranging) to 1 (trending)
double g_market_volatility = 0;
double g_success_threshold = 0.7;
double g_pattern_weight = 0.2;
double g_sentiment_weight = 0.15;
double g_account_growth_factor = 1.0;
double g_daily_risk_used = 0;
datetime g_last_risk_reset = 0;
datetime g_last_model_save = 0;
datetime g_last_bar_time = 0;
double g_prediction = 0;

// Trade history for learning
int g_trade_history_ticket[100];
double g_trade_history_prediction[100];
double g_trade_history_profit[100];
int g_trade_history_count = 0;

// Economic calendar events
EconomicEvent g_economic_events[50];  // Array to store economic events
int g_economic_events_count = 0;      // Number of events loaded



// Correlation matrix
double g_pair_correlation[10][10];

// Market sentiment
double g_market_sentiment[10];



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize magic number
   g_magic_number = MagicNumber;
   
   // Initialize trading pairs
   g_total_pairs = 0;
   if(Trade_EURUSD) g_pairs[g_total_pairs++] = "EURUSD";
   if(Trade_GBPUSD) g_pairs[g_total_pairs++] = "GBPUSD";
   if(Trade_USDJPY) g_pairs[g_total_pairs++] = "USDJPY";
   if(Trade_USDCHF) g_pairs[g_total_pairs++] = "USDCHF";
   if(Trade_AUDUSD) g_pairs[g_total_pairs++] = "AUDUSD";
   if(Trade_USDCAD) g_pairs[g_total_pairs++] = "USDCAD";
   if(Trade_NZDUSD) g_pairs[g_total_pairs++] = "NZDUSD";
   if(Trade_EURGBP) g_pairs[g_total_pairs++] = "EURGBP";
   if(Trade_EURJPY) g_pairs[g_total_pairs++] = "EURJPY";
   if(Trade_GBPJPY) g_pairs[g_total_pairs++] = "GBPJPY";
   if(Trade_XAUUSD) g_pairs[g_total_pairs++] = "XAUUSD";
   
   // Initialize indicator weights
   for(int i = 0; i < 10; i++)
   {
      g_indicator_weights[i] = 0.1;  // Equal weights initially
   }
   
   // Initialize market sentiment
   for(int i = 0; i < g_total_pairs; i++)
   {
      g_market_sentiment[i] = 0;  // Neutral initially
   }
   
   // Initialize correlation matrix
   for(int i = 0; i < g_total_pairs; i++)
   {
      for(int j = 0; j < g_total_pairs; j++)
      {
         g_pair_correlation[i][j] = 0;
      }
   }
   
   // Load model weights if adaptive learning is enabled
   if(UseAdaptiveLearning)
   {
      LoadModelWeights();
   }
   

   
   // Analyze market regime
   if(UseAdaptiveLearning)
   {
      AnalyzeMarketRegime();
   }
   
   // Initialize correlation matrix
   if(UseCorrelationFiltering)
   {
      UpdateCorrelationMatrix();
   }
   
   // Initialize money management
   if(UseAdvancedMoneyManagement)
   {
      UpdateMoneyManagement();
   }
   
   Print("Advanced Adaptive AI Trading Bot initialized");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Load model weights from file                                     |
//+------------------------------------------------------------------+
void LoadModelWeights()
{
   string filename = "model_weights.csv";
   int handle = FileOpen(filename, FILE_READ|FILE_CSV);
   
   if(handle != INVALID_HANDLE)
   {
      // Read indicator weights
      for(int i = 0; i < 10; i++)
      {
         if(!FileIsEnding(handle))
         {
            g_indicator_weights[i] = StringToDouble(FileReadString(handle));
         }
      }
      
      // Read success threshold
      if(!FileIsEnding(handle))
      {
         g_success_threshold = StringToDouble(FileReadString(handle));
      }
      
      // Read pattern weight
      if(!FileIsEnding(handle))
      {
         g_pattern_weight = StringToDouble(FileReadString(handle));
      }
      
      // Read sentiment weight
      if(!FileIsEnding(handle))
      {
         g_sentiment_weight = StringToDouble(FileReadString(handle));
      }
      
      FileClose(handle);
      Print("Model weights loaded successfully");
   }
   else
   {
      Print("Model weights file not found, using default weights");
   }
}

//+------------------------------------------------------------------+
//| Save model weights to file                                       |
//+------------------------------------------------------------------+
void SaveModelWeights()
{
   string filename = "model_weights.csv";
   int handle = FileOpen(filename, FILE_WRITE|FILE_CSV);
   
   if(handle != INVALID_HANDLE)
   {
      // Write indicator weights
      for(int i = 0; i < 10; i++)
      {
         FileWrite(handle, DoubleToString(g_indicator_weights[i], 6));
      }
      
      // Write success threshold
      FileWrite(handle, DoubleToString(g_success_threshold, 6));
      
      // Write pattern weight
      FileWrite(handle, DoubleToString(g_pattern_weight, 6));
      
      // Write sentiment weight
      FileWrite(handle, DoubleToString(g_sentiment_weight, 6));
      
      FileClose(handle);
      Print("Model weights saved successfully");
   }
   else
   {
      Print("Error saving model weights: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Analyze market regime (trend/range/volatility)                   |
//+------------------------------------------------------------------+
void AnalyzeMarketRegime()
{
   // Use SPX500 or major indices to determine overall market regime
   string regime_symbol = "SPX500";
   if(!MarketInfo(regime_symbol, MODE_SPREAD))
      regime_symbol = "EURUSD";  // Fallback to EURUSD if SPX not available
   
   // Calculate trend strength using ADX
   double adx = iADX(regime_symbol, PERIOD_D1, 14, PRICE_CLOSE, MODE_MAIN, 0);
   double di_plus = iADX(regime_symbol, PERIOD_D1, 14, PRICE_CLOSE, MODE_PLUSDI, 0);
   double di_minus = iADX(regime_symbol, PERIOD_D1, 14, PRICE_CLOSE, MODE_MINUSDI, 0);
   
   // Calculate market volatility using ATR
   double atr = iATR(regime_symbol, PERIOD_D1, 14, 0);
   double avg_atr = 0;
   for(int i = 1; i <= 20; i++)
   {
      avg_atr += iATR(regime_symbol, PERIOD_D1, 14, i);
   }
   avg_atr /= 20;
   
   // Normalize volatility to 0-1 range
   g_market_volatility = MathMin(atr / avg_atr, 2.0) / 2.0;
   
   // Determine market regime
   if(adx > 25)
   {
      // Trending market
      if(di_plus > di_minus)
      {
         // Uptrend
         g_market_regime = (adx - 25) / 25;  // 0 to 1 based on ADX strength
      }
      else
      {
         // Downtrend
         g_market_regime = -(adx - 25) / 25;  // 0 to -1 based on ADX strength
      }
   }
   else
   {
      // Ranging market
      g_market_regime = 0;
   }
   
   Print("Market regime analysis - Trend: ", DoubleToString(g_market_regime, 2), 
         ", Volatility: ", DoubleToString(g_market_volatility, 2));
}

//+------------------------------------------------------------------+
//| Update market sentiment                                          |
//+------------------------------------------------------------------+
void UpdateMarketSentiment()
{
   for(int i = 0; i < g_total_pairs; i++)
   {
      string symbol = g_pairs[i];
      
      // Calculate sentiment based on multiple factors
      
      // 1. Retail positioning (simplified simulation)
      double retail_long_percent = 50;  // Default to neutral
      
      // In a real implementation, you would connect to broker API or sentiment data provider
      // For now, we'll use a simple heuristic based on recent price action
      double ma_fast = iMA(symbol, PERIOD_H4, 10, 0, MODE_EMA, PRICE_CLOSE, 0);
      double ma_slow = iMA(symbol, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
      
      if(ma_fast > ma_slow)
      {
         // In uptrend, retail tends to be more short (contrarian)
         retail_long_percent = 40;
      }
      else if(ma_fast < ma_slow)
      {
         // In downtrend, retail tends to be more long (contrarian)
         retail_long_percent = 60;
      }
      
      // 2. Institutional positioning (simplified simulation)
      double institutional_bias = 0;  // -1 to 1 (bearish to bullish)
      
      // Use daily timeframe for institutional bias
      double daily_ma20 = iMA(symbol, PERIOD_D1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
      double daily_ma50 = iMA(symbol, PERIOD_D1, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
      double daily_ma200 = iMA(symbol, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
      
      if(daily_ma20 > daily_ma50 && daily_ma50 > daily_ma200)
      {
         // Strong bullish bias
         institutional_bias = 0.8;
      }
      else if(daily_ma20 < daily_ma50 && daily_ma50 < daily_ma200)
      {
         // Strong bearish bias
         institutional_bias = -0.8;
      }
      else if(daily_ma20 > daily_ma50)
      {
         // Moderate bullish bias
         institutional_bias = 0.4;
      }
      else if(daily_ma20 < daily_ma50)
      {
         // Moderate bearish bias
         institutional_bias = -0.4;
      }
      
      // 3. Calculate overall sentiment
      // Convert retail positioning to -1 to 1 scale and invert (contrarian indicator)
      double retail_sentiment = -(retail_long_percent - 50) / 50;
      
      // Combine retail and institutional with more weight to institutional
      g_market_sentiment[i] = (retail_sentiment * 0.3) + (institutional_bias * 0.7);
      
      // Ensure sentiment is within -1 to 1 range
      if(g_market_sentiment[i] > 1) g_market_sentiment[i] = 1;
      if(g_market_sentiment[i] < -1) g_market_sentiment[i] = -1;
   }
}

//+------------------------------------------------------------------+
//| Update correlation matrix                                        |
//+------------------------------------------------------------------+
void UpdateCorrelationMatrix()
{
   for(int i = 0; i < g_total_pairs; i++)
   {
      for(int j = 0; j < g_total_pairs; j++)
      {
         if(i == j)
         {
            g_pair_correlation[i][j] = 1.0;  // Self correlation is always 1
         }
         else
         {
            g_pair_correlation[i][j] = CalculateCorrelation(g_pairs[i], g_pairs[j]);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update money management based on account performance             |
//+------------------------------------------------------------------+
void UpdateMoneyManagement()
{
   // Calculate account growth factor based on equity vs balance
   double equity = AccountEquity();
   double balance = AccountBalance();
   
   // If we're in profit, we can be slightly more aggressive
   if(equity > balance * 1.05)
   {
      g_account_growth_factor = 1.1;  // Increase risk by 10%
   }
   // If we're in drawdown, be more conservative
   else if(equity < balance * 0.95)
   {
      g_account_growth_factor = 0.8;  // Decrease risk by 20%
   }
   // Otherwise, use normal risk
   else
   {
      g_account_growth_factor = 1.0;
   }
}

//+------------------------------------------------------------------+
//| Detect candlestick patterns                                      |
//+------------------------------------------------------------------+
double DetectCandlestickPatterns(string symbol, ENUM_TIMEFRAMES timeframe)
{
   double signal = 0;
   
   // Get candle data
   double open1 = iOpen(symbol, timeframe, 1);
   double close1 = iClose(symbol, timeframe, 1);
   double high1 = iHigh(symbol, timeframe, 1);
   double low1 = iLow(symbol, timeframe, 1);
   
   double open2 = iOpen(symbol, timeframe, 2);
   double close2 = iClose(symbol, timeframe, 2);
   double high2 = iHigh(symbol, timeframe, 2);
   double low2 = iLow(symbol, timeframe, 2);
   
   double open3 = iOpen(symbol, timeframe, 3);
   double close3 = iClose(symbol, timeframe, 3);
   double high3 = iHigh(symbol, timeframe, 3);
   double low3 = iLow(symbol, timeframe, 3);
   
   // Calculate candle sizes
   double body1 = MathAbs(open1 - close1);
   double body2 = MathAbs(open2 - close2);
   double body3 = MathAbs(open3 - close3);
   
   double range1 = high1 - low1;
   double range2 = high2 - low2;
   double range3 = high3 - low3;
   
   // Detect bullish patterns
   
   // Bullish engulfing
   if(close1 > open1 && close2 < open2 && open1 < close2 && close1 > open2 && body1 > body2 * 0.8)
   {
      signal += 0.7;
   }
   
   // Hammer (bullish)
   if(close1 > open1 && (high1 - close1) < body1 * 0.3 && (open1 - low1) > body1 * 2)
   {
      signal += 0.5;
   }
   
   // Morning star
   if(close3 < open3 && body3 > body2 * 1.5 && body2 < body3 * 0.5 && close1 > open1 && close1 > (open3 + close3) / 2)
   {
      signal += 0.8;
   }
   
   // Detect bearish patterns
   
   // Bearish engulfing
   if(close1 < open1 && close2 > open2 && open1 > close2 && close1 < open2 && body1 > body2 * 0.8)
   {
      signal -= 0.7;
   }
   
   // Shooting star (bearish)
   if(close1 < open1 && (close1 - low1) < body1 * 0.3 && (high1 - open1) > body1 * 2)
   {
      signal -= 0.5;
   }
   
   // Evening star
   if(close3 > open3 && body3 > body2 * 1.5 && body2 < body3 * 0.5 && close1 < open1 && close1 < (open3 + close3) / 2)
   {
      signal -= 0.8;
   }
   
   // Ensure signal is within -1 to 1 range
   if(signal > 1) signal = 1;
   if(signal < -1) signal = -1;
   
   return signal;
}

//+------------------------------------------------------------------+
//| Find first Friday of the month                                   |
//+------------------------------------------------------------------+
datetime FindFirstFriday(int month, int year)
{
   datetime first_day = StringToTime(IntegerToString(year) + "." + IntegerToString(month) + ".01");
   int day_of_week = TimeDayOfWeek(first_day);
   
   // Calculate days to add to get to Friday (day 5)
   int days_to_add = (5 - day_of_week) % 7;
   if(days_to_add < 0) days_to_add += 7;
   
   return first_day + days_to_add * 86400;
}

//+------------------------------------------------------------------+
//| Find third Wednesday of the month                                |
//+------------------------------------------------------------------+
datetime FindThirdWednesday(int month, int year)
{
   datetime first_day = StringToTime(IntegerToString(year) + "." + IntegerToString(month) + ".01");
   int day_of_week = TimeDayOfWeek(first_day);
   
   // Calculate days to add to get to Wednesday (day 3)
   int days_to_add = (3 - day_of_week) % 7;
   if(days_to_add < 0) days_to_add += 7;
   
   // Add two more weeks to get to third Wednesday
   return first_day + (days_to_add + 14) * 86400;
}

//+------------------------------------------------------------------+
//| Find first Thursday of the month                                 |
//+------------------------------------------------------------------+
datetime FindFirstThursday(int month, int year)
{
   datetime first_day = StringToTime(IntegerToString(year) + "." + IntegerToString(month) + ".01");
   int day_of_week = TimeDayOfWeek(first_day);
   
   // Calculate days to add to get to Thursday (day 4)
   int days_to_add = (4 - day_of_week) % 7;
   if(days_to_add < 0) days_to_add += 7;
   
   return first_day + days_to_add * 86400;
}

//+------------------------------------------------------------------+
//| Find third Friday of the month                                   |
//+------------------------------------------------------------------+
datetime FindThirdFriday(int month, int year)
{
   datetime first_day = StringToTime(IntegerToString(year) + "." + IntegerToString(month) + ".01");
   int day_of_week = TimeDayOfWeek(first_day);
   
   // Calculate days to add to get to Friday (day 5)
   int days_to_add = (5 - day_of_week) % 7;
   if(days_to_add < 0) days_to_add += 7;
   
   // Add two more weeks to get to third Friday
   return first_day + (days_to_add + 14) * 86400;
}

//+------------------------------------------------------------------+
//| Check if we should avoid trading due to economic events          |
//+------------------------------------------------------------------+
bool ShouldAvoidTradingDueToEvents(string symbol)
{
   if(!UseEconomicCalendar) return false;
   
   // Get currency pair components
   string base_currency = StringSubstr(symbol, 0, 3);
   string quote_currency = StringSubstr(symbol, 3, 3);
   
   // Current time
   datetime current_time = TimeCurrent();
   
   // Check upcoming events
   for(int i = 0; i < g_economic_events_count; i++)
   {
      // Only consider high-impact events (importance = 3)
      if(g_economic_events[i].importance >= 3)
      {
         // Check if event affects this currency pair
         if(g_economic_events[i].currency == base_currency || 
            g_economic_events[i].currency == quote_currency)
         {
            // Check if event is within the next 60 minutes or just happened within 30 minutes
            int time_diff_minutes = (int)(g_economic_events[i].time - current_time) / 60;
            
            if(time_diff_minutes >= -30 && time_diff_minutes <= 60)
            {
               return true;  // Avoid trading
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Load economic calendar data                                      |
//+------------------------------------------------------------------+
void LoadEconomicCalendar()
{
   // Reset event counter
   g_economic_events_count = 0;
   
   // Current time
   datetime current_time = TimeCurrent();
   datetime end_time = current_time + 7*24*60*60; // One week ahead
   
   // Since MT4 Calendar object might not be available in all versions,
   // we'll use the fallback method directly
   Print("Using placeholder events for economic calendar");
   LoadPlaceholderEvents();
}

//+------------------------------------------------------------------+
//| Load placeholder events as fallback                              |
//+------------------------------------------------------------------+
void LoadPlaceholderEvents()
{
   // Current time
   datetime current_time = TimeCurrent();
   
   // Sample events - as fallback when MT4 Calendar is not available
   // Add NFP for first Friday of the month
   datetime first_friday = FindFirstFriday(TimeMonth(current_time), TimeYear(current_time));
   g_economic_events[g_economic_events_count].time = first_friday + 8 * 3600 + 30 * 60;  // 8:30 AM EST
   g_economic_events[g_economic_events_count].currency = "USD";
   g_economic_events[g_economic_events_count].event_name = "Non-Farm Payrolls";
   g_economic_events[g_economic_events_count].importance = 3;
   g_economic_events_count++;
   
   // Add Fed rate decision (third Wednesday of the month)
   datetime third_wednesday = FindThirdWednesday(TimeMonth(current_time), TimeYear(current_time));
   g_economic_events[g_economic_events_count].time = third_wednesday + 14 * 3600;  // 2:00 PM EST
   g_economic_events[g_economic_events_count].currency = "USD";
   g_economic_events[g_economic_events_count].event_name = "Fed Rate Decision";
   g_economic_events[g_economic_events_count].importance = 3;
   g_economic_events_count++;
   
   // Add ECB rate decision (first Thursday of the month)
   datetime first_thursday = FindFirstThursday(TimeMonth(current_time), TimeYear(current_time));
   g_economic_events[g_economic_events_count].time = first_thursday + 7 * 3600 + 45 * 60;  // 7:45 AM EST
   g_economic_events[g_economic_events_count].currency = "EUR";
   g_economic_events[g_economic_events_count].event_name = "ECB Rate Decision";
   g_economic_events[g_economic_events_count].importance = 3;
   g_economic_events_count++;
   
   // Add BOE rate decision (first Thursday of the month)
   g_economic_events[g_economic_events_count].time = first_thursday + 7 * 3600;  // 7:00 AM EST
   g_economic_events[g_economic_events_count].currency = "GBP";
   g_economic_events[g_economic_events_count].event_name = "BOE Rate Decision";
   g_economic_events[g_economic_events_count].importance = 3;
   g_economic_events_count++;
   
   // Add BOJ rate decision (third Friday of the month)
   datetime third_friday = FindThirdFriday(TimeMonth(current_time), TimeYear(current_time));
   g_economic_events[g_economic_events_count].time = third_friday;  // Midnight EST
   g_economic_events[g_economic_events_count].currency = "JPY";
   g_economic_events[g_economic_events_count].event_name = "BOJ Rate Decision";
   g_economic_events[g_economic_events_count].importance = 3;
   g_economic_events_count++;
}


   
//+------------------------------------------------------------------+
//| Calculate correlation between two symbols                        |
//+------------------------------------------------------------------+
double CalculateCorrelation(string symbol1, string symbol2)
{
   int period = 20;  // Days to look back
   double x[20], y[20];
   double sum_x = 0, sum_y = 0, sum_xy = 0, sum_x2 = 0, sum_y2 = 0;
   
   // Get daily returns for both symbols
   for(int i = 0; i < period; i++)
   {
      double close1_today = iClose(symbol1, PERIOD_D1, i);
      double close1_yesterday = iClose(symbol1, PERIOD_D1, i+1);
      double close2_today = iClose(symbol2, PERIOD_D1, i);
      double close2_yesterday = iClose(symbol2, PERIOD_D1, i+1);
      
      // Calculate percentage change
      x[i] = (close1_today - close1_yesterday) / close1_yesterday * 100;
      y[i] = (close2_today - close2_yesterday) / close2_yesterday * 100;
      
      sum_x += x[i];
      sum_y += y[i];
      sum_xy += x[i] * y[i];
      sum_x2 += x[i] * x[i];
      sum_y2 += y[i] * y[i];
   }
   
   double correlation = (period * sum_xy - sum_x * sum_y) / 
                        (MathSqrt(period * sum_x2 - sum_x * sum_x) * 
                         MathSqrt(period * sum_y2 - sum_y * sum_y));
   
   return correlation;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if we need to reset daily risk
   if(TimeDay(TimeCurrent()) != TimeDay(g_last_risk_reset))
   {
      g_daily_risk_used = 0;
      g_last_risk_reset = TimeCurrent();
      
      // Update economic calendar at the start of a new day
      if(UseEconomicCalendar)
      {
         LoadEconomicCalendar();
      }
   }
   
   // Save model weights daily if enabled
   if(SaveModelDaily && TimeDay(TimeCurrent()) != TimeDay(g_last_model_save))
   {
      if(UseAdaptiveLearning)
      {
         SaveModelWeights();
         g_last_model_save = TimeCurrent();
      }
   }
   
   // Check if we should trade on new bar only
   if(TradeOnNewBar)
   {
      datetime current_bar_time = iTime(Symbol(), AnalysisTimeframe, 0);
      if(current_bar_time == g_last_bar_time)
      {
         // Not a new bar, just manage open positions
         for(int i = 0; i < g_total_pairs; i++)
         {
            ManageOpenPositions(g_pairs[i]);
         }
         return;
      }
      g_last_bar_time = current_bar_time;
   }
   
   // Update market analysis
   if(UseAdaptiveLearning)
   {
      AnalyzeMarketRegime();
   }
   
   if(UseSentimentAnalysis)
   {
      UpdateMarketSentiment();
   }
   
   if(UseCorrelationFiltering)
   {
      UpdateCorrelationMatrix();
   }
   
   if(UseAdvancedMoneyManagement)
   {
      UpdateMoneyManagement();
   }
   
   // Process closed trades for learning
   if(UseAdaptiveLearning)
   {
      ProcessClosedTrades();
   }
   
   // Check if we've reached maximum daily risk
   if(g_daily_risk_used >= MaxDailyRisk)
   {
      Print("Maximum daily risk reached (", MaxDailyRisk, "%). No more trades today.");
      return;
   }
   
   // Analyze and trade each pair
   for(int i = 0; i < g_total_pairs; i++)
   {
      string symbol = g_pairs[i];
      
      // Check if spread is too high
      double current_spread = MarketInfo(symbol, MODE_SPREAD) / 10.0;
      if(current_spread > MaxSpread)
      {
         Print("Spread too high for ", symbol, ": ", DoubleToString(current_spread, 1), " pips");
         continue;
      }
      
      // Check if we should avoid trading due to economic events
      if(AvoidNews && ShouldAvoidTradingDueToEvents(symbol))
      {
         Print("Avoiding trading ", symbol, " due to upcoming high-impact economic events");
         continue;
      }
      
      // Check if we already have an open position for this pair
      if(HasOpenPosition(symbol))
      {
         ManageOpenPositions(symbol);
         continue;
      }
      
      // Check correlation with other open positions
      if(UseCorrelationFiltering && IsHighlyCorrelatedWithOpenPositions(symbol))
      {
         Print("Skipping ", symbol, " due to high correlation with existing positions");
         continue;
      }
      
      // Analyze the pair and get trading signal
      double signal = AnalyzePair(symbol);
      
      // Store prediction for learning
      g_prediction = signal;
      
      // Execute trades based on signal
      if(signal > g_success_threshold)
      {
         Print("Buy signal for ", symbol, ": ", DoubleToString(signal, 2));
         OpenBuyOrder(symbol);
      }
      else if(signal < -g_success_threshold)
      {
         Print("Sell signal for ", symbol, ": ", DoubleToString(signal, 2));
         OpenSellOrder(symbol);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if there's an open position for the symbol                 |
//+------------------------------------------------------------------+
bool HasOpenPosition(string symbol)
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == symbol && OrderMagicNumber() == g_magic_number)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if symbol is highly correlated with open positions         |
//+------------------------------------------------------------------+
bool IsHighlyCorrelatedWithOpenPositions(string symbol)
{
   int symbol_index = -1;
   
   // Find index of the symbol
   for(int i = 0; i < g_total_pairs; i++)
   {
      if(g_pairs[i] == symbol)
      {
         symbol_index = i;
         break;
      }
   }
   
   if(symbol_index == -1) return false;
   
   // Check correlation with open positions
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == g_magic_number)
         {
            string open_symbol = OrderSymbol();
            
            // Find index of the open position symbol
            int open_symbol_index = -1;
            for(int j = 0; j < g_total_pairs; j++)
            {
               if(g_pairs[j] == open_symbol)
               {
                  open_symbol_index = j;
                  break;
               }
            }
            
            if(open_symbol_index != -1)
            {
               // Check correlation
               double correlation = g_pair_correlation[symbol_index][open_symbol_index];
               
               // If correlation is high (>0.7 or <-0.7) and same direction
               if((correlation > 0.7 && ((OrderType() == OP_BUY && g_prediction > 0) || 
                                         (OrderType() == OP_SELL && g_prediction < 0))) ||
                  (correlation < -0.7 && ((OrderType() == OP_BUY && g_prediction < 0) || 
                                         (OrderType() == OP_SELL && g_prediction > 0))))
               {
                  return true;
               }
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Process closed trades for adaptive learning                      |
//+------------------------------------------------------------------+
void ProcessClosedTrades()
{
   for(int i = 0; i < g_trade_history_count; i++)
   {
      // Skip already processed trades
      if(g_trade_history_profit[i] != 0) continue;
      
      // Check if trade is closed
      if(OrderSelect(g_trade_history_ticket[i], SELECT_BY_TICKET) && OrderCloseTime() > 0)
      {
         // Store profit/loss
         g_trade_history_profit[i] = OrderProfit();
         
         // Use this trade for learning
         LearnFromTrade(g_trade_history_prediction[i], g_trade_history_profit[i]);
      }
   }
}

//+------------------------------------------------------------------+
//| Learn from trade results to adjust weights                       |
//+------------------------------------------------------------------+
void LearnFromTrade(double prediction, double profit)
{
   // Skip if prediction was neutral
   if(MathAbs(prediction) < 0.3) return;
   
   // Determine if prediction was correct
   bool correct_prediction = (prediction > 0 && profit > 0) || (prediction < 0 && profit < 0);
   
   // Adjust success threshold based on results
   if(correct_prediction)
   {
      // Slightly lower threshold if we're making good predictions
      g_success_threshold = g_success_threshold * (1.0 - LearningRate * 0.1);
      if(g_success_threshold < 0.5) g_success_threshold = 0.5;
   }
   else
   {
      // Increase threshold if predictions are wrong
      g_success_threshold = g_success_threshold * (1.0 + LearningRate * 0.2);
      if(g_success_threshold > 0.9) g_success_threshold = 0.9;
   }
   
   // Adjust weights for pattern recognition and sentiment
   if(correct_prediction)
   {
      g_pattern_weight = g_pattern_weight * (1.0 + LearningRate * 0.05);
      g_sentiment_weight = g_sentiment_weight * (1.0 + LearningRate * 0.05);
   }
   else
   {
      g_pattern_weight = g_pattern_weight * (1.0 - LearningRate * 0.1);
      g_sentiment_weight = g_sentiment_weight * (1.0 - LearningRate * 0.1);
   }
   
   // Ensure weights stay in reasonable range
   if(g_pattern_weight < 0.05) g_pattern_weight = 0.05;
   if(g_pattern_weight > 0.4) g_pattern_weight = 0.4;
   if(g_sentiment_weight < 0.05) g_sentiment_weight = 0.05;
   if(g_sentiment_weight > 0.3) g_sentiment_weight = 0.3;
   
   // Adjust indicator weights based on market regime
   // In trending markets, give more weight to trend indicators
   // In ranging markets, give more weight to oscillators
   if(MathAbs(g_market_regime) > 0.5)
   {
      // Trending market - increase weight of trend indicators
      g_indicator_weights[0] *= (1.0 + LearningRate * 0.1);  // MA
      g_indicator_weights[1] *= (1.0 + LearningRate * 0.1);  // MACD
      g_indicator_weights[2] *= (1.0 - LearningRate * 0.1);  // RSI
      g_indicator_weights[3] *= (1.0 - LearningRate * 0.1);  // Stochastic
   }
   else
   {
      // Ranging market - increase weight of oscillators
      g_indicator_weights[0] *= (1.0 - LearningRate * 0.1);  // MA
      g_indicator_weights[1] *= (1.0 - LearningRate * 0.1);  // MACD
      g_indicator_weights[2] *= (1.0 + LearningRate * 0.1);  // RSI
      g_indicator_weights[3] *= (1.0 + LearningRate * 0.1);  // Stochastic
   }
   
   // Normalize weights to ensure they sum to 1
   double total_weight = 0;
   for(int i = 0; i < 10; i++)
   {
      if(g_indicator_weights[i] < 0.01) g_indicator_weights[i] = 0.01;
      total_weight += g_indicator_weights[i];
   }
   
   for(int i = 0; i < 10; i++)
   {
      g_indicator_weights[i] /= total_weight;
   }
}

//+------------------------------------------------------------------+
//| Analyze pair and return trading signal (-1 to 1)                 |
//+------------------------------------------------------------------+
double AnalyzePair(string symbol)
{
   double signal = 0;
   double weight_sum = 0;
   
   // 1. Moving Average signals
   double ma_signal = AnalyzeMA(symbol, AnalysisTimeframe);
   signal += ma_signal * g_indicator_weights[0];
   weight_sum += g_indicator_weights[0];
   
   // 2. MACD signals
   double macd_signal = AnalyzeMACD(symbol, AnalysisTimeframe);
   signal += macd_signal * g_indicator_weights[1];
   weight_sum += g_indicator_weights[1];
   
   // 3. RSI signals
   double rsi_signal = AnalyzeRSI(symbol, AnalysisTimeframe);
   signal += rsi_signal * g_indicator_weights[2];
   weight_sum += g_indicator_weights[2];
   
   // 4. Stochastic signals
   double stoch_signal = AnalyzeStochastic(symbol, AnalysisTimeframe);
   signal += stoch_signal * g_indicator_weights[3];
   weight_sum += g_indicator_weights[3];
   
   // 5. Bollinger Bands signals
   double bb_signal = AnalyzeBollingerBands(symbol, AnalysisTimeframe);
   signal += bb_signal * g_indicator_weights[4];
   weight_sum += g_indicator_weights[4];
   
   // 6. ADX signals
   double adx_signal = AnalyzeADX(symbol, AnalysisTimeframe);
   signal += adx_signal * g_indicator_weights[5];
   weight_sum += g_indicator_weights[5];
   
   // 7. Ichimoku signals
   double ichimoku_signal = AnalyzeIchimoku(symbol, AnalysisTimeframe);
   signal += ichimoku_signal * g_indicator_weights[6];
   weight_sum += g_indicator_weights[6];
   
   // 8. Fibonacci signals
   double fibo_signal = AnalyzeFibonacci(symbol, AnalysisTimeframe);
   signal += fibo_signal * g_indicator_weights[7];
   weight_sum += g_indicator_weights[7];
   
   // 9. Multi-timeframe analysis if enabled
   if(UseMultiTimeframe)
   {
      // Higher timeframe
      ENUM_TIMEFRAMES higher_tf = GetHigherTimeframe(AnalysisTimeframe);
      double higher_tf_signal = 0;
      
      higher_tf_signal += AnalyzeMA(symbol, higher_tf) * g_indicator_weights[0];
      higher_tf_signal += AnalyzeMACD(symbol, higher_tf) * g_indicator_weights[1];
      higher_tf_signal += AnalyzeRSI(symbol, higher_tf) * g_indicator_weights[2];
      higher_tf_signal += AnalyzeStochastic(symbol, higher_tf) * g_indicator_weights[3];
      higher_tf_signal += AnalyzeBollingerBands(symbol, higher_tf) * g_indicator_weights[4];
      higher_tf_signal /= 5;
      
      // Add higher timeframe signal with more weight
      signal += higher_tf_signal * g_indicator_weights[8] * 1.5;
      weight_sum += g_indicator_weights[8] * 1.5;
   }
   
   // 10. Pattern recognition if enabled
   if(UsePatternRecognition)
   {
      double pattern_signal = DetectCandlestickPatterns(symbol, AnalysisTimeframe);
      signal += pattern_signal * g_pattern_weight;
      weight_sum += g_pattern_weight;
   }
   
   // 11. Market sentiment if enabled
   if(UseSentimentAnalysis)
   {
      // Find index of the symbol
      int symbol_index = -1;
      for(int i = 0; i < g_total_pairs; i++)
      {
         if(g_pairs[i] == symbol)
         {
            symbol_index = i;
            break;
         }
      }
      
      if(symbol_index != -1)
      {
         double sentiment_signal = g_market_sentiment[symbol_index];
         signal += sentiment_signal * g_sentiment_weight;
         weight_sum += g_sentiment_weight;
      }
   }
   
   // 12. Volatility filter if enabled
   if(UseVolatilityFilter && g_market_volatility > 0.8)
   {
      // In high volatility, reduce signal strength
      signal *= 0.7;
   }
   
   // Normalize signal to account for actual weights used
   if(weight_sum > 0)
   {
      signal /= weight_sum;
   }
   
   // Ensure signal is within -1 to 1 range
   if(signal > 1) signal = 1;
   if(signal < -1) signal = -1;
   
   return signal;
}

//+------------------------------------------------------------------+
//| Get higher timeframe                                             |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES GetHigherTimeframe(ENUM_TIMEFRAMES timeframe)
{
   switch(timeframe)
   {
      case PERIOD_M1:  return PERIOD_M5;
      case PERIOD_M5:  return PERIOD_M15;
      case PERIOD_M15: return PERIOD_M30;
      case PERIOD_M30: return PERIOD_H1;
      case PERIOD_H1:  return PERIOD_H4;
      case PERIOD_H4:  return PERIOD_D1;
      case PERIOD_D1:  return PERIOD_W1;
      case PERIOD_W1:  return PERIOD_MN1;
      default:         return PERIOD_H4;
   }
}

//+------------------------------------------------------------------+
//| Analyze Moving Averages                                          |
//+------------------------------------------------------------------+
double AnalyzeMA(string symbol, ENUM_TIMEFRAMES timeframe)
{
   double signal = 0;
   
   // Fast and slow MAs
   double ma_fast = iMA(symbol, timeframe, 10, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ma_slow = iMA(symbol, timeframe, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
   
   // Current price
   double price = iClose(symbol, timeframe, 0);
   
   // MA crossover
   double ma_fast_prev = iMA(symbol, timeframe, 10, 0, MODE_EMA, PRICE_CLOSE, 1);
   double ma_slow_prev = iMA(symbol, timeframe, 50, 0, MODE_EMA, PRICE_CLOSE, 1);
   
   // Price relative to MAs
   if(price > ma_fast && price > ma_slow)
   {
      signal += 0.3;  // Price above both MAs - bullish
   }
   else if(price < ma_fast && price < ma_slow)
   {
      signal -= 0.3;  // Price below both MAs - bearish
   }
   
   // MA crossover
   if(ma_fast > ma_slow && ma_fast_prev <= ma_slow_prev)
   {
      signal += 0.7;  // Bullish crossover
   }
   else if(ma_fast < ma_slow && ma_fast_prev >= ma_slow_prev)
   {
      signal -= 0.7;  // Bearish crossover
   }
   
   // MA slope
   double ma_fast_slope = (ma_fast - iMA(symbol, timeframe, 10, 0, MODE_EMA, PRICE_CLOSE, 5)) / 5;
   double ma_slow_slope = (ma_slow - iMA(symbol, timeframe, 50, 0, MODE_EMA, PRICE_CLOSE, 5)) / 5;
   
   if(ma_fast_slope > 0 && ma_slow_slope > 0)
   {
      signal += 0.3;  // Both MAs rising - bullish
   }
   else if(ma_fast_slope < 0 && ma_slow_slope < 0)
   {
      signal -= 0.3;  // Both MAs falling - bearish
   }
   
   // Ensure signal is within -1 to 1 range
   if(signal > 1) signal = 1;
   if(signal < -1) signal = -1;
   
   return signal;
}

//+------------------------------------------------------------------+
//| Analyze MACD                                                     |
//+------------------------------------------------------------------+
double AnalyzeMACD(string symbol, ENUM_TIMEFRAMES timeframe)
{
   double signal = 0;
   
   // MACD values
   double macd = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double macd_signal = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
   double macd_prev = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   double macd_signal_prev = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 1);
   
   // MACD crossover
   if(macd > macd_signal && macd_prev <= macd_signal_prev)
   {
      signal += 0.7;  // Bullish crossover
   }
   else if(macd < macd_signal && macd_prev >= macd_signal_prev)
   {
      signal -= 0.7;  // Bearish crossover
   }
   
   // MACD histogram
   double histogram = macd - macd_signal;
   double histogram_prev = macd_prev - macd_signal_prev;
   
   // Histogram direction
   if(histogram > 0 && histogram > histogram_prev)
   {
      signal += 0.3;  // Increasing positive histogram - bullish
   }
   else if(histogram < 0 && histogram < histogram_prev)
   {
      signal -= 0.3;  // Increasing negative histogram - bearish
   }
   
   // Ensure signal is within -1 to 1 range
   if(signal > 1) signal = 1;
   if(signal < -1) signal = -1;
   
   return signal;
}

//+------------------------------------------------------------------+
//| Analyze RSI                                                      |
//+------------------------------------------------------------------+
double AnalyzeRSI(string symbol, ENUM_TIMEFRAMES timeframe)
{
   double signal = 0;
   
   // RSI values
   double rsi = iRSI(symbol, timeframe, 14, PRICE_CLOSE, 0);
   double rsi_prev = iRSI(symbol, timeframe, 14, PRICE_CLOSE, 1);
   
   // Overbought/oversold
   if(rsi < 30)
   {
      signal += 0.5;  // Oversold - bullish
   }
   else if(rsi > 70)
   {
      signal -= 0.5;  // Overbought - bearish
   }
   
   // RSI direction
   if(rsi > rsi_prev)
   {
      signal += 0.2;  // Rising RSI - bullish
   }
   else if(rsi < rsi_prev)
   {
      signal -= 0.2;  // Falling RSI - bearish
   }
   
   // RSI divergence (simplified)
   double price = iClose(symbol, timeframe, 0);
   double price_prev = iClose(symbol, timeframe, 5);
   
   // Bullish divergence: price making lower lows but RSI making higher lows
   if(price < price_prev && rsi > iRSI(symbol, timeframe, 14, PRICE_CLOSE, 5))
   {
      signal += 0.5;
   }
   
   // Bearish divergence: price making higher highs but RSI making lower highs
   if(price > price_prev && rsi < iRSI(symbol, timeframe, 14, PRICE_CLOSE, 5))
   {
      signal -= 0.5;
   }
   
   // Ensure signal is within -1 to 1 range
   if(signal > 1) signal = 1;
   if(signal < -1) signal = -1;
   
   return signal;
}

//+------------------------------------------------------------------+
//| Analyze Stochastic                                               |
//+------------------------------------------------------------------+
double AnalyzeStochastic(string symbol, ENUM_TIMEFRAMES timeframe)
{
   double signal = 0;
   
   // Stochastic values
   double stoch_k = iStochastic(symbol, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   double stoch_d = iStochastic(symbol, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 0);
   double stoch_k_prev = iStochastic(symbol, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double stoch_d_prev = iStochastic(symbol, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1);
   
   // Overbought/oversold
   if(stoch_k < 20 && stoch_d < 20)
   {
      signal += 0.4;  // Oversold - bullish
   }
   else if(stoch_k > 80 && stoch_d > 80)
   {
      signal -= 0.4;  // Overbought - bearish
   }
   
   // Stochastic crossover
   if(stoch_k > stoch_d && stoch_k_prev <= stoch_d_prev)
   {
      signal += 0.6;  // Bullish crossover
   }
   else if(stoch_k < stoch_d && stoch_k_prev >= stoch_d_prev)
   {
      signal -= 0.6;  // Bearish crossover
   }
   
   // Ensure signal is within -1 to 1 range
   if(signal > 1) signal = 1;
   if(signal < -1) signal = -1;
   
   return signal;
}

//+------------------------------------------------------------------+
//| Analyze Bollinger Bands                                          |
//+------------------------------------------------------------------+
double AnalyzeBollingerBands(string symbol, ENUM_TIMEFRAMES timeframe)
{
   double signal = 0;
   
   // Bollinger Bands values
   double bb_upper = iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double bb_middle = iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, 0);
   double bb_lower = iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);
   
   // Current price
   double price = iClose(symbol, timeframe, 0);
   double price_prev = iClose(symbol, timeframe, 1);
   
   // Price relative to bands
   if(price < bb_lower)
   {
      signal += 0.5;  // Price below lower band - potential buy
   }
   else if(price > bb_upper)
   {
      signal -= 0.5;  // Price above upper band - potential sell
   }
   
   // Band squeeze (volatility contraction)
   double band_width = (bb_upper - bb_lower) / bb_middle;
   double band_width_prev = (iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 10) - 
                            iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 10)) / 
                            iBands(symbol, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, 10);
   
   // Breakout from squeeze
   if(band_width < band_width_prev * 0.8 && price > price_prev)
   {
      signal += 0.3;  // Potential upside breakout
   }
   else if(band_width < band_width_prev * 0.8 && price < price_prev)
   {
      signal -= 0.3;  // Potential downside breakout
   }
   
   // Ensure signal is within -1 to 1 range
   if(signal > 1) signal = 1;
   if(signal < -1) signal = -1;
   
   return signal;
}

//+------------------------------------------------------------------+
//| Analyze ADX                                                      |
//+------------------------------------------------------------------+
double AnalyzeADX(string symbol, ENUM_TIMEFRAMES timeframe)
{
   double signal = 0;
   
   // ADX values
   double adx = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_MAIN, 0);
   double di_plus = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_PLUSDI, 0);
   double di_minus = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_MINUSDI, 0);
   
   // Trend strength
   if(adx > 25)
   {
      // Strong trend
      if(di_plus > di_minus)
      {
         signal += 0.5;  // Strong uptrend
      }
      else
      {
         signal -= 0.5;  // Strong downtrend
      }
   }
   
   // DI crossover
   double di_plus_prev = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_PLUSDI, 1);
   double di_minus_prev = iADX(symbol, timeframe, 14, PRICE_CLOSE, MODE_MINUSDI, 1);
   
   if(di_plus > di_minus && di_plus_prev <= di_minus_prev)
   {
      signal += 0.5;  // Bullish crossover
      }
      else if(di_plus < di_minus && di_plus_prev >= di_minus_prev)
      {
         signal -= 0.5;  // Bearish crossover
      }
      
      // Ensure signal is within -1 to 1 range
      if(signal > 1) signal = 1;
      if(signal < -1) signal = -1;
      
      return signal;
}
   
//+------------------------------------------------------------------+
//| Analyze Ichimoku                                                 |
//+------------------------------------------------------------------+
double AnalyzeIchimoku(string symbol, ENUM_TIMEFRAMES timeframe)
{
      double signal = 0;
      
      // Ichimoku values
      double tenkan = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_TENKANSEN, 0);
      double kijun = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_KIJUNSEN, 0);
      double senkou_a = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_SENKOUSPANA, 0);
      double senkou_b = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_SENKOUSPANB, 0);
      double chikou = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_CHIKOUSPAN, 0);
      
      // Current price
      double price = iClose(symbol, timeframe, 0);
      
      // Tenkan/Kijun cross
      double tenkan_prev = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_TENKANSEN, 1);
      double kijun_prev = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_KIJUNSEN, 1);
      
      if(tenkan > kijun && tenkan_prev <= kijun_prev)
      {
         signal += 0.5;  // Bullish TK cross
      }
      else if(tenkan < kijun && tenkan_prev >= kijun_prev)
      {
         signal -= 0.5;  // Bearish TK cross
      }
      
      // Price relative to cloud
      if(price > senkou_a && price > senkou_b)
      {
         signal += 0.3;  // Price above cloud - bullish
      }
      else if(price < senkou_a && price < senkou_b)
      {
         signal -= 0.3;  // Price below cloud - bearish
      }
      
      // Cloud twist
      double future_senkou_a = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_SENKOUSPANA, -26);
      double future_senkou_b = iIchimoku(symbol, timeframe, 9, 26, 52, MODE_SENKOUSPANB, -26);
      
      if(senkou_a < senkou_b && future_senkou_a > future_senkou_b)
      {
         signal += 0.2;  // Bullish cloud twist ahead
      }
      else if(senkou_a > senkou_b && future_senkou_a < future_senkou_b)
      {
         signal -= 0.2;  // Bearish cloud twist ahead
      }
      
      // Ensure signal is within -1 to 1 range
      if(signal > 1) signal = 1;
      if(signal < -1) signal = -1;
      
      return signal;
}
   
   //+------------------------------------------------------------------+
   //| Analyze Fibonacci levels                                         |
   //+------------------------------------------------------------------+
   double AnalyzeFibonacci(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      double signal = 0;
      
      // Find recent swing high and low
      double swing_high = 0;
      double swing_low = 999999;
      int high_bar = 0;
      int low_bar = 0;
      
      for(int i = 1; i < 100; i++)
      {
         double high = iHigh(symbol, timeframe, i);
         double low = iLow(symbol, timeframe, i);
         
         if(high > swing_high)
         {
            swing_high = high;
            high_bar = i;
         }
         
         if(low < swing_low)
         {
            swing_low = low;
            low_bar = i;
         }
      }
      
      // Current price
      double price = iClose(symbol, timeframe, 0);
      
      // Calculate Fibonacci levels
      double fib_range = swing_high - swing_low;
      double fib_38 = 0, fib_50 = 0, fib_62 = 0;
      
      // Determine if we're in an uptrend or downtrend
      bool uptrend = high_bar > low_bar;
      
      if(uptrend)
      {
         // Retracement levels for uptrend
         fib_38 = swing_high - fib_range * 0.382;
         fib_50 = swing_high - fib_range * 0.5;
         fib_62 = swing_high - fib_range * 0.618;
         
         // Check if price is near a Fibonacci level
         if(MathAbs(price - fib_38) < fib_range * 0.02)
         {
            signal += 0.3;  // Price at 38.2% retracement - potential buy
         }
         else if(MathAbs(price - fib_50) < fib_range * 0.02)
         {
            signal += 0.2;  // Price at 50% retracement - potential buy
         }
         else if(MathAbs(price - fib_62) < fib_range * 0.02)
         {
            signal += 0.4;  // Price at 61.8% retracement - potential buy
         }
      }
      else
      {
         // Retracement levels for downtrend
         fib_38 = swing_low + fib_range * 0.382;
         fib_50 = swing_low + fib_range * 0.5;
         fib_62 = swing_low + fib_range * 0.618;
         
         // Check if price is near a Fibonacci level
         if(MathAbs(price - fib_38) < fib_range * 0.02)
         {
            signal -= 0.3;  // Price at 38.2% retracement - potential sell
         }
         else if(MathAbs(price - fib_50) < fib_range * 0.02)
         {
            signal -= 0.2;  // Price at 50% retracement - potential sell
         }
         else if(MathAbs(price - fib_62) < fib_range * 0.02)
         {
            signal -= 0.4;  // Price at 61.8% retracement - potential sell
         }
      }
      
      // Ensure signal is within -1 to 1 range
      if(signal > 1) signal = 1;
      if(signal < -1) signal = -1;
      
      return signal;
   }
   
   //+------------------------------------------------------------------+
   //| Calculate lot size based on risk management                      |
   //+------------------------------------------------------------------+
   double CalculateLotSize(string symbol, int stop_loss_pips)
   {
      // Account risk calculation
      double risk_amount = AccountBalance() * (RiskPercent / 100.0) * g_account_growth_factor;
      
      // Convert stop loss to points
      double stop_loss_points = stop_loss_pips * 10;
      
      // Get tick value and size
      double tick_value = MarketInfo(symbol, MODE_TICKVALUE);
      double tick_size = MarketInfo(symbol, MODE_TICKSIZE);
      
      // Calculate lot size
      double lot_size = risk_amount / (stop_loss_points * tick_value / tick_size);
      
      // Round to nearest 0.01 (or minimum lot step)
      double lot_step = MarketInfo(symbol, MODE_LOTSTEP);
      lot_size = NormalizeDouble(lot_size, 2);
      lot_size = MathFloor(lot_size / lot_step) * lot_step;
      
      // Ensure lot size is within allowed range
      double min_lot = MarketInfo(symbol, MODE_MINLOT);
      double max_lot = MarketInfo(symbol, MODE_MAXLOT);
      
      if(lot_size < min_lot) lot_size = min_lot;
      if(lot_size > max_lot) lot_size = max_lot;
      
      // Adjust lot size based on market volatility if adaptive learning is enabled
      if(UseAdaptiveLearning && g_market_volatility > 0.7)
      {
         // Reduce position size in high volatility
         lot_size *= 0.7;
         lot_size = NormalizeDouble(lot_size, 2);
         lot_size = MathFloor(lot_size / lot_step) * lot_step;
         if(lot_size < min_lot) lot_size = min_lot;
      }
      
      return lot_size;
   }
   
   //+------------------------------------------------------------------+
   //| Open a buy order                                                 |
   //+------------------------------------------------------------------+
   void OpenBuyOrder(string symbol)
   {
      double price = MarketInfo(symbol, MODE_ASK);
      
      // Adaptive stop loss based on ATR if enabled
      int stop_loss_pips = StopLoss;
      if(UseAdaptiveLearning)
      {
      double atr = iATR(symbol, AnalysisTimeframe, 14, 0);
      double point = MarketInfo(symbol, MODE_POINT);
      stop_loss_pips = (int)MathRound(atr / (point * 10) * 1.5);  // Add (int) cast here
   
      // Ensure stop loss is within reasonable range
      if(stop_loss_pips < StopLoss / 2) stop_loss_pips = StopLoss / 2;
      if(stop_loss_pips > StopLoss * 2) stop_loss_pips = StopLoss * 2;
      }
      
      double sl = price - stop_loss_pips * MarketInfo(symbol, MODE_POINT) * 10;
      double tp = price + TakeProfit * MarketInfo(symbol, MODE_POINT) * 10;
      
      // Calculate lot size based on risk
      double lot_size = CalculateLotSize(symbol, stop_loss_pips);
      
      // Store prediction for this trade for later learning
      double trade_prediction = g_prediction;
      
      int ticket = OrderSend(symbol, OP_BUY, lot_size, price, Slippage, sl, tp, 
                            "AI Trading Bot", g_magic_number, 0, Green);
      
      if(ticket > 0)
      {
         Print("Buy order opened successfully for ", symbol, ". Ticket: ", ticket, 
               " Prediction: ", DoubleToString(trade_prediction, 2),
               " SL: ", stop_loss_pips, " pips, Lot size: ", DoubleToString(lot_size, 2));
         
         // Update daily risk used
         g_daily_risk_used += RiskPercent;
         
         // Store prediction for learning
         if(UseAdaptiveLearning && g_trade_history_count < LearningPeriod)
         {
            g_trade_history_ticket[g_trade_history_count] = ticket;
            g_trade_history_prediction[g_trade_history_count] = trade_prediction;
            g_trade_history_profit[g_trade_history_count] = 0; // Will be updated when trade closes
            g_trade_history_count++;
         }
      }
      else
      {
         Print("Error opening buy order for ", symbol, ". Error: ", GetLastError());
      }
   }
   
   //+------------------------------------------------------------------+
   //| Open a sell order                                                |
   //+------------------------------------------------------------------+
   void OpenSellOrder(string symbol)
   {
      double price = MarketInfo(symbol, MODE_BID);
      
      // Adaptive stop loss based on ATR if enabled
      int stop_loss_pips = StopLoss;
      if(UseAdaptiveLearning)
      {
      double atr = iATR(symbol, AnalysisTimeframe, 14, 0);
      double point = MarketInfo(symbol, MODE_POINT);
      stop_loss_pips = (int)MathRound(atr / (point * 10) * 1.5);  // Add (int) cast here
   
      // Ensure stop loss is within reasonable range
      if(stop_loss_pips < StopLoss / 2) stop_loss_pips = StopLoss / 2;
      if(stop_loss_pips > StopLoss * 2) stop_loss_pips = StopLoss * 2;
      }
      
      double sl = price + stop_loss_pips * MarketInfo(symbol, MODE_POINT) * 10;
      double tp = price - TakeProfit * MarketInfo(symbol, MODE_POINT) * 10;
      
      // Calculate lot size based on risk
      double lot_size = CalculateLotSize(symbol, stop_loss_pips);
      
      // Store prediction for this trade for later learning
      double trade_prediction = g_prediction;
      
      int ticket = OrderSend(symbol, OP_SELL, lot_size, price, Slippage, sl, tp, 
                            "AI Trading Bot", g_magic_number, 0, Red);
      
      if(ticket > 0)
      {
         Print("Sell order opened successfully for ", symbol, ". Ticket: ", ticket, 
               " Prediction: ", DoubleToString(trade_prediction, 2),
               " SL: ", stop_loss_pips, " pips, Lot size: ", DoubleToString(lot_size, 2));
         
         // Update daily risk used
         g_daily_risk_used += RiskPercent;
         
         // Store prediction for learning
         if(UseAdaptiveLearning && g_trade_history_count < LearningPeriod)
         {
            g_trade_history_ticket[g_trade_history_count] = ticket;
            g_trade_history_prediction[g_trade_history_count] = trade_prediction;
            g_trade_history_profit[g_trade_history_count] = 0; // Will be updated when trade closes
            g_trade_history_count++;
         }
      }
      else
      {
         Print("Error opening sell order for ", symbol, ". Error: ", GetLastError());
      }
   }
   
   //+------------------------------------------------------------------+
   //| Manage open positions (trailing stop, etc.)                      |
   //+------------------------------------------------------------------+
   void ManageOpenPositions(string symbol)
   {
      if(!UseTrailingStop) return;
      
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == symbol && OrderMagicNumber() == g_magic_number)
            {
               // Apply trailing stop
               if(OrderType() == OP_BUY)
               {
                  double bid = MarketInfo(OrderSymbol(), MODE_BID);
                  if(bid - OrderOpenPrice() > TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT) * 10)
                  {
                     double new_sl = bid - TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT) * 10;
                     if(new_sl > OrderStopLoss() + TrailingStep * MarketInfo(OrderSymbol(), MODE_POINT) * 10 || OrderStopLoss() == 0)
                     {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, Green);
                        if(!result) Print("Error modifying buy order: ", GetLastError());
                     }
                  }
               }
               else if(OrderType() == OP_SELL)
               {
                  double ask = MarketInfo(OrderSymbol(), MODE_ASK);
                  if(OrderOpenPrice() - ask > TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT) * 10)
                  {
                     double new_sl = ask + TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT) * 10;
                     if(new_sl < OrderStopLoss() - TrailingStep * MarketInfo(OrderSymbol(), MODE_POINT) * 10 || OrderStopLoss() == 0)
                     {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, Red);
                        if(!result) Print("Error modifying sell order: ", GetLastError());
                     }
                  }
               }
               
               // Adaptive take profit management
               if(UseAdaptiveLearning)
               {
                  double current_atr = iATR(symbol, AnalysisTimeframe, 14, 0);
                  double order_open_bar = (int)iBarShift(symbol, AnalysisTimeframe, OrderOpenTime());  // Add (int) cast here
                  double open_time_atr = iATR(symbol, AnalysisTimeframe, 14, order_open_bar);
                  
                  if(current_atr > open_time_atr * 1.5 && OrderProfit() > 0)
                  {
                     // Market volatility has increased, move take profit closer
                     if(OrderType() == OP_BUY)
                     {
                        double new_tp = OrderOpenPrice() + (OrderTakeProfit() - OrderOpenPrice()) * 0.7;
                        if(new_tp < OrderTakeProfit())
                        {
                           bool result = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), new_tp, 0, Green);
                           if(result) Print("Adjusted take profit due to increased volatility");
                        }
                     }
                     else if(OrderType() == OP_SELL)
                     {
                        double new_tp = OrderOpenPrice() - (OrderOpenPrice() - OrderTakeProfit()) * 0.7;
                        if(new_tp > OrderTakeProfit())
                        {
                           bool result = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), new_tp, 0, Red);
                           if(result) Print("Adjusted take profit due to increased volatility");
                        }
                     }
                  }
               }
            }
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Expert deinitialization function                                 |
   //+------------------------------------------------------------------+
   void OnDeinit(const int reason)
   {
      // Save model weights if adaptive learning is enabled
      if(UseAdaptiveLearning)
      {
         SaveModelWeights();
      }
      
      Print("Advanced Adaptive AI Trading Bot stopped");
   }