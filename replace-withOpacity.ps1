# Script para reemplazar withOpacity por withValues en todos los archivos Dart
# Quantum Gym App - Fase 4: Deprecaciones

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Reemplazando withOpacity -> withValues" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$libPath = "lib"
$filesModified = 0
$replacementsCount = 0

# Obtener todos los archivos .dart
$dartFiles = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart"

Write-Host "Archivos .dart encontrados: $($dartFiles.Count)" -ForegroundColor Yellow
Write-Host ""

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Reemplazar .withOpacity(valor) por .withValues(alpha: valor)
    # Patrón: .withOpacity(número decimal o entero)
    $pattern = '\.withOpacity\(([0-9]*\.?[0-9]+)\)'
    $replacement = '.withValues(alpha: $1)'
    
    $content = $content -replace $pattern, $replacement
    
    # Contar reemplazos en este archivo
    $matches = [regex]::Matches($originalContent, $pattern)
    $fileReplacements = $matches.Count
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $filesModified++
        $replacementsCount += $fileReplacements
        Write-Host "✓ $($file.Name): $fileReplacements reemplazos" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Archivos modificados: $filesModified" -ForegroundColor Green
Write-Host "Total de reemplazos: $replacementsCount" -ForegroundColor Green
Write-Host ""
Write-Host "Ejecuta flutter analyze para verificar los resultados" -ForegroundColor Yellow
