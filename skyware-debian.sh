#!/bin/bash
set -e

echo "== SkywareOS Debian setup starting =="

# -----------------------------
# Core packages
# -----------------------------
sudo apt update
sudo apt install -y flatpak cmatrix btop zsh alacritty kitty curl git build-essential \
    sudo software-properties-common wget unzip apt-transport-https ca-certificates gnupg lsb-release

# -----------------------------
# Firewall
# -----------------------------
sudo apt install -y ufw fail2ban
sudo systemctl enable ufw
sudo systemctl enable fail2ban
sudo ufw enable

# -----------------------------
# GPU Driver Selection
# -----------------------------
echo "Select your GPU driver:"
echo "1) NVIDIA (Modern)"
echo "2) NVIDIA (DKMS)"
echo "3) AMD"
echo "4) Intel"
echo "5) VMware/VirtualBox"
read -rp "Enter choice (1/2/3/4/5): " gpu_choice

case "$gpu_choice" in
    1)
        echo "Installing Modern NVIDIA drivers..."
        sudo apt install -y nvidia-driver nvidia-settings
        ;;
    2)
        echo "Installing NVIDIA DKMS drivers..."
        sudo apt install -y nvidia-driver nvidia-dkms nvidia-settings
        ;;
    3)
        echo "Installing AMD drivers..."
        sudo apt install -y xserver-xorg-video-amdgpu mesa-utils
        ;;
    4)
        echo "Installing Intel drivers..."
        sudo apt install -y xserver-xorg-video-intel mesa-utils
        ;;
    5)
        echo "Installing VMware/VirtualBox tools..."
        sudo apt install -y open-vm-tools mesa-utils virtualbox-guest-dkms virtualbox-guest-x11
        ;;
    *)
        echo "Invalid choice, skipping GPU drivers."
        ;;
esac

# -----------------------------
# Desktop Environment / Display Manager
# -----------------------------
sudo apt install -y gdm3 sddm lightdm

echo "Select your Desktop Environment:"
echo "1) KDE Plasma"
echo "2) GNOME"
echo "3) XFCE"
read -rp "Enter choice (1/2/3): " de_choice

case "$de_choice" in
    1)
        echo "Installing KDE Plasma..."
        sudo apt install -y kde-plasma-desktop sddm
        sudo systemctl enable sddm
        ;;
    2)
        echo "Installing GNOME..."
        sudo apt install -y gnome gnome-extra gdm3
        sudo systemctl enable gdm3
        ;;
    3)
        echo "Installing XFCE..."
        sudo apt install -y xfce4 lightdm
        sudo systemctl enable lightdm
        ;;
    *)
        echo "Invalid choice, skipping DE installation."
        ;;
esac

# -----------------------------
# Flatpak apps
# -----------------------------
if ! flatpak remote-list | grep -q flathub; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

flatpak install -y flathub \
    com.discordapp.Discord \
    com.spotify.Client \
    com.valvesoftware.Steam

# -----------------------------
# Fastfetch setup (ASCII logo)
# -----------------------------
FASTFETCH_DIR="$HOME/.config/fastfetch"
mkdir -p "$FASTFETCH_DIR/logos"

cat > "$FASTFETCH_DIR/logos/skyware.txt" << 'EOF'
      @@@@@@@-         +@@@@@@.     
    %@@@@@@@@@@=      @@@@@@@@@@   
   @@@@     @@@@@      -     #@@@  
  :@@*        @@@@             @@@ 
  @@@          @@@@            @@@ 
  @@@           @@@@           %@@ 
  @@@            @@@@          @@@ 
  :@@@            @@@@:        @@@ 
   @@@@     =      @@@@@     %@@@  
    @@@@@@@@@@       @@@@@@@@@@@   
      @@@@@@+          %@@@@@@     
EOF

cat > "$FASTFETCH_DIR/config.jsonc" << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "~/.config/fastfetch/logos/skyware.txt",
    "padding": { "top": 0, "left": 2 }
  },
  "modules": [
    "title",
    "separator",
    { "type": "os", "format": "SkywareOS", "use_pretty_name": false },
    "kernel",
    "uptime",
    "packages",
    "shell",
    "cpu",
    "gpu",
    "memory"
  ]
}
EOF

# -----------------------------
# Patch /etc/os-release
# -----------------------------
if [ -w /etc/os-release ] || sudo -n true 2>/dev/null; then
    echo "== Patching /etc/os-release for SkywareOS =="
    sudo cp /etc/os-release /etc/os-release.backup
    sudo tee /etc/os-release > /dev/null << 'EOF'
NAME="SkywareOS"
PRETTY_NAME="SkywareOS"
ID=skywareos
ID_LIKE=debian
VERSION="Debian"
VERSION_ID=Debian
HOME_URL="https://github.com/SkywareSW"
LOGO=skywareos
EOF
else
    echo "⚠️ Cannot write to /etc/os-release, skipping system-wide branding"
fi

# -----------------------------
# btop theme
# -----------------------------
BTOP_DIR="$HOME/.config/btop"
mkdir -p "$BTOP_DIR/themes"

cat > "$BTOP_DIR/themes/skyware-red.theme" << 'EOF'
theme[main_bg]="#0a0000"
theme[main_fg]="#f2dada"
theme[title]="#ff4d4d"
theme[hi_fg]="#ff6666"
theme[selected_bg]="#2a0505"
theme[inactive_fg]="#8a5a5a"
theme[cpu_box]="#ff4d4d"
theme[cpu_core]="#ff6666"
theme[cpu_misc]="#ff9999"
theme[mem_box]="#ff6666"
theme[mem_used]="#ff4d4d"
theme[mem_free]="#ff9999"
theme[mem_cached]="#ffb3b3"
theme[net_box]="#ff6666"
theme[net_download]="#ff9999"
theme[net_upload]="#ff4d4d"
theme[temp_start]="#ff9999"
theme[temp_mid]="#ff6666"
theme[temp_end]="#ff3333"
EOF

cat > "$BTOP_DIR/btop.conf" << 'EOF'
color_theme = "skyware-red"
rounded_corners = True
vim_keys = True
graph_symbol = "block"
update_ms = 2000
EOF

# -----------------------------
# zsh + Starship
# -----------------------------
chsh -s /bin/zsh "$USER" || true

if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh
fi

rm -f ~/.config/starship.toml
rm -rf ~/.config/starship.d

mkdir -p ~/.config
cat > "$HOME/.zshrc" << 'EOF'
eval "$(starship init zsh)"
alias ll='ls -lah'
EOF

cat > "$HOME/.config/starship.toml" << 'EOF'
[character]
success_symbol = "➜"
error_symbol   = "✗"
vicmd_symbol   = "❮"

[directory]
truncation_length = 3
style = "gray"

[git_branch]
symbol = " "
style = "bright-gray"

[git_status]
style = "gray"
conflicted = "✖"
ahead = "↑"
behind = "↓"
staged = "●"
deleted = "✖"
renamed = "➜"
modified = "!"
untracked = "?"
EOF

# -----------------------------
# Install Debian ware script
# -----------------------------
sudo tee /usr/local/bin/ware > /dev/null << 'EOF'
# (Paste the full Debian ware script here)
EOF

sudo chmod +x /usr/local/bin/ware

echo "== SkywareOS Debian full setup complete =="
echo "→ You can now use the 'ware' command to install packages, setup environments, or manage your system."
echo "→ Log out or reboot recommended."
