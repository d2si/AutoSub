#!/usr/bin/env python
# -*- coding:utf-8 -*-

from __future__ import print_function
from urllib.parse import unquote_plus

import json     # JSON library
import boto3    # Cloud provider API
# import urllib   # URL Parsing and Quoting
import re
# Logs details
import traceback

print('Loading function')

# Create Clients
s3 = boto3.client('s3')
transcoder = boto3.client('elastictranscoder')


# Function invoked : lambda_handler
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
        ???
    '''
    # Get bucket name
    autosub_bucket = event['Records'][0]['s3']['bucket']['name']
    # unquote is available only on Python 2.X
    # autosub_video = urllib.unquote_plus(event['Records'][0]['s3']
    #                                       ['object']['key'])
    # parse replaces unquote on Python 3.X
    autosub_input = unquote_plus(event['Records'][0]['s3']['object']['key'])
    try:
        print("Waiting for persistent object")
        waiter = s3.get_waiter('object_exists')
        waiter.wait(Bucket=autosub_bucket, Key=autosub_input)
        # Get some Metadata information from the object
        response = s3.head_object(Bucket=autosub_bucket, Key=autosub_input)
        print("CONTENT_TYPE: " + response['ContentType'])
        print("ETag: " + response['ETag'])
        print("Name: " + autosub_input)

        # Persistent Object validated. GO to transcode video to FLAC.
        print("Running Elastic Transcoder")

        # Parsing video name
        re_pattern = re.search('.*\/(.+)\.', autosub_input)
        video_name = re_pattern.group(1)
        print('Video Name: ' + video_name)

        pipeline_id = get_pipeline(transcoder, 'autosub-pipeline')
        print('Pipeline ID: ' + pipeline_id)
        print('Audio extraction is going to start.')
        extract_audio = transcoder.create_job(
            PipelineId=pipeline_id,
            Input={
                'Key': autosub_input,
                'FrameRate': 'auto',
                'Resolution': 'auto',
                'AspectRatio': 'auto',
                'Interlaced': 'auto',
                'Container': 'auto',
            },
            Output=[{
                'Key': 'Output/' + video_name + '.flac',
                'PresetId': '1351620000001-300110',
                'Rotate': 'auto',
                'ThumbnailPattern': '/Output/Thumbnail/' + video_name
            }]
        )
        print('Passed in the function')
        return extract_audio
        print('Audio extraction is done')
    except Exception as e:
        try:
            raise TypeError('Something Goes Wrong...')
        except:
            pass
        traceback.print_tb(e.__traceback__)


# Get Pipeline details
def get_pipeline(transcoder, pipeline_name):
    # Create paginator client
    paginator = transcoder.get_paginator('list_pipelines')
    for page in paginator.paginate():
        for pipeline in page['Pipelines']:
            if pipeline['Name'] == pipeline_name:
                return pipeline['Id']
