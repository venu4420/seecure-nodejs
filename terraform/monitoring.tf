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
  display_name = "High Error Rate"
  combiner     = "OR"
  
  conditions {
    display_name = "Error count condition"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/error_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 3
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}