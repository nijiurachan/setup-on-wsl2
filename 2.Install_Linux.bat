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
$DistroPath = "C:\WSL\$DistroName"
$DistroUrl = "https://ftp.riken.jp/Linux/ubuntu-releases/noble/ubuntu-24.04.4-wsl-amd64.wsl"
$DistroSHA256 = "9b2f7730dc68227dd04a9f3e5eab86ad85caf556b8606ad94f1f29ff5c4fd3f5"

# Install : WSL
#winget.exe install --id Microsoft.WSL --source winget

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

# Download Ubuntu24.04
curl.exe -o "$env:TEMP\ubuntu.wsl" $DistroUrl
if (-not (Test-Path "$env:TEMP\ubuntu.wsl")) {
    Write-Error "Failed to download Ubuntu WSL."
    pause
    exit
}

# Verify SHA256
$downloadedHash = (Get-FileHash -Path "$env:TEMP\ubuntu.wsl" -Algorithm SHA256).Hash.ToLower()
if ($downloadedHash -ne $DistroSHA256.ToLower()) {
    Write-Error "SHA256 hash mismatch! Downloaded: $downloadedHash, Expected: $DistroSHA256"
    Write-Warning "Continue despite mismatch? (y/n)"
    $answer = Read-Host "Type y to continue"
    if ($answer -ne "y") {
        Write-Host "Operation cancelled."
        exit
    }
}
else {
    Write-Host "SHA256 hash verified."
}

# Install Ubuntu24.04 Linux
if (Test-Path "$DistroPath") {
    Write-Warning "$DistroPath already exists. Remove and re-import? (y/n)"
    $answer = Read-Host "Type y to continue"
    if ($answer -eq "y") {
        Remove-Item -Path $DistroPath -Recurse -Force
    }
    else {
        Write-Host "Operation cancelled."
    }
}
New-Item -ItemType Directory -Path "$DistroPath" | Out-Null

# Import Ubuntu24.04 into WSL
wsl.exe --import "$DistroName" "$DistroPath" "$env:TEMP\ubuntu.wsl"

$bashScript = @'
#!/bin/bash

apt-get update
apt-get full-upgrade -y --no-install-recommends

apt-get install -y --no-install-recommends curl git ca-certificates vim tmux sudo

# libatomic1 は pnpmが利用する
# unzip は bunが利用する
# podman/uidmap はコンテナ環境用
apt-get install -y --no-install-recommends libatomic1 unzip podman uidmap

# Create developer
useradd -m -N -G adm -s /bin/bash developer
echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

mkdir -p /workspace
chown developer /workspace
chmod 755 /workspace

cat << '_EOL_' > /etc/wsl.conf
[boot]
systemd=true

[interop]
enabled = true
appendWindowsPath = false

[automount]
enabled = true
mountFsTab = true

[network]
generateHosts = true
generateResolvConf = true

[user]
default = developer
_EOL_

cat << '_EOL_' > /etc/tmux.conf
## Keybind
unbind-key C-b
set-option -g prefix C-z
bind-key C-z send-prefix
_EOL_

exit

'@

($bashScript -replace "`r`n", "`n") | Set-Content ".\setup_root.sh"
wsl.exe --user root -d $DistroName -- bash -c "bash ./setup_root.sh"

wsl.exe -t $DistroName

$bashScript = @'
#!/bin/bash

cat << '_EOL_' >> ~/.profile
export WORKSPACE_PATH=/workspace
_EOL_

export WORKSPACE="${WORKSPACE_PATH:-/workspace}"

# nvmをダウンロードしてインストールする：
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash

# シェルを再起動する代わりに実行する
\. "$HOME/.nvm/nvm.sh"

# Node.jsをダウンロードしてインストールする：
nvm install 24

# Node.jsのバージョンを確認する：
node -v # "v24.18.0"が表示される。

# pnpmをインストールする：
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
corepack enable pnpm

# pnpmのバージョンを確認する：
pnpm -v

# bun install
curl -fsSL https://bun.com/install | bash

# bun version
bun --version

echo "Node/pnpm/bun setup completed."

echo "Waiting for 5 seconds to ensure all processes are settled..."
sleep 5

exit

'@

($bashScript -replace "`r`n", "`n") | Set-Content ".\setup_developer.sh"
wsl.exe -d $DistroName -- bash -c "bash ./setup_developer.sh"

Remove-Item -Path ".\setup_root.sh"
Remove-Item -Path ".\setup_developer.sh"
