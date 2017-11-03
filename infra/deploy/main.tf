######################## AWS ########################

#
# AWS ROLE
#
# TRANSCODER ROLE
resource "aws_iam_role" "iam_role_transcoder" {
    name = "transcoder_role"

assume_role_policy  = <<EOF
{
    "Version": "2017-10-31",
    "Statetement": [
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
    name    = "transcoder_policy"
    role    = "${aws_iam_role.iam_role_transcoder.name}"

policy  = <<EOF
{
    "Version": "2017-10-31",
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
    name                = "lambda_role_speech"

assume_role_policy  = <<EOF
{
    "Version": "2017-10-30",
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
    name    = "lambda_policy_speech"
    role    = "${aws_iam_role.iam_role_lambda_speech.name}"

policy  = <<EOF
{
    "Version": "2017-10-31",
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
    bucket = "autosub-s3-bucket"
    acl    = "private"

    tags {
        Name        = "autosub-s3-bucket"
        Environment = "Dev"
    }
}


resource "aws_sns_topic" "input_notification" {
    name = "s3-input-notification"

policy = <<POLICY
{
    "Version": "2017-10-31",
    "Statement": [
    {
        "Effect": "Allow",
        "Principal": {
            "AWS": "003460636880"
        },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:003460636880:s3-event-notification-topic",
        "Condition":{
            "ArnLike": {
                "aws:SourceArn":"${aws_s3_bucket.main.arn}"
            }
    }
    ]
}
POLICY
}

#
# AWS ELASTIC TRANSCODER
#
resource "aws_elastictranscoder_pipeline" "transcoder_pipeline" {
    input_bucket    = "${aws_s3_bucket.main.bucket}"
    name            = "aws_etranscoder_pipeline_tf_autosub"
    role            = "${aws_iam_role.lambda_extractor_role.arn}"

    content_config {
        bucket          = "${aws_s3_bucket.main.bucket}"
        storage_class   = "Standard"
    }
}

resource "aws_elastictranscoder_preset" "transcoder_preset" {
    container   = "mp4"
    description = "autosub_preset"
    name        = "autosub_preset"

    audio = {
        audio_packing_mode = "SingleTrack"
        bit_rate           = 96
        channels           = 2
        codec              = "flac"
        sample_rate        = 44100
    }

    audio_codec_options = {
        bit_depth   = 24
    }
}


######################## GCP ########################


#
# GCP STORAGE BUCKET CREATION
#
// Configure the Google Cloud provider
provider "google" {
    #credentials = "${file("account.json")}"
    project     = "autosub-project"
    region      = "EU"
}

resource "google_storage_bucket" "main" {
    name        = "autosub-gcp-bucket"
    location    = "EU"
}


