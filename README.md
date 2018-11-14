<h1 align="center">My . files ❤ ~/ - Bootstrap</h1>
This is my setup to be productive on MacOS, Ubuntu/ Debian like systems and even
Windows 10. This is the bootstrap part to setup the stuff before to get the
actual dotfiles.

# Installation
The main part is to setup git and SSH before we can proceed with further
installation of the dotfiles.
## MacOS
Download Xcode in the AppStore and open in the terminal:
```bash
xcode-select --install
```
Then setup the SSH keys and add it to Github. Bash version of the setup script
will be made the next time I need to install Debian/ Mac OS agian. Next:
```bash
git clone git@github.com:MegaCookie/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
```
## Debian
```bash
sudo apt update && sudo apt upgrade && sudo apt install git
```
Then setup the SSH keys and add it to Github. Bash version of the setup script
will be made the next time I need to install Debian/ Mac OS agian. Next:
```bash
git clone git@github.com:MegaCookie/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
```
## Windows 10
We need to install git and SSH. Under Windows that is a bit difficult. Therefore
a PowerShell script is made.

Open an elevated Powershell (`Win` `x`  + `a`)
```PowerShell
Set-ExecutionPolicy Unrestricted
```
The following script installs git and add a SSH key to Github using the Github API.
```PowerShell
iex ((new-object net.webclient).DownloadString('https://raw.github.com/megacookie/dotfiles-bootstrap/master/setup.ps1'))
```

# Manual SSH config
If you used the script above it should already be added to ~/.ssh/config and
added to Github. If it fails or you want do it manually you can follow the
procedure described here below.

### Starting SSH agent and setup keys
**Mac/ Debian:** `eval $(ssh-agent -s)`

**Windows:**
```PowerShell
Set-Service ssh-agent -StartupType Manual
Start-Service ssh-agent
```

**Windows 10/ MacOS/ Debian**:
`ssh-keygen -t rsa -b 4096 -C "mail@jessevandervelden.nl" -f ~/.ssh/github_rsa`

**Add to `~/.ssh/config`:**
```
Host github.com
  HostName github.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/github_rsa
  IdentitiesOnly yes
```
### Add to Github
https://github.com/settings/keys

**Mac:** `pbcopy < ~/.ssh/github_rsa.pub`

**Debian:** `clip < ~/.ssh/github_rsa.pub`

**Windows 10:** `Get-Content ~\.ssh\github_rsa.pub | Set-Clipboard`

# Enjoy
Enjoy and be productive!
