# Exercise 0E-01: Reading Terraform/OpenTofu Configuration Files

## Theory

**Infrastructure as Code with Terraform/OpenTofu.** Terraform (and its open-source fork OpenTofu) lets you describe infrastructure — servers, networks, databases, DNS records — in declarative configuration files written in HCL (HashiCorp Configuration Language). Instead of clicking through a console or running imperative shell scripts, you write `.tf` files that describe the *desired end state*, and the tool figures out what needs to be created, changed, or deleted. The key building blocks are: **providers** (plugins that talk to an API like AWS, Azure, or GCP), **resources** (the actual infrastructure objects to create), **variables** (inputs that make configs reusable), **outputs** (values to expose after apply), and **data sources** (read-only lookups of existing infrastructure).

**HCL syntax and resource references.** HCL uses a `block_type "label" "name" { ... }` structure. Resources are referenced by other resources using the pattern `resource_type.resource_name.attribute` — for example, `aws_security_group.web.id` refers to the `id` attribute of a resource named `web` of type `aws_security_group`. These references create implicit dependencies: Terraform builds a dependency graph and ensures resources are created in the right order. If Resource B references Resource A, Terraform creates A first. You can also declare explicit dependencies with `depends_on`.

**State — the single source of truth.** Terraform maintains a state file (`terraform.tfstate`) that records what it last deployed. Every `plan` compares your `.tf` files against this state and the real infrastructure to compute a diff. If you lose state, Terraform no longer knows what it manages — it may try to recreate resources that already exist, or fail to delete things it should. In production, state is stored remotely (S3 + DynamoDB lock, Terraform Cloud, etc.) and is treated as critical infrastructure data.

**Installing OpenTofu (if not present).**
```bash
# Linux (one-liner)
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh -s -- --install-method standalone

# Or via package manager (Ubuntu/Debian)
sudo snap install --classic opentofu

# macOS
brew install opentofu

# Verify
tofu version
```

---

## Tasks

Work directory: `/tmp/devops-lab/0E-01/`

Run `reset.sh` first to populate the sample configuration.

**Task 1 — Annotate the configuration**

Read all `.tf` files in `/tmp/devops-lab/0E-01/sample-config/` carefully. Create a file at `/tmp/devops-lab/0E-01/annotations.txt` that answers the following questions. Write plain text — one answer per line or short paragraph:

1. How many providers are used, and which ones? (look in `terraform {}` blocks and `provider` blocks)
2. How many resources are defined, and what are their types and names?
3. Which variables have default values, and which are *required* (no default)?
4. What do the outputs expose?
5. Which resource references another resource (creates a dependency), and what is the reference expression used?

Example format (use your own words):
```
PROVIDERS: 1 provider — aws (hashicorp/aws ~> 5.0)
RESOURCES: 3 — aws_instance.web, aws_security_group.web, aws_key_pair.deployer
REQUIRED VARS: ami_id (no default)
OPTIONAL VARS: aws_region, instance_type, project_name, environment, ssh_allowed_cidr, public_key_path
OUTPUTS: instance_ip (public IP of the EC2 instance), security_group_id (SG ID)
DEPENDENCIES: aws_instance.web references aws_key_pair.deployer via aws_key_pair.deployer.key_name, and references aws_security_group.web via aws_security_group.web.id
```

**Task 2 — Security review**

The sample config has security issues. Write to `/tmp/devops-lab/0E-01/security-review.txt` identifying at least **2 security concerns** in the configuration. For each concern, state:
- What the problem is
- Where it appears in the config (which resource/variable)
- How you would fix it

---

## What Just Happened

You read a real-world-style Terraform configuration and identified its structure without running any commands. This is a critical skill: in code reviews, incident response, and infrastructure audits, you often need to read `.tf` files and quickly understand what they will create and what risks they carry.

The reference pattern (`resource_type.name.attribute`) is Terraform's way of wiring resources together and building a dependency graph. The provider block tells Terraform which plugin to download and use. Variables make the config reusable across environments. Outputs let other systems or modules consume values from this configuration.

---

## Interview Question

**"What is Terraform state? Why is it important and what happens if you lose it?"**

Terraform state (`terraform.tfstate`) is a JSON file that records the last-known mapping between your configuration and real infrastructure — resource IDs, attributes, dependencies. It is the source of truth for `plan`: Terraform compares desired state (your `.tf` files) against current state (the state file) and real infrastructure to determine what changes to make. If you lose state, Terraform loses track of what it manages. Running `plan` may show all resources as "to be created" (even if they already exist), and `apply` may try to create duplicates or fail with conflicts. Remote state backends (S3, GCS, Terraform Cloud) with locking prevent corruption from concurrent runs and guard against accidental loss.
