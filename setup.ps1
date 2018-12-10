###****************************###
### Install git and check SSH. ###
###****************************###

Write-Host "Installing Package Providers..." -ForegroundColor "Yellow"
Get-PackageProvider NuGet -Force | Out-Null

if (!(Test-Path -path "$env:ProgramData\Chocolatey")) {
  Set-ExecutionPolicy Unrestricted; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  choco feature enable -n allowGlobalConfirmation
}

Write-Host "Installing PowerShell Modules..." -ForegroundColor "Yellow"
if (!(Get-Module -ListAvailable -Name Posh-Git)) {
  Install-Module Posh-Git -Scope CurrentUser -Force
}
if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
  Install-Module PSWindowsUpdate -Scope CurrentUser -Force
}

if (!(Test-Path HKLM:Software\GitForWindows)) {
  choco install git.install --limit-output -params '"/GitAndUnixToolsOnPath /NoShellIntegration"' -y
}

#curl.exe is actually available since 1804
if (!((Test-Path -path "${env:ProgramData}\chocolatey\lib\curl") -and (Test-Path "${env:WinDir}\System32\curl.exe"))) {
  choco install curl --limit-output -y
}

# Assuming openssh is installed since 1804
Write-Host "Assuming OpenSSH is installed (default since 1804)" -ForegroundColor "Yellow"
if (!(Test-Path "${env:WinDir}\System32\OpenSSH\ssh-keygen.exe")) {
  Write-Host "${env:WinDir}\System32\OpenSSH\ssh-keygen.exe does not exsists. ABORT..." -ForegroundColor "Red"
  exit
  #Actually it can be installed with cocolatey but now i just don't support < 1804
}


###******************************************###
### Generating SSH key and add it to github. ###
###******************************************###
Set-Service ssh-agent -StartupType Manual
Start-Service ssh-agent

if (!(Test-Path $HOME\.ssh\github_rsa)) {
  $confirmation = Read-Host "Do you want to generate a new SSH key and add it to Github? [y/n]"
  if ($confirmation -eq 'y') {
    Write-Host "Trying to test the Github connection..." -ForegroundColor "Yellow"

    ssh -q git@github.com # Test github connection. It will auto exit on its own at the server side.
    if ($LASTEXITCODE -eq 255) {
      $gitemail = Read-Host -Prompt 'Input your github email'

      # Generating keys
      ssh-keygen -t rsa -b 4096 -C "$gitemail" -f $HOME\.ssh\github_rsa

      $gituser = Read-Host -Prompt 'Input your github username'

      $twoauth = Read-Host "Do you have 2factor authentication enabled? [y/n]"
      if ($twoauth -match "[yY]") {
        $gitotp = Read-Host -Prompt 'Input your github otp'
      }

      # Adding to Github using their API...
      $sshkey = [IO.File]::ReadAllText("$HOME\.ssh\github_rsa.pub")

      # Create data as PS hashtable literal.
      $json = @{ title = "WinTestje"; key = "$sshkey" }

      if ($twoauth -match "[yY]") {
        # Convert to JSON with ConvertTo-Json and pipe to `curl` via *stdin* (-d '@-')
        $added = $json | ConvertTo-Json -Compress | curl.exe -i -s -u $gituser `
          -H "X-GitHub-OTP: $gitotp"`
          -H "Content-Type: application/json"`
          -d '@-'`
          https://api.github.com/user/keys | Select -First 1 | Select-String '201' -quiet
      } else {
        $added = $json | ConvertTo-Json -Compress | curl.exe -i -s -u $gituser `
          -H "Content-Type: application/json"`
          -d '@-'`
          https://api.github.com/user/keys | Select -First 1 | Select-String '201' -quiet
      }

      if ($added) {
        ###*******************************###
        ### Adding to ~\.ssh\config file. ###
        ###*******************************###
        Write-Host "IT WORKED! :). Now we'll add it to: ~\.ssh\config" -ForegroundColor "Green"
        if (!(Test-Path $HOME\.ssh\config)) {
          New-Item $HOME\.ssh\config -ItemType file
        }
        
        if (!(Get-Content $HOME\.ssh\config  | Select-String -pattern "\bHostName github.com\b" -quiet)) {
          Write-Host "Didn't find it yet in the config file. So addding it..." -ForegroundColor "Green"
          Add-Content $HOME\.ssh\config "`nHost github.com`n`tHostName github.com`n`tPreferredAuthentications publickey`n`tIdentityFile ~/.ssh/github_rsa`n`tIdentitiesOnly yes"
        } else {
          Write-Host "There was already a hostname with github.com found! So didn't add it to: ~\.ssh\config!!" -ForegroundColor "Red"
        }
      }
    } else {
      Write-Host "Already connected to Github..." -ForegroundColor "Green"
    }
  }
} else {
  Write-Host "Already found a ~\.ssh\github_rsa file. You should be able to connect to github already. Follow the manual to proceed." -ForegroundColor "Green"
}

Write-Host "Trying to test the Github connection one more time..." -ForegroundColor "Yellow"
ssh -q git@github.com # Test github connection. It will auto exit on its own at the server side.
if ($LASTEXITCODE -eq 255) {
  Write-Host "Cannot connect to Github. Not authorized... Add your own keys to Github using the manual." -ForegroundColor "Red"
} else {
  Write-Host "Successfully connected to Github! You can proceed with the dotfiles installation" -ForegroundColor "Green"
}

Write-Host "Hopefully everything worked!" -ForegroundColor "Yellow"
