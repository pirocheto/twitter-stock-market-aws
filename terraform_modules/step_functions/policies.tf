resource "aws_iam_role" "step_function_role" {
  name = "step_function_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "step_functions_policy" {
  name = "step_functions_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${var.bucket_name}*"
      },
      {
        Effect   = "Allow"
        Action   = ["states:InvokeHTTPEndpoint"]
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["events:RetrieveConnectionCredentials"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "arn:aws:secretsmanager:*:*:secret:events!connection/*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "step_functions_policy_attachment" {
  name       = "step_functions_policy_attachment"
  roles      = [aws_iam_role.step_function_role.name]
  policy_arn = aws_iam_policy.step_functions_policy.arn
}


######################
# Event brige policies
######################

resource "aws_iam_role" "eventbridge_role" {
  name = "eventbridge_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_policy" "eventbridge_policy" {
  name = "eventbridge_policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect   = "Allow",
        Action   = "states:StartExecution",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_policy_attachment" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_policy.arn
}
