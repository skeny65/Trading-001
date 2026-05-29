#!/bin/bash

# ── Configuración ──────────────────────────────────────
WEBHOOK_URL="http://localhost:3000/webhook"
LOG_FILE="$HOME/claude-scheduler/log.txt"

# ── Ejecutar Claude Code ────────────────────────────────
RESPONSE=$(claude -p "¿Qué hora es ahora mismo? Responde SOLO en JSON con este formato exacto: {\"hora\": \"HH:MM:SS\", \"fecha\": \"YYYY-MM-DD\", \"timestamp\": 0}" 2>/dev/null)

# ── Enviar al webhook ───────────────────────────────────
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$RESPONSE")

# ── Log ─────────────────────────────────────────────────
echo "[$(date)] HTTP $HTTP_CODE → $RESPONSE" >> "$LOG_FILE"
