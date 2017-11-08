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

