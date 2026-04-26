param(
    [string]$Remote = "origin"
)

$ErrorActionPreference = "Continue"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Run-Git {
    param([string[]]$GitArgs)
    $output = & git @GitArgs 2>&1
    return [string]::Join("`n", $output)
}

Write-Section "Repositorio actual"
$repoRoot = (Run-Git -GitArgs @("rev-parse", "--show-toplevel")).Trim()
if (-not $repoRoot) {
    throw "No se detecto un repositorio git en este directorio."
}
Write-Host "Repo: $repoRoot"

Write-Section "Rama actual"
$branch = (Run-Git -GitArgs @("rev-parse", "--abbrev-ref", "HEAD")).Trim()
Write-Host "Branch: $branch"

Write-Section "Remote"
$remoteUrl = (Run-Git -GitArgs @("remote", "get-url", $Remote)).Trim()
Write-Host "$Remote -> $remoteUrl"

$isProxy = $remoteUrl -match "^http://127\.0\.0\.1:\d+"
if ($isProxy) {
    Write-Host "Detectado proxy local. Si este proxy esta en modo read-only, todo push devolvera 403." -ForegroundColor Yellow
}

Write-Section "Prueba de lectura (ls-remote)"
$readOutput = Run-Git -GitArgs @("ls-remote", "--heads", $Remote)
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: lectura/autenticacion de fetch funcional."
} else {
    Write-Host "FALLO lectura: $readOutput" -ForegroundColor Red
    exit 2
}

Write-Section "Prueba de escritura (push --dry-run)"
$testRef = "refs/heads/__write_test_$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
$writeOutput = Run-Git -GitArgs @("push", "--dry-run", $Remote, "HEAD:$testRef")
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: el remoto acepta escritura (dry-run)."
    Write-Host "Puedes hacer push real cuando quieras."
    exit 0
}

Write-Host $writeOutput -ForegroundColor DarkYellow
if ($writeOutput -match "403|not accessible by integration|permission denied|write access") {
    Write-Host ""
    Write-Host "Diagnostico: permisos de escritura bloqueados en la integracion/token/proxy." -ForegroundColor Red
    Write-Host "Acciones sugeridas:" -ForegroundColor Yellow
    Write-Host "1) Dar Contents Read/Write al token/conector."
    Write-Host "2) Revisar reglas de rama protegida y empujar a una feature branch."
    Write-Host "3) Si usas proxy local, habilitar push o usar credenciales directas en shell."
    exit 3
}

Write-Host "FALLO no clasificado en prueba de escritura. Revisar salida anterior." -ForegroundColor Red
exit 1