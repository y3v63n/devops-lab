## Hints

### Creating files with specific permissions
- Create a file first, then set permissions: `echo "content" > file.txt && chmod NNN file.txt`
- Or set permissions immediately after creation — chmod doesn't care about content
- Verify with: `ls -la file.txt` or `stat -c "%a %n" file.txt`

### Understanding the octal values
- `600` = rw------- (owner read+write, no one else)
- `644` = rw-r--r-- (owner read+write, everyone else read-only)
- `755` = rwxr-xr-x (owner full, everyone else read+execute)
- Each digit is a sum: read=4, write=2, execute=1

### Task 1: secret.txt with permissions 600
```bash
echo "classified" > /tmp/devops-lab/0A-03/secret.txt
chmod 600 /tmp/devops-lab/0A-03/secret.txt
```

### Task 2: shared.txt with permissions 644
```bash
echo "public" > /tmp/devops-lab/0A-03/shared.txt
chmod 644 /tmp/devops-lab/0A-03/shared.txt
```

### Task 3: script.sh with permissions 755
- Use `printf` to include a newline in the shebang line:
  ```bash
  printf '#!/bin/bash\necho hello\n' > /tmp/devops-lab/0A-03/script.sh
  chmod 755 /tmp/devops-lab/0A-03/script.sh
  ```

### Task 4: Read /etc/passwd octal permissions
- `stat -c "%a" /etc/passwd` prints just the octal mode (e.g., `644`)
- The `-c` flag takes a format string; `%a` means "access rights in octal"
- Write it: `stat -c "%a" /etc/passwd > /tmp/devops-lab/0A-03/passwd-perms.txt`
