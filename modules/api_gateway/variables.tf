variable "region" {
  description = "The AWS region"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "sqs_queue_name" {
  description = "The name of the SQS queue"
  type        = string
}

variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue"
  type        = string
}

variable "api_name" {
  description = "The name of the API Gateway REST API"
  type        = string
  default     = "flytrap-api"
}

variable "base_api_path" {
  description = "The base path part for API Gateway"
  type        = string
  default     = "api"
}

variable "errors_path" {
  description = "The 'errors' path ending for API Gateway"
  type        = string
  default     = "errors"
}

variable "stage_name" {
  description = "The deployment stage name"
  type        = string
  default     = "prod"
}