terraform {
  required_version = ">= 1.5.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Token comes from the GITHUB_TOKEN environment variable — never referenced
# here, so it's never written to a tracked file or Terraform state's config.
provider "github" {
  owner = var.github_owner
}

resource "github_repository" "this" {
  name        = var.repo_name
  description = var.repo_description
  visibility  = "private"

  # No auto-created initial commit — this folder already has content to push
  # as the first commit, and an auto_init'd remote would conflict with that.
  auto_init = false

  has_issues   = true
  has_wiki     = false
  has_projects = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
}

# Blocks direct pushes to main — changes must go through a reviewed PR.
# enforce_admins = false means the repo owner/admins can still push directly
# or merge without review in a pinch; collaborators added later cannot.
resource "github_branch_protection" "main" {
  repository_id = github_repository.this.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 1
  }

  enforce_admins      = false
  allows_deletions    = false
  allows_force_pushes = false
}
