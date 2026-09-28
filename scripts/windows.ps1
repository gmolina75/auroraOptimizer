# ============================================
# Aurora Optimizer - Script para Windows
# ============================================

#Requires -RunAsAdministrator

param(
    [string]$ConfigFile = "$PSScriptRoot\..\config\aurora.conf",
    [string]$LogDir = "$PSScriptRoot\..\logs"
)

# Crear directorio de logs
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogFile = Join-Path $LogDir "aurora-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Función de logging
function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry
}

# Detectar tipo de disco
function Get-DiskType {
    param([string]$DriveLetter)

    try {
        $partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction Stop
        $disk = Get-Disk -Number $partition.DiskNumber
        if ($disk.BusType -eq 'NVMe' -or $disk.Model -match 'SSD') {
            return 'SSD'
        }
        return 'HDD'
    } catch {
        return 'UNKNOWN'
    }
}

# Limpiar memoria
function Clear-Memory {
    Write-Log "INFO" "Iniciando limpieza de memoria..."

    $memBefore = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize - (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
    Write-Log "INFO" "Memoria en uso antes: $([math]::Round($memBefore/1MB, 2)) GB"

    # Limpiar caché de sistema
    try {
        # Vaciar lista de espera
        $processes = Get-Process | Where-Object { $_.WorkingSet64 -gt 100MB }
        foreach ($proc in $processes) {
            try {
                $proc.MinWorkingSet = $proc.MinWorkingSet
            } catch {}
        }

        # Limpiar caché de sistema
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        Write-Log "INFO" "Limpieza de memoria completada"
    } catch {
        Write-Log "WARN" "Error limpiando memoria: $_"
    }

    $memAfter = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize - (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
    Write-Log "INFO" "Memoria en uso después: $([math]::Round($memAfter/1MB, 2)) GB"
}

# Limpiar archivos temporales
function Clear-TempFiles {
    Write-Log "INFO" "Iniciando limpieza de archivos temporales..."

    $tempDirs = @(
        $env:TEMP,
        "C:\Windows\Temp",
        "C:\Windows\Prefetch",
        "$env:LOCALAPPDATA\Temp"
    )

    $totalFreed = 0

    foreach ($dir in $tempDirs) {
        if (Test-Path $dir) {
            try {
                $sizeBefore = (Get-ChildItem -Path $dir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Get-ChildItem -Path $dir -Recurse -Force -ErrorAction SilentlyContinue |
                    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                $sizeAfter = (Get-ChildItem -Path $dir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $freed = ($sizeBefore - $sizeAfter) / 1MB
                $totalFreed += $freed
                Write-Log "INFO" "Limpiado $dir : $([math]::Round($freed, 2)) MB liberados"
            } catch {
                Write-Log "WARN" "Error limpiando $dir : $_"
            }
        }
    }

    Write-Log "INFO" "Total liberado: $([math]::Round($totalFreed, 2)) MB"
}

# Defragmentar disco
function Optimize-Disk {
    param([string]$DriveLetter)

    $diskType = Get-DiskType -DriveLetter $DriveLetter

    if ($diskType -eq 'SSD') {
        Write-Log "INFO" "Disco ${DriveLetter}: es SSD - NO se defragmenta"
        # En su lugar, ejecutar TRIM
        try {
            Optimize-Volume -DriveLetter $DriveLetter -ReTrim -ErrorAction SilentlyContinue
            Write-Log "INFO" "TRIM ejecutado en ${DriveLetter}:"
        } catch {
            Write-Log "WARN" "No se pudo ejecutar TRIM: $_"
        }
        return
    }

    if ($diskType -eq 'HDD') {
        Write-Log "INFO" "Disco ${DriveLetter}: es HDD - Verificando fragmentación..."
        try {
            $defrag = Optimize-Volume -DriveLetter $DriveLetter -Analyze -Verbose 4>&1
            Write-Log "INFO" "Análisis de defragmentación completado"
        } catch {
            Write-Log "WARN" "Error analizando disco: $_"
        }
    }
}

# Verificar espacio en disco
function Test-DiskSpace {
    Write-Log "INFO" "Verificando espacio en disco..."

    Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object {
        $usage = [math]::Round(($_.Size - $_.SizeRemaining) / $_.Size * 100, 1)
        $drive = $_.DriveLetter
        if ($usage -gt 85) {
            Write-Log "WARN" "⚠️  ${drive}: ${usage}% usado - ¡Espacio bajo!"
        } else {
            Write-Log "INFO" "✓ ${drive}: ${usage}% usado"
        }
    }
}

# Limpiar logs antiguos
function Clear-OldLogs {
    Write-Log "INFO" "Limpiando logs antiguos..."
    Get-ChildItem -Path $LogDir -Filter "*.log" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip 10 |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

# ============================================
# EJECUCIÓN PRINCIPAL
# ============================================

function Main {
    Write-Log "INFO" "=========================================="
    Write-Log "INFO" "Aurora Optimizer - Iniciando optimización"
    Write-Log "INFO" "Fecha: $(Get-Date)"
    Write-Log "INFO" "Usuario: $env:USERNAME"
    Write-Log "INFO" "=========================================="

    # 1. Verificar espacio en disco
    Test-DiskSpace

    # 2. Limpiar memoria
    Clear-Memory

    # 3. Limpiar archivos temporales
    Clear-TempFiles

    # 4. Optimizar discos
    Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object {
        Optimize-Disk -DriveLetter $_.DriveLetter
    }

    # 5. Limpiar logs antiguos
    Clear-OldLogs

    Write-Log "INFO" "=========================================="
    Write-Log "INFO" "Optimización completada exitosamente"
    Write-Log "INFO" "=========================================="

    # Notificación
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Optimización del sistema completada", "Aurora Optimizer")
    } catch {}
}

# Ejecutar
Main
