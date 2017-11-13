#!/usr/bin/env python
# -*- coding:utf-8 -*-

from __future__ import print_function

import sys
import os
import json
import boto3
import botocore

# Appends the directory containing our libraries to the sys path.
dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(dir_path + '/lib')

from google.cloud import storage
from urllib.parse import unquote_plus

S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
CS_BUCKET_NAME = os.environ['CS_BUCKET_NAME']
PROJECT_ID = os.environ['PROJECT_ID']
LOCAL_FILES_PATH = "/tmp/"

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = ".credentials.json"

# Create Clients
s3 = boto3.client('s3')
sc = storage.Client(PROJECT_ID)


def lambda_handler(event, context):
    print("Received event for :" + json.dumps(event))

    key = unquote_plus(event['Records'][0]['s3']['object']['key'])
    video = key.split("/")[-1]
    video_name, video_ext = video.split(".")
    
    copy_file_s3_to_gcloud(LOCAL_FILES_PATH + video, S3_BUCKET_NAME, key, CS_BUCKET_NAME, key)    

def copy_file_s3_to_gcloud(local_file, s3bucket, s3key, gcloudbucket, gcloudkey):
    try:
        print("Downloading {} from {}".format(s3key, s3bucket))
        s3.download_file(Bucket=s3bucket, Key=s3key, Filename=local_file)
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            print("The object does not exist.")
            return false
        else:
            raise


    # Copy local_file under /tmp to GCloud storage
    file = open(local_file, "rb")
    print("Copying to GCP...")
    bucket = sc.bucket(gcloudbucket)
    blob = bucket.blob(gcloudkey)
    blob.upload_from_file(file)
