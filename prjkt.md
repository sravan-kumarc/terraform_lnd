# Terraform — Comprehensive Project

> Purpose: single end-to-end example that demonstrates provider configuration, backends and locking, modules, workspaces, provisioners, .tpl templates, data sources, variables, tfvars, debugging, state storage, and CI integration.

---

## 1) Project goals

- Show real-world structure for a multi-environment infrastructure (dev / staging / prod) using **workspaces**.
- Store remote state in **S3 backend** with **DynamoDB** locking.
- Split reusable infrastructure into **modules** (network, compute, database, monitoring).
- Use **data sources** to consume existing infra (e.g., AMI, VPC ID).
- Demonstrate **provisioners** for last-mile bootstrapping (file, remote-exec). Clarify when to avoid them.
- Use **template file (.tpl)** to generate config files (cloud-init, systemd unit, application config).
- Show **.tfvars** and environment-specific variables, and `var` definitions with validation and descriptions.
- Show **debugging** tips (`terraform plan -out`, `TF_LOG`, `terraform state` commands) and common pitfalls.
- Illustrate **state file storage** best practices and encryption.
- Example **CI pipeline** to run `fmt`, `validate`, `plan`, `apply` with approval gates.

---

## 2) High-level architecture

- Provider: `aws` (primary example). Can be swapped to other cloud providers by replacing provider block and minimal tweaks.
- Environments: `dev`, `staging`, `prod` (represented by workspaces and separate tfvars files).
- Modules:
  - `modules/network` — VPC, subnets, route tables, IGW, NAT
  - `modules/compute` — Autoscaling group, launch template, EC2; uses provisioners and template_file
  - `modules/db` — RDS instance with subnet group and parameter group
  - `modules/monitoring` — CloudWatch alarms, IAM roles, Grafana (optional)
- Root stack orchestrates modules and configures backend.

---

## 3) File tree (recommended)

```
terraform-comprehensive-project/
├── README.md
├── global/                     # infra shared across accounts/regions
│   └── s3-backend.tf           # backend and remote state bootstrap
├── envs/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── provider.tf
│   ├── staging/
│   └── prod/
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── user_data.tpl
│   │   └── variables.tf
│   ├── db/
│   └── monitoring/
├── scripts/
│   └── bootstrap-state.sh     # bootstrap s3/dynamodb for backend (optional)
├── ci/
│   └── github-actions.yaml
└── modules_registry/          # optional: mono-repo modules examples
```

---

## 4) Example: backend + locking (S3 + DynamoDB)

`global/s3-backend.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

# This is a helper to create the S3 and DynamoDB table used as backend.
# Run `terraform init` manually here or run script to bootstrap resources.
resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name
  acl    = "private"
  versioning { enabled = true }
  server_side_encryption_configuration {
    rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
  }
}

resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute { name = "LockID" type = "S" }
}

output "bucket" { value = aws_s3_bucket.tfstate.id }
output "dynamodb_table" { value = aws_dynamodb_table.lock.id }
```

Then in each environment directory (e.g. `envs/dev/provider.tf`):

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
```

Notes:
- Use lifecycle `prevent_destroy` for global backend resources (or manage bootstrap separately).
- Keep the backend config out of version control when it contains sensitive bucket names — you can use partial backend config and populate with `-backend-config` in CI.

---

## 5) Provider and multiple provider aliases

`envs/dev/provider.tf` (example with aliased providers):

```hcl
provider "aws" {
  alias  = "primary"
  region = var.region
}

provider "aws" {
  alias  = "monitoring"
  region = var.monitoring_region
}

# Pass provider to modules when required:
module "compute" {
  source = "../../modules/compute"
  providers = { aws = aws.primary }
  # other inputs
}
```

---

## 6) Modules (example compute module with template and provisioner)

`modules/compute/main.tf` (abridged):

```hcl
variable "instance_count" { type = number }
variable "instance_type" { type = string }
variable "ami_id" { type = string }
variable "key_name" { type = string }

resource "aws_launch_template" "app" {
  name_prefix   = "app-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  user_data = templatefile("${path.module}/user_data.tpl", {
    env = var.env
    app_port = var.app_port
  })
}

resource "aws_autoscaling_group" "asg" {
  name                      = "app-asg-${var.env}"
  max_size                  = var.instance_count
  min_size                  = 1
  desired_capacity          = var.instance_count
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}

# Provisioner example — only for bootstrap tasks that cannot be done via cloud-init
resource "null_resource" "post_bootstrap" {
  count = var.run_provisioner ? 1 : 0

  triggers = {
    asg_id = aws_autoscaling_group.asg.id
  }

  connection {
    type        = "ssh"
    host        = element(aws_instance.app.*.public_ip, 0)
    user        = var.ssh_user
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/files/app.service"
    destination = "/tmp/app.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/app.service /etc/systemd/system/app.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable --now app",
    ]
  }
}
```

`modules/compute/user_data.tpl` (example cloud-init header)

```
#cloud-config
runcmd:
  - [ sh, -c, "echo 'Starting app on ${app_port}' > /tmp/app.log" ]
  - [ sh, -c, "docker run -d -p ${app_port}:80 myapp:latest" ]
```

Notes:
- Prefer `user_data` or `cloud-init` for bootstrapping; provisioners are a last resort.
- Use `null_resource` with triggers to control re-run behavior.

---

## 7) Template files (.tpl) vs `templatefile()` function

- Use `.tpl` files with `templatefile()` for easier templating and readability.
- Example above shows passing variables into `user_data.tpl`.

---

## 8) Data sources

Examples:

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter { name = "name" values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] }
}

data "aws_vpc" "default" {
  default = true
}
```

Use data sources to avoid hardcoding IDs and to integrate with existing infra.

---

## 9) Variables & tfvars

`envs/dev/variables.tf`:

```hcl
variable "region" { type = string, default = "us-east-1" }
variable "instance_count" { type = number, default = 1 }
variable "env" { type = string }
variable "app_port" { type = number, default = 8080 }

variable "allowed_cidrs" {
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "List of CIDRs allowed to access the app (restrict in prod)."
}
```

`envs/dev/terraform.tfvars`:

```hcl
env = "dev"
instance_count = 1
region = "us-east-1"
```

Security note: do not commit secrets to tfvars; use environment variables, vault, or CI secrets.

---

## 10) Workspaces

- Create workspaces `terraform workspace new dev` / `staging` / `prod`.
- Use `terraform.workspace` inside configs to alter names or to pick different values.

Example:

```hcl
locals {
  suffix = terraform.workspace == "default" ? "dev" : terraform.workspace
}

resource "aws_s3_bucket" "app" {
  bucket = "myapp-${local.suffix}-${random_id.rnd.hex}"
}
```

Note: Some teams prefer separate directories + backend keys per environment rather than workspaces; both approaches have tradeoffs.

---

## 11) Debugging & testing

- `terraform fmt -check` and `terraform validate` in CI.
- `TF_LOG=DEBUG terraform apply` to see provider debug logs (be careful: may expose secrets in logs).
- `terraform plan -out=plan.tfplan` then `terraform show -json plan.tfplan > plan.json` for programmatic analysis.
- Use `terraform state list` / `terraform state show` to inspect resources.
- `terraform console` for expression evaluation.
- Use `-var-file` and `-backend-config` to avoid committing sensitive values.

---

## 12) Storing statefiles & encryption

- Use S3 with server-side encryption (SSE) and S3 versioning enabled.
- Use DynamoDB table for state locking.
- Restrict access to S3 bucket and DynamoDB via IAM policies to CI/principals only.
- Optionally enable client-side encrypted state with Terraform Cloud or remote backends (or use KMS encryption on S3 bucket).

---

## 13) Debugging common issues

- **State drift**: use `terraform refresh` and `terraform plan` often; reconcile manual changes.
- **Provider timeouts**: increase timeouts in resource blocks when hitting API rate limits.
- **Secrets in logs**: turn off `TF_LOG` when not needed; filter logs in CI.
- **Module versioning**: pin module sources and use `registry` or git tags.

---

## 14) CI example (GitHub Actions high level)

`ci/github-actions.yaml` (skeleton):

```yaml
name: terraform
on: [push, pull_request]

jobs:
  fmt-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      - run: terraform fmt -check -recursive

  validate-plan:
    runs-on: ubuntu-latest
    needs: fmt-check
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v2
      - run: |
          cd envs/${{ matrix.env }}
          terraform init -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
                         -backend-config="dynamodb_table=${{ secrets.TF_LOCK_TABLE }}"
          terraform workspace select ${{ matrix.env }} || terraform workspace new ${{ matrix.env }}
          terraform validate
          terraform plan -out=plan.tfplan
      - name: Upload plan
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: envs/${{ matrix.env }}/plan.tfplan

  apply:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    needs: validate-plan
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v2
      - run: |
          cd envs/prod
          terraform init -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
                         -backend-config="dynamodb_table=${{ secrets.TF_LOCK_TABLE }}"
          terraform workspace select prod || terraform workspace new prod
          terraform apply -auto-approve plan.tfplan
```

Notes:
- Keep `apply` gated (manual approval for prod) and protect `main` branch.
- Supply backend configs from secrets or CI variables.

---

## 15) Extras to add (optional enhancements)

- Use `terraform fmt` and `tflint` for linting.
- Integrate `terraform-compliance` or `sentinel` policies.
- Use remote state data sources: `terraform_remote_state` to reference outputs from other stacks.
- Store secrets in AWS Secrets Manager / Vault and reference via data sources in Terraform.
- Use `terragrunt` for DRY patterns across environments (optional).
- Consider Terraform Cloud / Enterprise for remote runs, state, and policy enforcement.

---

## 16) Example: `terraform_remote_state` usage

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state-bucket"
    key    = "global/network.tfstate"
    region = "us-east-1"
  }
}

# then use data.terraform_remote_state.network.outputs.vpc_id
```

---

## 17) Security checklist

- Do not commit `terraform.tfstate` or any `*.tfvars` containing secrets.
- Encrypt state at rest (SSE + KMS).
- Limit IAM to least privilege for the CI principal.
- Rotate keys and use short-lived credentials (OIDC/GitHub actions recommended).

---

## 18) Step-by-step quick start (dev)

1. Bootstrap backend (run `global/s3-backend.tf` in a dedicated AWS account or with appropriate credentials) or run `scripts/bootstrap-state.sh`.
2. In `envs/dev/` copy `terraform.tfvars.example` to `terraform.tfvars` and populate vars.
3. `terraform init`
4. `terraform workspace new dev` (or select existing)
5. `terraform plan -out=plan.tfplan`
6. `terraform apply plan.tfplan`

---

## 19) Deliverables in this repo

- Minimal working examples for each module.
- Scripts to bootstrap backend resources.
- CI pipeline example.
- Troubleshooting and debugging guide.

---

## 20) What I can add next (pick one)

- Fully worked repo with complete modules and tested examples for AWS (ready-to-run).  
- Terraform Cloud remote runs + policy examples.  
- Conversion for Azure / GCP providers.  
- Terragrunt wrapper example for multi-account setups.

---

_End of document._

