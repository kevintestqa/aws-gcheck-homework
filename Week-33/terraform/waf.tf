resource "aws_wafv2_web_acl" "hylian_shield" {
  scope = "REGIONAL"
  name  = "hylian_shield"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-tracking"
    sampled_requests_enabled   = true
  }
}

//Terraform registry advise on creating separate rules due to possible configuration drift if using aws_wafv2_web_acl_rule to manage rules
resource "aws_wafv2_web_acl_rule" "managed_rule" {
  name        = "managed_rule"
  priority    = 2
  web_acl_arn = aws_wafv2_web_acl.hylian_shield.arn

//used to override rules in statement block
  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"
    }
  }

//Used to see track under Logging and metrics tab
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "manage_rule_tracking"
    sampled_requests_enabled   = true
  }
}

//Terraform registry advise on creating separate rules due to possible configuration drift if using aws_wafv2_web_acl_rule to manage rules
resource "aws_wafv2_web_acl_rule" "rate_limit_100_per_5_min" {
  name        = "rate_limit_100_per_5_min"
  priority    = 0
  web_acl_arn = aws_wafv2_web_acl.hylian_shield.arn

  action {
    block {}
  }

  statement {
    rate_based_statement {
      limit              = 100
      aggregate_key_type = "IP"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "rate-limit"
    sampled_requests_enabled   = true
  }
}

//Creates an acl association with REST api gateway
resource "aws_wafv2_web_acl_association" "hylian_association" {
  resource_arn = aws_api_gateway_stage.qa_environment.arn
  web_acl_arn  = aws_wafv2_web_acl.hylian_shield.arn
}

