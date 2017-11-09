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
    # unquote is available only on Python 2.X
    # autosub_video = urllib.unquote_plus(event['Records'][0]['s3']
    #                                       ['object']['key'])
    # parse replaces unquote on Python 3.X
    autosub_input = unquote_plus(event['Records'][0]['s3']['object']['key'])
    print("Waiting for persistent object")
    waiter = s3.get_waiter('object_exists')
    waiter.wait(Bucket=autosub_bucket, Key=autosub_input)
    print("Name: " + autosub_input)

    # Parsing video name
    video = autosub_input.split("/")[-1]
    video_name, video_ext = video.split(".")
    print('Audio extraction is going to start for video {} in Pipeline {}'.format(video_name, TRANSCODER_PIPELINE_ID))
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
            'Key': 'Output/' + video_name + '.flac',
            'PresetId': TRANSCODER_PRESET_ID,
            'Rotate': 'auto'
        }]
    )
    print('Audio extraction is done')
    return extract_audio
