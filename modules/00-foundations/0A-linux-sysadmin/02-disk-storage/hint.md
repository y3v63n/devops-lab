## Hints

### Finding the most-used filesystem
- `df -h` shows all filesystems with human-readable sizes and a Use% column
- Sort by usage: `df -h | sort -k5 -rh | head -5` (column 5 is Use%)
- The mount point is the last column (e.g., `/`, `/boot`, `/home`)
- Write just the path: `echo "/" > /tmp/devops-lab/0A-02/largest-fs.txt`

### Finding the 3 largest directories under /var
- `du -sh /var/*` measures each top-level directory under /var
- Add `2>/dev/null` to suppress permission errors
- Pipe through `sort -rh` to sort by size (reverse, human-readable): `sudo du -sh /var/* 2>/dev/null | sort -rh | head -3`
- You need just the paths, not the sizes — use `awk '{print $2}'` to extract them
- Full pipeline: `sudo du -sh /var/* 2>/dev/null | sort -rh | head -3 | awk '{print $2}' > /tmp/devops-lab/0A-02/largest-dirs.txt`

### Listing block devices
- `lsblk` shows devices in a tree (disk → partitions)
- Redirect the output directly: `lsblk > /tmp/devops-lab/0A-02/block-devices.txt`
- You should see columns: NAME, MAJ:MIN, RM, SIZE, RO, TYPE, MOUNTPOINT
