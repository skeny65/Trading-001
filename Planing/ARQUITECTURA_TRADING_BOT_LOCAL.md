# 🤖 AGENTE DE TRADING 24/7 — ARQUITECTURA PC LOCAL
## Documentación Completa de Flujo de Despliegue
### Basado en Claude Code + Claude Opus 4.7 | PC Local Windows/Linux/Mac

---

> **Última actualización:** 2026-04-25  
> **Versión:** 1.0  
> **Autor:** Basado en Nate Herk + Adaptación PC Local

---

## 📋 ÍNDICE

1. [Visión General del Sistema](#1-visión-general-del-sistema)
2. [Stack Tecnológico](#2-stack-tecnológico)
3. [Mentalidad: Archivos = Cerebro](#3-mentalidad-archivos--cerebro)
4. [Arquitectura de Memoria](#4-arquitectura-de-memoria)
5. [Flujo de Despliegue por Fases](#5-flujo-de-despliegue-por-fases)
6. [Setup por Sistema Operativo](#6-setup-por-sistema-operativo)
7. [Guardrails de Seguridad](#7-guardrails-de-seguridad)
8. [Flujo Diario Detallado](#8-flujo-diario-detallado)
9. [Modelo de Costos](#9-modelo-de-costos)
10. [Checklist de Despliegue](#10-checklist-de-despliegue)
11. [Diagrama de Secuencia](#11-diagrama-de-secuencia)
12. [Resolución de Problemas](#12-resolución-de-problemas)

---

## 1. VISIÓN GENERAL DEL SISTEMA

### 1.1 Concepto Central
> **"Los archivos SON el cerebro."**

Claude Code es un agente **stateless** (sin estado). Cada vez que una rutina se ejecuta, Claude "despierta" sin memoria previa. La persistencia y el aprendizaje se logran mediante un sistema de archivos markdown que funciona como memoria externa compartida entre todas las rutinas.

### 1.2 ¿Por qué PC Local en vez de VPS?

| Aspecto | VPS en la nube | PC Local |
|---------|---------------|----------|
| Costo mensual | $10-50/mes | $0 (hardware existente) |
| Latencia a APIs | Dependiente de red del VPS | Tu conexión doméstica |
| Control total | Limitado por proveedor | Completo |
| Dependencia 3rd party | Alta (Hostinger, AWS, etc.) | Ninguna |
| Requiere PC prendida | No | **Sí, 24/7** |
| Riesgo de apagón | Bajo | Medio (requiere UPS) |
| Acceso remoto | SSH | TeamViewer / RDP / AnyDesk |

### 1.3 Dos Modalidades de Ejecución en PC Local

Según la documentación oficial de Anthropic, Claude Code ofrece dos formas de ejecución programada local:

| Modo | Requiere UI abierta | Persistencia | Mejor para |
|------|---------------------|--------------|------------|
| **Desktop Scheduled Tasks** | Sí (app abierta) | Sobrevive reinicios de app | Desarrollo, testing visual |
| **CLI Headless + Task Scheduler/Cron** | No | Completa (background) | **Producción 24/7** |

> **Recomendación para trading:** Usar **CLI Headless + Task Scheduler** (Windows) o **Cron + Systemd** (Linux/Mac) para ejecución autónoma real.

### 1.4 Flujo de Datos Principal (PC Local)

```
┌─────────────────────────────────────────────────────────────┐
│                    TU PC (Windows/Linux/Mac)                 │
│                    SIEMPRE ENCENDIDA 24/7                    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  CLAUDE CODE CLI (Headless)                         │   │
│  │  npm install -g @anthropic-ai/claude-code           │   │
│  │                                                      │   │
│  │  • Se ejecuta vía Task Scheduler / Cron             │   │
│  │  • Sin interfaz gráfica                             │   │
│  │  • Escribe logs a archivos                          │   │
│  │  • Hace git push automático                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                  │
│  ┌────────────────────────┴─────────────────────────────┐   │
│  │  SCHEDULER (El "despertador")                        │   │
│  │                                                      │   │
│  │  WINDOWS: Task Scheduler                            │   │
│  │  • Crea tareas programadas para cada horario        │   │
│  │  • Ejecuta: claude -p C:\trading\routines\pre-market.md │   │
│  │                                                      │   │
│  │  LINUX/MAC: Cron (crontab) + Systemd                │   │
│  │  • Igual funcionalidad, sintaxis diferente          │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                  │
│  ┌────────────────────────┴─────────────────────────────┐   │
│  │  ARCHIVOS LOCALES (la "memoria" del bot)           │   │
│  │                                                      │   │
│  │  C:\trading-routine\ (Windows)                      │   │
│  │  ~/trading-routine/ (Linux/Mac)                     │   │
│  │    ├── memory/                                       │   │
│  │    ├── skills/                                       │   │
│  │    ├── routines/                                     │   │
│  │    ├── .env                                          │   │
│  │    └── CLAUDE.md                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                  │
│  ┌────────────────────────┴─────────────────────────────┐   │
│  │  GIT (backup a GitHub)                               │   │
│  │  • git push origin main (después de cada rutina)    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS API
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              SERVICIOS EXTERNOS (IGUAL QUE ANTES)            │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Alpaca    │    │  Perplexity │    │   ClickUp   │     │
│  │  (Trades)   │    │  (Research) │    │ (Notify)    │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. STACK TECNOLÓGICO

| Capa | Tecnología | Rol | Costo Est. |
|------|-----------|-----|------------|
| **AI Core** | Claude Opus 4.7 | Toma de decisiones, análisis fundamental | $100-200/mes (plan Max) |
| **Scheduler** | Task Scheduler (Win) / Cron (Linux/Mac) | Disparadores temporales | $0 |
| **CLI** | Claude Code CLI | Ejecución headless sin UI | Incluido en plan |
| **Broker** | Alpaca API | Ejecución de órdenes paper/live | $0 (paper) |
| **Research** | Perplexity API | Inteligencia de mercado | ~$20/mes |
| **Notificaciones** | ClickUp API | Resúmenes diarios y alertas | ~$5-10/mes |
| **Control de Versiones** | Git/GitHub | Backup y trazabilidad | $0 (repo privado) |
| **Infraestructura** | Tu PC local | Ejecución 24/7 | $0 (hardware existente) |

**Total estimado mensual: $125-230/mes**

---

## 3. MENTALIDAD: ARCHIVOS = CEREBRO

### 3.1 El Problema del Contexto

Cada rutina opera con un **presupuesto de ~200K tokens**:

| Consumidor | Tokens Aprox. |
|-----------|---------------|
| System prompt + instrucciones | ~10K |
| Strategy file | ~2K |
| Trade log (semana 4+) | ~8K+ |
| Research log | ~5K+ |
| API responses + web search | ~5K+ |
| **TOTAL antes de pensar** | **~25K+** |

> **Regla de oro:** Solo leer lo necesario para el trabajo específico de esa rutina.

### 3.2 Por qué los Archivos son el Edge

> "A human trader has a gut feel. Scar tissue. Emotional memory of getting burned. The agent has none of that. The weekly-review.md line that says '18 trades = worst week, overtrading' is what stops the next routine from overtrading."

La memoria no es solo almacenamiento. Es:
- **Personalidad:** Cómo el agente interpreta señales
- **Disciplina:** Qué no debe hacer bajo ninguna circunstancia
- **Scar tissue:** Lecciones codificadas de pérdidas reales
- **Evolución:** La estrategia mejora semana a semana

---

## 4. ARQUITECTURA DE MEMORIA

### 4.1 Estructura de Archivos (El "Cerebro")

```
trading-routine/
├── CLAUDE.md                  # Persona, objetivo, modo paper default
├── .env                       # API keys (NUNCA en git)
├── env.template               # Template sin valores reales
├── .gitignore                 # Excluye .env
│
├── strategy/
│   └── TRADING-STRATEGY.md    # Reglas de trading (la "constitución")
│
├── memory/
│   ├── RESEARCH-LOG.md        # Hallazgos de mercado por día
│   ├── TRADE-LOG.md           # Registro de todas las operaciones
│   ├── REASONING.md           # Razonamiento detrás de cada decisión
│   ├── BENCHMARK.md           # Tracking vs SPY
│   └── WEEKLY-REVIEW.md       # Análisis semanal y lecciones
│
├── routines/
│   ├── pre-market.md          # 7:00 AM CT
│   ├── market-open.md         # 8:30 AM CT
│   ├── midday.md              # 11:00 AM CT
│   ├── daily-summary.md       # 3:30 PM CT
│   └── weekly-review.md       # Viernes 4:00 PM CT
│
├── skills/
│   ├── research.md            # Skill: investigación con Perplexity
│   ├── trade.md               # Skill: ejecución con Alpaca
│   ├── journal.md             # Skill: logging de decisiones
│   ├── benchmark.md           # Skill: tracking de rendimiento
│   └── report.md              # Skill: notificaciones ClickUp
│
└── logs/                      # Logs de ejecución por rutina
    ├── pre-market.log
    ├── market-open.log
    ├── midday.log
    ├── daily-summary.log
    └── weekly-review.log
```

### 4.2 Ciclo de Vida de la Memoria

```
Rutina N (lee archivos) ──▶ Procesa (Opus 4.7) ──▶ Escribe archivos ──▶ Git push
     ▲                                                                        │
     └────────────────────── Rutina N+1 (lee archivos) ◄──────────────────────┘
```


---

## 5. FLUJO DE DESPLIEGUE POR FASES

### FASE 1: ESTRATEGIA (Manual, sin código)
**Duración:** 1-3 días | **Herramienta:** Papel y lápiz

#### Checklist Estratégica:
- [ ] **Migrando de otro agente:** Pedirle que exporte setup, señales y posiciones actuales
- [ ] **Trader manual:** Documentar en lenguaje natural:
  - ¿Cómo inviertes hoy?
  - ¿Qué dispara una compra?
  - ¿Qué dispara una venta?
  - ¿Cuál es tu tolerancia al riesgo?
- [ ] **Empezando de cero:** Darle a Claude el objetivo ("beat SPY") y dejar que proponga estrategia

> ⚠️ **ADVERTENCIA:** Esto NO es asesoría financiera. Opus 4.7 es top en análisis fundamental (64.4% benchmark), pero NO ESTÁ PROBADO para day trading. Mejor para swing/long-term.

---

### FASE 2: SCAFFOLD (Estructura Base)
**Duración:** ~10 minutos | **Herramienta:** Terminal + Claude Code

#### Paso 2.1: Crear Proyecto

**Windows:**
```powershell
mkdir C:\trading-routine
cd C:\trading-routine
git init
git remote add origin https://github.com/TU_USUARIO/trading-routine.git
mkdir memory skills routines logs
notepad CLAUDE.md
notepad .env
notepad env.template
notepad .gitignore
```

**Linux/Mac:**
```bash
mkdir ~/trading-routine
cd ~/trading-routine
git init
git remote add origin https://github.com/TU_USUARIO/trading-routine.git
mkdir -p memory skills routines logs
touch CLAUDE.md .env env.template .gitignore
```

#### Paso 2.2: Crear CLAUDE.md

```markdown
# CLAUDE.md

## Goal
Beat SPY (S&P 500 ETF) on risk-adjusted returns over a 12-month horizon.

## Persona
Analytical, risk-aware, fundamentals-driven. Never FOMO. Always verify before acting.

## Default Mode
PAPER TRADING. Real trading requires explicit toggle in .env: MODE=live

## Rules
1. Read TRADING-STRATEGY.md FIRST on every routine
2. Read relevant memory files ONLY for this routine's job
3. Write back to memory files after completing work
4. Git commit + push after every routine
5. Respect all guardrails in strategy file
```

#### Paso 2.3: Crear .env

```bash
# Alpaca
ALPACA_API_KEY=PK_xxxxxxxxxxxxxxxxxxxxxxxx
ALPACA_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Perplexity
PERPLEXITY_API_KEY=pplx-xxxxxxxxxxxxxxxxxxxxxxxx

# ClickUp
CLICKUP_API_KEY=pk_xxxxxxxxxxxxxxxxxxxxxxxx
CLICKUP_LIST_ID=123456789

# Modo: paper | live
MODE=paper

# Zona horaria (CT = Chicago Time)
TIMEZONE=America/Chicago
```

#### Paso 2.4: Crear .gitignore

```gitignore
.env
*.log
__pycache__/
*.pyc
.DS_Store
```

#### Paso 2.5: Crear env.template

```bash
ALPACA_API_KEY=
ALPACA_SECRET_KEY=
PERPLEXITY_API_KEY=
CLICKUP_API_KEY=
CLICKUP_LIST_ID=
MODE=paper
TIMEZONE=America/Chicago
```

---

### FASE 3: GUARDRAILS (Seguridad Primero)
**Duración:** 30 min | **Herramienta:** Claude Code + Prompts

#### 3.1 Guardrails en Código

| Regla | Implementación | Dónde vive |
|-------|---------------|------------|
| Paper mode default | `MODE=paper` en .env | Archivo .env |
| Máximo 5% por posición | Validación previa a cada orden | Skill `trade.md` |
| Límite diario -2% | Si P&L diario < -2%, halt automático | Skill `trade.md` |
| Máximo 3 trades/semana | Contador en TRADE-LOG.md | Skill `trade.md` |
| No opciones, nunca | Blacklist de instrumentos | Skill `trade.md` |

#### 3.2 Guardrails en Prompts (Inyección directa)

Cada archivo de rutina debe incluir:

```markdown
## CRITICAL GUARDRAILS (NO NEGOTIABLE)
- Read TRADING-STRATEGY.md FIRST before any action
- MODE is {{MODE}} from .env. If paper, ONLY paper orders
- Max 3 trades per week. Check TRADE-LOG.md count before trading
- Max 5% of portfolio per position. Check current exposure
- No options, ever. No crypto, ever. No margin, ever
- Daily loss cap: -2%. If reached, STOP and log reason
- Don't send ClickUp notification unless you actually traded
- Always verify position exists before selling
- Never trade first 30 minutes of market open (volatility)
```

> **El agente es "eager" (ansioso). Sin guardrails, operará en cada sesión.**

---

### FASE 4: SKILLS (Capacidades Modulares)
**Duración:** 1 hora | **Herramienta:** Claude Code

#### 4.1 Skill: `skills/research.md`

```markdown
# SKILL: RESEARCH

## Purpose
Gather market intelligence using Perplexity API for pre-market analysis.

## Input
- TRADING-STRATEGY.md (read universe and criteria)
- RESEARCH-LOG.md (last 3 entries only, for context)

## Process
1. Call Perplexity API with query:
   "Market outlook today, macro events, earnings surprises, 
    analyst upgrades in {{UNIVERSE}}, any catalysts in next 30 days"
2. Filter results against TRADING-STRATEGY.md criteria
3. Identify 3-5 potential watchlist candidates
4. Rate each: STRONG / MODERATE / WEAK signal

## Output
Append to RESEARCH-LOG.md:
```markdown
## 2026-04-25 Pre-Market
**Macro:** [summary]
**Watchlist:**
- TICKER: Signal strength, catalyst, price target
- TICKER: Signal strength, catalyst, price target
**Notes:** [anything unusual]
```

## Constraints
- Max 5K tokens for API call
- Only US equities from S&P 500 or NASDAQ 100
- No penny stocks (<$5)
```

#### 4.2 Skill: `skills/trade.md`

```markdown
# SKILL: TRADE EXECUTION

## Purpose
Execute trades via Alpaca API with full guardrail validation.

## Input
- TRADING-STRATEGY.md (rules)
- RESEARCH-LOG.md (today's signals)
- TRADE-LOG.md (check weekly trade count, open positions)
- .env (MODE, API keys)

## Pre-Trade Guardrails (MUST PASS ALL)
1. MODE check: If MODE=paper, use paper trading endpoint
2. Trade count: Count entries in TRADE-LOG.md this week. If >=3, STOP
3. Exposure check: Get portfolio from Alpaca. If any position >5%, STOP
4. Cash check: Ensure 20% minimum cash reserve
5. Daily P&L check: If today's P&L < -2%, HALT
6. Instrument check: NO options, NO crypto, NO foreign ADRs
7. Time check: If market open <30 minutes ago, WAIT

## Execution Process
1. Get account info from Alpaca API
2. Get current positions
3. For BUY decisions:
   - Calculate position size: min(5% of portfolio, available cash - 20% reserve)
   - Place market order (paper or live based on MODE)
   - Set trailing stop 10%
4. For SELL decisions:
   - Verify position exists
   - Place market order
   - Cancel any open stop orders

## Output
Append to TRADE-LOG.md:
```markdown
## 2026-04-25 08:35 CT | ACTION: BUY/SELL TICKER
**Reason:** [signal that triggered trade]
**Size:** [shares] @ [price]
**Stop:** [trailing stop %]
**Mode:** [paper/live]
**Result:** [filled/partial/rejected]
```

## Error Handling
- If API fails: Log error, retry once, notify ClickUp if persistent
- If order rejected: Log reason, do NOT retry automatically
- If position sizing fails: Log math, skip trade
```

#### 4.3 Skill: `skills/journal.md`

```markdown
# SKILL: JOURNAL

## Purpose
Log reasoning and decisions for future analysis.

## Input
- Decision made (buy/sell/hold)
- Rationale from Opus 4.7
- Market context at decision time

## Output
Append to REASONING.md:
```markdown
## 2026-04-25 08:35 CT | TICKER | ACTION
**Context:** [market conditions]
**Signal:** [what triggered the decision]
**Reasoning:** [Claude's thought process]
**Confidence:** [HIGH/MEDIUM/LOW]
**Alternative considered:** [what else was evaluated]
```
```

#### 4.4 Skill: `skills/benchmark.md`

```markdown
# SKILL: BENCHMARK

## Purpose
Track portfolio performance vs SPY benchmark.

## Input
- Alpaca API (portfolio value, positions)
- SPY closing price (Alpaca or Perplexity)

## Process
1. Get current portfolio value from Alpaca
2. Get SPY previous close
3. Calculate daily P&L: (today_value - yesterday_value) / yesterday_value
4. Calculate SPY daily return
5. Calculate alpha: portfolio_return - spy_return

## Output
Append to BENCHMARK.md:
```markdown
## 2026-04-25 EOD
**Portfolio Value:** $XX,XXX.XX
**Daily P&L:** +X.XX% ($XXX.XX)
**SPY Close:** $XXX.XX
**SPY Return:** +X.XX%
**Alpha:** +X.XX%
**YTD Return:** +X.XX%
**vs SPY YTD:** +X.XX%
```
```

#### 4.5 Skill: `skills/report.md`

```markdown
# SKILL: REPORT

## Purpose
Compile and send EOD summary to ClickUp.

## Input
- TRADE-LOG.md (today's activity)
- BENCHMARK.md (today's performance)
- RESEARCH-LOG.md (context)

## Process
1. Read today's entries from all memory files
2. Compile summary:
   - Trades executed (count, tickers, P&L)
   - Open positions (list, stops set)
   - Portfolio snapshot
   - vs SPY performance
   - Any alerts or issues
3. Format as ClickUp task comment or description

## Output
Send to ClickUp via API:
- List: {{CLICKUP_LIST_ID}}
- Task name: "Trading Summary - 2026-04-25"
- Content: Formatted markdown summary

## Constraints
- Only send if there was trading activity OR it's the daily-summary routine
- Keep under 2000 characters for mobile readability
```


---

### FASE 5: ROUTINES (Horarios de Trading)
**Duración:** 1 hora | **Herramienta:** Claude Code

#### Horarios CT (Chicago Time)

| Rutina | Hora CT | Función | Archivo |
|--------|---------|---------|---------|
| **Pre-market** | 7:00 AM | Research, build watchlist | `routines/pre-market.md` |
| **Market-open** | 8:30 AM | Decisiones, colocar trades | `routines/market-open.md` |
| **Midday** | 11:00 AM | Reassess, trim o add | `routines/midday.md` |
| **EOD** | 3:30 PM | Cerrar riesgosas, benchmark, report | `routines/daily-summary.md` |
| **Weekly-review** | Viernes 4:00 PM | Análisis semanal, lecciones | `routines/weekly-review.md` |

> **Regla crítica:** Espaciar rutinas >=30 min para evitar corrupción de archivos.

#### 5.1 Routine: `routines/pre-market.md`

```markdown
# ROUTINE: PRE-MARKET (7:00 AM CT)

## Trigger
Daily, 7:00 AM CT, weekdays only

## Context Budget
- Read: TRADING-STRATEGY.md (~2K tokens)
- Read: RESEARCH-LOG.md (last 2 entries only, ~3K tokens)
- Call: Perplexity API (~5K tokens response)
- Write: RESEARCH-LOG.md (~2K tokens)
- Total: ~12K tokens

## Instructions
1. Read TRADING-STRATEGY.md to understand universe and criteria
2. Read last 2 entries from RESEARCH-LOG.md for context
3. Call Perplexity API:
   "US stock market outlook for today {{DATE}}. 
    Macro events, Fed speakers, earnings before bell. 
    Any analyst upgrades or downgrades in S&P 500. 
    Sector rotation signals. Key levels for SPY, QQQ, IWM."
4. Process response with Opus 4.7:
   - Extract actionable signals
   - Filter against strategy criteria
   - Build watchlist of 3-5 candidates
5. Write RESEARCH-LOG.md entry for today
6. Git commit: "Pre-market research {{DATE}}"
7. Git push origin main

## Output Format (RESEARCH-LOG.md)
```markdown
## {{DATE}} Pre-Market | Generated {{TIME}}
**Macro:** [2-3 sentence summary]
**Earnings Today:** [list if any]
**Fed/Events:** [calendar items]
**Watchlist:**
| Ticker | Signal | Catalyst | Confidence |
|--------|--------|----------|------------|
| AAPL   | STRONG | Earnings beat | HIGH |
| MSFT   | MODERATE | Upgrade | MEDIUM |
**Avoid:** [anything negative]
**Notes:** [unusual activity]
```

## Error Handling
- If Perplexity API fails: Log error, use yesterday's context + web search fallback
- If git push fails: Retry once, log error if persistent
```

#### 5.2 Routine: `routines/market-open.md`

```markdown
# ROUTINE: MARKET-OPEN (8:30 AM CT)

## Trigger
Daily, 8:30 AM CT, weekdays only

## Context Budget
- Read: TRADING-STRATEGY.md (~2K)
- Read: RESEARCH-LOG.md (today's entry, ~3K)
- Read: TRADE-LOG.md (this week, ~5K)
- API calls: Alpaca positions + orders (~3K)
- Write: TRADE-LOG.md (~2K)
- Total: ~15K tokens

## Instructions
1. Read TRADING-STRATEGY.md
2. Read today's RESEARCH-LOG.md entry
3. Read this week's TRADE-LOG.md (count trades, check positions)
4. Call Alpaca API:
   - GET /v2/account (portfolio value, buying power)
   - GET /v2/positions (open positions, P&L)
   - GET /v2/orders (check for open orders)
5. Apply GUARDRAILS:
   - If MODE=paper: Use paper endpoint
   - If weekly trades >= 3: STOP, log "Weekly limit reached"
   - If daily P&L < -2%: HALT, log "Daily loss cap reached"
   - If any position > 5%: Do NOT add to it
   - If cash < 20% of portfolio: Do NOT buy
6. Evaluate signals from research:
   - Match against open positions (add/trim/close?)
   - Identify new opportunities
   - Check if any position hit target or stop
7. Execute decisions:
   - For BUY: Calculate size, place order, set trailing stop 10%
   - For SELL: Verify position, place order, cancel stops
   - For HOLD: Log reasoning
8. Write TRADE-LOG.md
9. Git commit + push
10. If trades executed: Call ClickUp API to notify

## Output Format (TRADE-LOG.md)
```markdown
## {{DATE}} 08:30 CT | MARKET-OPEN
**Portfolio Value:** $XX,XXX.XX
**Cash:** $X,XXX.XX (XX%)
**Open Positions:** [list]
**Decisions:**
- BUY TICKER: [shares] @ [price], reason, stop 10%
- SELL TICKER: [shares] @ [price], reason
- HOLD: [reasoning]
**Trades Executed:** [count]
**Status:** [active/halted]
```

## Error Handling
- If Alpaca API down: Log error, skip trading, notify ClickUp
- If order rejected: Log reason, do NOT retry
- If position check fails: Log error, trade with caution
```

#### 5.3 Routine: `routines/midday.md`

```markdown
# ROUTINE: MIDDAY (11:00 AM CT)

## Trigger
Daily, 11:00 AM CT, weekdays only

## Context Budget
- Read: TRADING-STRATEGY.md (~2K)
- Read: TRADE-LOG.md (today, ~3K)
- API: Alpaca positions (~2K)
- Write: TRADE-LOG.md (~2K)
- Total: ~9K tokens

## Instructions
1. Read TRADING-STRATEGY.md
2. Read today's TRADE-LOG.md
3. Call Alpaca API: GET /v2/positions
4. For each open position:
   - If unrealized P&L < -7%: PLACE MARKET SELL (hard stop)
   - If unrealized P&L > +10%: Adjust trailing stop to lock gains
   - If flat (between -3% and +5%): Hold, monitor
5. Check if any morning buy signals have deteriorated:
   - If thesis invalidated: Consider cutting early
6. Write TRADE-LOG.md with midday actions
7. Git commit + push
8. If actions taken: Notify ClickUp

## Output Format (TRADE-LOG.md)
```markdown
## {{DATE}} 11:00 CT | MIDDAY REVIEW
**Positions Reviewed:** [count]
**Actions:**
- CUT TICKER: -7% stop triggered, loss $XXX
- ADJUST STOP TICKER: New stop at $XX.XX
- HOLD: [reasoning]
**Portfolio Status:** [snapshot]
```

## Special Rules
- Midday is for RISK MANAGEMENT, not new entries
- Only add to position if strong conviction AND within guardrails
- Prefer cutting losers over adding to winners after 11 AM
```

#### 5.4 Routine: `routines/daily-summary.md`

```markdown
# ROUTINE: DAILY-SUMMARY (3:30 PM CT)

## Trigger
Daily, 3:30 PM CT, weekdays only

## Context Budget
- Read: TRADE-LOG.md (full day, ~5K)
- API: Alpaca portfolio + SPY close (~3K)
- Write: BENCHMARK.md + TRADE-LOG.md EOD block (~3K)
- ClickUp API (~1K)
- Total: ~12K tokens

## Instructions
1. Read full TRADE-LOG.md for today
2. Call Alpaca API:
   - GET /v2/account (final portfolio value)
   - GET /v2/positions (EOD positions)
3. Get SPY closing price (Alpaca API or Perplexity)
4. Calculate:
   - Daily P&L ($ and %)
   - vs SPY daily return
   - Alpha
   - YTD metrics
5. Write BENCHMARK.md entry
6. Append EOD block to TRADE-LOG.md
7. Compile summary for ClickUp
8. Git commit + push
9. Send to ClickUp (ALWAYS, even if no trades)

## Output Format (BENCHMARK.md)
```markdown
## {{DATE}} EOD
**Portfolio Value:** $XX,XXX.XX
**Daily P&L:** +X.XX% ($XXX.XX)
**SPY Close:** $XXX.XX | Return: +X.XX%
**Alpha:** +X.XX%
**YTD Return:** +X.XX% | vs SPY: +X.XX%
**Open Positions:** [count] | Exposure: XX%
**Cash:** $X,XXX.XX (XX%)
```

## Output Format (ClickUp Summary)
```
📊 Trading Summary - {{DATE}}

Trades: [count] | P&L: [amount] ([%])
vs SPY: [alpha%]
Open: [positions] | Cash: [XX%]

Key Events:
- [bullet points]

Tomorrow Focus:
- [watchlist items]
```

## Error Handling
- If ClickUp fails: Log error, retry once, queue for tomorrow
- If SPY data unavailable: Use previous close, note in log
```

#### 5.5 Routine: `routines/weekly-review.md`

```markdown
# ROUTINE: WEEKLY-REVIEW (Friday 4:00 PM CT)

## Trigger
Weekly, Friday 4:00 PM CT

## Context Budget
- Read: All memory files (~20K)
- Process: Opus 4.7 analysis (~10K)
- Write: WEEKLY-REVIEW.md + possible strategy edits (~5K)
- ClickUp API (~1K)
- Total: ~36K tokens (largest routine, monitor budget)

## Instructions
1. Read ALL memory files for the week:
   - RESEARCH-LOG.md (Monday-Friday)
   - TRADE-LOG.md (all entries)
   - REASONING.md (all entries)
   - BENCHMARK.md (all entries)
2. Analyze metrics:
   - Total trades executed
   - Win/loss ratio
   - Average win vs average loss
   - Max drawdown
   - Total P&L ($ and %)
   - vs SPY weekly performance
   - Alpha for the week
3. Identify patterns:
   - Overtrading? (compare to 3 trades/week limit)
   - Revenge trading? (losses followed by impulsive trades)
   - Missed signals? (research said buy, didn't execute)
   - Premature exits? (sold before target)
4. Extract lessons:
   - What worked?
   - What didn't?
   - What to change?
5. Write WEEKLY-REVIEW.md
6. If lessons warrant: Propose edits to TRADING-STRATEGY.md
   - Add new scar tissue entries
   - Adjust parameters if data supports
7. Git commit + push
8. Send summary to ClickUp

## Output Format (WEEKLY-REVIEW.md)
```markdown
# WEEKLY REVIEW: {{WEEK_START}} to {{WEEK_END}}

## Performance
**Trades:** [count] | **Win Rate:** [XX%]
**Avg Win:** $XXX | **Avg Loss:** $XXX | **R:R:** [ratio]
**Total P&L:** $XXX.XX ([X.XX%])
**vs SPY:** [alpha%]
**Max Drawdown:** [X.XX%]

## What Worked
- [pattern 1]
- [pattern 2]

## What Didn't
- [mistake 1]
- [mistake 2]

## Lessons (Scar Tissue)
- "[lesson 1]" → Added to TRADING-STRATEGY.md
- "[lesson 2]" → Added to TRADING-STRATEGY.md

## Strategy Changes
- [change 1]: [reasoning]
- [change 2]: [reasoning]

## Next Week Focus
- [priority 1]
- [priority 2]
```

## Error Handling
- If analysis exceeds token budget: Split into two runs (Friday + Saturday)
- If strategy edit controversial: Log proposal, require manual approval
```

---

### FASE 6: DEPLOY LOCAL (PC 24/7)
**Duración:** 45 min | **Herramienta:** Task Scheduler / Cron

#### 6.1 Requisitos de Hardware

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| RAM | 4GB | 8GB+ |
| CPU | Dual core | Quad core |
| Storage | 10GB libres | 50GB SSD |
| Network | WiFi estable | Ethernet cable |
| UPS | Opcional | **Obligatorio** (cortes de luz) |
| OS | Windows 10 / Ubuntu 20.04 | Windows 11 / Ubuntu 22.04 |

#### 6.2 Consideraciones Críticas para PC 24/7

| Problema | Solución |
|----------|----------|
| **Se apaga la luz** | UPS (batería de respaldo) + auto-start on boot |
| **Windows Update reinicia** | Configurar "Active hours" fuera de trading (ej: 2 AM - 5 AM) |
| **PC se duerme/suspende** | `powercfg /change standby-timeout-ac 0` (nunca dormir conectada) |
| **Cambio de IP** | No importa, APIs usan HTTPS |
| **Acceso remoto** | TeamViewer, AnyDesk, o Windows Remote Desktop |
| **Seguridad** | BitLocker (Windows) / LUKS (Linux) encriptación de disco |
| **Cierre de tapa (laptops)** | Configurar "Do nothing" al cerrar tapa en Power Options |


---

## 6. SETUP POR SISTEMA OPERATIVO

### OPCIÓN A: WINDOWS (Más común)

#### Paso A1: Instalar Node.js 20+

```powershell
# Descargar desde https://nodejs.org (versión LTS)
# Verificar instalación
node --version    # Debe decir v20.x.x o superior
npm --version     # Debe decir 10.x.x o superior
```

#### Paso A2: Instalar Claude Code CLI

```powershell
# Instalar globalmente
npm install -g @anthropic-ai/claude-code

# Verificar
claude --version

# Login (primera vez)
claude auth login
```

#### Paso A3: Crear Estructura de Carpetas

```powershell
# Crear carpeta principal
mkdir C:\trading-routine
cd C:\trading-routine

# Crear subcarpetas
mkdir memory
mkdir skills
mkdir routines
mkdir logs

# Crear archivos base (usar notepad, VS Code, o cualquier editor)
# CLAUDE.md, .env, env.template, .gitignore
# (Ver contenido en Fase 2)
```

#### Paso A4: Configurar Windows Task Scheduler

1. Presiona `Win + R`, escribe `taskschd.msc`, Enter.
2. En el panel derecho, click **Create Task** (NO "Create Basic Task")
3. Configurar cada rutina:

**Tab General:**
```
Name: Trading Bot - Pre-Market
Description: Research and watchlist building
Run whether user is logged on or not: [CHECKED]
Run with highest privileges: [CHECKED]
Configure for: Windows 10/11
```

**Tab Triggers:**
```
New Trigger:
- Begin the task: On a schedule
- Settings: Daily
- Start: 7:00:00 AM
- Recur every: 1 days
- Advanced: Stop task if it runs longer than 30 minutes
```

**Tab Actions:**
```
New Action:
- Action: Start a program
- Program/script: C:\Users\TU_USUARIO\AppData\Roaming\npm\claude.cmd
  (o donde esté instalado: where claude)
- Add arguments: -p C:\trading-routine\routines\pre-market.md
- Start in: C:\trading-routine
```

**Tab Conditions:**
```
[ ] Start the task only if the computer is on AC power
[ ] Stop if the computer switches to battery power
[X] Wake the computer to run this task
```

**Tab Settings:**
```
[X] Allow task to be run on demand
[X] Run task as soon as possible after a scheduled start is missed
[X] If the task fails, restart every: 5 minutes, up to 3 times
```

#### Paso A5: Crear las 5 Tareas Programadas

| Tarea | Trigger | Programa | Argumentos |
|-------|---------|----------|------------|
| Pre-market | Daily, 6:00 AM | claude.cmd | `-p C:\trading-routine\routines\pre-market.md` |
| Market-open | Daily, 8:30 AM | claude.cmd | `-p C:\trading-routine\routines\market-open.md` |
| Midday | Daily, 12:00 PM | claude.cmd | `-p C:\trading-routine\routines\midday.md` |
| Daily-summary | Daily, 3:00 PM | claude.cmd | `-p C:\trading-routine\routines\daily-summary.md` |
| Weekly-review | Weekly, Friday 4:00 PM | claude.cmd | `-p C:\trading-routine\routines\weekly-review.md` |

> **NOTA:** Todos los días de la semana (lunes a viernes) para las 4 primeras. La weekly-review solo viernes.

#### Paso A6: Configurar PC para 24/7

```powershell
# 1. Nunca suspender (conectado a corriente)
powercfg /change standby-timeout-ac 0

# 2. Nunca hibernar
powercfg /change hibernate-timeout-ac 0

# 3. Cerrar tapa = "Do nothing" (para laptops)
powercfg -setacvalueindex scheme_current sub_buttons lidaction 0
powercfg -setactive scheme_current

# 4. Desactivar apagado automático de disco
powercfg /change disk-timeout-ac 0

# 5. Configurar Windows Update Active Hours
# Settings > Windows Update > Active hours
# Set: 2:00 AM - 5:00 AM (fuera de trading)
```

---

### OPCIÓN B: LINUX (Ubuntu/Debian)

#### Paso B1: Instalar Node.js 20+

```bash
# NodeSource setup
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar
node --version    # v20.x.x
npm --version     # 10.x.x
```

#### Paso B2: Instalar Claude Code CLI

```bash
# Instalar globalmente
npm install -g @anthropic-ai/claude-code

# Verificar
claude --version

# Login
claude auth login
```

#### Paso B3: Crear Estructura

```bash
# Crear carpeta
mkdir ~/trading-routine
cd ~/trading-routine
git init
git remote add origin https://github.com/TU_USUARIO/trading-routine.git

# Subcarpetas
mkdir -p memory skills routines logs

# Archivos base
touch CLAUDE.md .env env.template .gitignore
```

#### Paso B4: Configurar Cron

```bash
# Editar crontab
crontab -e

# Añadir estas líneas (CT timezone, ajusta a tu zona):
# Pre-market: 6:00 AM CT (lunes a viernes)
0 6 * * 1-5 cd ~/trading-routine && /usr/bin/claude -p routines/pre-market.md >> logs/pre-market.log 2>&1

# Market-open: 8:30 AM CT
30 8 * * 1-5 cd ~/trading-routine && /usr/bin/claude -p routines/market-open.md >> logs/market-open.log 2>&1

# Midday: 12:00 PM CT
0 12 * * 1-5 cd ~/trading-routine && /usr/bin/claude -p routines/midday.md >> logs/midday.log 2>&1

# Daily-summary: 3:00 PM CT
0 15 * * 1-5 cd ~/trading-routine && /usr/bin/claude -p routines/daily-summary.md >> logs/daily-summary.log 2>&1

# Weekly-review: Viernes 4:00 PM CT
0 16 * * 5 cd ~/trading-routine && /usr/bin/claude -p routines/weekly-review.md >> logs/weekly-review.log 2>&1
```

#### Paso B5: Configurar Systemd (Más robusto que Cron)

```bash
# Crear servicio para cada rutina
sudo nano /etc/systemd/system/trading-pre-market.service
```

```ini
[Unit]
Description=Trading Bot - Pre-Market Research
After=network.target

[Service]
Type=oneshot
User=tu_usuario
WorkingDirectory=/home/tu_usuario/trading-routine
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/bin/claude -p routines/pre-market.md
StandardOutput=append:/home/tu_usuario/trading-routine/logs/pre-market.log
StandardError=append:/home/tu_usuario/trading-routine/logs/pre-market.log

[Install]
WantedBy=multi-user.target
```

```bash
# Timer para ejecutar a las 6:00 AM CT, lunes a viernes
sudo nano /etc/systemd/system/trading-pre-market.timer
```

```ini
[Unit]
Description=Run Pre-Market at 6:00 AM CT weekdays

[Timer]
OnCalendar=Mon-Fri 06:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
# Activar
sudo systemctl daemon-reload
sudo systemctl enable trading-pre-market.timer
sudo systemctl start trading-pre-market.timer

# Verificar timers activos
systemctl list-timers --all
```

#### Paso B6: Prevenir Suspensión (Linux)

```bash
# Desactivar suspensión
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# O usar xautolock si tienes GUI
# En /etc/systemd/logind.conf:
# HandleLidSwitch=ignore
# IdleAction=ignore
```

---

### OPCIÓN C: MAC (macOS)

#### Paso C1: Instalar Node.js 20+

```bash
# Usar Homebrew
brew install node@20

# Verificar
node --version
```

#### Paso C2: Instalar Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
claude --version
claude auth login
```

#### Paso C3: Crear Estructura

```bash
mkdir ~/trading-routine
cd ~/trading-routine
git init
mkdir -p memory skills routines logs
```

#### Paso C4: Configurar LaunchD (Reemplazo de Cron en Mac)

```bash
# Crear plist para pre-market
nano ~/Library/LaunchAgents/com.trading.premarket.plist
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.trading.premarket</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/claude</string>
        <string>-p</string>
        <string>/Users/tu_usuario/trading-routine/routines/pre-market.md</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/tu_usuario/trading-routine</string>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>6</integer>
        <key>Minute</key>
        <integer>0</integer>
        <key>Weekday</key>
        <integer>1</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/tu_usuario/trading-routine/logs/pre-market.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/tu_usuario/trading-routine/logs/pre-market.log</string>
</dict>
</plist>
```

```bash
# Cargar
launchctl load ~/Library/LaunchAgents/com.trading.premarket.plist

# Verificar
launchctl list | grep com.trading
```

#### Paso C5: Prevenir Suspensión (Mac)

```bash
# Terminal: nunca dormir (conectado)
sudo pmset -c sleep 0

# O usar caffeinate para mantener despierto durante trading hours
# (Añadir a un script wrapper)
```


---

## 7. GUARDRAILS DE SEGURIDAD

### 7.1 Capas de Protección (Defense in Depth)

```
┌─────────────────────────────────────┐
│  CAPA 1: PROMPT INJECTION          │
│  "No options, ever. Max 3 trades." │
├─────────────────────────────────────┤
│  CAPA 2: ENV VARIABLE              │
│  MODE=paper (default)              │
├─────────────────────────────────────┤
│  CAPA 3: CODE VALIDATION           │
│  Max 5% per position check         │
├─────────────────────────────────────┤
│  CAPA 4: API LEVEL                 │
│  Alpaca paper keys != live keys     │
├─────────────────────────────────────┤
│  CAPA 5: DAILY HALT                │
│  -2% daily loss = stop all routines│
├─────────────────────────────────────┤
│  CAPA 6: HUMAN OVERRIDE            │
│  GitHub webhook pause, manual review│
└─────────────────────────────────────┘
```

### 7.2 Archivo de Estrategia Ejemplo (TRADING-STRATEGY.md)

```markdown
# TRADING STRATEGY v1.0

## Philosophy
Fundamentals-driven swing trading. Beat SPY with lower volatility.

## Universe
- US Equities only (S&P 500 constituents preferred)
- Market cap > $10B
- NO: Options, futures, crypto, penny stocks, foreign ADRs

## Entry Signals
1. Earnings surprise > 10% with positive guidance
2. RSI(14) < 30 on daily timeframe (oversold quality names)
3. Analyst upgrades with price target > 15% upside
4. Perplexity research confirms positive catalyst within 30 days

## Exit Signals
1. Target price reached (trailing stop 10%)
2. Fundamental thesis invalidated (earnings miss, guidance cut)
3. -7% hard stop loss
4. Time stop: 30 days if no movement

## Position Sizing
- Max 5% of portfolio per position
- Max 3 positions open simultaneously
- Max 3 trades per week (entry + exit = 2 trades)

## Risk Management
- Daily loss cap: -2% of portfolio → HALT
- Weekly loss cap: -5% of portfolio → HALT + review strategy
- Cash reserve: minimum 20% always

## Scar Tissue (Lecciones Aprendidas)
- 2026-04-18: 18 trades en una semana = peor semana. OVERTRADING kills returns.
- 2026-04-15: Opciones = pérdida de $545. NO OPTIONS, EVER.
```

---

## 8. FLUJO DIARIO DETALLADO

### Timeline Completo (CT - Chicago Time)

```
06:00 AM ──► Task Scheduler ejecuta pre-market
            ├── Claude CLI se inicia (headless)
            ├── Lee TRADING-STRATEGY.md + RESEARCH-LOG.md
            ├── Llama Perplexity API (investigación)
            ├── Escribe RESEARCH-LOG.md
            ├── Git commit + push
            └── Se cierra (libera memoria)

08:30 AM ──► Task Scheduler ejecuta market-open
            ├── Lee TRADING-STRATEGY.md + RESEARCH-LOG.md
            ├── Verifica posiciones abiertas (Alpaca API)
            ├── Decide trades según estrategia
            ├── Pasa guardrails (validaciones)
            ├── Ejecuta trades (Alpaca API)
            ├── Setea trailing stops 10%
            ├── Escribe TRADE-LOG.md
            ├── Git commit + push
            ├── Notifica ClickUp (solo si hubo trades)
            └── Se cierra

12:00 PM ──► Task Scheduler ejecuta midday
            ├── Lee TRADING-STRATEGY.md + TRADE-LOG.md
            ├── Revisa posiciones: ¿alguna en -7%?
            ├── Corta perdedores (-7%)
            ├── Ajusta stops en ganadores
            ├── Escribe TRADE-LOG.md
            ├── Git commit + push
            ├── Notifica ClickUp (solo si hubo acción)
            └── Se cierra

15:00 PM ──► Task Scheduler ejecuta daily-summary
            ├── Lee TRADE-LOG.md
            ├── Toma snapshot de portfolio (Alpaca API)
            ├── Compara vs SPY (benchmark)
            ├── Escribe TRADE-LOG.md (EOD block)
            ├── Escribe BENCHMARK.md
            ├── Git commit + push
            ├── Envía resumen a ClickUp (siempre)
            └── Se cierra

Viernes 16:00 ──► Task Scheduler ejecuta weekly-review
            ├── Lee toda la memoria de la semana
            ├── Analiza métricas: trades, P&L, lecciones
            ├── Escribe WEEKLY-REVIEW.md
            ├── Posiblemente edita TRADING-STRATEGY.md
            ├── Git commit + push
            ├── Envía resumen a ClickUp (siempre)
            └── Se cierra
```

---

## 9. MODELO DE COSTOS

### 9.1 Anthropic (Claude Opus 4.7)

| Uso | Estimación |
|-----|-----------|
| 5 rutinas/día x 5 días/semana | 25 ejecuciones/semana |
| Tokens por rutina | ~50K-150K |
| Costo aproximado | $100-200/mes (plan Max) |

### 9.2 APIs Externas

| Servicio | Costo |
|----------|-------|
| Alpaca | $0 (paper/live sin comisiones en equities) |
| Perplexity | ~$20/mes (API tier) |
| ClickUp | ~$5-10/mes (plan con API) |

### 9.3 Infraestructura

| Componente | Costo |
|------------|-------|
| PC Local | $0 (hardware existente) |
| Electricidad 24/7 | ~$15-30/mes (depende de consumo) |
| UPS (recomendado) | $50-100 (compra única) |
| Internet | $0 (ya lo tienes) |

### 9.4 Total Estimado

| Escenario | Costo Mensual |
|-----------|--------------|
| **Mínimo** | $125/mes |
| **Recomendado** | $180/mes |
| **Máximo** | $240/mes |

---

## 10. CHECKLIST DE DESPLIEGUE

### Pre-Despliegue
- [ ] Estrategia documentada en papel y validada mentalmente
- [ ] Cuenta Alpaca creada (paper trading primero)
- [ ] API keys de Alpaca, Perplexity, ClickUp obtenidas
- [ ] Cuenta Anthropic con plan Max activo
- [ ] PC dedicada identificada (no tu laptop de trabajo diario)
- [ ] PC conectada 24/7 a corriente
- [ ] UPS adquirido y configurado (recomendado)
- [ ] Conexión a internet estable (ethernet preferido)
- [ ] GitHub repo privado creado

### Setup Inicial
- [ ] Node.js 20+ instalado y funcionando
- [ ] Claude Code CLI instalado (`npm install -g @anthropic-ai/claude-code`)
- [ ] `claude auth login` completado
- [ ] Estructura de carpetas creada (`C:\trading-routine` o `~/trading-routine`)
- [ ] CLAUDE.md escrito con persona y goal claros
- [ ] .env configurado (MODE=paper)
- [ ] env.template creado
- [ ] TRADING-STRATEGY.md completo con guardrails
- [ ] Archivos de memoria inicializados (vacíos pero existentes)
- [ ] Git init + remote configurado
- [ ] `.gitignore` excluye `.env` y `*.log`

### Skills y Routines
- [ ] 5 skills creados (`skills/research.md`, `trade.md`, `journal.md`, `benchmark.md`, `report.md`)
- [ ] 5 routines creadas (`routines/pre-market.md`, `market-open.md`, `midday.md`, `daily-summary.md`, `weekly-review.md`)
- [ ] Cada routine incluye: read → process → write → git → notify
- [ ] Cada routine tiene guardrails en prompt

### Scheduler Configurado
- [ ] **Windows:** 5 tareas en Task Scheduler creadas
  - [ ] Pre-market: 6:00 AM, lunes-viernes
  - [ ] Market-open: 8:30 AM, lunes-viernes
  - [ ] Midday: 12:00 PM, lunes-viernes
  - [ ] Daily-summary: 3:00 PM, lunes-viernes
  - [ ] Weekly-review: Friday 4:00 PM
- [ ] **Linux/Mac:** Cron o Systemd timers configurados
- [ ] PC configurada para no suspender/hibernar
- [ ] Windows Update active hours configurados fuera de trading
- [ ] Cierre de tapa = "Do nothing" (si es laptop)

### Testing
- [ ] Ejecutar pre-market manualmente: `claude -p routines/pre-market.md`
- [ ] Verificar que RESEARCH-LOG.md se escribe correctamente
- [ ] Ejecutar market-open manualmente (paper mode)
- [ ] Verificar que TRADE-LOG.md se escribe correctamente
- [ ] Verificar que Alpaca recibe órdenes en paper mode
- [ ] Verificar que git push funciona automáticamente
- [ ] Verificar que ClickUp recibe notificación
- [ ] Simular -7% stop loss, verificar que se ejecuta
- [ ] Simular -2% daily loss, verificar HALT
- [ ] Ejecutar weekly-review manualmente, verificar formato

### Producción
- [ ] Paper trading por 1-2 semanas mínimo
- [ ] Revisar logs diariamente (primeras 2 semanas)
- [ ] Verificar que Task Scheduler/Cron ejecuta a tiempo
- [ ] Verificar que PC no se apaga ni entra en suspensión
- [ ] Cambiar a MODE=live (solo después de validación completa)
- [ ] Configurar alertas de uptime (si PC se apaga)
- [ ] Backup del repo en GitHub verificado


---

## 11. DIAGRAMA DE SECUENCIA COMPLETO

```
TIEMPO ─────────────────────────────────────────────────────────────►

06:00 CT  ┌─────────┐
          │  CRON   │────▶ claude -p routines/pre-market.md
          │  /TS    │              │
          └─────────┘              ▼
                          ┌─────────────────┐
                          │  READ:          │
                          │  TRADING-STRATEGY│
                          │  RESEARCH-LOG   │
                          └────────┬────────┘
                                   ▼
                          ┌─────────────────┐
                          │  CALL:          │
                          │  Perplexity API │
                          │  (research)     │
                          └────────┬────────┘
                                   ▼
                          ┌─────────────────┐
                          │  WRITE:         │
                          │  RESEARCH-LOG   │
                          │  git push       │
                          └─────────────────┘

08:30 CT  ┌─────────┐
          │  CRON   │────▶ claude -p routines/market-open.md
          │  /TS    │              │
          └─────────┘              ▼
                          ┌─────────────────┐
                          │  READ:          │
                          │  TRADING-STRATEGY│
                          │  RESEARCH-LOG   │
                          │  TRADE-LOG      │
                          └────────┬────────┘
                                   ▼
                          ┌─────────────────┐
                          │  CALL:          │
                          │  Alpaca API     │
                          │  (positions)    │
                          └────────┬────────┘
                                   ▼
                          ┌─────────────────┐
                          │  GUARDRAILS     │
                          │  CHECK          │
                          │  (5% max, etc)  │
                          └────────┬────────┘
                                   ▼
                          ┌─────────────────┐
                          │  DECISION:      │
                          │  Trade? Yes/No  │
                          └────────┬────────┘
                                   ▼
                          ┌─────────────────┐
                          │  CALL:          │
                          │  Alpaca API     │
                          │  (orders)       │
                          └────────┬────────┘
                                   ▼
                          ┌─────────────────┐
                          │  WRITE:         │
                          │  TRADE-LOG      │
                          │  git push       │
                          │  ClickUp notify │
                          └─────────────────┘

12:00 CT  ┌─────────┐
          │  CRON   │────▶ claude -p routines/midday.md
          │  /TS    │     (reassess, trim, stop loss)
          └─────────┘

15:00 CT  ┌─────────┐
          │  CRON   │────▶ claude -p routines/daily-summary.md
          │  /TS    │     (benchmark, report)
          └─────────┘

Vie 16:00 ┌─────────┐
          │  CRON   │────▶ claude -p routines/weekly-review.md
          │  /TS    │     (analysis, strategy update)
          └─────────┘
```

---

## 12. RESOLUCIÓN DE PROBLEMAS

### Problemas Comunes y Soluciones

| Problema | Causa Probable | Solución |
|----------|---------------|----------|
| **Rutina no ejecuta a tiempo** | PC en suspensión | Verificar power settings, desactivar suspensión |
| **Claude CLI no encontrado** | PATH no configurado | Usar ruta absoluta en Task Scheduler/Cron |
| **Git push falla** | Sin credenciales | Configurar SSH key o git credential helper |
| **Alpaca API error** | Keys incorrectas | Verificar `.env`, regenerar keys si necesario |
| **Perplexity sin respuesta** | Límite de rate | Esperar y reintentar, verificar plan API |
| **ClickUp no notifica** | List ID incorrecto | Verificar en ClickUp settings, probar con curl |
| **Token budget exceeded** | Leyendo archivos grandes | Limitar lectura a últimas entradas |
| **Corrupción de archivos** | Dos rutinas simultáneas | Verificar espaciado >=30 min entre rutinas |
| **Orden rechazada en Alpaca** | Insuficiente buying power | Verificar cash reserve, modo paper vs live |
| **PC se reinició sola** | Windows Update | Configurar Active Hours, desactivar auto-restart |
| **Logs vacíos** | Redirección incorrecta | Verificar path en Task Scheduler/Cron |
| **Claude tarda mucho** | Modelo lento o tokens altos | Reducir contexto, usar modelo más rápido |

### Comandos de Diagnóstico

**Windows:**
```powershell
# Verificar tareas programadas
Get-ScheduledTask | Where-Object {$_.TaskName -like "Trading*"}

# Ver última ejecución
Get-ScheduledTaskInfo -TaskName "Trading Bot - Pre-Market"

# Ver logs en tiempo real
Get-Content C:\trading-routine\logs\pre-market.log -Wait

# Verificar Claude instalado
where claude
claude --version

# Probar rutina manualmente
claude -p C:\trading-routine\routines\pre-market.md
```

**Linux/Mac:**
```bash
# Verificar cron jobs
crontab -l

# Ver logs
tail -f ~/trading-routine/logs/pre-market.log

# Verificar timers systemd
systemctl list-timers --all

# Probar rutina manualmente
claude -p ~/trading-routine/routines/pre-market.md

# Verificar git status
cd ~/trading-routine && git status
```

---

## 📎 APÉNDICE: ARCHIVOS DE CONFIGURACIÓN COMPLETOS

### A. CLAUDE.md (Completo)

```markdown
# CLAUDE.md — Trading Agent Configuration

## Identity
You are an autonomous trading agent operating on Claude Opus 4.7. 
Your goal is to generate risk-adjusted returns that beat SPY over a 12-month horizon.

## Persona
- Analytical: You verify data before acting
- Risk-aware: You prioritize capital preservation
- Disciplined: You follow strategy rules without exception
- Patient: You wait for high-conviction setups
- Humble: You learn from losses and adapt

## Default Mode
PAPER TRADING. Real trading requires explicit toggle in .env: MODE=live

## Operating Rules
1. ALWAYS read TRADING-STRATEGY.md FIRST on every routine
2. ONLY read memory files relevant to current routine's job
3. ALWAYS write back to memory files after completing work
4. ALWAYS git commit + push after every routine
5. NEVER override guardrails without explicit human approval
6. NEVER trade options, crypto, or leveraged instruments
7. ALWAYS verify position exists before placing sell orders
8. NEVER exceed 5% portfolio allocation per position
9. ALWAYS maintain minimum 20% cash reserve
10. STOP all trading if daily P&L < -2%

## Context Budget
You have ~200K tokens per routine. Budget wisely:
- System + instructions: ~10K
- Strategy file: ~2K
- Relevant memory: ~10-15K
- API responses: ~5-10K
- Leave room for reasoning and output

## Output Standards
- Always use structured markdown
- Include timestamps in CT (Chicago Time)
- Log reasoning for every decision
- Flag any guardrail violations or edge cases
```

### B. TRADING-STRATEGY.md (Template)

```markdown
# TRADING STRATEGY v1.0

## Philosophy
[Describe your trading philosophy: value, growth, momentum, etc.]

## Universe
- [ ] US Equities only
- [ ] Market cap > $X
- [ ] Exclusions: [list instruments you NEVER trade]

## Entry Signals
1. [Signal 1]
2. [Signal 2]
3. [Signal 3]

## Exit Signals
1. [Exit 1]
2. [Exit 2]
3. [Exit 3]

## Position Sizing
- Max X% per position
- Max X positions open
- Max X trades per week

## Risk Management
- Daily loss cap: X%
- Weekly loss cap: X%
- Cash reserve: minimum X%

## Scar Tissue (Lessons Learned)
- [Date]: [Lesson learned from loss/mistake]
```

### C. Comando de Prueba Rápida

```bash
# Probar todo el flujo manualmente (paper mode)
cd ~/trading-routine  # o C:\trading-routine

# 1. Pre-market
claude -p routines/pre-market.md

# 2. Market-open
claude -p routines/market-open.md

# 3. Midday
claude -p routines/midday.md

# 4. Daily-summary
claude -p routines/daily-summary.md

# 5. Weekly-review (solo viernes)
claude -p routines/weekly-review.md
```

---

## 🎯 RESUMEN EJECUTIVO

### Qué estamos construyendo
Un agente de trading autónomo 24/7 que:
- **Investiga** el mercado cada mañana (Perplexity API)
- **Ejecuta** trades disciplinados (Alpaca API)
- **Gestiona** riesgo con stops automáticos
- **Aprende** de sus errores (archivos markdown)
- **Reporta** resultados diarios (ClickUp)

### Cómo funciona
1. Tu PC está prendida 24/7
2. Task Scheduler/Cron dispara rutinas en horarios específicos
3. Cada rutina es una sesión de Claude Opus 4.7 que:
   - Lee archivos de memoria (estrategia + logs)
   - Toma decisiones basadas en reglas
   - Ejecuta acciones (API calls)
   - Escribe resultados de vuelta
   - Hace git push
4. La siguiente rutina lee lo que la anterior escribió

### Por qué funciona
- **Stateless:** Cada ejecución es independiente, no hay estado corrupto
- **Auditado:** Todo queda en git, puedes revisar cualquier decisión
- **Evolucionable:** La estrategia mejora semana a semana
- **Seguro:** Múltiples capas de guardrails protegen capital

### Próximos pasos
1. ✅ Definir estrategia (Fase 1)
2. ✅ Crear scaffold (Fase 2)
3. ⬜ Implementar guardrails (Fase 3)
4. ⬜ Crear skills (Fase 4)
5. ⬜ Crear routines (Fase 5)
6. ⬜ Configurar scheduler (Fase 6)
7. ⬜ Testear en paper mode
8. ⬜ Ir a live trading

---

> **"Lose the files, lose the lessons. The files ARE the edge."**
> 
> — Nate Herk

---

*Documento generado para uso con Claude Code Desktop/CLI.*
*Compatible con lectura en terminal mediante `cat` o `type`.*
