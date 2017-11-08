#
# CREATE ARCHIVE FILE
#
data "archive_file" "archive" {
  type        = "zip"
  source_dir  = "${path.module}/../../code/AudioExtractor/"
  output_path = "${path.module}/../../build/build-${var.aws_extractor}.zip"
}

resource "aws_lambda_function" "lambda" {
  filename      = "${data.archive_file.archive.output_path}"
  function_name = "launch-${var.aws_extractor}"
  role          = "${aws_iam_role.lambda_extractor_role.arn}"
  handler       = "extract_audio.lambda_handler"
  runtime       = "python3.6"
  timeout       = "120"

  source_code_hash = "${base64sha256(file(data.archive_file.archive.output_path))}"
}

#
# AWS ROLE
#
# INTPUT ROLE
resource "aws_iam_role" "lambda_extractor_role" {
  name = "lambda_extractor_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow"
    }
    ]
}
EOF
}

# INPUT POLICY
resource "aws_iam_role_policy" "lambda_extractor_policy" {
  name = "lambda_extractor_policy"
  role = "${aws_iam_role.lambda_extractor_role.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Sid":"S3",
        "Action": [
            "s3:GetObject",
            "s3:HeadObject"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::*"
    },
    {
        "Sid":"CloudWatch",
        "Action": [
            "logs:*"
        ],
        "Effect":"Allow",
        "Resource": "*"
    },
    {
        "Sid":"EslaticTranscoder",
        "Action": [
            "elastictranscoder:CreateJob",
            "elastictranscoder:ListPipelines"
        ],
        "Effect":"Allow",
        "Resource": "*"
    }
    ]
}
EOF
}

# INPUT PERMISSION
resource "aws_lambda_permission" "bucket_access" {
  statement_id  = "AllowExecutionFromS3Bucket1"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.main.arn}"
}
