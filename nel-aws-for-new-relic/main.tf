provider "aws" {
  region = var.aws_region
}

// Do not modify, provider must remain as is regardless of region you are deploying in
provider "aws" {
    alias = "east-1"
    region = "us-east-1"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "incapsula" {
    api_id = var.api_id
    api_key = var.api_key
}

data "aws_route53_zone" "zone" {
  name = var.naked_domain
}

data "aws_secretsmanager_secret" "NEL_Secrets_Manager" {
    name = var.secret_store_name
}

data "aws_secretsmanager_secret_version" "NEL_Secret" {
    secret_id = data.aws_secretsmanager_secret.NEL_Secrets_Manager.id
}

resource "aws_lambda_permission" "NEL" {
    statement_id = "AllowNELAPIInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.NEL_Handler.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.NEL.execution_arn}/Stage/POST/nel"
}

resource "aws_lambda_function" "NEL_Handler" {
    filename = "${path.module}/index.py.zip"
    function_name                  = "${var.aws_resource_prefix}_NEL_Handler"
    handler                        = "index.lambda_handler"
    memory_size                    = 128
    reserved_concurrent_executions = -1
    role                           = aws_iam_role.NEL_Role.arn
    runtime                        = "python3.8"
    timeout                        = 60
    source_code_hash = filebase64sha256("${path.module}/index.py.zip")
    environment {
        variables = {
            "StreamName" = aws_kinesis_stream.NEL_Receiver.name
        }
    }

    timeouts {}

    tracing_config {
        mode = "PassThrough"
    }
}

resource "aws_iam_role" "NEL_Role" {
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                        Service = [
                            "lambda.amazonaws.com",
                            "apigateway.amazonaws.com",
                            "firehose.amazonaws.com",
                        ]
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
    force_detach_policies = false
    managed_policy_arns   = []
    max_session_duration  = 3600
    name                  = "${var.aws_resource_prefix}_NEL_Role-TF"
    path                  = "/"
    tags                  = {}

    inline_policy {
        name   = "cloudwatch"
        policy = jsonencode(
            {
                Statement = [
                    {
                        Action   = "logs:*"
                        Effect   = "Allow"
                        Resource = "*"
                    },
                ]
                Version   = "2012-10-17"
            }
        )
    }
    inline_policy {
        name   = "kinesis"
        policy = jsonencode(
            {
                Statement = [
                    {
                        Action   = "kinesis:*"
                        Effect   = "Allow"
                        Resource = "*"
                    },
                ]
                Version   = "2012-10-17"
            }
        )
    }
    inline_policy {
        name   = "s3"
        policy = jsonencode(
            {
                Statement = [
                    {
                        Action   = "s3:*"
                        Effect   = "Allow"
                        Resource = "*"
                    },
                ]
                Version   = "2012-10-17"
            }
        )
    }
    inline_policy {
        name   = "secretsmanagers"
        policy = jsonencode(
            {
                Statement = [
                    {
                        Action   = "secretsmanager:*"
                        Effect   = "Allow"
                        Resource = "*"
                    },
                ]
                Version   = "2012-10-17"
            }
        )
    }
}

resource "aws_iam_role" "NEL_Firehose" {
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                        Service = "firehose.amazonaws.com"
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
    force_detach_policies = false
    managed_policy_arns   = [
        aws_iam_policy.NEL_NR_Firehouse.arn
    ]
    max_session_duration  = 3600
    name                  = "${var.aws_resource_prefix}_NEL_NR_Delivery-TF"
    path                  = "/service-role/"
    tags                  = {}
}

resource "aws_iam_policy" "NEL_NR_Firehouse" {
    name   = "${var.aws_resource_prefix}_NEL_NR_Delivery_Policy"
    path   = "/service-role/"
    policy = jsonencode(
        {
            Statement = [
//                {
//                    Action   = [
//                        "glue:GetTable",
//                        "glue:GetTableVersion",
//                        "glue:GetTableVersions",
//                    ]
//                    Effect   = "Allow"
//                    Resource = [
//                        "arn:aws:glue:us-east-1:658749227924:catalog",
//                        "arn:aws:glue:us-east-1:658749227924:database/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
//                        "arn:aws:glue:us-east-1:658749227924:table/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
//                    ]
//                    Sid      = ""
//                },
                {
                    Action   = [
                        "s3:AbortMultipartUpload",
                        "s3:GetBucketLocation",
                        "s3:GetObject",
                        "s3:ListBucket",
                        "s3:ListBucketMultipartUploads",
                        "s3:PutObject",
                    ]
                    Effect   = "Allow"
                    Resource = [
                        aws_s3_bucket.NEL_BOX.arn,
                        "${aws_s3_bucket.NEL_BOX.arn}/*",
                    ]
                    Sid      = ""
                },
//                {
//                    Action   = [
//                        "lambda:InvokeFunction",
//                        "lambda:GetFunctionConfiguration",
//                    ]
//                    Effect   = "Allow"
//                    Resource = "arn:aws:lambda:us-east-1:658749227924:function:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
//                    Sid      = ""
//                },
//                {
//                    Action    = [
//                        "kms:GenerateDataKey",
//                        "kms:Decrypt",
//                    ]
//                    Condition = {
//                        StringEquals = {
//                            kms:ViaService = "s3.us-east-1.amazonaws.com"
//                        }
//                        StringLike   = {
//                            kms:EncryptionContext:aws:s3:arn = [
//                                "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*",
//                            ]
//                        }
//                    }
//                    Effect    = "Allow"
//                    Resource  = [
//                        "arn:aws:kms:us-east-1:658749227924:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
//                    ]
//                },
//                {
//                    Action   = [
//                        "logs:PutLogEvents",
//                    ]
//                    Effect   = "Allow"
//                    Resource = [
//                        "arn:aws:logs:us-east-1:658749227924:log-group:/aws/kinesisfirehose/NEL_NR_Delivery:log-stream:*",
//                    ]
//                    Sid      = ""
//                },
                {
                    Action   = [
                        "kinesis:DescribeStream",
                        "kinesis:GetShardIterator",
                        "kinesis:GetRecords",
                        "kinesis:ListShards",
                    ]
                    Effect   = "Allow"
                    Resource = aws_kinesis_stream.NEL_Receiver.arn
                    Sid      = ""
                },
//                {
//                    Action    = [
//                        "kms:Decrypt",
//                    ]
//                    Condition = {
//                        StringEquals = {
//                            kms:ViaService = "kinesis.us-east-1.amazonaws.com"
//                        }
//                        StringLike   = {
//                            kms:EncryptionContext:aws:kinesis:arn = aws_kinesis_stream.NEL_Receiver.arn
//                        }
//                    }
//                    Effect    = "Allow"
//                    Resource  = [
//                        "arn:aws:kms:us-east-1:658749227924:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
//                    ]
//                },
            ]
            Version   = "2012-10-17"
        }
    )
}

resource "aws_api_gateway_rest_api" "NEL" {
    api_key_source               = "HEADER"
    binary_media_types           = []
    disable_execute_api_endpoint = true
    minimum_compression_size     = -1
    name                         = "${var.aws_resource_prefix}_NEL"
    tags                         = {}

    endpoint_configuration {
        types            = [
            "REGIONAL",
        ]
    }
}

resource "aws_api_gateway_rest_api_policy" "limited" {
    rest_api_id = aws_api_gateway_rest_api.NEL.id
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "execute-api:Invoke",
      "Resource": [
                "${aws_api_gateway_stage.Stage.execution_arn}/POST/nel",
                "${aws_api_gateway_stage.Stage.execution_arn}/OPTIONS/nel"
            ],
      "Condition" : {
        "IpAddress": {
          "aws:SourceIp": ["0.0.0.0/0"]
          }
      }
    }
  ]
}
EOF
}

resource "aws_api_gateway_method_response" "options_200" {
    rest_api_id   = aws_api_gateway_rest_api.NEL.id
    resource_id   = aws_api_gateway_resource.NEL.id
    http_method   = aws_api_gateway_method.OPTIONS.http_method
    status_code   = 204
    response_models = {
        "application/json" = "Empty"
    }
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true,
        "method.response.header.Strict-Transport-Security" = true,
        "method.response.header.Content-Security-Policy" = true
    }
    depends_on = [aws_api_gateway_method.OPTIONS]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = aws_api_gateway_rest_api.NEL.id
    resource_id   = aws_api_gateway_resource.NEL.id
    http_method   = aws_api_gateway_method.OPTIONS.http_method
    status_code   = 204
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'",
        "method.response.header.Access-Control-Allow-Methods" = "'POST'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'",
        "method.response.header.Strict-Transport-Security" = "'max-age=300; includeSubDomains; preload'",
        "method.response.header.Content-Security-Policy" = "'default-src 'none''"
    }
    depends_on = [aws_api_gateway_method_response.options_200]
}

resource "aws_api_gateway_resource" "NEL" {
    rest_api_id = aws_api_gateway_rest_api.NEL.id
    parent_id = aws_api_gateway_rest_api.NEL.root_resource_id
    path_part = "nel"
}

resource "aws_api_gateway_method_settings" "all" {
    rest_api_id = aws_api_gateway_rest_api.NEL.id
    stage_name  = aws_api_gateway_stage.Stage.stage_name
    method_path = "*/*"

    settings {
        metrics_enabled = true
        logging_level   = "INFO"
        data_trace_enabled = true
    }
}

resource "aws_api_gateway_integration" "LAMBDA_PROXY" {
    cache_namespace         = aws_api_gateway_resource.NEL.id
    connection_type         = "INTERNET"
    http_method             = aws_api_gateway_method.POST.http_method
    integration_http_method = "POST"
    passthrough_behavior    = "WHEN_NO_MATCH"
    resource_id             = aws_api_gateway_resource.NEL.id
    rest_api_id             = aws_api_gateway_rest_api.NEL.id
    timeout_milliseconds    = 29000
    type                    = "AWS_PROXY"
    uri = aws_lambda_function.NEL_Handler.invoke_arn
}

resource "aws_api_gateway_model" "NEL_Body" {
    content_type = "application/reports+json"
    name = "NELBody"
    rest_api_id = aws_api_gateway_rest_api.NEL.id
    schema = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "array",
  "items": [
    {
      "type": "object",
      "properties": {
        "age": {
          "type": "integer"
        },
        "type": {
          "type": "string"
        },
        "url": {
          "type": "string"
        },
        "body": {
          "type": "object",
          "properties": {
            "sampling_fraction": {
              "type": "number"
            },
            "referrer": {
              "type": "string"
            },
            "server_ip": {
              "type": "string"
            },
            "protocol": {
              "type": "string"
            },
            "method": {
              "type": "string"
            },
            "request_headers": {
              "type": "object"
            },
            "response_headers": {
              "type": "object"
            },
            "status_code": {
              "type": "integer"
            },
            "elapsed_time": {
              "type": "integer"
            },
            "phase": {
              "type": "string"
            },
            "type": {
              "type": "string"
            }
          },
          "required": [
            "type"
          ]
        }
      },
      "required": [
        "age",
        "type",
        "url",
        "body"
      ]
    }
  ]
}
EOF
}

resource "aws_api_gateway_request_validator" "NEL_Post" {
    name = "NELPost"
    rest_api_id = aws_api_gateway_rest_api.NEL.id
    validate_request_body = true
    validate_request_parameters = true

}

resource "aws_api_gateway_method" "POST" {
    depends_on = [aws_api_gateway_model.NEL_Body]
    api_key_required     = false
    authorization        = "NONE"
    http_method          = "POST"
    request_validator_id = aws_api_gateway_request_validator.NEL_Post.id
    request_parameters   = {
        "method.request.querystring.account_id" = true
        "method.request.querystring.asn"        = false
        "method.request.querystring.city"       = false
        "method.request.querystring.country"    = false
        "method.request.querystring.latitude"   = false
        "method.request.querystring.longitude"  = false
        "method.request.querystring.postalcode" = false
        "method.request.querystring.site_id"    = true
        "method.request.querystring.state"      = false
        "method.request.querystring.proxy_id"   = false
        "method.request.querystring.pop"        = false
        "method.request.querystring.origin_pop" = false
        "method.request.querystring.session_id" = false
        "method.request.querystring.request_id" = false
        "method.request.header.content-type" = true
    }
    resource_id          = aws_api_gateway_resource.NEL.id
    rest_api_id          = aws_api_gateway_rest_api.NEL.id
    request_models = {
        "application/reports+json" = "NELBody"
    }
}

resource "aws_api_gateway_method" "OPTIONS" {
    authorization = "NONE"
    http_method = "OPTIONS"
    resource_id = aws_api_gateway_resource.NEL.id
    rest_api_id = aws_api_gateway_rest_api.NEL.id
}

resource "aws_api_gateway_integration" "MOCK" {
    http_method             = aws_api_gateway_method.OPTIONS.http_method
    resource_id             = aws_api_gateway_resource.NEL.id
    rest_api_id             = aws_api_gateway_rest_api.NEL.id
    type                    = "MOCK"
    request_templates = {
        "application/json": "{\"statusCode\": 200}"
    }
    depends_on = [aws_api_gateway_method.OPTIONS]
}

resource "aws_api_gateway_stage" "Stage" {
    cache_cluster_enabled = false
    deployment_id         = aws_api_gateway_deployment.default.id
    rest_api_id           = aws_api_gateway_rest_api.NEL.id
    stage_name            = "Stage"
    tags                  = {}
    variables             = {}
    xray_tracing_enabled  = false
}

resource "aws_api_gateway_deployment" "default" {
    depends_on = [aws_api_gateway_method.POST, aws_api_gateway_method.OPTIONS, aws_api_gateway_rest_api.NEL, aws_api_gateway_integration.LAMBDA_PROXY]
    rest_api_id = aws_api_gateway_rest_api.NEL.id
    triggers = {
        redeployment = sha1(jsonencode([
        aws_api_gateway_resource.NEL.id,
        aws_api_gateway_method.POST.id,
        aws_api_gateway_method.OPTIONS.id,
        aws_api_gateway_integration.LAMBDA_PROXY.id,
        aws_api_gateway_integration.MOCK.id,
        ]))
    }
}

resource "aws_kinesis_stream" "NEL_Receiver" {
    encryption_type  = "NONE"
    name             = "${var.aws_resource_prefix}_NEL_Receiver"
    retention_period = 24
    shard_count      = 5
    tags             = {}

    timeouts {}
}

resource "aws_kinesis_firehose_delivery_stream" "NEL_NR_Delivery" {
    destination    = "http_endpoint"
    name           = "${var.aws_resource_prefix}_NEL_NR_Delivery"
    tags           = {}
    version_id     = "1"

    http_endpoint_configuration {
        buffering_interval = 60
        buffering_size     = 1
        name               = "New Relic"
        retry_duration     = 60
        role_arn           = aws_iam_role.NEL_Firehose.arn
        s3_backup_mode     = "FailedDataOnly"
        url                = "https://aws-api.newrelic.com/firehose/v1"
        access_key = jsondecode(data.aws_secretsmanager_secret_version.NEL_Secret.secret_string)["NR_API_KEY"]

        cloudwatch_logging_options {
            enabled         = true
            log_group_name  = "/aws/kinesisfirehose/${var.aws_resource_prefix}_NEL_NR_Delivery"
            log_stream_name = "HttpEndpointDelivery"
        }

        processing_configuration {
            enabled = false
        }

        request_configuration {
            content_encoding = "NONE"

            common_attributes {
                name  = "logtype"
                value = var.log_type
            }
        }
    }

    kinesis_source_configuration {
        kinesis_stream_arn = aws_kinesis_stream.NEL_Receiver.arn
        role_arn           = aws_iam_role.NEL_Firehose.arn
    }

    s3_configuration {
        bucket_arn         = aws_s3_bucket.NEL_BOX.arn
        buffer_interval    = 300
        buffer_size        = 5
        compression_format = "UNCOMPRESSED"
        role_arn           = aws_iam_role.NEL_Firehose.arn

        cloudwatch_logging_options {
            enabled         = true
            log_group_name  = "/aws/kinesisfirehose/${var.aws_resource_prefix}_NEL_NR_Delivery"
            log_stream_name = "S3Delivery"
        }
    }
}

resource "aws_s3_bucket" "NEL_BOX" {
    bucket                      = var.bucket_name
    request_payer               = "BucketOwner"
    tags                        = {}
    acl = "private"


    versioning {
        enabled    = false
        mfa_delete = false
    }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.NEL_BOX.id
    ignore_public_acls = true
    restrict_public_buckets = true
    block_public_acls   = true
    block_public_policy = true
}

resource "incapsula_incap_rule" "NEL_Header" {
    count = length(var.site_id)
    action        = "RULE_ACTION_RESPONSE_REWRITE_HEADER"
    add_missing   = true
    name          = "NEL_Header"
    rewrite_name  = "NEL"
    site_id       = var.site_id[count.index]
    to            = "{\"report_to\": \"default\", \"max_age\": ${var.max_age}, \"include_subdomains\": true, \"success_fraction\": ${var.success_fraction}, \"failure_fraction\": ${var.failure_fraction}}"
    filter = "ClientType == Browser"
}

resource "incapsula_incap_rule" "NEL_Report-To_Header" {
    count         = length(var.site_id)
    action        = "RULE_ACTION_RESPONSE_REWRITE_HEADER"
    add_missing   = true
    name          = "Report_To_NEL_Header"
    rewrite_name  = "Report-To"
    site_id       = var.site_id[count.index]
    to            = "{\"group\": \"default\", \"max_age\": ${var.max_age}, \"endpoints\": [{\"url\": \"https://${aws_api_gateway_domain_name.custom_api_domain.domain_name}/nel?${var.report_to_params}\"}], \"include_subdomains\": true}"
    filter = "ClientType == Browser"
}

resource "aws_wafregional_regex_match_set" "Imperva_Header" {
    name = "Allow Header"
    regex_match_tuple {
        regex_pattern_set_id = aws_wafregional_regex_pattern_set.method.id
        text_transformation = "NONE"
        field_to_match {
            type = "METHOD"
        }
    }
}

resource "aws_wafregional_regex_pattern_set" "method" {
    name = "Allow POST_OPTIONS"
    regex_pattern_strings = ["POST", "OPTIONS"]
}

resource "aws_wafregional_rule" "ProtectingNEL" {
    metric_name = "ProtectingNEL"
    name = "${var.aws_resource_prefix}_ProtectingNEL"
    predicate {
        data_id = aws_wafregional_regex_match_set.Imperva_Header.id
        negated = false
        type = "RegexMatch"
    }
}

resource "aws_wafregional_web_acl" "ProtectingNEL" {
    metric_name = "ProtectingNEL"
    name = "${var.aws_resource_prefix}_ProtectingNEL"
    default_action {
        type = "BLOCK"
    }
    rule {
        action {
            type = "ALLOW"
        }
        priority = 1
        rule_id = aws_wafregional_rule.ProtectingNEL.id
    }
}

resource "aws_wafregional_web_acl_association" "method" {
    resource_arn = aws_api_gateway_stage.Stage.arn
    web_acl_id = aws_wafregional_web_acl.ProtectingNEL.id
}

resource "aws_acm_certificate" "nel-cert" {
    provider = aws.east-1
    certificate_body = acme_certificate.certificate.certificate_pem
    certificate_chain = acme_certificate.certificate.issuer_pem
    private_key = tls_private_key.private_key.private_key_pem
}

resource "aws_acm_certificate" "nel-api-cert" {
    certificate_body = acme_certificate.certificate.certificate_pem
    certificate_chain = acme_certificate.certificate.issuer_pem
    private_key = tls_private_key.private_key.private_key_pem
}

resource "tls_private_key" "account_key" {
  algorithm = var.algorithm
}

resource "tls_private_key" "private_key" {
  algorithm = var.algorithm
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.account_key.private_key_pem
  email_address   = var.reg_email
}

resource "tls_cert_request" "impv" {
  key_algorithm = var.algorithm
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name = "${var.sub_domain}.${var.naked_domain}"
    organization = var.subject_organization
    organizational_unit = var.subject_organizational_unit
    country = var.subject_country
    postal_code = var.subject_postal_code
    locality = var.locality
    serial_number = var.serial_number
  }
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.reg.account_key_pem
  certificate_request_pem = tls_cert_request.impv.cert_request_pem

  dns_challenge {
    provider = "route53"
    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.zone.id
    }
  }
}

resource "aws_api_gateway_domain_name" "custom_api_domain" {
    domain_name = "${var.sub_domain}.${data.aws_route53_zone.zone.name}"
    regional_certificate_arn = aws_acm_certificate.nel-api-cert.arn
    security_policy = "TLS_1_2"
    endpoint_configuration {
        types = [
            "REGIONAL",
        ]
    }
}

resource "aws_api_gateway_base_path_mapping" "nel_mapping" {
    api_id = aws_api_gateway_rest_api.NEL.id
    domain_name = aws_api_gateway_domain_name.custom_api_domain.domain_name
    stage_name = aws_api_gateway_stage.Stage.stage_name
}

resource "aws_route53_record" "www_record" {
    type = "A"
    alias {
        evaluate_target_health = true
        name = aws_api_gateway_domain_name.custom_api_domain.regional_domain_name
        zone_id = aws_api_gateway_domain_name.custom_api_domain.regional_zone_id
    }
    name = aws_api_gateway_domain_name.custom_api_domain.domain_name
    zone_id = data.aws_route53_zone.zone.zone_id
}

resource "aws_cloudfront_distribution" "nel_front" {
    enabled = true
    default_cache_behavior {
        allowed_methods = ["GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "DELETE"]
        cached_methods = ["GET", "HEAD", "OPTIONS"]
        target_origin_id = aws_api_gateway_domain_name.custom_api_domain.domain_name
        viewer_protocol_policy = "https-only"
        forwarded_values {
            query_string = true
            cookies {
                forward = "none"
            }
        }
    }
    origin {
        domain_name = aws_api_gateway_domain_name.custom_api_domain.domain_name
        origin_id = aws_api_gateway_domain_name.custom_api_domain.domain_name
        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "https-only"
            origin_ssl_protocols = ["TLSv1.2"]
        }
    }
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
    viewer_certificate {
        acm_certificate_arn = aws_acm_certificate.nel-cert.arn
        ssl_support_method = "sni-only"
        minimum_protocol_version = "TLSv1.2_2019"
    }
}
