# 0A-02: Disk Storage

## Theory

Every Linux system carves its storage into **filesystems** — logical containers that track where files are stored on physical devices. A filesystem doesn't just store data; it maintains an **inode table**, where each inode holds a file's metadata (permissions, ownership, timestamps, size) and pointers to the actual data blocks. The filename you see is just a human-readable label; the inode number is what the kernel actually uses. You can run out of inodes before running out of disk space — if you create millions of tiny files (like email spools or build caches), you'll hit inode exhaustion and get "No space left on device" even though `df` shows free space.

**Mount points** are where filesystems attach to the directory tree. Linux has one unified tree starting at `/`. Every filesystem — whether it's a separate partition, an NFS share, or a tmpfs — gets mounted somewhere in that tree. `df` shows you each mounted filesystem's capacity and usage. `du` descends into directories and tallies actual file sizes. `lsblk` shows the physical block devices and how they're partitioned — the hardware layer beneath the filesystems.

---

## Tasks

### Task 1: Find the Most-Used Filesystem

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/0A-02
   ```

2. Use `df -h` to see all filesystems in human-readable form:
   ```bash
   df -h
   ```

3. Find the filesystem with the highest **Use%**. Write just its mount point (e.g., `/` or `/boot`) to the output file:
   ```bash
   echo "/" > /tmp/devops-lab/0A-02/largest-fs.txt
   ```

---

### Task 2: Find the 3 Largest Directories Under /var

1. Use `du` to measure directory sizes under `/var` (suppress permission errors):
   ```bash
   sudo du -sh /var/* 2>/dev/null | sort -rh | head -3
   ```

2. Write the 3 paths (one per line, just the path — no sizes) to the output file:
   ```bash
   echo "/var/log" > /tmp/devops-lab/0A-02/largest-dirs.txt
   echo "/var/lib" >> /tmp/devops-lab/0A-02/largest-dirs.txt
   echo "/var/cache" >> /tmp/devops-lab/0A-02/largest-dirs.txt
   ```

---

### Task 3: List All Block Devices

1. Use `lsblk` to list block devices in tree format:
   ```bash
   lsblk
   ```

2. Write the full output to the file:
   ```bash
   lsblk > /tmp/devops-lab/0A-02/block-devices.txt
   ```

---

> **Interview Q:** What's an inode? What happens when you run out of inodes but still have disk space? How would you diagnose and fix inode exhaustion in production?

---

## What Just Happened

You just surveyed your system's storage at three levels. `df -h` gave you the filesystem view — where space is allocated, what's mounted, how full it is. `du` gave you the directory view — which subdirectories are actually consuming that space, letting you track down what's eating your disk. `lsblk` gave you the block device view — the physical layout of disks and partitions before any filesystem mounts.

In practice, disk space alerts are one of the most common pages a sysadmin receives. The workflow is always the same: `df -h` to find which filesystem is full, `du -sh /path/* | sort -rh | head -10` to find what's consuming it, then investigate and clean up. Understanding the inode layer saves you from the confusing "disk full" error that `df` contradicts.
