# Sniper Scalper Ultra EA - MetaTrader 5

Expert Advisor (EA) para MetaTrader 5 com sistema de confluencia de **24 indicadores tecnicos**, trailing stop agressivo, stop loss curto e take profit longo.

## Caracteristicas Principais

### 24 Indicadores com Parametros Ajustaveis
| # | Indicador | Tipo |
|---|-----------|------|
| 1-3 | EMA (Rapida 8, Media 21, Lenta 50) | Tendencia |
| 4 | SMA (200) | Tendencia |
| 5 | RSI (14) | Oscilador |
| 6 | MACD (12, 26, 9) | Tendencia/Momentum |
| 7 | Bollinger Bands (20, 2.0) | Volatilidade |
| 8 | Stochastic (14, 3, 3) | Oscilador |
| 9 | ATR (14) | Volatilidade |
| 10 | ADX (14) | Forca de Tendencia |
| 11 | CCI (14) | Oscilador |
| 12 | Williams %R (14) | Oscilador |
| 13 | Parabolic SAR (0.02, 0.2) | Tendencia |
| 14 | Ichimoku Cloud (9, 26, 52) | Tendencia |
| 15 | MFI (14) | Volume |
| 16 | Momentum (14) | Momentum |
| 17 | DeMarker (14) | Oscilador |
| 18 | Force Index (13) | Volume/Forca |
| 19 | Envelopes (20, 0.10%) | Volatilidade |
| 20 | Awesome Oscillator | Momentum |
| 21 | OBV | Volume |
| 22 | Volumes | Volume |
| 23 | Fractals | Padrao de Preco |
| 24 | Canais de Donchian (20) | Breakout/Canal |

### Sistema de Gerenciamento de Risco
- **Stop Loss Curto** (padrao: 150 pontos / 15 pips)
- **Take Profit Longo** (padrao: 600 pontos / 60 pips) - Ratio R:R = 1:4
- **SL/TP baseado em ATR** (opcional)
- **Lote fixo ou dinamico** (baseado em % do saldo)

### Trailing Stop Agressivo (4 Modos)
1. **Imediato** - Segue o preco a cada tick de lucro
2. **Por Degraus** - Move em steps fixos configurados
3. **Baseado no ATR** - Distancia dinamica conforme volatilidade
4. **Baseado no Parabolic SAR** - Usa o SAR como referencia

### Protecao Adicional
- **Break Even** automatico (ativacao + lucro garantido configuravel)
- **Stop de Ganho Diario** - Para de operar ao atingir lucro diario
- **Stop de Perda Diaria** - Para de operar ao atingir perda diaria
- **Filtro de Spread** maximo
- **Filtro de Horario** de operacao

### Painel Visual no Grafico
- Score de COMPRA e VENDA em tempo real
- Indicadores ativos e score minimo
- Sinal atual (COMPRA / VENDA / AGUARDANDO)
- P/L diario
- Informacoes de SL, TP e R:R

## Como Instalar

1. Copie o arquivo `SniperScalperEA.mq5` para a pasta `MQL5/Experts/` do seu MetaTrader 5
2. Compile o EA no MetaEditor (F7)
3. Arraste o EA para o grafico desejado
4. Configure os parametros conforme sua estrategia
5. Ative o "AutoTrading" no MT5

## Configuracao Recomendada (Scalper)

| Parametro | Valor Recomendado |
|-----------|-------------------|
| Timeframe | M5 |
| Stop Loss | 100-200 pontos |
| Take Profit | 400-800 pontos |
| Score Minimo | 10-14 |
| Trailing Mode | Imediato |
| Trailing Start | 10 pontos |
| Trailing Distance | 80-120 pontos |
| Break Even Start | 50 pontos |

## Modo de Sinal

- **Confluencia**: Entra quando o score (soma dos indicadores concordantes) atinge o minimo configurado
- **Todos Concordam**: Entra apenas quando TODOS os indicadores ativos concordam na direcao

## Aviso Legal

Este EA e fornecido apenas para fins educacionais. Opere com responsabilidade e sempre teste em conta demo antes de usar em conta real. Trading envolve risco de perda financeira.
