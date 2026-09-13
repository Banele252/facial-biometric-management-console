output "repository_full_name" {
  description = "owner/name of the created repository."
  value       = github_repository.this.full_name
}

output "repository_html_url" {
  description = "Web URL of the repository."
  value       = github_repository.this.html_url
}

output "repository_ssh_clone_url" {
  description = "SSH URL to use with `git remote add origin`."
  value       = github_repository.this.ssh_clone_url
}

output "repository_git_clone_url" {
  description = "HTTPS URL to use with `git remote add origin`."
  value       = github_repository.this.git_clone_url
}
