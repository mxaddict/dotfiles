# config.nu

source ~/.config/nushell/carapace.nu
source ~/.config/nushell/starship.nu
source ~/.config/nushell/zoxide.nu

alias l   = ls
alias ll  = ls -a
alias lll = ls -al

alias v = nvim
alias vi = nvim
alias vim = nvim

alias h  = helix
alias hx = helix

alias c = cmatrix

alias lg = lazygit

alias q = kweri

alias nav = navcoin-cli

alias cl = clear

alias tree = eza --tree

alias nvm = fnm

alias ":q!" = exit
alias ":q" = exit
alias ":qa!" = exit
alias ":qa" = exit
alias ":wq!" = exit
alias ":wq" = exit
alias ":wqa!" = exit
alias ":wqa" = exit

def ff [] {
    clear
    fastfetch
}

def g [] {
    git commit -am (quoty)
    git pull --no-edit
    git push
}

def gg [] {
    git add .; git commit -m (quoty)
    git pull --no-edit
    git push
}

alias gi  = got
alias gti = got
alias gto = got
alias tgi = got
alias gut = got
alias fur = got
alias hot = got

def got [ ...args ] {
    print "Hey! Fat fingers!!!"
    git ...$args
}
