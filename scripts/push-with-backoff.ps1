param(
    [string]$Remote = "origin",
    [string]$Branch,
    [int]$MaxRetries = 4,
    [int]$InitialDelaySeconds = 2,
    [switch]$SetUpstream
)

$ErrorActionPreference = "Continue"

function Run-GitPush {
    param(
        [string]$RemoteName,
        [string]$BranchName,
        [bool]$UseSetUpstream
    )

    $args = @("push")
    if ($UseSetUpstream) {
        $args += "-u"
    }
    $args += @($RemoteName, $BranchName)

    $output = & git @args 2>&1
    $text = [string]::Join("`n", $output)
    return @($LASTEXITCODE, $text)
}

if (-not $Branch) {
    $Branch = (& git rev-parse --abbrev-ref HEAD 2>$null).Trim()
}

if (-not $Branch) {
    throw "No se pudo determinar la rama actual. Usa -Branch explicitamente."
}

Write-Host "Push target: $Remote/$Branch"
Write-Host "Retries: $MaxRetries, delay inicial: ${InitialDelaySeconds}s"

$delay = [Math]::Max(1, $InitialDelaySeconds)

for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
    Write-Host ""
    Write-Host "Intento $attempt de $MaxRetries..." -ForegroundColor Cyan
    $result = Run-GitPush -RemoteName $Remote -BranchName $Branch -UseSetUpstream $SetUpstream.IsPresent
    $exitCode = [int]$result[0]
    $output = [string]$result[1]

    if ($output) {
        Write-Host $output
    }

    if ($exitCode -eq 0) {
        Write-Host "Push completado correctamente." -ForegroundColor Green
        exit 0
    }

    if ($output -match "403|not accessible by integration|permission denied|write access") {
        Write-Host ""
        Write-Host "Error persistente de permisos detectado (403/denegado)." -ForegroundColor Red
        Write-Host "No se reintenta mas porque no es un fallo transitorio de red." -ForegroundColor Yellow
        Write-Host "Accion manual sugerida: git push -u $Remote $Branch"
        exit 2
    }

    if ($attempt -lt $MaxRetries) {
        Write-Host "Fallo transitorio. Reintentando en $delay segundos..." -ForegroundColor Yellow
        Start-Sleep -Seconds $delay
        $delay *= 2
    }
}

Write-Host ""
Write-Host "Se agotaron los reintentos de push." -ForegroundColor Red
exit 1