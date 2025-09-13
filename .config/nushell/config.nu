# config.nu

source ~/.config/nushell/carapace.nu
source ~/.config/nushell/starship.nu
source ~/.config/nushell/zoxide.nu

# ls
alias l   = ls
alias ll  = ls -a
alias lll = ls -al

# neovim
alias v = nvim
alias vi = nvim
alias vim = nvim

# helix
alias h  = helix
alias hx = helix

# Alias for cmatrix
alias c = cmatrix

# Alias for lazygit
alias lg = lazygit

# Alias for kweri
alias q = kweri

# Add navcoin alias
alias nav = navcoin-cli

# Alias for clear
alias cl = clear

# Replace tree command with eza
alias tree = eza --tree

# nvm lias to fnm
alias nvm = fnm

# fastfetch
def ff [] {
    clear
    fastfetch
}

# Alias for quick and dirty git commit
def g [] {
    git commit -am (quoty); git pull --no-edit; git push
}

def gg [] {
    git add .; git commit -m (quoty); git pull --no-edit; git push
}

# More git
alias gti = got
alias gto = got
alias tgi = got
alias gut = got
alias fur = got
alias hot = got

# Git typo
def got [ ...args ] {
    print "Hey! Fat fingers!!!"
    git ...$args
}

# Check for nproc
if (which nproc | is-empty) {
    alias nproc = sysctl -n hw.physicalcpu
}

# Check for batcat
if not (which batcat | is-empty) {
    alias bat = batcat
}

# Check for exa and alias to eza
if not (which exa | is-empty) {
    alias eza = exa
}
