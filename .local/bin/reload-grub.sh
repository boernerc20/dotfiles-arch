#!/usr/bin/env bash
set -euo pipefail

# Robust GRUB refresh for UEFI + Btrfs (subvol=@) + dual boot.
# Assumes:
#   - ESP is mounted at /efi via /etc/fstab (UUID=193C-297D in your case)
#   - /etc/default/grub includes: GRUB_DISABLE_OS_PROBER=false and rootflags=subvol=@
#   - os-prober, efibootmgr installed

die() { echo "[!] $*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"
}

main() {
  # 0) deps
  need_cmd grub-install
  need_cmd grub-mkconfig
  need_cmd grub-script-check      # <-- NEW: we'll lint the generated config
  need_cmd efibootmgr
  need_cmd os-prober
  need_cmd grub-probe
  need_cmd findmnt
  need_cmd mount
  need_cmd install                # coreutils 'install' for atomic copy

  # 1) UEFI check
  [[ -d /sys/firmware/efi ]] || die "Not booted in UEFI mode; x86_64-efi grub-install will fail."

  # 2) Ensure ESP mounted at /efi (fstab should have it)
  if ! findmnt -no TARGET /efi >/dev/null 2>&1; then
    echo "[*] Mounting ESP at /efi via fstab..."
    mkdir -p /efi
    mount /efi || die "Failed to mount /efi. Check /etc/fstab and ESP UUID."
  fi

  # 3) Sanity probes (non-fatal)
  echo "[*] Probing filesystems for GRUB:"
  grub-probe /    -t fs || true   # should print btrfs
  grub-probe /efi -t fs || true   # should print fat
  grub-probe /    -t abstraction || true

  # 4) Detect other OSes (non-fatal if none)
  echo "[*] Running os-prober (OK if nothing shows for non-dual-boot):"
  os-prober || true

  # 5) Reinstall GRUB to the *Arch* ESP
  echo "[*] Reinstalling GRUB to the ESP at /efi..."
  grub-install \
    --target=x86_64-efi \
    --efi-directory=/efi \
    --bootloader-id=GRUB \
    --recheck

  # 6) Backup current grub.cfg (if present)
  if [[ -f /boot/grub/grub.cfg ]]; then
    cp -a /boot/grub/grub.cfg /boot/grub/grub.cfg.bak.$(date +%Y%m%d-%H%M%S)
  fi

  # 6.1) Generate to a temp file, validate, then atomically install  <-- CHANGED BLOCK
  TMP_CFG="/boot/grub/grub.cfg.new"
  echo "[*] Regenerating $TMP_CFG..."
  grub-mkconfig -o "$TMP_CFG"

  echo "[*] Validating $TMP_CFG..."
  grub-script-check "$TMP_CFG"   # exits non-zero on syntax errors

  echo "[*] Installing new grub.cfg..."
  install -m 0644 "$TMP_CFG" /boot/grub/grub.cfg
  rm -f "$TMP_CFG"

  # Best-effort clean-up for os-prober mounts (non-fatal)
  umount -l /var/lib/os-prober/mount 2>/dev/null || true
  rmdir /var/lib/os-prober/mount     2>/dev/null || true

  # 7) Show EFI entries
  echo "[*] Current EFI boot entries:"
  efibootmgr -v || true

  echo "[✓] GRUB updated successfully."
}

main "$@"
