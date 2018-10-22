provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_route53_zone" "this" {
  name = "${var.domain}."
}

## api-gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.client_name}-${var.application_name}"
  description = "${var.description}"
  body        = "${var.swagger_template}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  stage_name    = "${var.stage}"
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  deployment_id = "${aws_api_gateway_deployment.deployment.id}"

  cache_cluster_enabled = "${var.cache_cluster_enabled}"
  cache_cluster_size    = "${var.cache_cluster_size}"

  tags {
    Name = "${var.client_name}-${var.application_name}"
  }
}

resource "aws_acm_certificate" "this" {
  provider          = "aws.us-east-1"
  domain_name       = "${var.subdomain}.${var.domain}"
  validation_method = "DNS"

  tags {
    Name             = "${var.subdomain}.${var.domain}"
    application_name = "${var.application_name}"
    client_name      = "${var.client_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count = "${var.use_custom_domain ? 1 : 0}"

  zone_id = "${data.aws_route53_zone.this.zone_id}"
  name    = "${aws_acm_certificate.this.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.this.domain_validation_options.0.resource_record_type}"
  records = ["${aws_acm_certificate.this.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = "${var.use_custom_domain ? 1 : 0}"
  provider                = "aws.us-east-1"
  certificate_arn         = "${aws_acm_certificate.this.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

# API Deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = ""
  description = "${sha256(var.swagger_template)}"

  variables = "${var.api_env}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_domain_name" "api_domain" {
  count = "${var.use_custom_domain ? 1 : 0}"

  domain_name     = "${var.subdomain}.${var.domain}"
  certificate_arn = "${aws_acm_certificate.this.arn}"
}

resource "aws_api_gateway_base_path_mapping" "dns_mapping" {
  count       = "${var.use_custom_domain ? 1 : 0}"
  api_id      = "${aws_api_gateway_rest_api.api.id}"
  domain_name = "${aws_api_gateway_domain_name.api_domain.domain_name}"
}

resource "aws_route53_record" "api_domain" {
  count = "${var.use_custom_domain ? 1 : 0}"

  zone_id = "${data.aws_route53_zone.this.zone_id}"
  name    = "${aws_api_gateway_domain_name.api_domain.domain_name}"
  type    = "A"

  alias {
    name                   = "${aws_api_gateway_domain_name.api_domain.cloudfront_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.api_domain.cloudfront_zone_id}"
    evaluate_target_health = true
  }
}
