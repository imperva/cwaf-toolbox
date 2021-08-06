provider "aws" {
  region = var.aws_region
}

provider "incapsula" {
    api_id = var.api_id
    api_key = var.api_key
}

resource "aws_lambda_permission" "NEL" {
    statement_id = "AllowNELAPIInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.NEL_Handler.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.NEL.execution_arn}/*/*/*"
}

resource "aws_lambda_function" "NEL_Handler" {
    filename = "${path.cwd}/index.py.zip"
    function_name                  = "${var.aws_resource_prefix}-NEL_Handler"
    handler                        = "index.lambda_handler"
    layers                         = []
    memory_size                    = 128
    reserved_concurrent_executions = -1
    role                           = aws_iam_role.NEL_Role.arn
    runtime                        = "python3.7"
    timeout                        = 60

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
    name                  = "${var.aws_resource_prefix}-NELRole-TF"
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
    name                  = "${var.aws_resource_prefix}-NEL_NR_Delivery-TF"
    path                  = "/service-role/"
    tags                  = {}
}

resource "aws_iam_policy" "NEL_NR_Firehouse" {
    name   = "${var.aws_resource_prefix}-NEL_NR_Delivery_Policy"
    path   = "/service-role/"
    policy = jsonencode(
        {
            Statement = [
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
            ]
            Version   = "2012-10-17"
        }
    )
}

resource "aws_api_gateway_rest_api" "NEL" {
    api_key_source               = "HEADER"
    binary_media_types           = []
    disable_execute_api_endpoint = false
    minimum_compression_size     = -1
    name                         = "${var.aws_resource_prefix}-NEL"
    tags                         = {}

    endpoint_configuration {
        types            = [
            "EDGE",
        ]
    }
}

resource "aws_api_gateway_resource" "NEL" {
    rest_api_id = aws_api_gateway_rest_api.NEL.id
    parent_id = aws_api_gateway_rest_api.NEL.root_resource_id
    path_part = "nel"
}

resource "aws_api_gateway_integration" "LAMBDA_PROXY" {
    cache_key_parameters    = []
    cache_namespace         = aws_api_gateway_resource.NEL.id
    connection_type         = "INTERNET"
    http_method             = aws_api_gateway_method.ANY.http_method
    integration_http_method = "POST"
    passthrough_behavior    = "WHEN_NO_MATCH"
    request_parameters      = {}
    request_templates       = {}
    resource_id             = aws_api_gateway_resource.NEL.id
    rest_api_id             = aws_api_gateway_rest_api.NEL.id
    timeout_milliseconds    = 29000
    type                    = "AWS_PROXY"
    uri = aws_lambda_function.NEL_Handler.invoke_arn
}

resource "aws_api_gateway_method" "ANY" {
    api_key_required     = false
    authorization        = "NONE"
    authorization_scopes = []
    http_method          = "ANY"
    request_models       = {}
    request_parameters   = {
        "method.request.querystring.account_id" = false
        "method.request.querystring.asn"        = false
        "method.request.querystring.city"       = false
        "method.request.querystring.country"    = false
        "method.request.querystring.latitude"   = false
        "method.request.querystring.longitude"  = false
        "method.request.querystring.postalcode" = false
        "method.request.querystring.site_id"    = false
        "method.request.querystring.state"      = false
        "method.request.querystring.proxy_id"   = false
        "method.request.querystring.pop"        = false
        "method.request.querystring.origin_pop" = false
        "method.request.querystring.session_id" = false
        "method.request.querystring.request_id" = false
    }
    resource_id          = aws_api_gateway_resource.NEL.id
    rest_api_id          = aws_api_gateway_rest_api.NEL.id
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
    depends_on = [aws_api_gateway_method.ANY, aws_api_gateway_rest_api.NEL, aws_api_gateway_integration.LAMBDA_PROXY]
    rest_api_id = aws_api_gateway_rest_api.NEL.id
}

data "aws_secretsmanager_secret" "NEL_Secrets_Manager" {
    name = var.secret_store_name
}

data "aws_secretsmanager_secret_version" "NEL_Secret" {
    secret_id = data.aws_secretsmanager_secret.NEL_Secrets_Manager.id
}

resource "aws_kinesis_stream" "NEL_Receiver" {
    encryption_type  = "NONE"
    name             = "${var.aws_resource_prefix}-NEL_Receiver"
    retention_period = 24
    shard_count      = 5
    tags             = {}

    timeouts {}
}

resource "aws_kinesis_firehose_delivery_stream" "NEL_NR_Delivery" {
    destination    = "http_endpoint"
    name           = "${var.aws_resource_prefix}-NEL_NR_Delivery"
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
            enabled         = false
        }

        processing_configuration {
            enabled = false
        }

        request_configuration {
            content_encoding = "NONE"

            common_attributes {
                name  = "logtype"
                value = "nel"
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
            enabled         = false
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
resource "incapsula_incap_rule" "NEL_Header" {
    count = length(var.site_id)
    action        = "RULE_ACTION_RESPONSE_REWRITE_HEADER"
    add_missing   = true
    name          = "NEL_Header"
    rewrite_name  = "NEL"
    site_id       = var.site_id[count.index]
    to            = "{\"report_to\": \"default\", \"max_age\": 3600, \"include_subdomains\": true, \"success_fraction\": ${var.success_fraction}, \"failure_fraction\": ${var.failure_fraction}"
    filter = ""
}

resource "incapsula_incap_rule" "NEL_Report-To_Header" {
    count         = length(var.site_id)
    action        = "RULE_ACTION_RESPONSE_REWRITE_HEADER"
    add_missing   = true
    name          = "Report_To_NEL_Header"
    rewrite_name  = "Report-To"
    site_id       = var.site_id[count.index]
    to            = "{\"group\": \"default\", \"max_age\": 3600, \"endpoints\": [{\"url\": \"${aws_api_gateway_stage.Stage.invoke_url}/nel?account_id=$account_id&city=$city&country=$country&postalcode=$postalcode&state=$state&epoch=$epoch&longitude=$longitude&latitude=$latitude&site_id=$site_id&proxy_id=$proxy_id&pop=$pop&origin_pop=$origin_pop&session_id=$session_id&request_id=$request_id&asn=$asn\"}], \"include_subdomains\": true}"
    filter = ""
}
