#!/usr/bin/env python
# -*- coding:utf-8 -*-

from __future__ import print_function
from urllib.parse import unquote_plus

import json
import boto3
import os
import traceback

print('Loading function')

# Create Clients
s3 = boto3.client('s3')
transcoder = boto3.client('elastictranscoder')

S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
TRANSCODER_PIPELINE_ID = os.environ['TRANSCODER_PIPELINE_ID']
TRANSCODER_PRESET_ID = os.environ['TRANSCODER_PRESET_ID']


def lambda_handler(event, context):
    print("Received event for :" + json.dumps(event))

    # Get the object from the event and show its contents
    ''' Explanation for <Event> stucture
    Args:
        Records             : Head structure name
        0                   : Indicate the first and only record
        s3                  : Service name
        bucket or object    : Service Component
        name or key         : Component details
        We actually traversing the simple event JSON structure
    Returns:
    '''

    # Get bucket name
    autosub_bucket = event['Records'][0]['s3']['bucket']['name']
    autosub_input = unquote_plus(event['Records'][0]['s3']['object']['key'])

    # Parsing video name
    video = autosub_input.split("/")[-1]
    video_name, video_ext = video.split(".")

    # Cleaning existing file before generating the new one
    output_file_path = 'Output/' + video_name + '.flac'
    response = s3.delete_object(
        Bucket=S3_BUCKET_NAME,
        Key=output_file_path
    )

    print('Audio extraction is going to start for video {} in Pipeline {}'.format(video, TRANSCODER_PIPELINE_ID))
    extract_audio = transcoder.create_job(
        PipelineId=TRANSCODER_PIPELINE_ID,
        Input={
            'Key': autosub_input,
            'FrameRate': 'auto',
            'Resolution': 'auto',
            'AspectRatio': 'auto',
            'Interlaced': 'auto',
            'Container': 'auto',
        },
        Outputs=[{
            'Key': output_file_path,
            'PresetId': TRANSCODER_PRESET_ID,
            'Rotate': 'auto'
        }]
    )
    print('Audio extraction is done')
    return extract_audio
