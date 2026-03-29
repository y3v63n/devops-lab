# Exercise 0E-03: Modify, Plan, Apply, Destroy

## Theory

**The Terraform workflow cycle.** Working with Terraform is a continuous loop: write or modify configuration, `plan` to preview changes, `apply` to execute them, and eventually `destroy` when resources are no longer needed. Each cycle teaches you something important: `plan` is your safety net — it shows exactly what will be created, changed, or destroyed before anything happens. In a team workflow, plan output is often saved as a file, reviewed in a pull request, and then applied using that exact saved plan to guarantee no drift between review and execution.

**Modify in place vs. recreate.** When you change a resource attribute in your config, Terraform tries to update it in place if the provider supports it. But some changes require destroying and recreating the resource — Terraform marks these with `-/+` (replace) in the plan output. For `local_file` resources, changing the content updates the file in place. For something like an `aws_instance`, changing the AMI ID would force replacement — the old VM is destroyed and a new one is created. Understanding this distinction is critical before applying changes in production.

**Destroy — the full teardown.** `terraform destroy` (or `tofu destroy`) is the inverse of apply: it reads your configuration, computes what needs to be deleted, and removes everything. In practice, destroy is used when decommissioning an environment (tearing down a dev environment at end of day, removing a feature branch environment, decommissioning a service). After destroy, the state file is empty. If you re-apply, all resources are created fresh. On AWS, this means terminating instances, deleting S3 buckets, removing security groups — complete cleanup, which is why IaC is so valuable for ephemeral environments.

---

## Tasks

Work directory: `/tmp/devops-lab/0E-03/`

Run `reset.sh` first — it creates a working Terraform config with initial state (two files already applied).

**Task 1 — Modify the configuration**

Open `/tmp/devops-lab/0E-03/main.tf` (or `variables.tf`) and make two changes:

1. Change the `environment` variable's default value from `"dev"` to `"staging"`
2. Add a **third** `local_file` resource named `deployment_notes` that writes to `/tmp/devops-lab/0E-03/output/deployment-notes.txt` with content describing the deployment (project name, environment, and a brief note)

**Task 2 — Plan and inspect the diff**

```bash
cd /tmp/devops-lab/0E-03
tofu plan 2>&1 | tee /tmp/devops-lab/0E-03/plan-output.txt
# or: terraform plan 2>&1 | tee /tmp/devops-lab/0E-03/plan-output.txt
```

Read the output. You should see:
- 1 resource to change (the files referencing `environment` will update)
- 1 resource to add (the new `deployment_notes` file)
- Total: `Plan: 1 to add, 1 to change, 0 to destroy`

**Task 3 — Apply the changes**

```bash
cd /tmp/devops-lab/0E-03
tofu apply -auto-approve
```

Verify the output files reflect the changes:
```bash
cat /tmp/devops-lab/0E-03/output/config.json
cat /tmp/devops-lab/0E-03/output/deployment-notes.txt
```

**Task 4 — Destroy everything**

```bash
cd /tmp/devops-lab/0E-03
tofu destroy -auto-approve
```

Check that the output files no longer exist:
```bash
ls /tmp/devops-lab/0E-03/output/
```

**Task 5 — Write your observations**

Create `/tmp/devops-lab/0E-03/lifecycle-notes.txt` and explain in your own words what happened at each step:
- What did `plan` show and why?
- What did `apply` do to the existing files vs. the new file?
- What did `destroy` do and where did the state end up?
- What would happen if you ran `apply` again after `destroy`?

---

## What Just Happened

You completed the full Terraform lifecycle: initial apply (done by reset.sh), modify config, plan (diff), apply (execute), destroy (teardown). The `plan` step was the most informative — it showed that changing `environment` from `"dev"` to `"staging"` would update existing files (Terraform knows their current content from state) and that the new resource was a net addition. State was updated after each apply and after destroy.

This pattern — modify → plan → review → apply — is exactly how teams operate Terraform in production. The plan is often posted to a pull request for peer review before anyone runs apply. The destroy step mirrors what happens in CI/CD pipelines for ephemeral environments: after a PR is merged and the test environment is no longer needed, a `terraform destroy` cleans up all resources so you don't pay for idle infrastructure.

---

## Interview Question

**"What's the difference between `terraform plan` and `terraform apply`? Can you apply without planning first? Should you?"**

`plan` is read-only: it computes a diff between desired state (your `.tf` files) and current state (state file + real infrastructure) and displays what would change — no infrastructure is touched. `apply` executes the changes and updates the state file. You can run `apply` without a prior explicit `plan` — Terraform will compute and show the plan, then ask for confirmation (unless `-auto-approve` is set). However, best practice in production is to save the plan to a file (`terraform plan -out=tfplan`), have it reviewed, and then apply that exact saved plan (`terraform apply tfplan`) — this guarantees that what was reviewed is exactly what gets applied, with no drift from config changes between plan and apply.
