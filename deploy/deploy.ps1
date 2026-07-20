# Quantum Gym — deploy del build web al VPS desde Windows.
#
# Uso:
#   .\deploy\deploy.ps1 -VpsHost usuario@IP-DEL-VPS
#
# Requisitos: OpenSSH (viene con Windows 10/11) y Docker instalado en el VPS.
# Primera vez en el VPS: instala Docker con
#   curl -fsSL https://get.docker.com | sh

param(
    [Parameter(Mandatory = $true)]
    [string]$VpsHost,
    [string]$RemoteDir = "/opt/quantum-gym"
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

Write-Host "1/4 Compilando build web..." -ForegroundColor Cyan
Push-Location $root
flutter build web --release
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "flutter build web falló" }
Pop-Location

Write-Host "2/4 Creando estructura remota..." -ForegroundColor Cyan
ssh $VpsHost "mkdir -p $RemoteDir/deploy $RemoteDir/build"

Write-Host "3/4 Subiendo archivos (build/web + deploy/)..." -ForegroundColor Cyan
scp -r "$root/build/web" "${VpsHost}:$RemoteDir/build/"
scp -r "$root/deploy/nginx.conf" "$root/deploy/Dockerfile" `
    "$root/deploy/docker-compose.yml" "$root/deploy/Caddyfile" `
    "${VpsHost}:$RemoteDir/deploy/"

Write-Host "4/4 Levantando contenedores en el VPS..." -ForegroundColor Cyan
ssh $VpsHost "cd $RemoteDir && docker compose -f deploy/docker-compose.yml up -d --build"

Write-Host "Listo. La app queda en el puerto 443 (dominio del Caddyfile) y 8080 (directo)." -ForegroundColor Green
