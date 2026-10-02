#!/usr/bin/env bash
# Ran on ubuntu@cloud-node-01 (OCI / Kubernetes cp-3).
# Initializes ONLY the new blank 100 GiB /dev/sdb shown on 2026-10-02.
# ONE-TIME INITIALIZER for a NEW BLANK OCI Longhorn block volume on cp-3.
#
# DO NOT use this script to recover or remount an existing Longhorn disk.
# It intentionally creates a new ext4 filesystem after proving the disk is blank.
#
# For cluster/Longhorn rebuilds with the existing disk intact:
# preserve the filesystem, remount it at /mnt/longhorn-data, then run
# configure-storage-nodes.sh.
set -Eeuo pipefail
umask 077
die() { printf 'STOP: %s\n' "$*" >&2; exit 1; }
trap 'printf "STOP at line %s. Preserve all output; do not force formatting or delete files.\n" "$LINENO" >&2' ERR

[[ ${1:-} == --initialize-new-oci-disk ]] || die 'Usage: sudo bash prepare-oci-longhorn.sh --initialize-new-oci-disk'
[[ $EUID == 0 ]] || die 'Run with sudo.'
for tool in lsblk findmnt blkid wipefs blockdev mkfs.ext4 mount mountpoint systemctl python3 udevadm; do
  command -v "$tool" >/dev/null || die "Missing command: $tool"
done

lh_dev=/dev/sdb
lh_mount=/mnt/longhorn-data
lh_guard=/usr/local/sbin/longhorn-data-mount-check
lh_root_uuid=c8cb7c2c-5c3e-4723-806e-e4f6a9646bd0
[[ $(findmnt -nro UUID --target /) == "$lh_root_uuid" ]] || die 'Wrong host or root filesystem UUID.'
[[ $(uname -m) == aarch64 ]] || die 'Expected the OCI ARM64 host.'
[[ -b $lh_dev && ! -L $lh_dev ]] || die 'Expected /dev/sdb to be a block device.'
[[ $(lsblk -dnro TYPE "$lh_dev") == disk ]] || die 'Target is not a whole disk.'
[[ $(blockdev --getsize64 "$lh_dev") == 107374182400 ]] || die 'Target is not the expected 100 GiB disk.'
[[ $(blockdev --getro "$lh_dev") == 0 ]] || die 'Target is read-only.'
lh_serial=$(lsblk -dnro SERIAL "$lh_dev" | tr -d '[:space:]')
[[ $lh_serial == 608c04* ]] || die "Unexpected disk serial: $lh_serial"
[[ -d /mnt && ! -L /mnt && ! -L $lh_mount ]] || die 'Unexpected mount-directory layout.'
[[ -f /etc/fstab && ! -L /etc/fstab ]] || die 'Unexpected /etc/fstab layout.'
[[ ! -e $lh_guard && ! -L $lh_guard ]] || die 'Mount guard already exists; inspect the previous run instead of rerunning.'
for lh_service in containerd kubelet; do
  [[ $(systemctl show -p LoadState --value "$lh_service.service") == loaded ]] || die "$lh_service.service is not loaded."
  lh_dropin="/etc/systemd/system/$lh_service.service.d/30-longhorn-data-mount.conf"
  [[ ! -e $lh_dropin && ! -L $lh_dropin ]] || die "Existing drop-in: $lh_dropin"
done
python3 - "$lh_dev" "$lh_mount" <<'PY'
import json, pathlib, subprocess, sys
dev, mount = sys.argv[1:]
def stop(message):
    raise SystemExit('STOP: ' + message)
disk = json.loads(subprocess.check_output(['lsblk','--json','--paths','--output','NAME,TYPE,FSTYPE,MOUNTPOINTS',dev]))['blockdevices']
if len(disk) != 1 or disk[0].get('children'):
    stop('Target has partitions or mapped child devices.')
if disk[0].get('fstype') or any(disk[0].get('mountpoints') or []):
    stop('Target has a filesystem or is mounted.')
holders = pathlib.Path('/sys/class/block/sdb/holders')
if not holders.is_dir() or any(holders.iterdir()):
    stop('Target has block-device holders, or holders cannot be checked.')
p = pathlib.Path(mount)
if p.exists() and (not p.is_dir() or any(p.iterdir())):
    stop('Mount directory already contains data or is not a directory.')
for line in pathlib.Path('/etc/fstab').read_text().splitlines():
    fields = line.split()
    if not fields or fields[0].startswith('#'):
        continue
    if len(fields) > 1 and (fields[1] == mount or fields[0].startswith(dev)):
        stop('fstab already refers to the target disk or mount directory.')
PY
lh_signatures=$(wipefs --no-act --noheadings --output TYPE "$lh_dev")
[[ -z $lh_signatures ]] || die 'Target has a recognized disk/filesystem signature; no formatting performed.'
if mountpoint -q "$lh_mount"; then die 'Target directory is already mounted.'; fi

lh_backup=$(mktemp -d /root/longhorn-oci-setup.XXXXXX)
cp -a /etc/fstab "$lh_backup/fstab.before"
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,UUID,MOUNTPOINTS,MODEL,SERIAL > "$lh_backup/lsblk.before.txt"
printf 'Verified new blank disk: %s; serial: %s; backup: %s\n' "$lh_dev" "$lh_serial" "$lh_backup"
printf 'Creating ext4 ONLY on %s. No force or wipe option is used.\n' "$lh_dev"
mkfs.ext4 -L longhorn-data -m 0 "$lh_dev"
udevadm settle
lh_uuid=$(blkid -s UUID -o value "$lh_dev")
[[ $lh_uuid =~ ^[[:xdigit:]-]+$ ]] || die 'Could not obtain the new filesystem UUID.'
printf '%s\n' "$lh_uuid" > "$lh_backup/new-filesystem-uuid.txt"
mkdir -p -m 0755 "$lh_mount"
cp -a /etc/fstab "$lh_backup/fstab.proposed"
printf '\n# Dedicated OCI Longhorn data volume; created 2026-10-02\nUUID=%s %s ext4 defaults,noatime,_netdev,nofail 0 2\n' "$lh_uuid" "$lh_mount" >> "$lh_backup/fstab.proposed"
findmnt --verify --tab-file "$lh_backup/fstab.proposed"
cat "$lh_backup/fstab.proposed" > /etc/fstab
systemctl daemon-reload
mount "$lh_mount"
mountpoint -q "$lh_mount" || die 'New disk did not mount.'
[[ $(findmnt -nro UUID --mountpoint "$lh_mount") == "$lh_uuid" ]] || die 'Mounted disk UUID does not match.'
mkdir -m 0700 "$lh_mount/longhorn"

# Boot/startup checks: missing or wrong data mount blocks the next start of
# containerd and kubelet. Existing running services are NOT restarted.
# This is startup protection, not runtime fencing of running containers.
mkdir -p /usr/local/sbin
cat > "$lh_guard" <<'GUARD'
#!/bin/sh
set -eu
/usr/bin/mountpoint -q /mnt/longhorn-data
GUARD
printf '[ "$(/usr/bin/findmnt -nro UUID --mountpoint /mnt/longhorn-data)" = "%s" ]\n' "$lh_uuid" >> "$lh_guard"
chmod 0755 "$lh_guard"
"$lh_guard"
for lh_service in containerd kubelet; do
  mkdir -p "/etc/systemd/system/$lh_service.service.d"
  cat > "/etc/systemd/system/$lh_service.service.d/30-longhorn-data-mount.conf" <<'UNIT'
[Unit]
RequiresMountsFor=/mnt/longhorn-data

[Service]
ExecStartPre=/usr/local/sbin/longhorn-data-mount-check
UNIT
done
systemctl daemon-reload
findmnt --verify
printf '\nSETUP COMPLETE — no services restarted and no Kubernetes resources changed.\n'
printf 'Longhorn path to register: /mnt/longhorn-data/longhorn\n'
printf 'Filesystem UUID: %s\nBackup directory: %s\n' "$lh_uuid" "$lh_backup"
findmnt --mountpoint "$lh_mount"
df -hT / "$lh_mount"
systemctl show containerd.service kubelet.service -p Id -p ActiveState -p RequiresMountsFor -p ExecStartPre
printf 'If a later step failed after formatting, do not rerun with force: keep this output for recovery.\n'
