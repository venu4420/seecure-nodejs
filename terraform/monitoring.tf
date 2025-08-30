# Notification Channels
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Alerts"
  type         = "email"
  
  labels = {
    email_address = var.notification_email
  }
}

resource "google_monitoring_notification_channel" "chat" {
  display_name = "Google Chat"
  type         = "webhook_tokenauth"
  
  labels = {
    url = var.chat_webhook_url
  }
}

# Log-based Metric for Errors
resource "google_logging_metric" "error_count" {
  name   = "error_count_metric"
  filter = "resource.type=\"cloud_run_revision\" AND severity>=ERROR"
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
  }
}

# Error Alert Policy
resource "google_monitoring_alert_policy" "error_alert" {
  display_name = "High Error Rate Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "Error count condition"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/error_count_metric\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 3
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.chat.name]
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# CPU Alert Policy
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Usage Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "CPU usage warning"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.7
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.chat.name]
}

resource "google_monitoring_alert_policy" "cpu_critical" {
  display_name = "Critical CPU Usage Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "CPU usage critical"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Memory Alert Policy
resource "google_monitoring_alert_policy" "memory_alert" {
  display_name = "High Memory Usage Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "Memory usage warning"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.7
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.chat.name]
}

resource "google_monitoring_alert_policy" "memory_critical" {
  display_name = "Critical Memory Usage Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "Memory usage critical"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}