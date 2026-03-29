# Hints — Exercise 0E-02

## Task 1: Writing main.tf

**Hint 1 — Terraform block structure**
```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
```

**Hint 2 — local_file resource**
The `local_file` resource needs two key arguments: `filename` (full path to write) and `content` (the string to write). Use variable interpolation with `${}`:
```hcl
resource "local_file" "config_json" {
  filename = "/tmp/devops-lab/0E-02/output/config.json"
  content  = "{\"project\": \"${var.project_name}\", \"env\": \"${var.environment}\"}"
}
```
Or use a heredoc for the README:
```hcl
resource "local_file" "readme" {
  filename = "/tmp/devops-lab/0E-02/output/README.md"
  content  = <<-EOT
    # ${var.project_name}
    Environment: ${var.environment}
  EOT
}
```

**Hint 3 — AWS equivalent comment**
```hcl
# AWS equivalent: instead of local_file, you would use:
# resource "aws_s3_object" "config_json" {
#   bucket  = aws_s3_bucket.configs.id
#   key     = "config.json"
#   content = "{\"project\": \"${var.project_name}\", \"env\": \"${var.environment}\"}"
# }
```

---

## Task 1: Writing variables.tf

**Hint 1 — Variable declaration**
```hcl
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devops-lab"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
```

---

## Task 1: Writing outputs.tf

**Hint 1 — Output declaration**
Reference the `filename` attribute of the resource:
```hcl
output "config_json_path" {
  value       = local_file.config_json.filename
  description = "Path to the generated config.json"
}

output "readme_path" {
  value       = local_file.readme.filename
  description = "Path to the generated README.md"
}
```

---

## Task 2: Init

```bash
cd /tmp/devops-lab/0E-02
tofu init
```

You should see: `Terraform has been successfully initialized!`

If you see errors about missing providers or incorrect version constraints, check your `required_providers` block in `main.tf`.

---

## Task 3: Plan

```bash
cd /tmp/devops-lab/0E-02
tofu plan 2>&1 | tee /tmp/devops-lab/0E-02/plan-output.txt
```

A successful plan ends with: `Plan: 2 to add, 0 to change, 0 to destroy.`

If the plan shows errors, run `tofu validate` first to check for syntax problems.
