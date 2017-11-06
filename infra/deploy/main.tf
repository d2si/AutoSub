######################## AWS ########################

#
# AWS ROLE
#
# TRANSCODER ROLE
resource "aws_iam_role" "iam_role_transcoder" {
  name = "transcoder_role"

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

resource "aws_iam_role_policy" "iam_policy_transcoder" {
  name = "transcoder_policy"
  role = "${aws_iam_role.iam_role_transcoder.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": [
            "s3:PutObject"
        ],
        "Effect": "Allow",
        "Resource": "*"
    }
    ]
}
EOF
}

# OUTPUT ROLE
resource "aws_iam_role" "iam_role_lambda_speech" {
  name = "lambda_role_speech"

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

resource "aws_iam_role_policy" "iam_policy_lambda_speech" {
  name = "lambda_policy_speech"
  role = "${aws_iam_role.iam_role_lambda_speech.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": [
            "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": "*"
    }
    ]
}
EOF
}

#
# AWS S3 BUCKET CREATION
#
resource "aws_s3_bucket" "main" {
  bucket = "autosub"
  acl    = "private"

  tags {
    Name        = "autosub"
    Environment = "Dev"
  }
}

resource "aws_sns_topic" "input_notification" {
  name = "s3-input-notification"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Principal": {
            "AWS": "*"
        },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:s3-event-notification-topic",
        "Condition":{
            "ArnLike": {
                "aws:SourceArn":"${aws_s3_bucket.main.arn}"
            }
        }
    }

    ]
}
POLICY
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.main.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "Input/"
  }
}

#
# AWS CREATE INPUT & OUTPUT FOLDERS
#
resource "aws_s3_bucket_object" "input_folder" {
  bucket = "${aws_s3_bucket.main.id}"
  acl    = "private"
  key    = "Input/"
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "output_folder" {
  bucket = "${aws_s3_bucket.main.id}"
  acl    = "private"
  key    = "Output/"
  source = "/dev/null"
}

#
# AWS ELASTIC TRANSCODER
#
resource "aws_elastictranscoder_pipeline" "transcoder_pipeline" {
  input_bucket = "${aws_s3_bucket.main.bucket}"
  name         = "autosub-pipeline"
  role         = "${aws_iam_role.lambda_extractor_role.arn}"

  content_config {
    bucket        = "${aws_s3_bucket.main.bucket}"
    storage_class = "Standard"
  }

  thumbnail_config {
    bucket        = "${aws_s3_bucket.main.bucket}"
    storage_class = "Standard"
  }
}

resource "aws_elastictranscoder_preset" "transcoder_preset" {
  container   = "flac"
  description = "Preset for Autosub"
  name        = "autosub-preset"

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

######################## GCP ########################


#
# GCP STORAGE BUCKET CREATION
#
// Configure the Google Cloud provider
#provider "google" {
#    #credentials = "${file("account.json")}"
#    project     = "autosub-project"
#    region      = "EU"
#}
#
#resource "google_storage_bucket" "main" {
#    name        = "autosub-gcp-bucket"
#    location    = "EU"
#}

