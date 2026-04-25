# 🤖 CLAUDE TRADING BOT — ESTRATEGIA IDEAL OPTIMIZADA
# Documento Maestro para Claude Code
# Versión: 1.0 | Fecha: 2026-04-24
# Autor: Basado en Nate Herk + Análisis Experto 2026

================================================================================
SECCIÓN 0: INSTRUCCIONES CRÍTICAS PARA CLAUDE CODE
================================================================================

> ⚠️ LEER ESTO PRIMERO ANTES DE CUALQUIER ACCIÓN

Eres un agente de trading autónomo. Tu única fuente de verdad son los archivos
de este repositorio. NO inventes datos. NO asumas información. SIEMPRE lee los
archivos de memoria antes de actuar.

REGLAS ABSOLUTAS (violación = shutdown inmediato):
1. Lee TRADING-STRATEGY.md PRIMERO en cada rutina
2. Lee TRADE-LOG.md para saber posiciones actuales
3. Verifica GUARDRAILS.md antes de CUALQUIER orden
4. Paper trading default. Live trading requiere toggle explícito en .env
5. NUNCA operes si VIX > 40
6. NUNCA operes si daily loss > -2%
7. NUNCA operes si drawdown > -10%
8. Máximo 5 trades por semana
9. Máximo 5 posiciones abiertas
10. Máximo 50% exposure del portfolio
11. NUNCA uses options, futures, ni derivados
12. SIEMPRE usa órdenes limit (nunca market orders)

================================================================================
SECCIÓN 1: VISIÓN Y FILOSOFÍA
================================================================================

## 1.1 Objetivo Principal

Beat SPY con Sharpe Ratio > 1.0 y Max Drawdown < 15%.

No buscamos maximizar retorno bruto. Buscamos maximizar retorno ajustado por
riesgo. Un bot que gana 50% con 40% drawdown es PEOR que uno que gana 25% con
10% drawdown.

## 1.2 Estilo de Trading

SWING TRADING + MOMENTUM QUALITY

- Horizonte: 3-10 días promedio
- Basado en: Fundamentals (fortaleza de Claude Opus 4.7) + Filtros técnicos
- NO day trading: Opus 4.7 no está optimizado para micro-tiempo-real
- NO buy-and-hold puro: Buscamos alpha activo

## 1.3 Benchmark

SPY (S&P 500 ETF) como benchmark primario.

Métricas de éxito:
- Annual Return > SPY + 5%
- Sharpe Ratio > 1.0
- Max Drawdown < 15%
- Win Rate > 45%
- Average Win : Average Loss > 2:1

## 1.4 Principios No Negociables

1. PROTECCIÓN DE CAPITAL > Ganancia
2. DISCIPLINA MECÁNICA > Intuición
3. RIESGO CALCULADO > Esperanza
4. CONSISTENCIA > Home runs
5. CASH ES UNA POSICIÓN válida

================================================================================
SECCIÓN 2: MODELO MENTAL — FILES ARE THE BRAIN
================================================================================

## 2.1 Arquitectura de Memoria

Cada rutina sigue este protocolo:

    1. READ: Cargar memoria necesaria (mínima, por context budget)
    2. THINK: Analizar según estrategia
    3. ACT: Ejecutar solo si pasa guardrails
    4. WRITE: Guardar resultados en archivos
    5. COMMIT: Git commit + push (backup y audit trail)

## 2.2 Context Budget (~200K tokens por rutina)

Presupuesto de tokens por rutina:
- System prompt + instrucciones: ~10K
- TRADING-STRATEGY.md: ~2K
- GUARDRAILS.md: ~1K
- TRADE-LOG.md (última semana): ~5K
- RESEARCH-LOG.md (último entry): ~2K
- API responses: ~5K
- Espacio para razonamiento: ~175K

REGLA: Solo leer lo necesario. No leer WEEKLY-REVIEW.md en market-open.
No leer RESEARCH-LOG.md completo en EOD summary.

## 2.3 Archivos Críticos y su Flujo

┌─────────────────────────────────────────────────────────────────────────────┐
│  ARCHIVO              │  LEÍDO POR    │  ESCRITO POR  │  PROPÓSITO          │
├─────────────────────────────────────────────────────────────────────────────┤
│  TRADING-STRATEGY.md  │  1,2,3,4,5    │  5 (raro)     │  La Biblia          │
│  GUARDRAILS.md        │  1,2,3,4,5    │  5 (raro)     │  Reglas de protección│
│  TRADE-LOG.md         │  1,2,3,4,5    │  2,3,4        │  Diario de trades   │
│  RESEARCH-LOG.md      │  2,3,5        │  1,3 (raro)   │  Investigación      │
│  WEEKLY-REVIEW.md     │  5            │  5            │  Memoria emocional  │
│  MARKET-REGIME.md     │  1,2,3,4,5    │  4            │  Estado del mercado │
│  .env                 │  1,2,3,4,5    │  NUNCA        │  API keys (NO git)  │
└─────────────────────────────────────────────────────────────────────────────┘

Rutinas: 1=Pre-market, 2=Market-open, 3=Midday, 4=EOD, 5=Weekly-review

================================================================================
SECCIÓN 3: ANÁLISIS DEL MODELO (CLAUDE OPUS 4.7)
================================================================================

## 3.1 Fortalezas del Modelo

- Finance Agent v1.1: 64.4% (top-of-class)
- SWE-bench Verified: 87.6% (excelente para coding/agentic)
- MCP-Atlas (Tool Use): 77.3% (bueno para llamar APIs)
- GPQA Diamond: 94.2% (razonamiento superior)

## 3.2 Debilidades Críticas

- BrowseComp (Web Search): 79.3% (DEBIL vs GPT-5.4 89.3%)
- NO tiene memoria entre sesiones (stateless)
- NO tiene "scar tissue" emocional (necesita archivos para aprender)
- Puede ser "eager" (querer tradear en cada sesión sin guardrails)

## 3.3 Implicaciones para la Estrategia

1. Usar Perplexity API para investigación web (compensa debilidad de Claude)
2. NUNCA confiar en "intuición" de Claude — solo en reglas mecánicas
3. Los archivos de memoria SON la disciplina del bot
4. Guardrails deben estar en CÓDIGO, no solo en prompts

================================================================================
SECCIÓN 4: FILTROS DE MERCADO (MACRO)
================================================================================

## 4.1 Regimen de Mercado por VIX

El VIX (Volatility Index) determina el regimen operativo:

┌─────────────┬──────────────┬────────────────────────┬──────────────────────┐
│   VIX       │   REGIMEN    │   ACCIÓN               │   PARÁMETROS         │
├─────────────┼──────────────┼────────────────────────┼──────────────────────┤
│   < 15      │   Calm       │   Operar normal        │   Stop -3%, Trail 8% │
│   15-20     │   Normal     │   Operar normal        │   Stop -4%, Trail 10%│
│   20-25     │   Caution    │   Reducir size 20%     │   Stop -4%, Trail 10%│
│   25-30     │   Stress     │   Reducir size 40%     │   Stop -5%, NO trail │
│   30-40     │   High Alert │   Solo gestionar       │   NO nuevas entradas │
│   > 40      │   CRISIS     │   NO TRADING           │   Cerrar todo, cash  │
└─────────────┴──────────────┴────────────────────────┴──────────────────────┘

## 4.2 Filtros Adicionales de Mercado

- S&P 500 > 200-day SMA: Solo operar en tendencia alcista
- Volumen del mercado > promedio 20 días: Evitar thin sessions
- NO operar en: Días de FOMC (2pm), NFP (8:30am primer viernes), earnings
  masivos (si > 10% del S&P 500 reporta mismo día)

## 4.3 Actualización de Regimen

La rutina EOD (4) actualiza MARKET-REGIME.md:

```markdown
## 2026-04-24
- VIX: 22 (Caution regime)
- S&P 500 vs 200-SMA: +4.2% (above)
- Volume: 1.1x avg (normal)
- FOMC: Next meeting May 7 (12 days)
- Earnings season: Active (Q1 2026)
- Regimen: CAUTION → Reduce size 20%
- Next review: 2026-04-25 EOD
```

================================================================================
SECCIÓN 5: CRITERIOS DE ENTRADA (BUY SIGNALS)
================================================================================

## 5.1 Nivel 1: Filtro de Stock (Fundamental)

Cada stock debe cumplir TODOS estos criterios:

- [ ] Market Cap > $10B (evitar micro-caps iliquidos)
- [ ] Revenue Growth YoY > 10% (growth sostenible)
- [ ] Debt/Equity < 1.0 (balance sheet sana)
- [ ] Current Ratio > 1.5 (liquidez)
- [ ] Free Cash Flow > 0 (genera dinero real)
- [ ] NO está en bankruptcy, merger, o spin-off activo

## 5.2 Nivel 2: Filtro Técnico (Timing)

Cada stock debe cumplir AL MENOS 4 de 6:

- [ ] Precio > 50-day SMA (momentum alcista)
- [ ] Precio > 200-day SMA (tendencia largo plazo)
- [ ] RSI(14) entre 50-70 (no overbought, no oversold)
- [ ] Volume spike > 1.5x promedio 20 días (confirmación)
- [ ] MACD histograma positivo y creciente
- [ ] Close confirmado above resistance (breakout válido)

## 5.3 Nivel 3: Catalyst

Debe existir AL MENOS 1 catalyst en los próximos 10 días:

- Earnings report (próximos 7 días)
- Product launch / FDA approval
- Analyst upgrade con target price > 15% current
- Sector rotation favorable (momentum sectorial)
- Insider buying reciente (Form 4 filings)

## 5.4 Nivel 4: Setup Quality Score

Sistema de puntuación 1-10:

| Criterio | Puntos |
|----------|--------|
| Fundamental: Revenue > 20% YoY | +2 |
| Fundamental: Debt/Equity < 0.5 | +1 |
| Técnico: > 50-SMA + > 200-SMA | +2 |
| Técnico: RSI 55-65 (zona ideal) | +1 |
| Técnico: Volume > 2x avg | +1 |
| Técnico: Breakout confirmed | +1 |
| Catalyst: Earnings en 3-5 días | +1 |
| Catalyst: Analyst upgrade +20% | +1 |

**MÍNIMO PARA ENTRAR: 7/10**
**IDEAL: 9-10/10 (permite size aumentado)**

## 5.5 Sector Diversificación

- Máximo 2 posiciones por sector
- Sectores preferidos (momentum 2026): Tech, Healthcare, Energy, Financials
- Evitar: Sectores con VIX sectorial > 35

================================================================================
SECCIÓN 6: CRITERIOS DE SALIDA (SELL SIGNALS)
================================================================================

## 6.1 Stop Loss (Protección Principal)

- **Stop fijo: -4% desde precio de entrada**
- Implementado como orden stop-loss en Alpaca (automático)
- NO trailing stop en fase inicial (evitar sacadas prematuras)
- Ajustar a -5% si VIX > 25

## 6.2 Profit Taking (Toma de Ganancias)

Sistema escalonado:

| Nivel de Ganancia | Acción | Rationale |
|-------------------|--------|-----------|
| +8% | Vender 50% de posición | Lock profits parcial |
| +8% | Mover stop a breakeven en resto | Proteger capital |
| +15% | Vender 25% adicional | Dejar correr 25% |
| +15% | Trailing stop 10% en resto | Capturar momentum |
| +25% | Vender 100% restante | Target extendido alcanzado |

## 6.3 Time Stop

- Máximo 10 días en posición
- Si después de 10 días el stock no ha movido ±5% → salir
- Rationale: Capital dead es oportunidad perdida

## 6.4 Technical Exit

- Close below 50-day SMA → salir al día siguiente
- Death cross (50-SMA cruza below 200-SMA) → salir inmediato
- Volume collapse (< 0.5x avg por 3 días) → salir

## 6.5 Earnings Exit

- Si earnings report es NEGATIVO (miss revenue o EPS) → salir al open siguiente
- Si earnings es POSITIVO pero guidance baja → salir al open siguiente
- Si earnings es POSITIVO y guidance up → mantener, ajustar stop a +5%

## 6.6 Forced Exit (Regimen Change)

- Si VIX sube > 40 mientras posición abierta → cerrar TODO al mercado siguiente
- Si daily loss cap (-2%) se alcanza → cerrar posiciones restantes, pausar

================================================================================
SECCIÓN 7: POSITION SIZING Y GESTIÓN DE RIESGO
================================================================================

## 7.1 Fórmula Base

```
POSITION_SIZE = (PORTFOLIO_VALUE × RISK_PER_TRADE) / STOP_DISTANCE

Donde:
- PORTFOLIO_VALUE = Valor actual del portfolio (cash + positions)
- RISK_PER_TRADE = 1.0% (default) o 1.5% (setup ideal 10/10)
- STOP_DISTANCE = 4% (0.04) o 5% si VIX > 25

EJEMPLO:
Portfolio: $10,000
Risk per trade: 1% = $100
Stop distance: 4%
Position size = $100 / 0.04 = $2,500

Esto significa: $2,500 en el trade, si cae -4% pierdes $100 (1% del portfolio)
```

## 7.2 Ajustes Dinámicos

| Condición | Multiplicador | Rationale |
|-----------|---------------|-----------|
| VIX > 25 | × 0.8 | Mercado más volátil |
| 3+ posiciones abiertas | × 0.6 | Diversificación forzada |
| Setup Score = 10/10 | × 1.2 | Convicción alta (max 5% total) |
| Setup Score < 7/10 | × 0.0 | NO ENTRAR |
| Weekly loss > -5% | × 0.5 | Reducir exposure |
| Monthly loss > -8% | × 0.0 | PAUSA MENSUAL |

## 7.3 Límites Absolutos

- MÁXIMO por posición: 5% del portfolio
- MÁXIMO exposure total: 50% del portfolio
- MÍNIMO cash reserve: 50% del portfolio
- MÁXIMO posiciones abiertas: 5
- MÁXIMO por sector: 30% del exposure

## 7.4 Ejemplos de Sizing

```
Escenario A: Portfolio $10,000, VIX 18, 2 posiciones abiertas, Score 8/10
- Base: ($10,000 × 0.01) / 0.04 = $2,500
- Ajustes: VIX 18 (no aplica), 2 pos (no aplica), Score 8 (no aplica)
- Resultado: $2,500 (25% del portfolio, dentro del 5% max? NO — limitar a $500)

Escenario B: Portfolio $10,000, VIX 22, 4 posiciones, Score 10/10
- Base: ($10,000 × 0.015) / 0.04 = $3,750
- Ajustes: VIX 22 (×0.8), 4 pos (×0.6), Score 10 (×1.2)
- Resultado: $3,750 × 0.8 × 0.6 × 1.2 = $2,160
- Limitar a 5% max: $500
- RESULTADO FINAL: $500
```

================================================================================
SECCIÓN 8: PORTFOLIO CONSTRUCTION
================================================================================

## 8.1 Estructura Objetivo

```
Portfolio $10,000:
├── Cash: $5,000 (50%)
├── Posición 1: $1,000 (10%) — AAPL
├── Posición 2: $1,000 (10%) — XOM
├── Posición 3: $1,000 (10%) — WMT
├── Posición 4: $1,000 (10%) — FANG
└── Posición 5: $1,000 (10%) — HAL
```

## 8.2 Rebalanceo

- NO rebalanceo automático diario
- Revisar weekly si alguna posición > 15% del portfolio (profit taking natural)
- Si cash > 60% por 5 días consecutivos → agresividad +20% (más oportunidades)

## 8.3 Correlation Check

- NO abrir posición si correlation > 0.8 con posición existente
- Ejemplo: Si tienes AAPL, NO abrir MSFT (tech correlation alta)
- Preferir diversificación: Tech + Energy + Healthcare + Financials + Consumer

================================================================================
SECCIÓN 9: GUARDRAILS (REGLAS DE PROTECCIÓN)
================================================================================

## 9.1 Guardrails en CÓDIGO (Scripts Shell)

Estas reglas están implementadas en scripts y NO pueden ser ignoradas por Claude:

```bash
#!/bin/bash
# guardrails.sh — Verificación antes de CUALQUIER trade

# 1. Verificar modo
if [ "$PAPER_MODE" != "true" ] && [ "$LIVE_TOGGLE" != "CONFIRMED" ]; then
    echo "ERROR: Paper mode default. Live requires explicit toggle."
    exit 1
fi

# 2. Verificar VIX
VIX=$(curl -s "$ALPACA_API/v1/bars?symbols=VIX" | jq '.VIX[0].c')
if (( $(echo "$VIX > 40" | bc -l) )); then
    echo "ERROR: VIX > 40. NO TRADING."
    exit 1
fi

# 3. Verificar daily loss
DAILY_PNL=$(python3 calculate_daily_pnl.py)
if (( $(echo "$DAILY_PNL < -0.02" | bc -l) )); then
    echo "ERROR: Daily loss cap -2% reached. Paused until tomorrow."
    exit 1
fi

# 4. Verificar drawdown
DRAWDOWN=$(python3 calculate_drawdown.py)
if (( $(echo "$DRAWDOWN > 0.10" | bc -l) )); then
    echo "ERROR: Max drawdown -10% reached. PAUSE ALL. Human review required."
    exit 1
fi

# 5. Verificar posiciones abiertas
OPEN_POSITIONS=$(python3 count_positions.py)
if [ "$OPEN_POSITIONS" -ge 5 ]; then
    echo "ERROR: Max 5 positions reached."
    exit 1
fi

# 6. Verificar exposure
EXPOSURE=$(python3 calculate_exposure.py)
if (( $(echo "$EXPOSURE > 0.50" | bc -l) )); then
    echo "ERROR: Max 50% exposure reached."
    exit 1
fi

# 7. Verificar trades esta semana
WEEKLY_TRADES=$(python3 count_weekly_trades.py)
if [ "$WEEKLY_TRADES" -ge 5 ]; then
    echo "ERROR: Max 5 trades/week reached."
    exit 1
fi

# 8. Verificar setup score
SCORE=$(python3 calculate_setup_score.py "$SYMBOL")
if [ "$SCORE" -lt 7 ]; then
    echo "ERROR: Setup score $SCORE < 7. NO ENTRY."
    exit 1
fi

echo "GUARDRAILS PASSED. Proceeding with trade."
exit 0
```

## 9.2 Guardrails en PROMPTS (Instrucciones a Claude)

Cada rutina incluye estas instrucciones en su prompt:

```
ANTES de cualquier acción de trading:
1. Lee TRADING-STRATEGY.md completo
2. Lee GUARDRAILS.md completo
3. Ejecuta scripts/guardrails.sh
4. Si guardrails.sh falla (exit != 0), ABORTAR rutina inmediatamente
5. Si guardrails.sh pasa, proceder con precaución

DURANTE el análisis:
- NO inventar datos de stock. Usar Alpaca API o Perplexity API.
- NO asumir que un stock cumple criterios. Verificar cada uno.
- NO proponer más de 2 candidatos por rutina (context budget).
- SIEMPRE calcular position size con la fórmula completa.

DESPUÉS de cualquier trade:
- Escribir reasoning COMPLETO en TRADE-LOG.md
- Incluir: por qué entré, qué vi, qué riesgo asumí
- Git commit inmediato
```

## 9.3 Circuit Breakers

| Trigger | Acción | Reset |
|---------|--------|-------|
| Daily loss > -2% | Pausar hasta mañana | Auto al siguiente día |
| Weekly loss > -5% | Reducir size 50% | Weekly review manual |
| Monthly loss > -8% | PAUSA MENSUAL | Human review obligatorio |
| Drawdown > -10% | Cerrar TODO, pausa | Human review obligatorio |
| 3 stops consecutivos | Pausar 2 días | Auto después de 2 días |
| VIX > 40 | Cerrar todo, cash 100% | VIX < 30 por 2 días |

================================================================================
SECCIÓN 10: LAS 5 RUTINAS DETALLADAS
================================================================================

## 10.1 RUTINA 1: PRE-MARKET RESEARCH (6:00 AM CT)

**Trigger:** Cron 0 6 * * 1-5
**Input:** TRADING-STRATEGY.md, WEEKLY-REVIEW.md, MARKET-REGIME.md
**Output:** RESEARCH-LOG.md
**Notifica:** ClickUp (solo si hay alerta crítica)

### Protocolo:

```
PASO 1: Verificar Regimen de Mercado
- Consultar VIX actual (Alpaca API)
- Si VIX > 40: Escribir "NO TRADING TODAY" en RESEARCH-LOG.md, SALIR
- Si VIX 30-40: Escribir "HIGH ALERT — Solo gestión" en RESEARCH-LOG.md

PASO 2: Investigación con Perplexity API
Query: "Market catalysts today [DATE], earnings reports, macro news"
Query: "Sectors with momentum today, volume leaders"
Query: "Analyst upgrades/downgrades today"

PASO 3: Screen de Candidatos
Para cada stock mencionado en research:
- Verificar Market Cap > $10B (Alpaca API)
- Verificar Revenue Growth > 10% (Perplexity o Alpaca fundamentals)
- Verificar Precio > 50-SMA y > 200-SMA (Alpaca bars)
- Verificar RSI 50-70 (calcular desde bars)
- Verificar Volume > 1.5x avg (Alpaca API)
- Verificar Catalyst en próximos 10 días
- Calcular Setup Quality Score

PASO 4: Construir Watchlist Priorizada
Máximo 5 candidatos, ordenados por Score descendente
Solo incluir si Score >= 7

PASO 5: Escribir RESEARCH-LOG.md
Formato:
## 2026-04-24 Pre-Market
- VIX: 22 (Caution)
- Regimen: Reduce size 20%
- Watchlist (Score):
  1. AAPL (9/10): Earnings mañana, >50-SMA, volume 2x
  2. XOM (8/10): Oil rally, breakout confirmed
  3. WMT (7/10): Defensive play, RSI 58
- NO operar: TSLA (Score 4, VIX sectorial alto)
- Alertas: FOMC minutes hoy 2pm (avoid new entries post-1pm)

PASO 6: Commit
- git add memory/RESEARCH-LOG.md
- git commit -m "pre-market: 3 candidates, VIX 22 caution"
- git push origin main
```

## 10.2 RUTINA 2: MARKET-OPEN EXECUTION (8:30 AM CT)

**Trigger:** Cron 30 8 * * 1-5
**Input:** RESEARCH-LOG.md, TRADE-LOG.md, TRADING-STRATEGY.md, GUARDRAILS.md
**Output:** TRADE-LOG.md (si trades)
**Notifica:** ClickUp (solo si trade ejecutado)

### Protocolo:

```
PASO 1: Verificaciones Iniciales
- Ejecutar scripts/guardrails.sh
- Si falla: ABORTAR, loguear razón, SALIR
- Leer posiciones actuales (Alpaca API)
- Si 5 posiciones abiertas: NO NUEVAS ENTRADAS, SALIR

PASO 2: Revisar Watchlist del Pre-Market
- Leer RESEARCH-LOG.md del día
- Verificar que candidatos siguen válidos post-open
- Descartar si gap down > -3% o gap up > +5% (evitar chasing)

PASO 3: Análisis Técnico Post-Open
Para cada candidato restante:
- Verificar open price vs plan
- Verificar que RSI sigue 50-70
- Verificar que volume sigue > 1.5x en primeros 15 min
- Recalcular Setup Quality Score con datos post-open

PASO 4: Decisión de Trade
Para cada candidato con Score >= 7:
- Calcular position size con fórmula completa
- Verificar exposure total < 50%
- Verificar sector diversification
- Preparar orden LIMIT (no market):
  * Buy limit = current price + 0.1% (evitar slippage)
  * Stop loss = entry price × 0.96 (-4%)

PASO 5: Ejecutar (si aplica)
- Colocar orden buy limit (Alpaca API)
- Colocar orden stop loss automático (Alpaca API)
- Confirmar fills (Alpaca API)

PASO 6: Documentar
Escribir en TRADE-LOG.md:
## 2026-04-24 Market-Open
- BUY AAPL: 28 shares @ $175.50 (limit fill)
  - Reason: Earnings mañana, Score 9/10, breakout confirmed
  - Position size: $4,914 (49.1% of portfolio? NO — limitar a $500)
  - CORRECTION: Size recalculado = $500 / $175.50 = 2.85 → 3 shares
  - Stop: $168.48 (-4%)
  - Risk: $21.06 (0.21% of portfolio)
  - Cash after: $9,500
- NO trades: XOM (gap up +6%, chasing avoided)

PASO 7: Commit (solo si trade)
- git add memory/TRADE-LOG.md
- git commit -m "market-open: BUY AAPL 3sh, VIX 22 caution"
- git push origin main

PASO 8: Notificar ClickUp (solo si trade)
- Enviar mensaje: "BUY AAPL 3sh @ $175.50 | Stop $168.48 | Risk 0.21%"
```

## 10.3 RUTINA 3: MIDDAY SCAN (12:00 PM CT)

**Trigger:** Cron 0 12 * * 1-5
**Input:** TRADE-LOG.md, posiciones actuales (Alpaca API)
**Output:** TRADE-LOG.md (si acciones)
**Notifica:** ClickUp (solo si acción)

### Protocolo:

```
PASO 1: Leer Estado Actual
- Posiciones abiertas (Alpaca API)
- TRADE-LOG.md (últimos entries)
- MARKET-REGIME.md (regimen actual)

PASO 2: Revisar Cada Posición
Para cada posición:
- Current P&L % (Alpaca API)
- Current price vs 50-SMA
- Volume hoy vs avg

PASO 3: Acciones Posibles

A. Si posición en -4%:
   → Stop loss ya ejecutado por Alpaca. Verificar fill.
   → Documentar en TRADE-LOG.md.

B. Si posición en +8%:
   → Vender 50% de posición (orden limit)
   → Mover stop a breakeven en resto
   → Documentar: "Partial profit AAPL, sold 50% @ +8%"

C. Si posición en +15%:
   → Vender 25% adicional (si queda > 25% original)
   → Trailing stop 10% en resto
   → Documentar

D. Si close below 50-SMA ayer:
   → Preparar orden de salida mañana al open
   → Documentar: "Technical exit signal AAPL, below 50-SMA"

E. Si posición lleva 10 días:
   → Si movimiento < ±5%: preparar salida mañana (time stop)
   → Documentar

PASO 4: NO NUEVAS ENTRADAS
- Midday es SOLO gestión de posiciones existentes
- NO analizar nuevos candidatos (context budget)

PASO 5: Commit (solo si acción)
- git add memory/TRADE-LOG.md
- git commit -m "midday: partial profit AAPL, time stop HAL"
- git push origin main
```

## 10.4 RUTINA 4: DAILY SUMMARY (3:00 PM CT)

**Trigger:** Cron 0 15 * * 1-5
**Input:** Todo
**Output:** TRADE-LOG.md (EOD block), MARKET-REGIME.md
**Notifica:** ClickUp (SIEMPRE)

### Protocolo:

```
PASO 1: Snapshot de Portfolio
- Portfolio value (Alpaca API)
- Cash balance
- Posiciones abiertas con P&L
- Day's P&L total

PASO 2: Benchmark
- SPY close price
- SPY daily change %
- Bot vs SPY (outperform/underperform)

PASO 3: Verificar Circuit Breakers
- Daily loss > -2%? → PAUSAR BOT MAÑANA
- Drawdown > -10%? → PAUSAR TODO, HUMAN REVIEW
- VIX subió > 30 durante el día? → Notificar alerta

PASO 4: Actualizar MARKET-REGIME.md
- VIX close
- S&P 500 vs 200-SMA
- Volume vs avg
- Próximos catalysts (FOMC, earnings)
- Regimen para mañana

PASO 5: Escribir EOD Block en TRADE-LOG.md

## EOD 2026-04-24
- Portfolio Value: $10,245.00
- Day P&L: +$245.00 (+2.45%)
- vs SPY: +1.20% → OUTPERFORM (+1.25% alpha)
- Cash: $5,500 (53.7%)
- Open Positions: 3
  - AAPL: 3sh @ $175.50 | Current $178.20 | P&L +$8.10 (+1.54%)
  - XOM: 5sh @ $120.00 | Current $118.50 | P&L -$7.50 (-1.25%)
  - WMT: 4sh @ $95.00 | Current $96.80 | P&L +$7.20 (+1.89%)
- Closed Today: HAL (time stop, -$12.30)
- Total Trades Today: 1 (BUY AAPL)
- Week Trades So Far: 2/5
- VIX: 22 (Caution regime continues)
- Regimen Tomorrow: Caution, reduce size 20%
- Notes: FOMC minutes caused volatility 2-3pm. Avoid entries post-FOMC.

PASO 6: Commit SIEMPRE
- git add memory/TRADE-LOG.md memory/MARKET-REGIME.md
- git commit -m "EOD 2026-04-24: +2.45%, 3 positions, VIX 22"
- git push origin main

PASO 7: Notificar ClickUp (SIEMPRE)
Mensaje:
"📊 EOD Summary 2026-04-24
Portfolio: $10,245 (+2.45%)
vs SPY: +1.25% alpha
Positions: 3 open
Cash: 54%
Week trades: 2/5
VIX: 22 (Caution)
Status: NORMAL"
```

## 10.5 RUTINA 5: WEEKLY REVIEW (Viernes 4:00 PM CT)

**Trigger:** Cron 0 16 * * 5
**Input:** Todo el historial de la semana
**Output:** WEEKLY-REVIEW.md, posibles edits a TRADING-STRATEGY.md
**Notifica:** ClickUp (SIEMPRE)

### Protocolo:

```
PASO 1: Compilar Métricas Semanales
- Total trades esta semana
- Win rate (trades ganadores / total trades)
- Average win % vs average loss %
- Max drawdown semanal (peak to trough)
- Sharpe ratio semanal (si calculable)
- vs SPY semanal
- Total P&L semanal

PASO 2: Análisis de Patrones
- ¿Overtrading? (> 5 trades = WARNING)
- ¿Sector concentration? (> 30% en un sector = WARNING)
- ¿Stops muy ajustados? (sacados prematuramente antes de rally)
- ¿Profit taking temprano? (vendido en +8% cuando iba a +20%)
- ¿Chasing? (entradas en gap up > 5%)

PASO 3: Lecciones Aprendidas
Identificar 1-3 lecciones CLAVE de la semana.
Ejemplos:
- "18 trades = worst week ever. OVERTRADING. Cap en 5."
- "Chased TSLA gap up +7%, perdió -5% después. NO chase gaps > 5%."
- "Trailing stop 10% sacó AAPL antes de earnings rally. Revisar trailing logic."

PASO 4: Proponer Edits a Estrategia
Si lección es crítica y recurrente:
- Proponer edit a TRADING-STRATEGY.md
- Proponer edit a GUARDRAILS.md
- Documentar reasoning en WEEKLY-REVIEW.md

PASO 5: Escribir WEEKLY-REVIEW.md

## Week 16 (Apr 14-18, 2026)
- Trades: 4 (within limit)
- Win Rate: 50% (2 wins, 2 losses)
- Avg Win: +12.3% | Avg Loss: -3.8%
- Risk/Reward: 3.2:1 (excellent)
- Max Drawdown: -4.2%
- Weekly P&L: +$340 (+3.4%)
- vs SPY: +2.1% (outperform)
- Sharpe (est): 1.4

LESSONS:
1. Partial profit at +8% worked well. AAPL went to +15%, captured 50%.
2. Time stop on HAL saved -2% additional loss. Good discipline.
3. Need better earnings date filter. Entered JPM day before earnings, 
   gap down -4% next day. Add: "NO entry within 24h of earnings."

STRATEGY EDITS PROPOSED:
- Add to TRADING-STRATEGY.md: "Minimum 48h buffer before earnings"
- Add to GUARDRAILS.md: "Check earnings calendar before entry"

NEXT WEEK FOCUS:
- VIX trending up. Maintain caution.
- Earnings season peak next week. Reduce size further.
- Watchlist: AAPL (post-earnings), XOM (oil momentum), PFE (healthcare defensive)

PASO 6: Commit SIEMPRE
- git add memory/WEEKLY-REVIEW.md
- git add memory/TRADING-STRATEGY.md (si edits)
- git add memory/GUARDRAILS.md (si edits)
- git commit -m "weekly-review W16: +3.4%, 4 trades, 3.2:1 RR"
- git push origin main

PASO 7: Notificar ClickUp (SIEMPRE)
Mensaje:
"📈 Weekly Review W16
P&L: +$340 (+3.4%)
Win Rate: 50% | RR: 3.2:1
Max DD: -4.2%
vs SPY: +2.1%
Status: ON TRACK
Focus: Earnings caution next week"
```

================================================================================
SECCIÓN 11: LOGS Y AUDIT TRAIL
================================================================================

## 11.1 Formato de Commit Messages

```
pre-market YYYY-MM-DD: [N candidates], [VIX level], [regimen]
market-open YYYY-MM-DD: [BUY/NO TRADE] [TICKER] [shares]@[price], [reason]
midday YYYY-MM-DD: [action taken or no-op], [positions affected]
EOD YYYY-MM-DD: [portfolio value], [day P&L%], [positions count], [VIX]
weekly-review YYYY-WW: [weekly P&L%], [trades count], [win rate], [RR ratio]
```

## 11.2 Estructura de Logs

```
/logs/
├── pre-market/
│   ├── 2026-04-24.log
│   └── ...
├── market-open/
├── midday/
├── eod/
└── errors/
    └── 2026-04-24-guardrails-fail.log
```

## 11.3 Retención de Datos

- TRADE-LOG.md: Mantener últimas 4 semanas en archivo principal
- Archivar mensualmente a `/archive/trade-log-2026-04.md`
- RESEARCH-LOG.md: Mantener última semana, archivar semanalmente
- WEEKLY-REVIEW.md: Mantener todo (es la memoria emocional)

================================================================================
SECCIÓN 12: EXPECTATIVAS Y MÉTRICAS DE ÉXITO
================================================================================

## 12.1 Targets Realistas (Año 1)

| Métrica | Target | Mínimo Aceptable |
|---------|--------|------------------|
| Annual Return | 20% | 12% |
| Sharpe Ratio | 1.2 | 0.8 |
| Max Drawdown | < 12% | < 20% |
| Win Rate | 50% | 40% |
| Avg Win : Avg Loss | 2.5:1 | 1.5:1 |
| Trades/Semana | 3-4 | < 6 |
| vs SPY | +8% alpha | +3% alpha |

## 12.2 Señales de Alerta (Revisar Estrategia)

- Win rate < 35% por 4 semanas consecutivas
- Sharpe < 0.5 por 2 meses
- Max drawdown > 15% en cualquier momento
- 3 circuit breakers de daily loss en una semana
- Underperform SPY por 8 semanas consecutivas

## 12.3 Señales de Éxito (Mantener Rumbo)

- Sharpe > 1.0 por 3 meses consecutivos
- Win rate > 45% y RR > 2:1
- Outperform SPY en 6 de 8 semanas
- Max drawdown < 10% en 6 meses
- Consistencia mensual (no meses de -10% seguidos)

================================================================================
SECCIÓN 13: KILL SWITCH Y EMERGENCIAS
================================================================================

## 13.1 Kill Switch Manual

Crear archivo `/emergency/PAUSE` en el repo:
- Si existe: TODAS las rutinas abortan inmediatamente
- Para activar: `touch /trading-routine/emergency/PAUSE`
- Para desactivar: `rm /trading-routine/emergency/PAUSE`

## 13.2 Auto-Pause Conditions

El bot se pausa automáticamente si:
- VIX > 40 (ya en guardrails)
- Daily loss > -2% (circuit breaker)
- Drawdown > -10% (circuit breaker)
- 3 stops consecutivos (pausa 2 días)
- Error en API de Alpaca por > 30 min (protección técnica)

## 13.3 Contacto de Emergencia

En .env (NO en git):
```
EMERGENCY_PHONE=+1234567890
EMERGENCY_EMAIL=trader@example.com
SLACK_WEBHOOK=https://hooks.slack.com/...
```

================================================================================
SECCIÓN 14: GLOSARIO
================================================================================

- **Alpha**: Retorno por encima del benchmark (SPY)
- **Beta**: Sensibilidad al mercado (target < 1.0)
- **Drawdown**: Caída desde peak hasta trough
- **Exposure**: % del portfolio en posiciones (target < 50%)
- **Position Size**: $ asignado a un trade
- **Risk per Trade**: % del portfolio en riesgo por trade (1%)
- **Setup Quality Score**: 1-10, mínimo 7 para entrar
- **Sharpe Ratio**: Retorno ajustado por volatilidad (target > 1.0)
- **Stop Loss**: Orden automática para limitar pérdida (-4%)
- **Time Stop**: Salida por tiempo máximo (10 días)
- **Trailing Stop**: Stop que sigue al precio (8-10% en winners)
- **VIX**: Índice de volatilidad del S&P 500

================================================================================
FIN DEL DOCUMENTO
================================================================================

> Última actualización: 2026-04-24
> Versión: 1.0
> Próxima revisión: Después de Week 1 de paper trading
