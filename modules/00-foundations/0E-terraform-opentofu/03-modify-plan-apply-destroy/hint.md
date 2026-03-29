# Hints — Exercise 0E-03

## Task 1: Modifying the configuration

**Hint 1 — Changing the environment default**
In `variables.tf`, find the `variable "environment"` block and change its `default` value:
```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"   # was "dev"
}
```

**Hint 2 — Adding the third resource**
Add this block to `main.tf` after the existing two `local_file` resources:
```hcl
resource "local_file" "deployment_notes" {
  filename = "/tmp/devops-lab/0E-03/output/deployment-notes.txt"
  content  = <<-EOT
    Deployment Notes
    ================
    Project:     ${var.project_name}
    Environment: ${var.environment}
    Notes:       Initial deployment — add release notes here
  EOT
}
```

---

## Task 2: Reading the plan output

**Hint 1 — Understanding the symbols**
- `+` green = resource will be created (new)
- `~` yellow = resource will be updated in place (changed)
- `-` red = resource will be destroyed
- `-/+` = resource will be replaced (destroy + create)

**Hint 2 — Expected plan summary**
```
Plan: 1 to add, 1 to change, 0 to destroy.
```
The `1 to change` is the `config_json` file (its content includes `${var.environment}` which changed from `dev` to `staging`). The `1 to add` is the new `deployment_notes` file.

Wait — both `config_json` and `readme` reference `var.environment`. Why does the plan show only 1 change? Check whether your `readme` content actually uses `var.environment`. If both reference it, you'll see `2 to change`.

---

## Task 3: Apply

```bash
cd /tmp/devops-lab/0E-03
tofu apply -auto-approve
```

After apply, check the files:
```bash
cat /tmp/devops-lab/0E-03/output/config.json
# Should show: {"project": "devops-lab", "env": "staging"}

cat /tmp/devops-lab/0E-03/output/deployment-notes.txt
# Should show your deployment notes content
```

---

## Task 4: Destroy

```bash
cd /tmp/devops-lab/0E-03
tofu destroy -auto-approve
```

After destroy:
```bash
ls /tmp/devops-lab/0E-03/output/
# Should be empty — all files removed
```

Check the state file:
```bash
cat /tmp/devops-lab/0E-03/terraform.tfstate | python3 -m json.tool | grep '"resources"'
# Should show: "resources": []
```

---

## Task 5: lifecycle-notes.txt

Write at least 3-4 sentences per phase. Think about:
- **Plan**: What did it show? Why did only some resources change? How did it know what was different?
- **Apply**: Which files were updated vs. newly created? Did it ask for confirmation (you used `-auto-approve`, but in production you might not)?
- **Destroy**: Where did the files go? Is the state file empty now? What would a second `apply` do?

Example structure:
```
Plan:
  The plan showed...

Apply:
  After applying...

Destroy:
  After destroy...

Re-applying after destroy would...
```
