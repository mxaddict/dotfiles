# .files

## Tools

1. `bat` for `cat` replacement
1. `bear` for creating a `compile_commands.json`
1. `eza` for `ls`
1. `fastfetch` for a nice system info command
1. `fd` for a better `find` alternative
1. `fish` for my `shell`
1. `fisher` for managing fish plugins
1. `fzf` for fuzzy finder in cli for `history` and files
1. `git` for `git` duh...
1. `kanata` for keyboard custom bindings
1. `findex` for my launcher
1. `kweri` a simple cli tool for using search engines via default browser
1. `neovim` for my `$EDITOR`
1. `quoty` for random programmer quotes to use with commit messages
1. `ripgrep` for a better `grep` alternative
1. `starship` for my prompt
1. `tealdeer` for a nice short alternative to man pages
1. `tmux` for my terminal multiplexer
1. `zoxide` for navigation (alternative to `cd` command)

## Requirements

### Arch

```sh
sudo pacman -S --needed base-devel rustup
rustup install stable
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
```

```sh
paru -S \
    alacritty \
    bat \
    bear \
    btop \
    eza \
    fastfetch \
    fd \
    findex \
    fish \
    fzf \
    git \
    kanata \
    lazygit \
    man-db \
    neovim \
    nodejs \
    npm \
    ripgrep \
    rustup \
    starship \
    stow \
    tealdeer \
    tmux \
    wl-clipboard\
    zoxide
```

### Mac

```sh
brew install \
    alacritty \
    bat \
    bear \
    btop \
    eza \
    fish \
    fzf \
    git \
    lazygit \
    fastfetch \
    fd \
    neovim \
    nodejs \
    npm \
    ripgrep \
    rust \
    starship \
    stow \
    tldr \
    tmux \
    zoxide
```

### Ubuntu 24.04

```sh
curl -sS https://starship.rs/install.sh | sh
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
sudo apt-add-repository ppa:fish-shell/release-3
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
```

```sh
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm -rf lazygit lazygit.tar.gz
```

```sh
sudo apt install \
    alacritty \
    bat \
    bear \
    btop \
    eza \
    fastfetch \
    fd-find \
    fish \
    fzf \
    git \
    libssl-dev \
    neovim \
    nodejs \
    npm \
    pkg-config \
    python3 \
    python3-venv \
    ripgrep \
    rustup \
    stow \
    tldr \
    tmux \
    zoxide
```

## All OSs

```sh
rustup install stable
cargo install quoty
cargo install kweri
```

## Installation of .files

```sh
curl -SsL https://raw.github.com/mxaddict/dotfiles/main/.local/bin/.install | fish
```

## Hyprland

### QT support

```sh
paru -S qt5-wayland qt6-wayland
```

### Video Codecs

```sh
paru -S gst-libav gst-plugins-{base,good,bad,ugly}
```

### NetworkManager (Network)

```sh
paru -S networkmanager network-manager-applet
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
```

### Bluez (Bluetooth)

```sh
paru -S bluez bluez-utils blueman
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

### BIND

```sh
paru -S bind
```

### Pipewire (Audio) and xdg-portal

```sh
paru -S \
    sof-firmware \
    alsa-firmware \
    alsa-utils \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pavucontrol \
    wireplumber \
    xdg-desktop-portal-hyprland

systemctl --user enable pipewire.service
systemctl --user enable pipewire-pulse.service
systemctl --user enable wireplumber.service
```

### Notifications / Wallpaper / Waybar / Lockscreen / Brightness / Idle / Color Picker

```sh
paru -S hyprpaper waybar swaync hyprlock hypridle brightnessctl
```

### Fonts

```sh
paru -S \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-font-awesome \
    ttf-hack \
    ttf-hack-nerd \
    ttf-noto-nerd \
    ttf-roboto \
    ttf-roboto-mono \
    ttf-roboto-mono-nerd
```

### Colorpicker, Screenshots and Screenrecording

```sh
paru -S grimblast-git kooha wl-clipboard hyprpicker
```

### Themeing

```sh
paru -S \
    breeze \
    breeze-gtk \
    breeze-plymouth
```

### Util for displays and gtk settings

```sh
paru -S nwg-displays
```

### Browser, Files, Calc, Email, etc

```sh
paru -S chromium firefox thunderbird dolphin kcalc
```

### Kanata setup

```sh
.kanata
```
