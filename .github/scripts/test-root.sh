#!/usr/bin/env bash
# Runs `krypt system root` on a fresh Arch container as a non-root user with
# paru, the way a new machine runs it, and checks that every file in .root/
# landed, the UKI was built and the services are enabled. Runs as root in an
# archlinux container with base-devel, git and sudo installed and `krypt` on
# PATH; it creates the user, and puts this checkout where `krypt init` would
# have cloned the repo.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
user=builder

useradd -m "$user"
echo "$user ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/"$user"
as_user() { sudo -u "$user" env PATH="$PATH" HOME="/home/$user" "$@"; }

# paru builds AUR packages (kanata) and refuses to do that as root, which is
# what this run checks krypt respects.
as_user git clone --depth 1 https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
(cd /tmp/paru-bin && as_user makepkg -si --noconfirm)

# Stand-in for an ESP mounted at /boot, which the script requires.
mkdir -p /boot/EFI

clone="/home/$user/.config/krypt/repo"
mkdir -p "$(dirname "$clone")"
cp -a "$repo" "$clone"
printf '[repo]\npath = "%s"\n' "$clone" >"/home/$user/.config/krypt/config.toml"
chown -R "$user:" "/home/$user/.config"

as_user krypt system root

failures=()
installed=()
while IFS= read -r -d '' file; do
    dst="/${file#"$repo/.root/"}"
    cmp -s "$file" "$dst" || failures+=("not installed: $dst")
    installed+=("$dst")
done < <(find "$repo/.root" -type f -print0)
checked=${#installed[@]}
((checked > 0)) || failures+=("found no files under .root/ to check")
[[ -x /usr/bin/auto-power-profile ]] || failures+=("not executable: /usr/bin/auto-power-profile")
[[ -f /boot/EFI/Linux/arch-linux.efi ]] || failures+=("no UKI at /boot/EFI/Linux/arch-linux.efi")
for unit in ly@tty2.service kanata.service power-check.timer power-profiles-daemon.service \
    NetworkManager.service avahi-daemon.service bluetooth.service cups.service ufw.service; do
    [[ $(systemctl is-enabled "$unit" 2>&1) == enabled ]] || failures+=("not enabled: $unit")
done

# A second run finds nothing to do: it rewrites no file and does not rebuild
# the UKI, so none of their modification times move.
uki=/boot/EFI/Linux/arch-linux.efi
before=$(stat -c '%n %y' "${installed[@]}" "$uki" 2>&1)
as_user krypt system root
after=$(stat -c '%n %y' "${installed[@]}" "$uki" 2>&1)
[[ "$before" == "$after" ]] || failures+=("the second run rewrote files: $(diff <(echo "$before") <(echo "$after") | grep '^>' | tr '\n' ' ')")

if ((${#failures[@]})); then
    printf '::error::%s\n' "${failures[@]}"
    exit 1
fi
echo "every .root/ file is installed and every service enabled"
