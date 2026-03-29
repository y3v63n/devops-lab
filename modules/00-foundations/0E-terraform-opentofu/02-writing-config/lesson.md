# Exercise 0E-02: Writing a Terraform Configuration

## Theory

**The local provider.** While most real-world Terraform configs target cloud APIs (AWS, GCP, Azure), the `local` provider lets you practice HCL syntax without cloud credentials. It can create, update, and delete files on the local filesystem — which perfectly demonstrates Terraform's lifecycle and makes every concept verifiable with a simple `ls` or `cat`. Everything you learn here transfers directly to real resources: the HCL syntax, variable declarations, output blocks, resource references, and the `init → plan → apply` workflow are identical.

**Writing HCL.** A Terraform configuration is a directory of `.tf` files. You typically separate concerns: `main.tf` for resources, `variables.tf` for input declarations, `outputs.tf` for output declarations. Variables are declared with a `variable "name" { ... }` block and referenced as `var.name`. String interpolation uses `"${var.name}"` syntax. Resources reference each other by `resource_type.resource_name.attribute` — this creates an implicit dependency. The `local_file` resource has a `content` argument (the string to write) and `filename` (where to write it).

**AWS equivalents.** In a real AWS config, instead of `local_file` you would use `aws_s3_object` to write content to S3, `aws_instance` to provision a server, or `aws_secretsmanager_secret_version` to store a config value. The pattern is always the same: declare resources, wire them together with references, declare what you want as outputs. The `local` provider is a sandbox — once you understand the workflow, switching to `aws` is mostly a matter of learning the resource types and their arguments.

---

## Tasks

Work directory: `/tmp/devops-lab/0E-02/`

**Task 1 — Write the Terraform configuration**

Create the following files in `/tmp/devops-lab/0E-02/`:

**`main.tf`** — must include:
- A `terraform {}` block requiring the `local` provider (`hashicorp/local`, version `~> 2.0`)
- A `local_file` resource named `config_json` that writes to `/tmp/devops-lab/0E-02/output/config.json` with content: `{"project": "<project_name>", "env": "<environment>"}` (use variable interpolation)
- A `local_file` resource named `readme` that writes a `README.md` to `/tmp/devops-lab/0E-02/output/README.md` with any meaningful content that includes the project name and environment
- Comments showing what the AWS equivalent would be (e.g., `# AWS equivalent: aws_s3_object "config" { ... }`)

**`variables.tf`** — must declare:
- `project_name` variable, type string, default `"devops-lab"`
- `environment` variable, type string, default `"dev"`

**`outputs.tf`** — must declare:
- An output for the config.json file path
- An output for the README.md file path

**Task 2 — Initialize**

```bash
cd /tmp/devops-lab/0E-02
tofu init    # or: terraform init
```

This downloads the `local` provider plugin into `.terraform/`. It must succeed before you can plan or apply.

**Task 3 — Plan and save output**

```bash
cd /tmp/devops-lab/0E-02
tofu plan 2>&1 | tee /tmp/devops-lab/0E-02/plan-output.txt
# or: terraform plan 2>&1 | tee /tmp/devops-lab/0E-02/plan-output.txt
```

The plan should show **2 resources to add** (the two `local_file` resources). Save it to `plan-output.txt`.

---

## What Just Happened

You wrote a complete Terraform module from scratch and ran the first two phases of the workflow. `init` reached out to the Terraform Registry, downloaded the `local` provider plugin binary, and stored it under `.terraform/providers/`. It also created `.terraform.lock.hcl` to pin the exact provider version — like a `package-lock.json` for infrastructure.

`plan` read your `.tf` files, consulted the state file (empty, since this is new), and computed a diff: 2 new resources to create. It showed you exactly what values each attribute would have, with `+` prefix for additions. Nothing was changed yet — plan is always read-only.

The same workflow applies to AWS: `tofu init` downloads the `aws` provider, `tofu plan` shows what EC2 instances, security groups, or S3 buckets would be created. The only difference is the provider and resource type names.

---

## Interview Question

**"What does `terraform init` do? What gets downloaded and where?"**

`terraform init` prepares the working directory for use. It reads the `required_providers` block in your configuration and downloads the specified provider plugins from the Terraform Registry (or a private registry) into `.terraform/providers/`. It also initializes the backend (where state is stored — local by default, but could be S3, GCS, etc.) and installs any child modules referenced with `module` blocks. It creates `.terraform.lock.hcl` to record the exact version and hash of each provider, ensuring consistent installs across machines. You must run `init` any time you add a new provider, change backend configuration, or check out a config for the first time. The `.terraform/` directory is local and gitignored — everyone who clones the repo runs their own `init`.
