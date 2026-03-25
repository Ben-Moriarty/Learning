$Results = @{}

$DriveHealth = (Get-PhysicalDisk).HealthStatus
$Results['DriveHealth'] = $DriveHealth


$MaxCPU = (Get-CimInstance -ClassName Win32_Processor).MaxClockSpeed
$EndTime = (Get-Date).AddMinutes(20)

$x = 1
While ((Get-Date) -lt $EndTime) {
    $x * $x
    $x++
}
$CurCPU = (Get-CimInstance -ClassName Win32_Processor).CurrentClockSpeed

if ($CurCPU -lt 0.5 * ($MaxCPU)) {
    $Results['CPU'] = 'Throttling'
}
else {
    $Results['CPU'] = 'NoThrottling'
}

$MemCapGB = (Get-CimInstance Win32_PhysicalMemory).Capacity / 1GB
$Results['Memory'] = $MemCapGB