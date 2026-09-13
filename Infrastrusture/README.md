# Infrastructure — GitHub repository

Terraform config that creates the private GitHub repository this project
lives in. It creates the empty repository only — it does not push any code;
that's a manual git step at the end of this doc.

## 1. Create a GitHub Personal Access Token

Needs permission to create repositories under your account:

- **Classic PAT** ([github.com/settings/tokens](https://github.com/settings/tokens)):
  `repo` scope.
- **Fine-grained PAT**: "Administration" repository permission set to
  **Read and write**, granted at the account level (there's no existing repo
  to scope it to yet).

Export it in your shell — never put it in a file in this repo:

```bash
export GITHUB_TOKEN="ghp_..."
```

## 2. Set your GitHub username

`github_owner` has no default, so Terraform will refuse to run without it.
Either:

```bash
cp terraform.tfvars.example terraform.tfvars
# then edit terraform.tfvars and fill in github_owner
```

or pass it per-command:

```bash
export TF_VAR_github_owner="your-github-username"
```

## 3. Run Terraform

```bash
cd Infrastrusture
terraform init
terraform plan     # review: should show exactly one resource to add
terraform apply
```

## 4. Push this project into the new (empty) repo

Terraform only created the repository shell. Connect this existing local
folder to it and push:

```bash
cd ..   # repo root
git init
git add .
git commit -m "Initial commit"
git remote add origin "$(terraform -chdir=Infrastrusture output -raw repository_ssh_clone_url)"
git branch -M main
git push -u origin main
```

(Use `repository_git_clone_url` instead of `repository_ssh_clone_url` if you
authenticate to GitHub over HTTPS rather than SSH.)

## Notes

- The repository is created as **private** and with
  `lifecycle { prevent_destroy = true }`, so `terraform destroy` will refuse
  to delete it — remove that block deliberately first if you ever actually
  want to.
- `auto_init = false`: GitHub does not create an initial commit/README, so
  there's nothing to reconcile with the `git push` above.
