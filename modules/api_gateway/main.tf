# iam role and policy to allow api gateway to connect to sqs
resource "aws_iam_role" "api_gateway_role" {
  name = "api_gateway_role"

  # grants permission to assume this role to api gateway
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# create policy allowing messages to be sent to sqs
resource "aws_iam_policy" "api_gateway_sqs_policy" {
  name   = "api_gateway_sqs_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sqs:SendMessage"
      Resource = var.sqs_queue_arn
    }]
  })
}

# attach policy to role
resource "aws_iam_role_policy_attachment" "api_gateway_sqs_attach" {
  policy_arn = aws_iam_policy.api_gateway_sqs_policy.arn
  role       = aws_iam_role.api_gateway_role.name
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name = var.api_name
}

# Creating the base 'api' resource
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.base_api_path
}

# Creating the 'errors' resource as a child of 'api'
resource "aws_api_gateway_resource" "errors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.api.id  # Link to the parent resource
  path_part   = var.errors_path
}

# should all of these be required?
resource "aws_api_gateway_model" "request_model" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  name        = "PostRequestModel"
  content_type = "application/json"
  schema = jsonencode({
    type = "object"
    properties = {
      error = {
        type = "object"
        properties = {
          name = { type = "string" }
          message = { type = "string" }
          stack = { type = "string" }
        }
        required = ["name", "message", "stack"]
      }
      handled = { type = "boolean" } # boolean is correct here, right?
      timestamp = { type = "string", format = "date-time" } # is this correct?
      project_id = { type = "string" }
    }
    required = ["error", "handled", "timestamp", "project_id"]
  })
}

resource "aws_api_gateway_request_validator" "request_validator" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  name        = "PostRequestValidator"
  validate_request_body = true
  validate_request_parameters = false # I think this is ok?
}

# API Gateway method (POST method for sending requests)
resource "aws_api_gateway_method" "post_errors" {
  rest_api_id   = aws_api_gateway_rest_api.api.id # API Gateway id from above
  resource_id   = aws_api_gateway_resource.errors.id # API Gateway endpoint from above
  http_method   = "POST"
  authorization = "NONE" # ("API_KEY")allows our SDKs to send error data without authentication tokens or IAM permissions

  request_models = {
    "application/json" = aws_api_gateway_model.request_model.name
  }

  request_validator_id = aws_api_gateway_request_validator.request_validator.id
}

# response for post method (this is the response to the sdk)
resource "aws_api_gateway_method_response" "post_200_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.errors.id
  http_method = aws_api_gateway_method.post_errors.http_method
  status_code = "200"

  # need to add
  response_parameters = {
    "method.response.header.Content-Type" = true
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods"  = "'POST'" # test
    "method.response.header.Access-Control-Allow-Headers"  = "'Content-Type'" # test
  }
}

resource "aws_api_gateway_method_response" "post_500_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.errors.id
  http_method = aws_api_gateway_method.post_errors.http_method
  status_code = "500"

  response_parameters = {
    "method.response.header.Content-Type" = true
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods"  = "'POST'" # test
    "method.response.header.Access-Control-Allow-Headers"  = "'Content-Type'" # test
  }
}

# see readme about above!
# once we add API keys, will need to provision a useage plan resource (output id so it can be added
# to env variables in ec2 module) and update above resources to require api keys

# API Gateway Integration with SQS
resource "aws_api_gateway_integration" "sqs_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id # API Gateway id from above
  resource_id             = aws_api_gateway_resource.errors.id # endoint from above
  http_method             = aws_api_gateway_method.post_errors.http_method # from above
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${var.account_id}/${var.sqs_queue_name}"

  credentials             = aws_iam_role.api_gateway_role.arn # This associates the IAM role with the integration

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

resource "aws_api_gateway_integration_response" "sqs_200_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.errors.id
  http_method = aws_api_gateway_method.post_errors.http_method
  status_code = "200"
  selection_pattern = "^2[0-9][0-9]"

  response_templates = {
    "application/json" = "{\"message\": \"Successfully processed message\"}"
  }

  depends_on = [aws_api_gateway_integration.sqs_integration]
}

resource "aws_api_gateway_integration_response" "sqs_500_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.errors.id
  http_method = aws_api_gateway_method.post_errors.http_method
  status_code = "500"
  selection_pattern = "^5[0-9][0-9]"

  response_templates = {
    "application/json" = "{\"message\": \"Internal server error while processing message\"}"
  }

  depends_on = [aws_api_gateway_integration.sqs_integration]
}

# Deployment for API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id # from above
  depends_on  = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_resource.errors,
    aws_api_gateway_method.post_errors,
    aws_api_gateway_integration.sqs_integration
  ] # these must complete before deploying
}

# Stage for API Gateway Deployment
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.stage_name
}