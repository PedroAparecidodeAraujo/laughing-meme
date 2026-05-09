//+------------------------------------------------------------------+
//|                                              SniperScalperEA.mq5 |
//|                        Sniper Scalper Ultra - Expert Advisor      |
//|                        Sistema de Confluencia com 24 Indicadores  |
//+------------------------------------------------------------------+
#property copyright   "Sniper Scalper Ultra EA"
#property link        "https://github.com/PedroAparecidodeAraujo"
#property version     "1.00"
#property description "EA Scalper Sniper com 24 indicadores, trailing stop agressivo, stop curto e take profit longo."
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+
enum ENUM_TRAILING_MODE
  {
   TRAIL_IMMEDIATE = 0,   // Imediato (a cada tick de lucro)
   TRAIL_STEP      = 1,   // Por degraus (step fixo)
   TRAIL_ATR       = 2,   // Baseado no ATR
   TRAIL_PARABOLIC = 3    // Baseado no Parabolic SAR
  };

enum ENUM_SIGNAL_MODE
  {
   MODE_CONFLUENCE  = 0,  // Confluencia (score minimo)
   MODE_ALL_AGREE   = 1   // Todos indicadores concordam
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - GENERAL                                       |
//+------------------------------------------------------------------+
input group "=== CONFIGURACOES GERAIS ==="
input double   InpLotSize           = 0.01;      // Tamanho do Lote
input bool     InpUseDynamicLot     = false;      // Usar Lote Dinamico
input double   InpRiskPercent       = 1.0;        // Risco % do Saldo (Lote Dinamico)
input int      InpMagicNumber       = 777777;     // Numero Magico
input int      InpMaxSpread         = 30;         // Spread Maximo (pontos)
input int      InpMaxOpenPositions  = 1;          // Maximo de Posicoes Abertas
input ENUM_SIGNAL_MODE InpSignalMode = MODE_CONFLUENCE; // Modo de Sinal
input int      InpMinScore          = 12;         // Score Minimo para Entrada (Confluencia)
input ENUM_TIMEFRAMES InpTimeframe  = PERIOD_M5;  // Timeframe Principal

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - STOP LOSS / TAKE PROFIT                       |
//+------------------------------------------------------------------+
input group "=== STOP LOSS / TAKE PROFIT ==="
input int      InpStopLoss          = 150;        // Stop Loss (pontos) - CURTO
input int      InpTakeProfit        = 600;        // Take Profit (pontos) - LONGO
input bool     InpUseATRStopLoss    = false;      // Usar ATR para Stop Loss
input double   InpATRMultiplierSL   = 1.5;        // Multiplicador ATR para SL
input bool     InpUseATRTakeProfit  = false;      // Usar ATR para Take Profit
input double   InpATRMultiplierTP   = 4.0;        // Multiplicador ATR para TP

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - TRAILING STOP                                 |
//+------------------------------------------------------------------+
input group "=== TRAILING STOP ==="
input bool     InpUseTrailingStop   = true;       // Ativar Trailing Stop
input ENUM_TRAILING_MODE InpTrailingMode = TRAIL_IMMEDIATE; // Modo do Trailing Stop
input int      InpTrailingStart     = 10;         // Inicio do Trailing (pontos de lucro)
input int      InpTrailingStep      = 10;         // Passo do Trailing (pontos)
input int      InpTrailingDistance  = 100;        // Distancia do Trailing (pontos)
input double   InpTrailingATRMult   = 1.0;        // Multiplicador ATR (modo ATR)

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - BREAK EVEN                                    |
//+------------------------------------------------------------------+
input group "=== BREAK EVEN ==="
input bool     InpUseBreakEven      = true;       // Ativar Break Even
input int      InpBreakEvenStart    = 50;         // Ativacao Break Even (pontos de lucro)
input int      InpBreakEvenProfit   = 10;         // Lucro Garantido no BE (pontos)

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - STOP DE GANHO (PROFIT STOP)                   |
//+------------------------------------------------------------------+
input group "=== STOP DE GANHO ==="
input bool     InpUseProfitStop     = false;      // Ativar Stop de Ganho Diario
input double   InpDailyProfitStop   = 100.0;      // Lucro Diario Maximo (moeda)
input bool     InpUseLossStop       = false;       // Ativar Stop de Perda Diario
input double   InpDailyLossStop     = 50.0;       // Perda Diaria Maxima (moeda)

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - EMA (3 periodos)                              |
//+------------------------------------------------------------------+
input group "=== 1-3. EMA (Rapida/Media/Lenta) ==="
input bool     InpUseEMA            = true;       // Usar EMAs
input int      InpEMAFastPeriod     = 8;          // EMA Rapida - Periodo
input int      InpEMAMediumPeriod   = 21;         // EMA Media - Periodo
input int      InpEMASlowPeriod     = 50;         // EMA Lenta - Periodo
input ENUM_APPLIED_PRICE InpEMAPrice = PRICE_CLOSE; // EMA - Preco Aplicado

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - SMA                                           |
//+------------------------------------------------------------------+
input group "=== 4. SMA ==="
input bool     InpUseSMA            = true;       // Usar SMA
input int      InpSMAPeriod         = 200;        // SMA - Periodo
input ENUM_APPLIED_PRICE InpSMAPrice = PRICE_CLOSE; // SMA - Preco Aplicado

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - RSI                                           |
//+------------------------------------------------------------------+
input group "=== 5. RSI ==="
input bool     InpUseRSI            = true;       // Usar RSI
input int      InpRSIPeriod         = 14;         // RSI - Periodo
input double   InpRSIOverbought     = 70.0;       // RSI - Sobrecomprado
input double   InpRSIOversold       = 30.0;       // RSI - Sobrevendido
input ENUM_APPLIED_PRICE InpRSIPrice = PRICE_CLOSE; // RSI - Preco Aplicado

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - MACD                                          |
//+------------------------------------------------------------------+
input group "=== 6. MACD ==="
input bool     InpUseMACD           = true;       // Usar MACD
input int      InpMACDFast          = 12;         // MACD - EMA Rapida
input int      InpMACDSlow          = 26;         // MACD - EMA Lenta
input int      InpMACDSignal        = 9;          // MACD - Linha de Sinal
input ENUM_APPLIED_PRICE InpMACDPrice = PRICE_CLOSE; // MACD - Preco Aplicado

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - BOLLINGER BANDS                               |
//+------------------------------------------------------------------+
input group "=== 7. Bollinger Bands ==="
input bool     InpUseBB             = true;       // Usar Bollinger Bands
input int      InpBBPeriod          = 20;         // BB - Periodo
input double   InpBBDeviation       = 2.0;        // BB - Desvio Padrao
input ENUM_APPLIED_PRICE InpBBPrice  = PRICE_CLOSE; // BB - Preco Aplicado

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - STOCHASTIC                                    |
//+------------------------------------------------------------------+
input group "=== 8. Stochastic ==="
input bool     InpUseStochastic     = true;       // Usar Stochastic
input int      InpStochKPeriod      = 14;         // Stochastic - %K Periodo
input int      InpStochDPeriod      = 3;          // Stochastic - %D Periodo
input int      InpStochSlowing      = 3;          // Stochastic - Slowing
input double   InpStochOverbought   = 80.0;       // Stochastic - Sobrecomprado
input double   InpStochOversold     = 20.0;       // Stochastic - Sobrevendido

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - ATR                                           |
//+------------------------------------------------------------------+
input group "=== 9. ATR ==="
input bool     InpUseATR            = true;       // Usar ATR (filtro de volatilidade)
input int      InpATRPeriod         = 14;         // ATR - Periodo
input double   InpATRMinValue       = 0.0005;     // ATR - Valor Minimo (filtro)
input double   InpATRMaxValue       = 0.0100;     // ATR - Valor Maximo (filtro)

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - ADX                                           |
//+------------------------------------------------------------------+
input group "=== 10. ADX ==="
input bool     InpUseADX            = true;       // Usar ADX
input int      InpADXPeriod         = 14;         // ADX - Periodo
input double   InpADXMinLevel       = 20.0;       // ADX - Nivel Minimo (forca da tendencia)

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - CCI                                           |
//+------------------------------------------------------------------+
input group "=== 11. CCI ==="
input bool     InpUseCCI            = true;       // Usar CCI
input int      InpCCIPeriod         = 14;         // CCI - Periodo
input double   InpCCIOverbought     = 100.0;      // CCI - Sobrecomprado
input double   InpCCIOversold       = -100.0;     // CCI - Sobrevendido
input ENUM_APPLIED_PRICE InpCCIPrice = PRICE_TYPICAL; // CCI - Preco Aplicado

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - WILLIAMS %R                                   |
//+------------------------------------------------------------------+
input group "=== 12. Williams %R ==="
input bool     InpUseWPR            = true;       // Usar Williams %R
input int      InpWPRPeriod         = 14;         // WPR - Periodo
input double   InpWPROverbought     = -20.0;      // WPR - Sobrecomprado
input double   InpWPROversold       = -80.0;      // WPR - Sobrevendido

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - PARABOLIC SAR                                 |
//+------------------------------------------------------------------+
input group "=== 13. Parabolic SAR ==="
input bool     InpUseSAR            = true;       // Usar Parabolic SAR
input double   InpSARStep           = 0.02;       // SAR - Step
input double   InpSARMaximum        = 0.2;        // SAR - Maximum

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - ICHIMOKU                                      |
//+------------------------------------------------------------------+
input group "=== 14. Ichimoku Cloud ==="
input bool     InpUseIchimoku       = true;       // Usar Ichimoku
input int      InpIchiTenkan        = 9;          // Ichimoku - Tenkan-sen
input int      InpIchiKijun         = 26;         // Ichimoku - Kijun-sen
input int      InpIchiSenkou        = 52;         // Ichimoku - Senkou Span B

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - MFI                                           |
//+------------------------------------------------------------------+
input group "=== 15. MFI (Money Flow Index) ==="
input bool     InpUseMFI            = true;       // Usar MFI
input int      InpMFIPeriod         = 14;         // MFI - Periodo
input double   InpMFIOverbought     = 80.0;       // MFI - Sobrecomprado
input double   InpMFIOversold       = 20.0;       // MFI - Sobrevendido

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - MOMENTUM                                      |
//+------------------------------------------------------------------+
input group "=== 16. Momentum ==="
input bool     InpUseMomentum       = true;       // Usar Momentum
input int      InpMomentumPeriod    = 14;         // Momentum - Periodo
input ENUM_APPLIED_PRICE InpMomPrice = PRICE_CLOSE; // Momentum - Preco Aplicado

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - DEMARKER                                      |
//+------------------------------------------------------------------+
input group "=== 17. DeMarker ==="
input bool     InpUseDeMarker       = true;       // Usar DeMarker
input int      InpDeMarkerPeriod    = 14;         // DeMarker - Periodo
input double   InpDeMarkerOB        = 0.7;        // DeMarker - Sobrecomprado
input double   InpDeMarkerOS        = 0.3;        // DeMarker - Sobrevendido

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - FORCE INDEX                                   |
//+------------------------------------------------------------------+
input group "=== 18. Force Index ==="
input bool     InpUseForce          = true;       // Usar Force Index
input int      InpForcePeriod       = 13;         // Force Index - Periodo
input ENUM_MA_METHOD InpForceMethod  = MODE_SMA;  // Force Index - Metodo MA
input ENUM_APPLIED_VOLUME InpForceVolume = VOLUME_TICK; // Force Index - Volume

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - ENVELOPES                                     |
//+------------------------------------------------------------------+
input group "=== 19. Envelopes ==="
input bool     InpUseEnvelopes      = true;       // Usar Envelopes
input int      InpEnvPeriod         = 20;         // Envelopes - Periodo
input double   InpEnvDeviation      = 0.10;       // Envelopes - Desvio (%)
input ENUM_MA_METHOD InpEnvMethod    = MODE_SMA;  // Envelopes - Metodo MA
input ENUM_APPLIED_PRICE InpEnvPrice = PRICE_CLOSE; // Envelopes - Preco Aplicado

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - AWESOME OSCILLATOR                            |
//+------------------------------------------------------------------+
input group "=== 20. Awesome Oscillator ==="
input bool     InpUseAO             = true;       // Usar Awesome Oscillator

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - OBV                                           |
//+------------------------------------------------------------------+
input group "=== 21. OBV (On Balance Volume) ==="
input bool     InpUseOBV            = true;       // Usar OBV
input ENUM_APPLIED_VOLUME InpOBVVolume = VOLUME_TICK; // OBV - Volume

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - VOLUMES                                       |
//+------------------------------------------------------------------+
input group "=== 22. Volumes ==="
input bool     InpUseVolumes        = true;       // Usar Volumes
input ENUM_APPLIED_VOLUME InpVolType = VOLUME_TICK; // Volume - Tipo

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - FRACTALS                                      |
//+------------------------------------------------------------------+
input group "=== 23. Fractals ==="
input bool     InpUseFractals       = true;       // Usar Fractals

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - DONCHIAN CHANNELS                             |
//+------------------------------------------------------------------+
input group "=== 24. Canais de Donchian ==="
input bool     InpUseDonchian       = true;       // Usar Canais de Donchian
input int      InpDonchianPeriod    = 20;         // Donchian - Periodo

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - HORARIO DE OPERACAO                           |
//+------------------------------------------------------------------+
input group "=== HORARIO DE OPERACAO ==="
input bool     InpUseTimeFilter     = false;      // Usar Filtro de Horario
input int      InpStartHour         = 3;          // Hora Inicio (servidor)
input int      InpEndHour           = 20;         // Hora Fim (servidor)

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - PAINEL VISUAL                                 |
//+------------------------------------------------------------------+
input group "=== PAINEL VISUAL ==="
input bool     InpShowPanel         = true;       // Mostrar Painel no Grafico
input int      InpPanelX            = 10;         // Painel - Posicao X
input int      InpPanelY            = 30;         // Painel - Posicao Y
input color    InpPanelBuyColor     = clrLime;    // Cor Sinal Compra
input color    InpPanelSellColor    = clrRed;     // Cor Sinal Venda
input color    InpPanelNeutralColor = clrGray;    // Cor Sinal Neutro

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;

// Indicator handles
int hEMAFast, hEMAMedium, hEMASlow;
int hSMA;
int hRSI;
int hMACD;
int hBB;
int hStochastic;
int hATR;
int hADX;
int hCCI;
int hWPR;
int hSAR;
int hIchimoku;
int hMFI;
int hMomentum;
int hDeMarker;
int hForce;
int hEnvelopes;
int hAO;
int hOBV;
int hVolumes;
int hFractals;
int hDonchianHigh, hDonchianLow;

// Tracking
datetime lastBarTime = 0;
double   dailyProfit = 0;
datetime lastDayChecked = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   symInfo.Name(_Symbol);
   symInfo.Refresh();

   // Initialize indicator handles
   if(!CreateIndicatorHandles())
     {
      Print("ERRO: Falha ao criar handles dos indicadores!");
      return(INIT_FAILED);
     }

   Print("=== Sniper Scalper Ultra EA Inicializado ===");
   Print("Simbolo: ", _Symbol, " | Timeframe: ", EnumToString(InpTimeframe));
   Print("Stop Loss: ", InpStopLoss, " pts | Take Profit: ", InpTakeProfit, " pts");
   Print("Ratio R:R = 1:", DoubleToString((double)InpTakeProfit / InpStopLoss, 1));
   Print("Trailing Stop: ", InpUseTrailingStop ? "ATIVO" : "INATIVO");
   Print("Score Minimo: ", InpMinScore);

   if(InpShowPanel)
      CreatePanel();

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Release indicator handles
   ReleaseHandles();

   if(InpShowPanel)
      DeletePanel();

   Print("=== Sniper Scalper Ultra EA Removido ===");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   symInfo.Refresh();

   // Check daily profit/loss stops
   if(InpUseProfitStop || InpUseLossStop)
     {
      UpdateDailyProfitLoss();
      if(InpUseProfitStop && dailyProfit >= InpDailyProfitStop)
        {
         if(InpShowPanel)
            UpdatePanelStatus("STOP GANHO DIARIO ATINGIDO");
         return;
        }
      if(InpUseLossStop && dailyProfit <= -InpDailyLossStop)
        {
         if(InpShowPanel)
            UpdatePanelStatus("STOP PERDA DIARIA ATINGIDO");
         return;
        }
     }

   // Manage existing positions (trailing stop, break even)
   ManageOpenPositions();

   // Check for new bar
   datetime currentBarTime = iTime(_Symbol, InpTimeframe, 0);
   if(currentBarTime == lastBarTime)
      return;
   lastBarTime = currentBarTime;

   // Time filter
   if(InpUseTimeFilter && !IsWithinTradingHours())
      return;

   // Spread filter
   if(symInfo.Spread() > InpMaxSpread)
      return;

   // Count open positions
   if(CountPositions() >= InpMaxOpenPositions)
      return;

   // Calculate signals from all 22 indicators
   int buyScore = 0, sellScore = 0;
   int totalActive = 0;

   CalculateAllSignals(buyScore, sellScore, totalActive);

   // Update panel
   if(InpShowPanel)
      UpdatePanel(buyScore, sellScore, totalActive);

   // Execute trades based on signal mode
   bool buySignal = false, sellSignal = false;

   if(InpSignalMode == MODE_CONFLUENCE)
     {
      buySignal  = (buyScore >= InpMinScore);
      sellSignal = (sellScore >= InpMinScore);
     }
   else // MODE_ALL_AGREE
     {
      buySignal  = (buyScore == totalActive && totalActive > 0);
      sellSignal = (sellScore == totalActive && totalActive > 0);
     }

   // Execute orders
   if(buySignal && !sellSignal)
      OpenBuy();
   else if(sellSignal && !buySignal)
      OpenSell();
  }

//+------------------------------------------------------------------+
//| Create all indicator handles                                     |
//+------------------------------------------------------------------+
bool CreateIndicatorHandles()
  {
   bool success = true;

   // 1-3. EMAs
   if(InpUseEMA)
     {
      hEMAFast   = iMA(_Symbol, InpTimeframe, InpEMAFastPeriod, 0, MODE_EMA, InpEMAPrice);
      hEMAMedium = iMA(_Symbol, InpTimeframe, InpEMAMediumPeriod, 0, MODE_EMA, InpEMAPrice);
      hEMASlow   = iMA(_Symbol, InpTimeframe, InpEMASlowPeriod, 0, MODE_EMA, InpEMAPrice);
      if(hEMAFast == INVALID_HANDLE || hEMAMedium == INVALID_HANDLE || hEMASlow == INVALID_HANDLE)
        { Print("Erro: EMA handles"); success = false; }
     }

   // 4. SMA
   if(InpUseSMA)
     {
      hSMA = iMA(_Symbol, InpTimeframe, InpSMAPeriod, 0, MODE_SMA, InpSMAPrice);
      if(hSMA == INVALID_HANDLE)
        { Print("Erro: SMA handle"); success = false; }
     }

   // 5. RSI
   if(InpUseRSI)
     {
      hRSI = iRSI(_Symbol, InpTimeframe, InpRSIPeriod, InpRSIPrice);
      if(hRSI == INVALID_HANDLE)
        { Print("Erro: RSI handle"); success = false; }
     }

   // 6. MACD
   if(InpUseMACD)
     {
      hMACD = iMACD(_Symbol, InpTimeframe, InpMACDFast, InpMACDSlow, InpMACDSignal, InpMACDPrice);
      if(hMACD == INVALID_HANDLE)
        { Print("Erro: MACD handle"); success = false; }
     }

   // 7. Bollinger Bands
   if(InpUseBB)
     {
      hBB = iBands(_Symbol, InpTimeframe, InpBBPeriod, 0, InpBBDeviation, InpBBPrice);
      if(hBB == INVALID_HANDLE)
        { Print("Erro: BB handle"); success = false; }
     }

   // 8. Stochastic
   if(InpUseStochastic)
     {
      hStochastic = iStochastic(_Symbol, InpTimeframe, InpStochKPeriod, InpStochDPeriod, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
      if(hStochastic == INVALID_HANDLE)
        { Print("Erro: Stochastic handle"); success = false; }
     }

   // 9. ATR
   if(InpUseATR || InpUseATRStopLoss || InpUseATRTakeProfit || InpTrailingMode == TRAIL_ATR)
     {
      hATR = iATR(_Symbol, InpTimeframe, InpATRPeriod);
      if(hATR == INVALID_HANDLE)
        { Print("Erro: ATR handle"); success = false; }
     }

   // 10. ADX
   if(InpUseADX)
     {
      hADX = iADX(_Symbol, InpTimeframe, InpADXPeriod);
      if(hADX == INVALID_HANDLE)
        { Print("Erro: ADX handle"); success = false; }
     }

   // 11. CCI
   if(InpUseCCI)
     {
      hCCI = iCCI(_Symbol, InpTimeframe, InpCCIPeriod, InpCCIPrice);
      if(hCCI == INVALID_HANDLE)
        { Print("Erro: CCI handle"); success = false; }
     }

   // 12. Williams %R
   if(InpUseWPR)
     {
      hWPR = iWPR(_Symbol, InpTimeframe, InpWPRPeriod);
      if(hWPR == INVALID_HANDLE)
        { Print("Erro: WPR handle"); success = false; }
     }

   // 13. Parabolic SAR
   if(InpUseSAR)
     {
      hSAR = iSAR(_Symbol, InpTimeframe, InpSARStep, InpSARMaximum);
      if(hSAR == INVALID_HANDLE)
        { Print("Erro: SAR handle"); success = false; }
     }

   // 14. Ichimoku
   if(InpUseIchimoku)
     {
      hIchimoku = iIchimoku(_Symbol, InpTimeframe, InpIchiTenkan, InpIchiKijun, InpIchiSenkou);
      if(hIchimoku == INVALID_HANDLE)
        { Print("Erro: Ichimoku handle"); success = false; }
     }

   // 15. MFI
   if(InpUseMFI)
     {
      hMFI = iMFI(_Symbol, InpTimeframe, InpMFIPeriod, VOLUME_TICK);
      if(hMFI == INVALID_HANDLE)
        { Print("Erro: MFI handle"); success = false; }
     }

   // 16. Momentum
   if(InpUseMomentum)
     {
      hMomentum = iMomentum(_Symbol, InpTimeframe, InpMomentumPeriod, InpMomPrice);
      if(hMomentum == INVALID_HANDLE)
        { Print("Erro: Momentum handle"); success = false; }
     }

   // 17. DeMarker
   if(InpUseDeMarker)
     {
      hDeMarker = iDeMarker(_Symbol, InpTimeframe, InpDeMarkerPeriod);
      if(hDeMarker == INVALID_HANDLE)
        { Print("Erro: DeMarker handle"); success = false; }
     }

   // 18. Force Index
   if(InpUseForce)
     {
      hForce = iForce(_Symbol, InpTimeframe, InpForcePeriod, InpForceMethod, InpForceVolume);
      if(hForce == INVALID_HANDLE)
        { Print("Erro: Force handle"); success = false; }
     }

   // 19. Envelopes
   if(InpUseEnvelopes)
     {
      hEnvelopes = iEnvelopes(_Symbol, InpTimeframe, InpEnvPeriod, 0, InpEnvMethod, InpEnvPrice, InpEnvDeviation);
      if(hEnvelopes == INVALID_HANDLE)
        { Print("Erro: Envelopes handle"); success = false; }
     }

   // 20. Awesome Oscillator
   if(InpUseAO)
     {
      hAO = iAO(_Symbol, InpTimeframe);
      if(hAO == INVALID_HANDLE)
        { Print("Erro: AO handle"); success = false; }
     }

   // 21. OBV
   if(InpUseOBV)
     {
      hOBV = iOBV(_Symbol, InpTimeframe, InpOBVVolume);
      if(hOBV == INVALID_HANDLE)
        { Print("Erro: OBV handle"); success = false; }
     }

   // 22. Volumes
   if(InpUseVolumes)
     {
      hVolumes = iVolumes(_Symbol, InpTimeframe, InpVolType);
      if(hVolumes == INVALID_HANDLE)
        { Print("Erro: Volumes handle"); success = false; }
     }

   // 23. Fractals
   if(InpUseFractals)
     {
      hFractals = iFractals(_Symbol, InpTimeframe);
      if(hFractals == INVALID_HANDLE)
        { Print("Erro: Fractals handle"); success = false; }
     }

   // 24. Donchian Channels (custom via iCustom or manual calculation with iMA handles)
   if(InpUseDonchian)
     {
      hDonchianHigh = iHighest(_Symbol, InpTimeframe, MODE_HIGH, InpDonchianPeriod, 1);
      hDonchianLow  = iLowest(_Symbol, InpTimeframe, MODE_LOW, InpDonchianPeriod, 1);
      // Donchian uses iHighest/iLowest at runtime, no persistent handle needed
      // We store -1 as placeholder; actual calculation is done in signal function
      hDonchianHigh = -1;
      hDonchianLow  = -1;
     }

   return success;
  }

//+------------------------------------------------------------------+
//| Release all indicator handles                                    |
//+------------------------------------------------------------------+
void ReleaseHandles()
  {
   if(InpUseEMA)
     { IndicatorRelease(hEMAFast); IndicatorRelease(hEMAMedium); IndicatorRelease(hEMASlow); }
   if(InpUseSMA)        IndicatorRelease(hSMA);
   if(InpUseRSI)        IndicatorRelease(hRSI);
   if(InpUseMACD)       IndicatorRelease(hMACD);
   if(InpUseBB)         IndicatorRelease(hBB);
   if(InpUseStochastic) IndicatorRelease(hStochastic);
   if(InpUseATR || InpUseATRStopLoss || InpUseATRTakeProfit || InpTrailingMode == TRAIL_ATR)
      IndicatorRelease(hATR);
   if(InpUseADX)        IndicatorRelease(hADX);
   if(InpUseCCI)        IndicatorRelease(hCCI);
   if(InpUseWPR)        IndicatorRelease(hWPR);
   if(InpUseSAR)        IndicatorRelease(hSAR);
   if(InpUseIchimoku)   IndicatorRelease(hIchimoku);
   if(InpUseMFI)        IndicatorRelease(hMFI);
   if(InpUseMomentum)   IndicatorRelease(hMomentum);
   if(InpUseDeMarker)   IndicatorRelease(hDeMarker);
   if(InpUseForce)      IndicatorRelease(hForce);
   if(InpUseEnvelopes)  IndicatorRelease(hEnvelopes);
   if(InpUseAO)         IndicatorRelease(hAO);
   if(InpUseOBV)        IndicatorRelease(hOBV);
   if(InpUseVolumes)    IndicatorRelease(hVolumes);
   if(InpUseFractals)   IndicatorRelease(hFractals);
  }

//+------------------------------------------------------------------+
//| Calculate signals from all 24 indicators                         |
//+------------------------------------------------------------------+
void CalculateAllSignals(int &buyScore, int &sellScore, int &totalActive)
  {
   buyScore = 0;
   sellScore = 0;
   totalActive = 0;

   double close1 = iClose(_Symbol, InpTimeframe, 1);
   double close2 = iClose(_Symbol, InpTimeframe, 2);
   double open1  = iOpen(_Symbol, InpTimeframe, 1);

   // ===== 1-3. EMA Cross System =====
   if(InpUseEMA)
     {
      double emaFast[], emaMed[], emaSlow[];
      if(GetIndicatorValue(hEMAFast, 0, emaFast, 3) &&
         GetIndicatorValue(hEMAMedium, 0, emaMed, 3) &&
         GetIndicatorValue(hEMASlow, 0, emaSlow, 3))
        {
         // EMA Fast > Medium > Slow = Bullish alignment
         totalActive++;
         if(emaFast[1] > emaMed[1] && emaMed[1] > emaSlow[1] && close1 > emaFast[1])
            buyScore++;
         else if(emaFast[1] < emaMed[1] && emaMed[1] < emaSlow[1] && close1 < emaFast[1])
            sellScore++;

         // EMA Fast cross Medium
         totalActive++;
         if(emaFast[1] > emaMed[1] && emaFast[2] <= emaMed[2])
            buyScore++;
         else if(emaFast[1] < emaMed[1] && emaFast[2] >= emaMed[2])
            sellScore++;

         // Price above/below slow EMA
         totalActive++;
         if(close1 > emaSlow[1])
            buyScore++;
         else if(close1 < emaSlow[1])
            sellScore++;
        }
     }

   // ===== 4. SMA 200 - Trend Filter =====
   if(InpUseSMA)
     {
      double sma[];
      if(GetIndicatorValue(hSMA, 0, sma, 2))
        {
         totalActive++;
         if(close1 > sma[1])
            buyScore++;
         else if(close1 < sma[1])
            sellScore++;
        }
     }

   // ===== 5. RSI =====
   if(InpUseRSI)
     {
      double rsi[];
      if(GetIndicatorValue(hRSI, 0, rsi, 3))
        {
         totalActive++;
         if(rsi[1] > 50.0 && rsi[1] < InpRSIOverbought)
            buyScore++;
         else if(rsi[1] < 50.0 && rsi[1] > InpRSIOversold)
            sellScore++;

         // RSI reversal from oversold/overbought
         totalActive++;
         if(rsi[2] <= InpRSIOversold && rsi[1] > InpRSIOversold)
            buyScore++;
         else if(rsi[2] >= InpRSIOverbought && rsi[1] < InpRSIOverbought)
            sellScore++;
        }
     }

   // ===== 6. MACD =====
   if(InpUseMACD)
     {
      double macdMain[], macdSignal[];
      if(GetIndicatorValue(hMACD, 0, macdMain, 3) &&
         GetIndicatorValue(hMACD, 1, macdSignal, 3))
        {
         totalActive++;
         if(macdMain[1] > macdSignal[1] && macdMain[2] <= macdSignal[2])
            buyScore++;
         else if(macdMain[1] < macdSignal[1] && macdMain[2] >= macdSignal[2])
            sellScore++;

         // MACD above/below zero
         totalActive++;
         if(macdMain[1] > 0)
            buyScore++;
         else if(macdMain[1] < 0)
            sellScore++;
        }
     }

   // ===== 7. Bollinger Bands =====
   if(InpUseBB)
     {
      double bbMid[], bbUpper[], bbLower[];
      if(GetIndicatorValue(hBB, 0, bbMid, 2) &&
         GetIndicatorValue(hBB, 1, bbUpper, 2) &&
         GetIndicatorValue(hBB, 2, bbLower, 2))
        {
         totalActive++;
         if(close1 <= bbLower[1] || (close2 < bbLower[0] && close1 > bbLower[1]))
            buyScore++;
         else if(close1 >= bbUpper[1] || (close2 > bbUpper[0] && close1 < bbUpper[1]))
            sellScore++;
        }
     }

   // ===== 8. Stochastic =====
   if(InpUseStochastic)
     {
      double stochK[], stochD[];
      if(GetIndicatorValue(hStochastic, 0, stochK, 3) &&
         GetIndicatorValue(hStochastic, 1, stochD, 3))
        {
         totalActive++;
         if(stochK[1] > stochD[1] && stochK[2] <= stochD[2] && stochK[1] < InpStochOverbought)
            buyScore++;
         else if(stochK[1] < stochD[1] && stochK[2] >= stochD[2] && stochK[1] > InpStochOversold)
            sellScore++;
        }
     }

   // ===== 9. ATR - Volatility Filter =====
   if(InpUseATR)
     {
      double atr[];
      if(GetIndicatorValue(hATR, 0, atr, 2))
        {
         totalActive++;
         if(atr[1] >= InpATRMinValue && atr[1] <= InpATRMaxValue)
           {
            // Volatilidade dentro do range aceitavel, confirma direcao do candle
            if(close1 > open1)
               buyScore++;
            else if(close1 < open1)
               sellScore++;
           }
        }
     }

   // ===== 10. ADX - Trend Strength =====
   if(InpUseADX)
     {
      double adxMain[], adxPlus[], adxMinus[];
      if(GetIndicatorValue(hADX, 0, adxMain, 2) &&
         GetIndicatorValue(hADX, 1, adxPlus, 2) &&
         GetIndicatorValue(hADX, 2, adxMinus, 2))
        {
         totalActive++;
         if(adxMain[1] >= InpADXMinLevel)
           {
            if(adxPlus[1] > adxMinus[1])
               buyScore++;
            else if(adxMinus[1] > adxPlus[1])
               sellScore++;
           }
        }
     }

   // ===== 11. CCI =====
   if(InpUseCCI)
     {
      double cci[];
      if(GetIndicatorValue(hCCI, 0, cci, 3))
        {
         totalActive++;
         if(cci[1] > 0 && cci[1] < InpCCIOverbought)
            buyScore++;
         else if(cci[1] < 0 && cci[1] > InpCCIOversold)
            sellScore++;
        }
     }

   // ===== 12. Williams %R =====
   if(InpUseWPR)
     {
      double wpr[];
      if(GetIndicatorValue(hWPR, 0, wpr, 3))
        {
         totalActive++;
         if(wpr[2] <= InpWPROversold && wpr[1] > InpWPROversold)
            buyScore++;
         else if(wpr[2] >= InpWPROverbought && wpr[1] < InpWPROverbought)
            sellScore++;
        }
     }

   // ===== 13. Parabolic SAR =====
   if(InpUseSAR)
     {
      double sar[];
      if(GetIndicatorValue(hSAR, 0, sar, 2))
        {
         totalActive++;
         if(close1 > sar[1])
            buyScore++;
         else if(close1 < sar[1])
            sellScore++;
        }
     }

   // ===== 14. Ichimoku Cloud =====
   if(InpUseIchimoku)
     {
      double tenkan[], kijun[], spanA[], spanB[];
      if(GetIndicatorValue(hIchimoku, 0, tenkan, 2) &&
         GetIndicatorValue(hIchimoku, 1, kijun, 2) &&
         GetIndicatorValue(hIchimoku, 2, spanA, 2) &&
         GetIndicatorValue(hIchimoku, 3, spanB, 2))
        {
         // Tenkan/Kijun cross
         totalActive++;
         if(tenkan[1] > kijun[1])
            buyScore++;
         else if(tenkan[1] < kijun[1])
            sellScore++;

         // Price above/below cloud
         totalActive++;
         double cloudTop = MathMax(spanA[1], spanB[1]);
         double cloudBot = MathMin(spanA[1], spanB[1]);
         if(close1 > cloudTop)
            buyScore++;
         else if(close1 < cloudBot)
            sellScore++;
        }
     }

   // ===== 15. MFI =====
   if(InpUseMFI)
     {
      double mfi[];
      if(GetIndicatorValue(hMFI, 0, mfi, 3))
        {
         totalActive++;
         if(mfi[2] <= InpMFIOversold && mfi[1] > InpMFIOversold)
            buyScore++;
         else if(mfi[2] >= InpMFIOverbought && mfi[1] < InpMFIOverbought)
            sellScore++;
        }
     }

   // ===== 16. Momentum =====
   if(InpUseMomentum)
     {
      double mom[];
      if(GetIndicatorValue(hMomentum, 0, mom, 3))
        {
         totalActive++;
         if(mom[1] > 100.0 && mom[1] > mom[2])
            buyScore++;
         else if(mom[1] < 100.0 && mom[1] < mom[2])
            sellScore++;
        }
     }

   // ===== 17. DeMarker =====
   if(InpUseDeMarker)
     {
      double dem[];
      if(GetIndicatorValue(hDeMarker, 0, dem, 3))
        {
         totalActive++;
         if(dem[2] <= InpDeMarkerOS && dem[1] > InpDeMarkerOS)
            buyScore++;
         else if(dem[2] >= InpDeMarkerOB && dem[1] < InpDeMarkerOB)
            sellScore++;
        }
     }

   // ===== 18. Force Index =====
   if(InpUseForce)
     {
      double force[];
      if(GetIndicatorValue(hForce, 0, force, 2))
        {
         totalActive++;
         if(force[1] > 0)
            buyScore++;
         else if(force[1] < 0)
            sellScore++;
        }
     }

   // ===== 19. Envelopes =====
   if(InpUseEnvelopes)
     {
      double envUpper[], envLower[];
      if(GetIndicatorValue(hEnvelopes, 0, envUpper, 2) &&
         GetIndicatorValue(hEnvelopes, 1, envLower, 2))
        {
         totalActive++;
         if(close1 <= envLower[1])
            buyScore++;
         else if(close1 >= envUpper[1])
            sellScore++;
        }
     }

   // ===== 20. Awesome Oscillator =====
   if(InpUseAO)
     {
      double ao[];
      if(GetIndicatorValue(hAO, 0, ao, 3))
        {
         totalActive++;
         if(ao[1] > 0 && ao[1] > ao[2])
            buyScore++;
         else if(ao[1] < 0 && ao[1] < ao[2])
            sellScore++;
        }
     }

   // ===== 21. OBV =====
   if(InpUseOBV)
     {
      double obv[];
      if(GetIndicatorValue(hOBV, 0, obv, 3))
        {
         totalActive++;
         if(obv[1] > obv[2])
            buyScore++;
         else if(obv[1] < obv[2])
            sellScore++;
        }
     }

   // ===== 22. Volumes =====
   if(InpUseVolumes)
     {
      double vol[];
      if(GetIndicatorValue(hVolumes, 0, vol, 3))
        {
         totalActive++;
         // Volume crescente na direcao do preco
         if(vol[1] > vol[2] && close1 > open1)
            buyScore++;
         else if(vol[1] > vol[2] && close1 < open1)
            sellScore++;
        }
     }

   // ===== 23. Fractals =====
   if(InpUseFractals)
     {
      double fracUp[], fracDown[];
      if(GetIndicatorValue(hFractals, 0, fracUp, 10) &&
         GetIndicatorValue(hFractals, 1, fracDown, 10))
        {
         totalActive++;
         // Procura fractal recente (fractals aparecem com atraso de 2 barras)
         double lastFracUp = 0, lastFracDown = 0;
         for(int f = 3; f < 10; f++)
           {
            if(lastFracUp == 0 && fracUp[f] != EMPTY_VALUE && fracUp[f] != 0)
               lastFracUp = fracUp[f];
            if(lastFracDown == 0 && fracDown[f] != EMPTY_VALUE && fracDown[f] != 0)
               lastFracDown = fracDown[f];
            if(lastFracUp != 0 && lastFracDown != 0)
               break;
           }
         // Preco acima do ultimo fractal de alta = bullish
         if(lastFracUp != 0 && lastFracDown != 0)
           {
            if(close1 > lastFracUp)
               buyScore++;
            else if(close1 < lastFracDown)
               sellScore++;
           }
        }
     }

   // ===== 24. Canais de Donchian =====
   if(InpUseDonchian)
     {
      double donchianHigh = 0, donchianLow = DBL_MAX;
      for(int d = 1; d <= InpDonchianPeriod; d++)
        {
         double h = iHigh(_Symbol, InpTimeframe, d);
         double l = iLow(_Symbol, InpTimeframe, d);
         if(h > donchianHigh) donchianHigh = h;
         if(l < donchianLow)  donchianLow = l;
        }
      double donchianMid = (donchianHigh + donchianLow) / 2.0;

      totalActive++;
      // Breakout acima do canal = compra, abaixo = venda
      if(close1 >= donchianHigh)
         buyScore++;
      else if(close1 <= donchianLow)
         sellScore++;

      // Posicao relativa ao meio do canal
      totalActive++;
      if(close1 > donchianMid)
         buyScore++;
      else if(close1 < donchianMid)
         sellScore++;
     }
  }

//+------------------------------------------------------------------+
//| Get indicator buffer values                                      |
//+------------------------------------------------------------------+
bool GetIndicatorValue(int handle, int bufferIndex, double &values[], int count)
  {
   ArraySetAsSeries(values, true);
   if(CopyBuffer(handle, bufferIndex, 0, count, values) < count)
      return false;
   return true;
  }

//+------------------------------------------------------------------+
//| Open BUY position                                                |
//+------------------------------------------------------------------+
void OpenBuy()
  {
   double ask = symInfo.Ask();
   double point = symInfo.Point();
   int digits = (int)symInfo.Digits();

   double sl = 0, tp = 0;
   double slPoints = InpStopLoss;
   double tpPoints = InpTakeProfit;

   // ATR-based SL/TP
   if(InpUseATRStopLoss || InpUseATRTakeProfit)
     {
      double atr[];
      if(GetIndicatorValue(hATR, 0, atr, 2))
        {
         if(InpUseATRStopLoss)
            slPoints = (int)MathRound(atr[1] * InpATRMultiplierSL / point);
         if(InpUseATRTakeProfit)
            tpPoints = (int)MathRound(atr[1] * InpATRMultiplierTP / point);
        }
     }

   sl = NormalizeDouble(ask - slPoints * point, digits);
   tp = NormalizeDouble(ask + tpPoints * point, digits);

   double lots = CalculateLotSize(slPoints);

   if(trade.Buy(lots, _Symbol, ask, sl, tp, "SniperScalper BUY"))
      Print("BUY aberto: ", lots, " lotes | SL: ", sl, " | TP: ", tp);
   else
      Print("Erro ao abrir BUY: ", GetLastError());
  }

//+------------------------------------------------------------------+
//| Open SELL position                                               |
//+------------------------------------------------------------------+
void OpenSell()
  {
   double bid = symInfo.Bid();
   double point = symInfo.Point();
   int digits = (int)symInfo.Digits();

   double sl = 0, tp = 0;
   double slPoints = InpStopLoss;
   double tpPoints = InpTakeProfit;

   // ATR-based SL/TP
   if(InpUseATRStopLoss || InpUseATRTakeProfit)
     {
      double atr[];
      if(GetIndicatorValue(hATR, 0, atr, 2))
        {
         if(InpUseATRStopLoss)
            slPoints = (int)MathRound(atr[1] * InpATRMultiplierSL / point);
         if(InpUseATRTakeProfit)
            tpPoints = (int)MathRound(atr[1] * InpATRMultiplierTP / point);
        }
     }

   sl = NormalizeDouble(bid + slPoints * point, digits);
   tp = NormalizeDouble(bid - tpPoints * point, digits);

   double lots = CalculateLotSize(slPoints);

   if(trade.Sell(lots, _Symbol, bid, sl, tp, "SniperScalper SELL"))
      Print("SELL aberto: ", lots, " lotes | SL: ", sl, " | TP: ", tp);
   else
      Print("Erro ao abrir SELL: ", GetLastError());
  }

//+------------------------------------------------------------------+
//| Calculate lot size (fixed or dynamic)                            |
//+------------------------------------------------------------------+
double CalculateLotSize(double slPoints)
  {
   if(!InpUseDynamicLot)
      return InpLotSize;

   double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * InpRiskPercent / 100.0;
   double tickValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point      = symInfo.Point();

   if(tickValue == 0 || tickSize == 0 || slPoints == 0)
      return InpLotSize;

   double slMoney = slPoints * point * tickValue / tickSize;
   double lots    = NormalizeDouble(riskAmount / slMoney, 2);

   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lots = MathMax(minLot, MathMin(maxLot, lots));
   lots = MathFloor(lots / lotStep) * lotStep;

   return NormalizeDouble(lots, 2);
  }

//+------------------------------------------------------------------+
//| Manage open positions - Trailing Stop & Break Even               |
//+------------------------------------------------------------------+
void ManageOpenPositions()
  {
   double point = symInfo.Point();
   int digits   = (int)symInfo.Digits();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!posInfo.SelectByIndex(i))
         continue;
      if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagicNumber)
         continue;

      double openPrice = posInfo.PriceOpen();
      double currentSL = posInfo.StopLoss();
      double currentTP = posInfo.TakeProfit();
      ulong  ticket    = posInfo.Ticket();

      if(posInfo.PositionType() == POSITION_TYPE_BUY)
        {
         double bid = symInfo.Bid();
         double profitPoints = (bid - openPrice) / point;

         // Break Even
         if(InpUseBreakEven && profitPoints >= InpBreakEvenStart)
           {
            double beLevel = NormalizeDouble(openPrice + InpBreakEvenProfit * point, digits);
            if(currentSL < beLevel)
              {
               trade.PositionModify(ticket, beLevel, currentTP);
               continue;
              }
           }

         // Trailing Stop
         if(InpUseTrailingStop && profitPoints >= InpTrailingStart)
           {
            double newSL = CalculateTrailingSL(true, bid, openPrice, currentSL);
            newSL = NormalizeDouble(newSL, digits);
            if(newSL > currentSL && newSL < bid)
               trade.PositionModify(ticket, newSL, currentTP);
           }
        }
      else if(posInfo.PositionType() == POSITION_TYPE_SELL)
        {
         double ask = symInfo.Ask();
         double profitPoints = (openPrice - ask) / point;

         // Break Even
         if(InpUseBreakEven && profitPoints >= InpBreakEvenStart)
           {
            double beLevel = NormalizeDouble(openPrice - InpBreakEvenProfit * point, digits);
            if(currentSL > beLevel || currentSL == 0)
              {
               trade.PositionModify(ticket, beLevel, currentTP);
               continue;
              }
           }

         // Trailing Stop
         if(InpUseTrailingStop && profitPoints >= InpTrailingStart)
           {
            double newSL = CalculateTrailingSL(false, ask, openPrice, currentSL);
            newSL = NormalizeDouble(newSL, digits);
            if((newSL < currentSL || currentSL == 0) && newSL > ask)
               trade.PositionModify(ticket, newSL, currentTP);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Calculate trailing stop level based on selected mode             |
//+------------------------------------------------------------------+
double CalculateTrailingSL(bool isBuy, double currentPrice, double openPrice, double currentSL)
  {
   double point  = symInfo.Point();
   double newSL  = currentSL;

   switch(InpTrailingMode)
     {
      case TRAIL_IMMEDIATE:
         // Trailing imediato - segue o preco de perto
         if(isBuy)
            newSL = currentPrice - InpTrailingDistance * point;
         else
            newSL = currentPrice + InpTrailingDistance * point;
         break;

      case TRAIL_STEP:
         // Trailing por degraus
         if(isBuy)
           {
            double targetSL = currentPrice - InpTrailingDistance * point;
            if(targetSL - currentSL >= InpTrailingStep * point)
               newSL = targetSL;
           }
         else
           {
            double targetSL = currentPrice + InpTrailingDistance * point;
            if(currentSL == 0 || currentSL - targetSL >= InpTrailingStep * point)
               newSL = targetSL;
           }
         break;

      case TRAIL_ATR:
         // Trailing baseado no ATR
        {
         double atr[];
         if(GetIndicatorValue(hATR, 0, atr, 2))
           {
            double atrDistance = atr[1] * InpTrailingATRMult;
            if(isBuy)
               newSL = currentPrice - atrDistance;
            else
               newSL = currentPrice + atrDistance;
           }
        }
        break;

      case TRAIL_PARABOLIC:
         // Trailing baseado no Parabolic SAR
         if(InpUseSAR)
           {
            double sar[];
            if(GetIndicatorValue(hSAR, 0, sar, 2))
              {
               if(isBuy && sar[1] < currentPrice)
                  newSL = sar[1];
               else if(!isBuy && sar[1] > currentPrice)
                  newSL = sar[1];
              }
           }
         break;
     }

   return newSL;
  }

//+------------------------------------------------------------------+
//| Count positions for this EA                                      |
//+------------------------------------------------------------------+
int CountPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(posInfo.SelectByIndex(i))
        {
         if(posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            count++;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Check if within trading hours                                    |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   int hour = dt.hour;

   if(InpStartHour < InpEndHour)
      return (hour >= InpStartHour && hour < InpEndHour);
   else
      return (hour >= InpStartHour || hour < InpEndHour);
  }

//+------------------------------------------------------------------+
//| Update daily profit/loss tracking                                |
//+------------------------------------------------------------------+
void UpdateDailyProfitLoss()
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   datetime today = StringToTime(IntegerToString(dt.year) + "." +
                                 IntegerToString(dt.mon) + "." +
                                 IntegerToString(dt.day));

   if(today != lastDayChecked)
     {
      dailyProfit = 0;
      lastDayChecked = today;
     }

   // Calculate from history
   dailyProfit = 0;
   HistorySelect(today, TimeCurrent());
   int totalDeals = HistoryDealsTotal();
   for(int i = 0; i < totalDeals; i++)
     {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) == InpMagicNumber &&
         HistoryDealGetString(dealTicket, DEAL_SYMBOL) == _Symbol)
        {
         dailyProfit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT) +
                        HistoryDealGetDouble(dealTicket, DEAL_SWAP) +
                        HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
        }
     }

   // Add floating P/L
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(posInfo.SelectByIndex(i))
        {
         if(posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            dailyProfit += posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
        }
     }
  }

//+------------------------------------------------------------------+
//| PANEL FUNCTIONS                                                  |
//+------------------------------------------------------------------+
void CreatePanel()
  {
   string prefix = "SSU_";

   // Background
   ObjectCreate(0, prefix + "bg", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, prefix + "bg", OBJPROP_XDISTANCE, InpPanelX);
   ObjectSetInteger(0, prefix + "bg", OBJPROP_YDISTANCE, InpPanelY);
   ObjectSetInteger(0, prefix + "bg", OBJPROP_XSIZE, 280);
   ObjectSetInteger(0, prefix + "bg", OBJPROP_YSIZE, 420);
   ObjectSetInteger(0, prefix + "bg", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, prefix + "bg", OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, prefix + "bg", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, prefix + "bg", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, prefix + "bg", OBJPROP_WIDTH, 2);

   // Title
   CreateLabel(prefix + "title", InpPanelX + 10, InpPanelY + 5,
               "SNIPER SCALPER ULTRA", clrGold, 10, "Arial Bold");

   // Separator
   CreateLabel(prefix + "sep1", InpPanelX + 10, InpPanelY + 25,
               "----------------------------", clrDarkGray, 8, "Arial");

   // Info labels
   int y = InpPanelY + 40;
   int step = 18;

   CreateLabel(prefix + "symb", InpPanelX + 10, y,
               "Simbolo: " + _Symbol, clrWhite, 8, "Arial");
   y += step;
   CreateLabel(prefix + "tf", InpPanelX + 10, y,
               "Timeframe: " + EnumToString(InpTimeframe), clrWhite, 8, "Arial");
   y += step;
   CreateLabel(prefix + "spread", InpPanelX + 10, y,
               "Spread: ---", clrWhite, 8, "Arial");
   y += step;

   CreateLabel(prefix + "sep2", InpPanelX + 10, y,
               "----------------------------", clrDarkGray, 8, "Arial");
   y += step;

   // Score
   CreateLabel(prefix + "buysc", InpPanelX + 10, y,
               "Score COMPRA: 0", InpPanelBuyColor, 9, "Arial Bold");
   y += step;
   CreateLabel(prefix + "sellsc", InpPanelX + 10, y,
               "Score VENDA: 0", InpPanelSellColor, 9, "Arial Bold");
   y += step;
   CreateLabel(prefix + "total", InpPanelX + 10, y,
               "Indicadores Ativos: 0", clrWhite, 8, "Arial");
   y += step;
   CreateLabel(prefix + "minsc", InpPanelX + 10, y,
               "Score Minimo: " + IntegerToString(InpMinScore), clrYellow, 8, "Arial");
   y += step;

   CreateLabel(prefix + "sep3", InpPanelX + 10, y,
               "----------------------------", clrDarkGray, 8, "Arial");
   y += step;

   // Signal
   CreateLabel(prefix + "signal", InpPanelX + 10, y,
               "SINAL: AGUARDANDO", clrYellow, 10, "Arial Bold");
   y += step + 5;

   CreateLabel(prefix + "sep4", InpPanelX + 10, y,
               "----------------------------", clrDarkGray, 8, "Arial");
   y += step;

   // Risk info
   CreateLabel(prefix + "sl", InpPanelX + 10, y,
               "SL: " + IntegerToString(InpStopLoss) + " pts", clrOrangeRed, 8, "Arial");
   y += step;
   CreateLabel(prefix + "tp", InpPanelX + 10, y,
               "TP: " + IntegerToString(InpTakeProfit) + " pts", clrLimeGreen, 8, "Arial");
   y += step;
   CreateLabel(prefix + "rr", InpPanelX + 10, y,
               "R:R = 1:" + DoubleToString((double)InpTakeProfit / InpStopLoss, 1),
               clrGold, 8, "Arial");
   y += step;
   CreateLabel(prefix + "trail", InpPanelX + 10, y,
               "Trailing: " + (InpUseTrailingStop ? EnumToString(InpTrailingMode) : "OFF"),
               clrWhite, 8, "Arial");
   y += step;

   CreateLabel(prefix + "sep5", InpPanelX + 10, y,
               "----------------------------", clrDarkGray, 8, "Arial");
   y += step;

   // Daily P/L
   CreateLabel(prefix + "daily", InpPanelX + 10, y,
               "P/L Diario: $0.00", clrWhite, 8, "Arial");
   y += step;

   // Status
   CreateLabel(prefix + "status", InpPanelX + 10, y,
               "Status: Operando", clrLime, 8, "Arial");

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Create a text label object                                       |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize, string font)
  {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
  }

//+------------------------------------------------------------------+
//| Update panel with current signals                                |
//+------------------------------------------------------------------+
void UpdatePanel(int buyScore, int sellScore, int totalActive)
  {
   string prefix = "SSU_";

   // Spread
   ObjectSetString(0, prefix + "spread", OBJPROP_TEXT,
                   "Spread: " + IntegerToString(symInfo.Spread()) + " pts");

   // Scores
   ObjectSetString(0, prefix + "buysc", OBJPROP_TEXT,
                   "Score COMPRA: " + IntegerToString(buyScore));
   ObjectSetString(0, prefix + "sellsc", OBJPROP_TEXT,
                   "Score VENDA: " + IntegerToString(sellScore));
   ObjectSetString(0, prefix + "total", OBJPROP_TEXT,
                   "Indicadores Ativos: " + IntegerToString(totalActive));

   // Signal
   string signalText = "SINAL: AGUARDANDO";
   color signalColor = InpPanelNeutralColor;

   if(InpSignalMode == MODE_CONFLUENCE)
     {
      if(buyScore >= InpMinScore)
        { signalText = "SINAL: >>> COMPRA <<<"; signalColor = InpPanelBuyColor; }
      else if(sellScore >= InpMinScore)
        { signalText = "SINAL: >>> VENDA <<<"; signalColor = InpPanelSellColor; }
     }
   else
     {
      if(buyScore == totalActive && totalActive > 0)
        { signalText = "SINAL: >>> COMPRA <<<"; signalColor = InpPanelBuyColor; }
      else if(sellScore == totalActive && totalActive > 0)
        { signalText = "SINAL: >>> VENDA <<<"; signalColor = InpPanelSellColor; }
     }

   ObjectSetString(0, prefix + "signal", OBJPROP_TEXT, signalText);
   ObjectSetInteger(0, prefix + "signal", OBJPROP_COLOR, signalColor);

   // Daily P/L
   color plColor = dailyProfit >= 0 ? clrLime : clrRed;
   ObjectSetString(0, prefix + "daily", OBJPROP_TEXT,
                   "P/L Diario: $" + DoubleToString(dailyProfit, 2));
   ObjectSetInteger(0, prefix + "daily", OBJPROP_COLOR, plColor);

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Update panel status text                                         |
//+------------------------------------------------------------------+
void UpdatePanelStatus(string statusText)
  {
   string prefix = "SSU_";
   ObjectSetString(0, prefix + "status", OBJPROP_TEXT, "Status: " + statusText);
   ObjectSetInteger(0, prefix + "status", OBJPROP_COLOR, clrOrange);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Delete all panel objects                                         |
//+------------------------------------------------------------------+
void DeletePanel()
  {
   string prefix = "SSU_";
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
     }
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
