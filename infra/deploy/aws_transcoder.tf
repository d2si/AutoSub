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

resource "aws_iam_role" "transcoder_role" {

  name = "autosub-transcoder-role"

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

resource "aws_iam_role_policy" "transcoder_policy" {
  name = "autosub-transcoder-policy"
  role = "${aws_iam_role.transcoder_role.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": [
            "s3:GetObject",
            "s3:PutObject"
        ],
        "Effect": "Allow",
        "Resource": "*"
    }
    ]
}
EOF
}
