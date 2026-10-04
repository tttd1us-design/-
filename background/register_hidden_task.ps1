# register_hidden_task.ps1
# 파이썬 스크립트를 Windows 작업 스케줄러에 "숨김 실행"으로 등록합니다.
#
# 사용 예 (PowerShell):
#   # 로그온할 때 한 번 실행
#   .\register_hidden_task.ps1 -Script "C:\bot\auto_content.py"
#
#   # 30분마다 반복 실행
#   .\register_hidden_task.ps1 -Script "C:\bot\auto_content.py" -EveryMinutes 30
#
#   # 등록 해제
#   Unregister-ScheduledTask -TaskName "AutoBot_auto_content" -Confirm:$false
#
# 실행 정책 오류가 나면 먼저:  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

param(
    [Parameter(Mandatory = $true)][string]$Script,
    [string]$TaskName,
    [int]$EveryMinutes = 0,
    [string]$Arguments = ""
)

$Script = (Resolve-Path $Script).Path
$workDir = Split-Path $Script -Parent
if (-not $TaskName) { $TaskName = "AutoBot_" + [IO.Path]::GetFileNameWithoutExtension($Script) }

# python.exe 대신 pythonw.exe 를 사용해야 콘솔 창이 뜨지 않습니다.
$pythonw = (Get-Command pythonw.exe -ErrorAction SilentlyContinue).Source
if (-not $pythonw) {
    $python = (Get-Command python.exe -ErrorAction Stop).Source
    $pythonw = Join-Path (Split-Path $python -Parent) "pythonw.exe"
}
if (-not (Test-Path $pythonw)) { throw "pythonw.exe 를 찾을 수 없습니다: $pythonw" }

$action = New-ScheduledTaskAction -Execute $pythonw `
    -Argument ("`"$Script`" " + $Arguments).Trim() -WorkingDirectory $workDir

if ($EveryMinutes -gt 0) {
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
        -RepetitionInterval (New-TimeSpan -Minutes $EveryMinutes)
} else {
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
}

$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Settings $settings -Description "Hidden background run of $Script" -Force | Out-Null

Write-Host "등록 완료: $TaskName"
Write-Host "  실행 파일 : $pythonw"
Write-Host "  스크립트  : $Script"
Write-Host "  즉시 테스트: Start-ScheduledTask -TaskName `"$TaskName`""
