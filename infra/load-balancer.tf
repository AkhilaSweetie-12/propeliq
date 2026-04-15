# -----------------------------------------------------------------------------
# Global Static IP for Ingress
# -----------------------------------------------------------------------------

resource "google_compute_global_address" "ingress" {
  name    = "${var.app_name}-ingress-ip"
  project = var.project_id
}

# -----------------------------------------------------------------------------
# Google-Managed SSL Certificate (conditional)
# -----------------------------------------------------------------------------

resource "google_compute_managed_ssl_certificate" "app" {
  count   = var.enable_managed_certificate && var.domain != "" ? 1 : 0
  project = var.project_id
  name    = "${var.app_name}-ssl-cert"

  managed {
    domains = [var.domain]
  }
}

# -----------------------------------------------------------------------------
# Cloud Armor Security Policy
# -----------------------------------------------------------------------------

resource "google_compute_security_policy" "app" {
  name    = "${var.app_name}-security-policy"
  project = var.project_id

  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }

  rule {
    action   = "deny(403)"
    priority = 1000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "Deny XSS attacks"
  }

  rule {
    action   = "deny(403)"
    priority = 1001
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "Deny SQL injection attacks"
  }

  rule {
    action   = "throttle"
    priority = 2000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
    description = "Rate limit: 100 requests per minute per IP"
  }
}