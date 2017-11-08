######################## AWS ########################

#
# AWS ROLE
#
# OUTPUT ROLE
# resource "aws_iam_role" "iam_role_lambda_speech" {
#   name = "lambda_role_speech"
#
#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#     {
#         "Action": "sts:AssumeRole",
#         "Principal": {
#             "Service": "lambda.amazonaws.com"
#         },
#         "Effect": "Allow"
#     }
#     ]
# }
# EOF
# }
#
# resource "aws_iam_role_policy" "iam_policy_lambda_speech" {
#   name = "lambda_policy_speech"
#   role = "${aws_iam_role.iam_role_lambda_speech.name}"
#
#   policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#     {
#         "Action": [
#             "s3:GetObject"
#         ],
#         "Effect": "Allow",
#         "Resource": "*"
#     }
#     ]
# }
# EOF
# }

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

