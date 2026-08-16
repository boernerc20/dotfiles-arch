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
  endeavouros) icon=" " ;;  # EndeavourOS is Arch-based; nf-linux has
                               # no dedicated glyph for it, so this reuses
                               # Arch's. The $ID_LIKE fallback below covers
                               # any OTHER Arch derivative the same way —
                               # this explicit case just documents why.
  fedora)     icon=" " ;;  # Fedora
  debian)     icon=" " ;;  # Debian
  manjaro)    icon=" " ;;  # Manjaro
  opensuse)   icon=" " ;;  # openSUSE
  centos)     icon=" " ;;  # CentOS
  void)       icon=" " ;;  # Void Linux
  alpine)     icon=" " ;;  # Alpine
  gentoo)     icon=" " ;;  # Gentoo
  rocky)      icon=" " ;;  # Rocky Linux (use same as RHEL)
  rhel)       icon=" " ;;  # RHEL
  *)
    # No exact match on $ID — fall back to the FAMILY via $ID_LIKE before
    # giving up on a real icon. This is what actually matters for
    # portability: any future Arch/Debian/Fedora/SUSE derivative with its
    # own $ID gets a sensible icon with no case-statement edit needed.
    case "$ID_LIKE" in
      *arch*)          icon=" " ;;
      *debian*)        icon=" " ;;
      *fedora*|*rhel*) icon=" " ;;
      *suse*)          icon=" " ;;
      *)               icon=" " ;;  # truly unknown
    esac
    ;;
esac

echo -e "$icon"
