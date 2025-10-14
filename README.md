# MkDocs on AWS (S3 + CloudFront) — Template

Use this repo as a template to spin up a static site with MkDocs, deployed to S3 behind CloudFront using GitHub Actions OIDC.

## Prereqs
- A Route53 public hosted zone for your domain.
- An AWS IAM OIDC provider for GitHub already set up in the account.

## Configure
1. Copy `infra/terraform.tfvars.example` to `infra/terraform.tfvars` and fill in values.
2. From `infra/`, initialize and apply Terraform.
3. Set GitHub repo secrets using the Terraform outputs:
   - `AWS_DEPLOY_ROLE_ARN`
   - `S3_BUCKET`
   - `CF_DISTRIBUTION_ID`
4. Push to `main` to deploy.

### One-liners
- Init/apply: `cd infra && terraform init && terraform apply -auto-approve`
- Set secrets (example with GitHub CLI): `gh secret set AWS_DEPLOY_ROLE_ARN -b"$(terraform -chdir=infra output -raw gh_deploy_role_arn)"; gh secret set S3_BUCKET -b"$(terraform -chdir=infra output -raw bucket_name)"; gh secret set CF_DISTRIBUTION_ID -b"$(terraform -chdir=infra output -raw distribution_id)"`

## Local dev
- Serve locally: `pip install -r requirements.txt && mkdocs serve`

