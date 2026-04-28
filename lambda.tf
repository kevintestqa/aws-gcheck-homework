data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "chewbacca_node_lambda" {
  type        = "zip"
  source_file = "./src/chewbacca-node-lambda.js"
  output_path = "./lambda/node.zip"
}

resource "aws_lambda_function" "chewbacca_node_lambda" {
  filename      = data.archive_file.chewbacca_node_lambda.output_path
  function_name = "node_lambda_function"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "chewbacca-node-lambda.handler"
  code_sha256   = data.archive_file.chewbacca_node_lambda.output_base64sha256

  runtime = "nodejs24.x"
}

#python
data "archive_file" "chewbacca_python_lambda" {
  type        = "zip"
  source_file = "./src/chewbacca-python-lambda.py"
  output_path = "./lambda/python.zip"
}

resource "aws_lambda_function" "chewbacca_python_lambda" {
  filename      = data.archive_file.chewbacca_python_lambda.output_path
  function_name = "python_lambda_function"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "chewbacca-python-lambda.lambda_handler"
  code_sha256   = data.archive_file.chewbacca_python_lambda.output_base64sha256

  runtime = "python3.14"
}


resource "aws_lambda_permission" "lambda_permission_node" {
  statement_id  = "AllowMyDemoAPIInvokeNode"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chewbacca_node_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.termina.execution_arn}/*"
}

#Python lambda permission:

resource "aws_lambda_permission" "lambda_permission_python" {
  statement_id  = "AllowMyDemoAPIInvokeNode"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chewbacca_python_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.termina.execution_arn}/*"
}