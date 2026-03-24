$DriveHealth = (Get-PhysicalDisk).HealthStatus

$MaxCPU = (Get-CimInstance -ClassName Win32_Processor).MaxClockSpeed
Write-Host $MaxCPU

$EndTime = (Get-Date).AddMinutes(20)
$x = 1
While ((Get-Date) -lt $EndTime) {
    $x * $x
    $x++
}

$CurCPU = (Get-CimInstance -ClassName Win32_Processor).CurrentClockSpeed
Write-Host $CurCPU