variable "github_owner" {
  description = "GitHub username (or organization) that will own the repository. Required — no default, so a missing value fails clearly instead of guessing."
  type        = string
}

variable "repo_name" {
  description = "Name of the GitHub repository to create."
  type        = string
  default     = "facial-biometric-management-console"
}

variable "repo_description" {
  description = "Repository description shown on GitHub."
  type        = string
  default     = "Management console for the facial biometric verification platform — admin API and dashboard over the shared analytics database."
}
