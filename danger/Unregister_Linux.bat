@echo off

set "SRC_BAT=%~f0"
set "TMP_PS=%TEMP%\temp_install_linux.ps1"

REM "REM --- BEGIN POWERSHELL ---"以降を.ps1に書き出し
powershell -NoProfile -Command ^
  "$lines = Get-Content -Raw -Encoding UTF8 '%SRC_BAT%';" ^
  "$split = $lines -split 'REM --- BEGIN POWERSHELL ---\r?\n', 2;" ^
  "if ($split.Count -eq 2) { $split[1] | Set-Content -Encoding UTF8 '%TMP_PS%' } else { Write-Error 'Marker not found.'; exit 1 }"

REM PowerShellスクリプトを実行
powershell -NoProfile -ExecutionPolicy Unrestricted -File "%TMP_PS%"
del "%TMP_PS%"
exit

REM -----------------------------------------------------------------------------------------------

REM --- BEGIN POWERSHELL ---
# Install WSL2 and Ubuntu on Windows using PowerShell

$env:WSL_UTF8 = 1
$DistroName = "Ubuntu24.04-Developer"


$wslList = wsl.exe --list | Select-String "$DistroName"
if ($wslList) {
    Write-Warning "WSL2($DistroName) is already installed. Unregister and re-import? (y/n)"
    $answer = Read-Host "Type y to continue"
    if ($answer -eq "y") {
        wsl.exe -t "$DistroName"
        wsl.exe --unregister "$DistroName"
        Write-Host "$DistroName has been unregistered."
    }
    else {
        Write-Host "Operation cancelled."
    }
}
pause
