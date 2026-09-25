---
title: "Replacing a Failed Disk in a ZFS rpool Mirror (RAID1) on Proxmox VE"
categories:
  - proxmox
  - zfs
  - homelab
tags:
  - proxmox
  - zfs
  - raid1
  - storage
  - disks
excerpt: "A step-by-step guide to safely replacing a failed disk in a mirrored (RAID1) ZFS rpool that hosts the Proxmox VE installation itself, including bootloader recovery."
header:
  overlay_image:
  overlay_filter: rgba(0, 0, 0, 0.5)
---

Losing a disk in a **mirror (RAID1)** ZFS pool is one of those scenarios every homelab and production Proxmox VE setup should be prepared for. The good news: if the pool has redundancy (RAID1), the system keeps running on the remaining healthy disk, and replacing the failed drive is a fully safe, well-documented procedure — even when we're talking about **rpool**, the pool Proxmox itself is installed on.

This post walks through the entire process: diagnosis, physically swapping the disk, recreating the partition table, resilvering, and restoring the bootloader (systemd-boot or GRUB), based on the current [Proxmox VE Wiki – ZFS on Linux](https://pve.proxmox.com/wiki/ZFS_on_Linux#sysadmin_zfs_change_failed_dev) documentation.

## Diagnosing the Failed Disk

Before starting the replacement, check the pool status and identify which disk actually failed.

```bash
zpool status -v
```

During a failure, you'll see something like this:

```
  pool: rpool
 state: DEGRADED
status: One or more devices could not be used because the label is missing or invalid.
config:

        NAME        STATE     READ WRITE CKSUM
        rpool       DEGRADED     0     0     0
          mirror-0  DEGRADED     0     0     0
            sda2    ONLINE       0     0     0
            sdb2    UNAVAIL      0     0     0
```

It's also worth checking SMART data and kernel logs to confirm a genuine physical failure rather than, say, a loose SATA/SAS cable:

```bash
smartctl -a /dev/sdb
dmesg -T | grep -i sdb
```

Note down the disk identifier from `/dev/disk/by-id/` — you'll need it in later steps, since `/dev/sdX` names can change between reboots.

```bash
ls -la /dev/disk/by-id/ | grep sdb
```

## Checking Which Bootloader the System Uses

Because rpool also hosts the operating system, replacing the data isn't enough — you also need to restore the boot entry on the new disk. Since Proxmox VE 6.4 (and on EFI systems since 5.4), the default is `proxmox-boot-tool`, though older installations may still rely on classic GRUB. Check this with [web:1]:

```bash
proxmox-boot-tool status
```

The output will tell you whether the system uses `systemd-boot` or `grub` — this determines which commands you'll use in the final step.

## Physically Replacing the Disk

1. Shut down the machine (or, if your hardware supports hot-swap, you can do this live — depending on the controller/backplane).
2. Remove the failed disk from the server.
3. Install a new disk with **capacity equal to or greater than** the other disks in the mirror — ZFS requires the new device to be no smaller than the original.
4. Reboot the system (if it was powered off) and log in to the Proxmox host console.

## Copying the Partition Table from the Healthy Disk

Since rpool is a bootable pool, the new disk must have an identical partition layout to the healthy disk in the mirror (EFI/boot partition plus ZFS partition). Instead of manually creating partitions, clone the layout from the healthy disk using `sgdisk` [web:1]:

```bash
sgdisk <healthy_boot_disk> -R <new_disk>
sgdisk -G <new_disk>
```

- `sgdisk -R` copies the partition table from the healthy disk to the new one.
- `sgdisk -G` generates new, unique GUIDs for the partitions on the new disk, avoiding identifier conflicts.

Example with real device names (assuming the healthy disk is `/dev/sda` and the new one is `/dev/sdb`):

```bash
sgdisk /dev/sda -R /dev/sdb
sgdisk -G /dev/sdb
```

## Attaching the New Partition to the ZFS Pool

Now swap the failed ZFS partition for the partition on the new disk within the existing mirror [web:1]:

```bash
zpool replace -f rpool <old_zfs_partition> <new_zfs_partition>
```

For example, if ZFS lived on the second partition of the disk (`sdb2`), the command after replacement looks like this:

```bash
zpool replace -f rpool sdb2 sdb2
```

The pool will automatically start the **resilvering** process, rebuilding data on the new disk from the copy held on the other, healthy mirror member.

## Monitoring the Resilver

Rebuilding data can take anywhere from a few minutes to several hours, depending on pool size and I/O load. Watch the progress live with:

```bash
watch zpool status -v
```

The process is complete once the pool status returns to `ONLINE` and the `scan:` entry shows `resilvered ... in ...` with no errors.

## Restoring the Boot Entry on the New Disk

This is the step that sets this procedure apart from replacing a plain data disk — a bootable disk also needs its boot mechanism configured on the new drive [web:1].

### If You Use proxmox-boot-tool (systemd-boot or GRUB via proxmox-boot-tool)

```bash
proxmox-boot-tool format <new_disk_ESP>
proxmox-boot-tool init <new_disk_ESP> [grub]
```

Only add the `[grub]` parameter if `proxmox-boot-tool status` previously showed that the system uses GRUB — this matters especially if Secure Boot is enabled. The ESP (EFI System Partition) is usually the second partition on the disk (`sdb2` in a typical layout created by the Proxmox installer since version 5.4).

### If You Use Classic GRUB (PVE 6.3 or earlier, non-migrated installations)

```bash
grub-install <new_disk>
```

## Final Verification

Once resilvering finishes and the bootloader has been restored, run a full check:

```bash
zpool status -v
proxmox-boot-tool status
cat /etc/zfs/zpool.cache
```

It's also good practice to do a test reboot of the host to confirm the system boots correctly from both disks in the mirror — including the one you just replaced.

## Additional Notes

- **Don't upgrade pool features (`zpool upgrade`)** if your system still boots via classic GRUB — newer ZFS features can make the pool unmountable by the older GRUB implementation, resulting in an unbootable system [web:1].
- Set up email notifications from the ZED daemon (`/etc/zfs/zed.d/zed.rc`, `ZED_EMAIL_ADDR` variable) so you learn about the next disk failure automatically instead of stumbling on it during a routine check [web:1].
- It's worth keeping a snapshot of `zpool status -v` and `ls -la /dev/disk/by-id/` from a healthy system in your infrastructure documentation — it makes disk identification during a real outage much faster when you're working under time pressure.

Despite involving the system disk, the whole procedure is safe precisely because of RAID1 redundancy — the host never loses access to its data, and the only real "cost" is resilvering time and a moment of attention when restoring the bootloader.
