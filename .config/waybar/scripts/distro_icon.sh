#!/usr/bin/env bash
#
# distro-icon.sh — print a Nerd-Font icon for your Linux distro

# Load the standard os-release variables
if [ -r /etc/os-release ]; then
  . /etc/os-release
else
  echo ""  # fallback question-mark icon
  exit 0
fi

# Map $ID to an icon (requires a patched font like Nerd Font or Font Awesome)
case "$ID" in
  ubuntu)     icon=" " ;;  # Ubuntu
  arch)       icon=" " ;;  # Arch Linux
  fedora)     icon=" " ;;  # Fedora
  debian)     icon=" " ;;  # Debian
  manjaro)    icon=" " ;;  # Manjaro
  opensuse)   icon=" " ;;  # openSUSE
  centos)     icon=" " ;;  # CentOS
  void)       icon=" " ;;  # Void Linux
  alpine)     icon=" " ;;  # Alpine
  gentoo)     icon=" " ;;  # Gentoo
  void)       icon=" " ;;  # Void
  rocky)      icon=" " ;;  # Rocky Linux (use same as RHEL)
  rhel)       icon=" " ;;  # RHEL
  *)          icon=" " ;;  # unknown/fallback
esac

echo -e "$icon"
