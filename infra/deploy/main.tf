# Lambda
data "archive_file" "archive" {
  type        = "zip"
  source_dir  = "${path.module}/../../code/AudioExtractor/"
  output_path = "${path.module}/../../build/build-${var.aws_extractor}.zip"
}

resource "aws_lambda_function" "audio_extractor" {
  filename      = "${data.archive_file.archive.output_path}"
  function_name = "${var.aws_extractor}"
  role          = "${aws_iam_role.lambda_extractor.arn}"
  handler       = "entrypoint.lambda_handler"
  runtime       = "python3.6"
  timeout       = "120"
  source_code_hash = "${base64sha256(file(data.archive_file.archive.output_path))}"

  environment {
    variables {
      "TRANSCODER_PIPELINE_ID" = "${aws_elastictranscoder_pipeline.main.id}"
      "TRANSCODER_PRESET_ID"   = "${aws_elastictranscoder_preset.main.id}"
    }
  }
}

resource "aws_lambda_permission" "bucket_access" {
  statement_id  = "${terraform.workspace}-AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.audio_extractor.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.main.arn}"
}

# S3
resource "aws_s3_bucket" "main" {
  bucket = "${terraform.workspace}-autosub"
  acl    = "private"

  tags {
    Name        = "autosub"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_sns_topic" "input_notification" {
  name = "${terraform.workspace}-autosub"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.main.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.audio_extractor.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "Input/"
  }
}

# ElasticTranscoder
resource "aws_elastictranscoder_pipeline" "main" {
  name         = "${terraform.workspace}-autosub"
  input_bucket = "${aws_s3_bucket.main.bucket}"
  role         = "${aws_iam_role.transcoder.arn}"

  content_config {
    bucket        = "${aws_s3_bucket.main.bucket}"
    storage_class = "Standard"
  }

  thumbnail_config {
    bucket        = "${aws_s3_bucket.main.bucket}"
    storage_class = "Standard"
  }
}

resource "aws_elastictranscoder_preset" "main" {
  name        = "${terraform.workspace}-autosub"
  container   = "flac"
  description = "Preset for Autosub"

  audio = {
    audio_packing_mode = "SingleTrack"
    channels           = 2
    codec              = "flac"
    sample_rate        = 44100
  }

  audio_codec_options = {
    bit_depth = 24
  }
}

# IAM
resource "aws_iam_role" "lambda_extractor" {
  name = "${terraform.workspace}-lambda-audio-extractor"

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

resource "aws_iam_role_policy" "lambda_extractor" {
  name = "${terraform.workspace}-autosub-audio-extractor"
  role = "${aws_iam_role.lambda_extractor.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Sid":"S3",
        "Action": [
            "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::${aws_s3_bucket.main.bucket}/*"
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
            "elastictranscoder:CreateJob"
        ],
        "Effect":"Allow",
        "Resource": "*"
    }
    ]
}
EOF
}

resource "aws_iam_role" "transcoder" {
  name = "${terraform.workspace}-autosub-transcoder"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "elastictranscoder.amazonaws.com"
        },
        "Effect": "Allow"
    }
    ]
}
EOF
}

resource "aws_iam_role_policy" "transcoder" {
  name = "${terraform.workspace}-autosub-transcoder"
  role = "${aws_iam_role.transcoder.name}"

  policy = <<EOF
{
    "Version":"2008-10-17",
    "Statement":[
        {
            "Sid":"1",
            "Effect":"Allow",
            "Action": "s3:ListBucket",
            "Resource":"arn:aws:s3:::${aws_s3_bucket.main.bucket}"
        },
        {
            "Sid":"2",
            "Effect":"Allow",
            "Action":[
                "s3:Put*",
                "s3:*MultipartUpload*",
                "s3:Get*"
            ],
            "Resource":"arn:aws:s3:::${aws_s3_bucket.main.bucket}/*"
        },
        {
            "Sid":"3",
            "Effect":"Allow",
            "Action":"sns:Publish",
            "Resource":"*"
        },
        {
            "Sid":"4",
            "Effect":"Deny",
            "Action":[
                "s3:*Delete*",
                "s3:*Policy*",
                "sns:*Remove*",
                "sns:*Delete*",
                "sns:*Permission*"
            ],
            "Resource":"*"
        }
    ]
}
EOF
}
