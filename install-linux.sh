#!/usr/bin/env bash
# enhanced_arch_setup.sh: Comprehensive setup script for Arch Linux (KDE Plasma)
# This script handles:
# - System updates
# - Essential software installation (official repos, AUR, Flatpak)
# - Graphics drivers (NVIDIA/AMD/Intel)
# - Drive mounting in fstab with UUIDs
# - GRUB configuration with os-prober
# - User environment setup (ZSH, dotfiles, etc.)
# - Development environment setup

set -euo pipefail

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# Ensure script is run as root
if [[ "$EUID" -ne 0 ]]; then
  error "Please run as root (use sudo)"
fi

# Check if yay is installed, install if not
check_yay() {
  if ! command -v yay &> /dev/null; then
    log "Installing yay AUR helper..."
    pacman -S --needed --noconfirm git base-devel
    
    # Create a temporary user for building AUR packages if needed
    if ! id "aurbuilder" &>/dev/null; then
      useradd -m aurbuilder
      echo "aurbuilder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/aurbuilder
      chmod 0440 /etc/sudoers.d/aurbuilder
    fi
    
    cd /tmp
    rm -rf yay-git
    sudo -u aurbuilder git clone https://aur.archlinux.org/yay-git.git
    cd yay-git
    sudo -u aurbuilder makepkg -si --noconfirm
    success "yay installed successfully"
  else
    log "yay is already installed"
  fi
}

# Update system and sync package databases
system_update() {
  log "Updating system and syncing package databases..."
  pacman -Syu --noconfirm
  success "System updated successfully"
}

# Install official repository packages
install_official_packages() {
  log "Installing packages from official repositories..."
  
  # System utilities
  log "Installing system utilities..."
  read -p "Install system utilities? (y/n): " install_sys_utils
  if [[ "$install_sys_utils" == "y" ]]; then
    pacman -S --needed --noconfirm \
      base-devel sudo neovim vim git htop neofetch tree \
      wget curl unzip zip p7zip lzop rsync timeshift \
      reflector bat exa ripgrep fd fzf \
      pacman-contrib arch-install-scripts
    success "System utilities installed"
  else
    log "Skipping system utilities installation"
  fi

  # Network utilities
  log "Installing networking utilities..."
  read -p "Install network utilities? (y/n): " install_net_utils
  if [[ "$install_net_utils" == "y" ]]; then
    pacman -S --needed --noconfirm \
      networkmanager network-manager-applet nm-connection-editor \
      bluez bluez-utils blueman \
      openssh nmap traceroute whois inetutils \
      wireguard-tools openvpn
    success "Network utilities installed"
  else
    log "Skipping network utilities installation"
  fi

  # File systems support
  log "Installing filesystem support..."
  read -p "Install filesystem support packages? (y/n): " install_fs
  if [[ "$install_fs" == "y" ]]; then
    pacman -S --needed --noconfirm \
      ntfs-3g exfat-utils dosfstools f2fs-tools \
      e2fsprogs xfsprogs btrfs-progs
    success "Filesystem support packages installed"
  else
    log "Skipping filesystem support packages installation"
  fi

  # Development tools
  log "Installing development tools..."
  read -p "Install development tools? (y/n): " install_dev_tools
  if [[ "$install_dev_tools" == "y" ]]; then
    pacman -S --needed --noconfirm \
      gcc clang cmake make automake autoconf \
      python python-pip python-setuptools python-wheel \
      nodejs npm yarn \
      docker docker-compose \
      lazygit tmux zsh \
      jq yq shellcheck \
      man-db man-pages texinfo
    success "Development tools installed"
  else
    log "Skipping development tools installation"
  fi

  # GUI applications
  log "Installing GUI applications..."
  read -p "Install GUI applications? (y/n): " install_gui_apps
  if [[ "$install_gui_apps" == "y" ]]; then
    pacman -S --needed --noconfirm \
      firefox chromium \
      libreoffice-fresh \
      vlc mpv \
      gimp krita inkscape \
      kdenlive audacity \
      okular gwenview \
      kate konsole yakuake \
      ark filelight dolphin \
      flameshot spectacle \
      flatpak
    success "GUI applications installed"
  else
    log "Skipping GUI applications installation"
  fi

  # Fonts
  log "Installing fonts..."
  read -p "Install fonts? (y/n): " install_fonts
  if [[ "$install_fonts" == "y" ]]; then
    pacman -S --needed --noconfirm \
      ttf-dejavu ttf-liberation ttf-droid ttf-roboto \
      noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra \
      ttf-jetbrains-mono ttf-fira-code ttf-hack \
      adobe-source-code-pro-fonts adobe-source-sans-fonts \
      adobe-source-serif-fonts
    success "Fonts installed"
  else
    log "Skipping fonts installation"
  fi

  success "Official packages installed successfully"
}

# Install AUR packages
install_aur_packages() {
  log "Installing AUR packages using yay..."
  read -p "Install AUR packages? (y/n): " install_aur
  if [[ "$install_aur" == "y" ]]; then
    sudo -u "$(logname)" yay -S --needed --noconfirm \
      visual-studio-code-bin \
      postman-bin \
      google-chrome \
      timeshift-autosnap \
    success "AUR packages installed successfully"
  else
    log "Skipping AUR packages installation"
  fi
}

# Install Flatpak applications
install_flatpak_apps() {
  log "Setting up Flatpak and installing applications..."
  
  # Add Flathub remote
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  
  read -p "Install Flatpak applications? (y/n): " install_flatpak
  if [[ "$install_flatpak" == "y" ]]; then
    echo "Available Flatpak applications:"
    echo "1) Spotify"
    echo "2) Discord"
    echo "3) OBS Studio"
    echo "4) Slack"
    echo "5) Telegram"
    echo "6) DBeaver"
    echo "7) Signal"
    echo "8) IntelliJ IDEA Community"
    echo "9) Bitwarden"
    echo "10) OnlyOffice"
    echo "11) Zoom"
    echo "12) Flatseal"
    echo ""
    
    # Ask for each application individually
    read -p "Install Spotify? (y/n): " install_spotify
    read -p "Install Discord? (y/n): " install_discord
    read -p "Install OBS Studio? (y/n): " install_obs
    read -p "Install Slack? (y/n): " install_slack
    read -p "Install Telegram? (y/n): " install_telegram
    read -p "Install DBeaver? (y/n): " install_dbeaver
    read -p "Install Signal? (y/n): " install_signal
    read -p "Install IntelliJ IDEA Community? (y/n): " install_intellij
    read -p "Install Bitwarden? (y/n): " install_bitwarden
    read -p "Install OnlyOffice? (y/n): " install_onlyoffice
    read -p "Install Zoom? (y/n): " install_zoom
    read -p "Install Flatseal? (y/n): " install_flatseal
    
    # Install selected applications
    [[ "$install_spotify" == "y" ]] && flatpak install -y flathub com.spotify.Client
    [[ "$install_discord" == "y" ]] && flatpak install -y flathub com.discordapp.Discord
    [[ "$install_obs" == "y" ]] && flatpak install -y flathub com.obsproject.Studio
    [[ "$install_slack" == "y" ]] && flatpak install -y flathub com.slack.Slack
    [[ "$install_telegram" == "y" ]] && flatpak install -y flathub org.telegram.desktop
    [[ "$install_dbeaver" == "y" ]] && flatpak install -y flathub io.dbeaver.DBeaverCommunity
    [[ "$install_signal" == "y" ]] && flatpak install -y flathub org.signal.Signal
    [[ "$install_intellij" == "y" ]] && flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community
    [[ "$install_bitwarden" == "y" ]] && flatpak install -y flathub com.bitwarden.desktop
    [[ "$install_onlyoffice" == "y" ]] && flatpak install -y flathub org.onlyoffice.desktopeditors
    [[ "$install_zoom" == "y" ]] && flatpak install -y flathub us.zoom.Zoom
    [[ "$install_flatseal" == "y" ]] && flatpak install -y flathub com.github.tchx84.Flatseal
    
    success "Selected Flatpak applications installed"
  else
    log "Skipping Flatpak applications installation"
  fi
}

# Setup graphics drivers
setup_graphics_drivers() {
  log "Setting up graphics drivers..."
  
  read -p "Do you want to install graphics drivers? (y/n): " install_graphics
  if [[ "$install_graphics" != "y" ]]; then
    log "Skipping graphics driver installation"
    return
  fi
  
  # Check for NVIDIA
  if lspci | grep -i nvidia &>/dev/null; then
    log "NVIDIA GPU detected"
    read -p "Install NVIDIA drivers? (y/n): " install_nvidia
    
    if [[ "$install_nvidia" == "y" ]]; then
      log "Installing NVIDIA drivers..."
      pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
      
      # Create NVIDIA configuration for Xorg
      mkdir -p /etc/X11/xorg.conf.d/
      cat > /etc/X11/xorg.conf.d/20-nvidia.conf << EOF
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    Option         "NoLogo" "1"
    Option         "RegistryDwords" "EnableBrightnessControl=1"
    Option         "AllowEmptyInitialConfiguration"
EndSection
EOF

      # Create NVIDIA configuration for GRUB with DRM modeset
      read -p "Enable NVIDIA DRM modeset in GRUB? (y/n): " enable_drm
      if [[ "$enable_drm" == "y" ]]; then
        if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
          sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
        fi
      fi
      
      success "NVIDIA drivers installed and configured"
    fi
  fi
  
  # Check for AMD
  if lspci | grep -i amd &>/dev/null || lspci | grep -i radeon &>/dev/null; then
    log "AMD GPU detected"
    read -p "Install AMD drivers? (y/n): " install_amd
    
    if [[ "$install_amd" == "y" ]]; then
      log "Installing AMD drivers..."
      pacman -S --needed --noconfirm xf86-video-amdgpu mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
      success "AMD drivers installed"
    fi
  fi
  
  # Check for Intel
  if lspci | grep -i intel &>/dev/null; then
    log "Intel GPU detected"
    read -p "Install Intel drivers? (y/n): " install_intel
    
    if [[ "$install_intel" == "y" ]]; then
      log "Installing Intel drivers..."
      pacman -S --needed --noconfirm xf86-video-intel mesa lib32-mesa vulkan-intel lib32-vulkan-intel
      success "Intel drivers installed"
    fi
  fi
  
  # Install general video acceleration packages
  read -p "Install video acceleration packages? (y/n): " install_va
  if [[ "$install_va" == "y" ]]; then
    pacman -S --needed --noconfirm libva-utils vdpauinfo
  fi
}

# Configure GRUB
configure_grub() {
  log "Configuring GRUB bootloader..."
  
  read -p "Configure GRUB bootloader? (y/n): " configure_grub_yn
  if [[ "$configure_grub_yn" != "y" ]]; then
    log "Skipping GRUB configuration"
    return
  fi
  
  # Enable os-prober in GRUB configuration
  read -p "Enable OS-prober in GRUB (for dual boot)? (y/n): " enable_os_prober
  if [[ "$enable_os_prober" == "y" ]]; then
    if ! grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
      echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    fi
  fi
  
  # Update GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
  
  success "GRUB configured successfully"
}

# Setup automatic mounting of drives
setup_drive_mounting() {
  log "Setting up automatic drive mounting with UUIDs..."
  
  # Create mount points
  mkdir -p /home/"$(logname)"/mnt/{SSD,HDD,Windows}
  chown "$(logname)":"$(logname)" /home/"$(logname)"/mnt/{SSD,HDD,Windows}
  
  # Get list of drives (excluding the root filesystem)
  ROOT_DEVICE=$(findmnt -no SOURCE /)
  ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEVICE")
  
  log "Detected drives:"
  lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT | grep -v "$ROOT_UUID" | grep -i "ntfs\|ext4\|xfs\|btrfs" | tee /tmp/detected_drives
  
  # Function to safely add an entry to fstab
  add_to_fstab() {
    local uuid=$1
    local mountpoint=$2
    local fstype=$3
    local options=$4
    
    # Check if entry already exists
    if ! grep -q "$uuid" /etc/fstab; then
      echo "UUID=$uuid    $mountpoint    $fstype    $options    0    2" >> /etc/fstab
      log "Added $mountpoint to fstab"
    else
      warn "Entry for UUID=$uuid already exists in fstab"
    fi
  }
  
  # Prompt for drive selection
  echo
  read -p "Would you like to auto-mount detected drives? (y/n): " automount
  
  if [[ "$automount" == "y" ]]; then
    # Windows partition (NTFS)
    ntfs_drives=$(lsblk -o NAME,FSTYPE,UUID | grep ntfs | awk '{print $1, $3}')
    
    if [[ -n "$ntfs_drives" ]]; then
      log "Detected NTFS drives (Windows partitions):"
      echo "$ntfs_drives"
      
      # Get the first NTFS partition as Windows
      first_ntfs_uuid=$(echo "$ntfs_drives" | head -1 | awk '{print $2}')
      if [[ -n "$first_ntfs_uuid" ]]; then
        add_to_fstab "$first_ntfs_uuid" "/home/$(logname)/mnt/Windows" "ntfs-3g" "uid=1000,gid=1000,rw,user,exec,umask=000 0 0"
      fi
    fi
    
    # SSD/HDD partitions (ext4, xfs, btrfs, etc.)
    other_drives=$(lsblk -o NAME,FSTYPE,UUID | grep -E "ext4|xfs|btrfs" | grep -v "$ROOT_UUID" | awk '{print $1, $2, $3}')
    
    if [[ -n "$other_drives" ]]; then
      log "Detected Linux formatted drives:"
      echo "$other_drives"
      
      # SSD detection (crude method based on naming convention)
      ssd_drives=$(echo "$other_drives" | grep -i "ssd\|nvme")
      if [[ -n "$ssd_drives" ]]; then
        first_ssd_uuid=$(echo "$ssd_drives" | head -1 | awk '{print $3}')
        first_ssd_fs=$(echo "$ssd_drives" | head -1 | awk '{print $2}')
        
        if [[ -n "$first_ssd_uuid" ]]; then
          add_to_fstab "$first_ssd_uuid" "/home/$(logname)/mnt/SSD" "$first_ssd_fs" "defaults,uid=1000,gid=1000,exec 0 0"
        fi
      fi
      
      # HDD detection (remaining drives)
      hdd_drives=$(echo "$other_drives" | grep -v -i "ssd\|nvme")
      if [[ -n "$hdd_drives" ]]; then
        first_hdd_uuid=$(echo "$hdd_drives" | head -1 | awk '{print $3}')
        first_hdd_fs=$(echo "$hdd_drives" | head -1 | awk '{print $2}')
        
        if [[ -n "$first_hdd_uuid" ]]; then
          add_to_fstab "$first_hdd_uuid" "/home/$(logname)/mnt/HDD" "$first_hdd_fs" "defaults,uid=1000,gid=1000,exec 0 0"
        fi
      fi
    fi
    
    # Mount the drives
    mount -a
    success "Drives mounted successfully"
  else
    log "Skipping automatic drive mounting"
  fi
}

# Enable system services
enable_services() {
  log "Enabling essential services..."
  
  systemctl enable --now NetworkManager
  systemctl enable --now bluetooth
  systemctl enable --now docker
  systemctl enable --now fstrim.timer
  systemctl enable --now paccache.timer
  
  # Enable CUPS if installed
  if pacman -Q cups &>/dev/null; then
    systemctl enable --now cups
  fi
  
  success "Services enabled successfully"
}

# Setup ZSH as default shell with Oh-My-Zsh
setup_zsh() {
  log "Setting up ZSH with Oh-My-Zsh..."
  
  # Ensure zsh is installed
  pacman -S --needed --noconfirm zsh
  
  # Install Oh-My-Zsh for the regular user
  user=$(logname)
  user_home="/home/$user"
  
  # Install Oh-My-Zsh
  if [[ ! -d "$user_home/.oh-my-zsh" ]]; then
    sudo -u "$user" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install powerlevel10k theme
    sudo -u "$user" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$user_home/.oh-my-zsh/custom/themes/powerlevel10k"
    
    # Install useful plugins
    sudo -u "$user" git clone https://github.com/zsh-users/zsh-autosuggestions "$user_home/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    sudo -u "$user" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$user_home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    
    # Configure .zshrc
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$user_home/.zshrc"
    sed -i 's/plugins=(git)/plugins=(git docker docker-compose npm pip python sudo zsh-autosuggestions zsh-syntax-highlighting)/' "$user_home/.zshrc"
    
    # Set ZSH as default shell
    chsh -s "$(which zsh)" "$user"
  fi
  
  success "ZSH setup completed"
}

# Setup development environment and tools
setup_dev_environment() {
  log "Setting up development environment..."
  
  user=$(logname)
  user_home="/home/$user"
  
  # Setup git global config
  read -p "Would you like to configure git? (y/n): " configure_git
  if [[ "$configure_git" == "y" ]]; then
    read -p "Enter your git username: " git_username
    read -p "Enter your git email: " git_email
    
    sudo -u "$user" git config --global user.name "$git_username"
    sudo -u "$user" git config --global user.email "$git_email"
    sudo -u "$user" git config --global core.editor "vim"
    sudo -u "$user" git config --global init.defaultBranch "main"
  fi
  
  # Setup tmux configuration
  if [[ ! -f "$user_home/.tmux.conf" ]]; then
    log "Setting up tmux configuration..."
    cat > "$user_home/.tmux.conf" << EOF
# Set prefix to Ctrl+a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse mode
set -g mouse on

# Start window numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Improve colors
set -g default-terminal "screen-256color"

# Increase scrollback buffer size
set -g history-limit 10000

# Easier split commands
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Reload config file
bind r source-file ~/.tmux.conf \; display "Config reloaded!"
EOF
    chown "$user":"$user" "$user_home/.tmux.conf"
  fi
  
  # Setup Neovim config
  mkdir -p "$user_home/.config/nvim"
  chown -R "$user":"$user" "$user_home/.config/nvim"
  
  # Install vim-plug for Neovim
  log "Setting up Neovim with vim-plug..."
  sudo -u "$user" sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  
  # Create initial Neovim config
  cat > "$user_home/.config/nvim/init.vim" << EOF
" vim-plug setup
call plug#begin('~/.local/share/nvim/plugged')

" Essential plugins
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'sheerun/vim-polyglot'
Plug 'jiangmiao/auto-pairs'
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'morhetz/gruvbox'

call plug#end()

" Basic settings
syntax enable
set number
set relativenumber
set cursorline
set expandtab
set shiftwidth=2
set tabstop=2
set smartindent
set termguicolors
set background=dark
colorscheme gruvbox

" Key mappings
let mapleader = " "
nnoremap <leader>f :Files<CR>
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>s :source ~/.config/nvim/init.vim<CR>
EOF
  chown "$user":"$user" "$user_home/.config/nvim/init.vim"
  
  # Install Neovim plugins
  sudo -u "$user" nvim +PlugInstall +qall
  
  success "Development environment setup completed"
}

# Setup Pacman Hooks
setup_pacman_hooks() {
  log "Setting up Pacman hooks..."
  
  # Create hooks directory
  mkdir -p /etc/pacman.d/hooks
  
  # GRUB update hook
  cat > /etc/pacman.d/hooks/grub-update.hook << EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = grub

[Action]
Description = Updating GRUB config after GRUB update
When = PostTransaction
Exec = /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
EOF

  # Nvidia kernel module hook
  cat > /etc/pacman.d/hooks/nvidia.hook << EOF
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Package
Target = nvidia
Target = linux

[Action]
Description = Updating Nvidia module in initcpio
Depends = mkinitcpio
When = PostTransaction
Exec = /usr/bin/mkinitcpio -P
EOF

  # Clean package cache
  cat > /etc/pacman.d/hooks/clean-cache.hook << EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Cleaning pacman cache (keeping the latest 3 versions)...
When = PostTransaction
Exec = /usr/bin/paccache -rk3
EOF

  success "Pacman hooks configured"
}

# Optimize system performance
optimize_system() {
  log "Optimizing system performance..."
  
  read -p "Apply system performance optimizations? (y/n): " apply_optimizations
  if [[ "$apply_optimizations" != "y" ]]; then
    log "Skipping system performance optimizations"
    return
  fi
  
  # Create swappiness configuration
  cat > /etc/sysctl.d/99-swappiness.conf << EOF
# Reduce swappiness for better performance
vm.swappiness=10
EOF

  # I/O scheduler optimization
  cat > /etc/udev/rules.d/60-ioscheduler.rules << EOF
# Set scheduler for NVMe
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
# Set scheduler for SSD and eMMC
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# Set scheduler for rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF

  # Enable periodic TRIM for SSDs
  systemctl enable fstrim.timer
  
  success "System performance optimizations applied"
}

# Setup system security
setup_security() {
  log "Setting up system security..."
  
  read -p "Configure system security (firewall, fail2ban)? (y/n): " configure_security
  if [[ "$configure_security" != "y" ]]; then
    log "Skipping security configuration"
    return
  fi
  
  # Install security tools
  pacman -S --needed --noconfirm \
    ufw fail2ban \
    rkhunter lynis \
    cronie
  
  # Enable and configure firewall
  systemctl enable --now ufw
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow ssh
  ufw limit ssh
  
  # If KDE is installed, allow KDE Connect
  if pacman -Q plasma-desktop &>/dev/null; then
    ufw allow 1714:1764/udp
    ufw allow 1714:1764/tcp
  fi
  
  ufw enable
  
  # Enable and configure fail2ban
  systemctl enable --now fail2ban
  cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
EOF
  
  systemctl restart fail2ban
  
  success "System security configured"
}

# Main execution
main() {
  log "Starting comprehensive Arch Linux setup..."
  
  system_update
  check_yay
  install_official_packages
  install_aur_packages
  install_flatpak_apps
  setup_graphics_drivers
  configure_grub
  setup_drive_mounting
  enable_services
  setup_zsh
  setup_dev_environment
  setup_pacman_hooks
  optimize_system
  setup_security
  
  success "Arch Linux setup completed! You should reboot your system now."
  echo -e "\n${GREEN}✅ All done! You can reboot now to apply all changes.${NC}"
}

# Execute main function
main
