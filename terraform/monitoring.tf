# Basic monitoring for free tier (simplified)

# Log-based metric for errors
resource "google_logging_metric" "error_count" {
  name   = "error_count"
  filter = "resource.type=\"cloud_run_revision\" AND severity>=ERROR"
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
  }
}

# Simple error alert policy
resource "google_monitoring_alert_policy" "error_alert" {
  display_name = "Error Alert"
  combiner     = "OR"
  conditions {
    condition_threshold {
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
      filter          = "metric.type=\"logging.googleapis.com/user/error_count\" AND resource.type=\"gae_app\""
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.email.name]
}

  notification_channels = []  # Simplified - no external notifications
  
  alert_strategy {
    auto_close = "1800s"
  }
}