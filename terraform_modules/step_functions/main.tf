resource "aws_cloudwatch_event_connection" "finnhub_connection" {
  name               = "finnhub_connection"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "X-Finnhub-Token"
      value = var.finnhub_api_key
    }
  }
}



resource "aws_sfn_state_machine" "step_funcions" {
  name     = "twitter_stock_market_step_functions"
  role_arn = aws_iam_role.step_function_role.arn
  definition = jsonencode({
    StartAt = "Call third-party API",
    States = {
      "Call third-party API" = {
        Type     = "Task"
        Resource = "arn:aws:states:::http:invoke"
        Parameters = {
          Authentication = {
            ConnectionArn = aws_cloudwatch_event_connection.finnhub_connection.arn
          }
          ApiEndpoint     = "https://finnhub.io/api/v1/quote"
          Method          = "GET"
          QueryParameters = { "symbol" : "AAPL" }
        }
        Next = "PutObject"
      },
      PutObject = {
        Type     = "Task",
        Resource = "arn:aws:states:::aws-sdk:s3:putObject",
        Parameters = {
          Bucket      = var.bucket_name
          ContentType = "application/json"
          "Key.$"     = "States.Format('stock_market/raw/{}.json', States.UUID())"
          "Body.$"    = "$"
        },
        End = true
      }
    }
  })
}

resource "aws_cloudwatch_event_rule" "trigger_rule" {
  name                = "step_function_trigger_rule"
  description         = "Rule to trigger Step Function every 2 minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "step_function_target" {
  target_id = "step_function_target"
  rule      = aws_cloudwatch_event_rule.trigger_rule.name
  arn       = aws_sfn_state_machine.step_funcions.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}
