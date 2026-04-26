# Trading-001

Utilidades para diagnosticar y mitigar fallos de push cuando una integracion
(rutina/proxy/MCP) tiene permisos de solo lectura en GitHub.

## Problema tipico

Si el push falla con errores como:

- `403 Resource not accessible by integration`
- `Permission denied`

entonces el problema no suele ser del codigo ni del commit, sino del contexto de
autenticacion de la rutina (token/proxy sin permisos de escritura).

## Solucion implementada

Se agregaron scripts en `scripts/`:

- `diagnose-github-write.ps1`: valida remoto, detecta proxy local y prueba
	autorizacion de lectura/escritura.
- `push-with-backoff.ps1`: intenta push con backoff exponencial y corta rapido
	cuando detecta un 403 persistente por permisos.

## Uso

Desde la raiz del repo:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\diagnose-github-write.ps1
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\push-with-backoff.ps1 -Branch main -SetUpstream
```

Para una rama especifica:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\push-with-backoff.ps1 -Branch claude/keen-cray-begtT -Remote origin -SetUpstream
```

## Que corregir en la rutina cuando hay 403

1. Confirmar que el conector/token tenga `Contents: Read and write`.
2. Confirmar que la integracion apunta al repo correcto y cuenta correcta.
3. Si hay proxy local (ej. `http://127.0.0.1:*`), verificar que no este en modo
	 read-only para operaciones de push.
4. Si hay reglas de proteccion de rama, hacer push a rama feature y abrir PR.
5. Si el entorno de rutina sigue bloqueado, empujar desde shell local con
	 credenciales validas.

## Workflow en GitHub Actions

Se agrego el workflow [GitHub Write Check](.github/workflows/github-write-check.yml).

Permite:

1. Ejecutar diagnostico de permisos (`diagnose-github-write.ps1`).
2. Opcionalmente hacer push con backoff (`push-with-backoff.ps1`).

Como usarlo:

1. Ir a la pestana Actions del repo.
2. Ejecutar `GitHub Write Check` con `Run workflow`.
3. Definir `branch` (por ejemplo `claude/keen-cray-begtT`).
4. Si quieres push real, poner `perform_push=true`.

Nota: el workflow declara `permissions: contents: write`, pero si tu org/repo
restringe permisos de `GITHUB_TOKEN` o requiere reglas adicionales, puede seguir
fallando con 403 y deberas ajustar politicas de repositorio/organizacion.

## Flujo elegido: rutina escribe via GitHub Actions

Para evitar que la rutina haga commit directo, se agrego:

- [Routine Result To test.txt](.github/workflows/routine-to-test-file.yml)

Este workflow hace:

1. Recibe el resultado de rutina.
2. Agrega una linea en [test.txt](test.txt) con timestamp + source + result.
3. Hace commit y push desde `github-actions[bot]`.

### Disparo manual (prueba rapida)

1. Ir a Actions.
2. Ejecutar `Routine Result To test.txt`.
3. Cargar:
	 - `result`: por ejemplo `status=no_signal; confidence=0.61`
	 - `source`: por ejemplo `claude-routine`

### Disparo automatico (desde tu rutina)

El workflow tambien acepta `repository_dispatch` con tipo `routine_result`.
Payload esperado:

```json
{
	"event_type": "routine_result",
	"client_payload": {
		"source": "claude-routine",
		"result": "status=no_signal; confidence=0.61"
	}
}
```

Si este workflow falla por 403, entonces el bloqueo esta en permisos de
`GITHUB_TOKEN` a nivel repo/org (no en la logica del flujo).

## Claude API paso a paso

Para usar el workflow [Claude Edit Test](.github/workflows/claude-edit-test.yml):

1. Crear API key en Anthropic.
2. Ir a GitHub repo -> Settings -> Secrets and variables -> Actions.
3. Click en `New repository secret`.
4. Name: `CLAUDE_API_KEY`.
5. Value: pega tu API key de Anthropic.
6. Guardar.
7. Ir a Actions -> `Claude Edit Test` -> `Run workflow`.
8. Completar `prompt` (ej: `Linea de prueba desde rutina`).
9. Ejecutar y verificar que cree commit actualizando [test.txt](test.txt).

Si ejecutas un workflow y no ves cambios locales, sincroniza:

```powershell
git pull --rebase origin main
```