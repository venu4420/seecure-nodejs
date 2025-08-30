variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "notification_email" {
  description = "Email for alerts"
  type        = string
}

variable "chat_webhook_url" {
  description = "Google Chat webhook URL"
  type        = string
}