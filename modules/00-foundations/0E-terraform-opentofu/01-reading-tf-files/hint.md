# Hints — Exercise 0E-01

## Task 1: annotations.txt

**Hint 1 — Finding providers**
Look in `main.tf` for the `terraform { required_providers { ... } }` block. Each entry is a provider. Also look for `provider "name" { ... }` blocks. Count them.

**Hint 2 — Finding resources**
Every `resource "type" "name" { ... }` block is one resource. Count the blocks. Record both the type (e.g., `aws_instance`) and the logical name (e.g., `web`).

**Hint 3 — Required vs optional variables**
In `variables.tf`, every `variable` block that has a `default = ...` line is optional. Any variable block **without** a `default` line is required — Terraform will prompt for it or error if not provided. `ami_id` has no default.

**Hint 4 — Finding dependencies**
Look inside resource blocks for references to other resources. The pattern is `resource_type.resource_name.attribute`. In `aws_instance.web`, find the lines that reference `aws_key_pair.deployer` and `aws_security_group.web`.

---

## Task 2: security-review.txt

**Hint 1 — SSH exposure**
Look at the `ingress` block for port 22 in `aws_security_group.web`. What CIDR is SSH open to? Is that a good idea for a production server? What would be better?

**Hint 2 — Public key path**
The `public_key_path` variable defaults to `~/.ssh/id_rsa.pub`. What problems could this cause in CI/CD or when multiple engineers use the config? How would you make this more explicit and auditable?

**Hint 3 — Other things to look for**
- Is there any encryption configuration for the EC2 instance root volume?
- Is the state file configuration present? What if this is run without a remote backend?
- The `ssh_allowed_cidr` variable defaults to `0.0.0.0/0` — same issue as Hint 1, but it's a variable so someone may not notice it.
- Egress is wide open (`0.0.0.0/0` all protocols) — is that appropriate?

---

## Format tips

Your `annotations.txt` does not need to be pretty — just clear. Plain lines like:

```
PROVIDERS: 1 — aws (hashicorp/aws ~> 5.0)
RESOURCES: 3
  - aws_instance.web
  - aws_security_group.web
  - aws_key_pair.deployer
REQUIRED: ami_id (no default)
...
```

Your `security-review.txt` should have at least two clearly labeled concerns. For each one: state the problem, point to the exact resource/variable, and suggest a fix.
