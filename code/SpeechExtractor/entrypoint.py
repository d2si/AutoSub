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

import google
from google import cloud
from google.cloud import storage
from google.cloud import speech
from google.cloud.speech import enums
from google.cloud.speech import types
from google.cloud import translate
from os.path import basename
from urllib.parse import unquote_plus

S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
CS_BUCKET_NAME = os.environ['CS_BUCKET_NAME']
PROJECT_ID = os.environ['PROJECT_ID']
LOCAL_FILES_PATH = "/tmp/"
TARGET_LANGUAGE = "fr"
LANGUAGE = "en-US"

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = ".credentials.json"

# Create Clients
s3 = boto3.client('s3')
gsc = storage.Client(PROJECT_ID)
spc = speech.SpeechClient()
tsc = translate.Client()


def lambda_handler(event, context):
    print("Received event for :" + json.dumps(event))

    key = unquote_plus(event['Records'][0]['s3']['object']['key'])
    video = key.split("/")[-1]
    video_name, video_ext = video.split(".")
    
    copy_file_s3_to_gcloud(LOCAL_FILES_PATH + video, S3_BUCKET_NAME, key, CS_BUCKET_NAME, key)
    print("Transcripting...")
    transcribe_gcs(CS_BUCKET_NAME, key)

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
    bucket = gsc.bucket(gcloudbucket)
    blob = bucket.blob(gcloudkey)
    blob.upload_from_file(file)

def transcript_original(response):
    # Print the first alternative of all the consecutive results.
    transcript = ""
    for result in response.results:
        transcript += ' ' + result.alternatives[0].transcript

    return transcript

def subtitles_nanos(response):
    subtitles = ""
    line = 1
    #Every words
    for result in response.results:
        for word in result.alternatives[0].words:
            subtitles += str(line) + '\n'
            subtitles += '00:{:02d}:'.format(int(word.start_time.seconds//60))
            subtitles += '{:02d},'.format(word.start_time.seconds%60) + '{:03}'.format(word.start_time.nanos)[:3]
            subtitles += ' --> '
            subtitles += '00:{:02d}:'.format(int(word.end_time.seconds//60))
            subtitles += '{:02d},'.format(word.end_time.seconds%60) + '{:03}'.format(word.end_time.nanos)[:3] + '\n'
            subtitles += word.word + '\n\n'
            line += 1
    return subtitles

def subtitles_seconds(response, second_time):
    subtitles = ""
    line = 0
    subtitles_lines = []
    #Every seconds
    for result in response.results:
        for word in result.alternatives[0].words:
            if ( ( int(word.start_time.seconds/second_time)%60) >= (line%60) ) and not ( line%60 == 0 and int(word.start_time.seconds/second_time)%60 == 59) :
                line += 1
                subtitles += '\n\n' + str(line) + '\n'
                subtitles += '00:{:02d}:'.format(int(word.start_time.seconds//60))
                subtitles += '{:02d},'.format(word.start_time.seconds%60) + '000'
                subtitles += ' --> '
                subtitles += '00:{:02d}:'.format(int((word.start_time.seconds + second_time)//60))
                subtitles += '{:02d},'.format((word.start_time.seconds + second_time)%60) + '000\n'
                subtitles += word.word + ' '
                subtitles_lines.append(word.word + ' ')
            else:
                subtitles += word.word + ' '
                subtitles_lines[line-1] += word.word + ' '

    return subtitles, subtitles_lines

def transcribe_gcs(bucket, key):
    gcs_uri = "gs://{}/{}".format(bucket, key)
    audio = types.RecognitionAudio(uri=gcs_uri)
    config = types.RecognitionConfig(
        encoding=enums.RecognitionConfig.AudioEncoding.FLAC,
        sample_rate_hertz=44100,
        language_code=LANGUAGE,
        enable_word_time_offsets=True)

    response = spc.recognize(config, audio)

    print('Waiting for operation to complete...')

    #Get the transcript and put it to s3
    transcript = transcript_original(response)
    s3.put_object(Body=transcript.encode(), Bucket=S3_BUCKET_NAME, Key='text/'+basename(key).split('.')[0]+'.txt')
    print('Transcript is now in s3. Waiting for subtitles file creation to complete...')

    #Get the subtitles and put it to s3
    subtitles, subtitles_lines = subtitles_seconds(response, 2)
    s3.put_object(Body=subtitles.encode(), Bucket=S3_BUCKET_NAME, Key='subtitles/'+basename(key).split('.')[0]+'.srt')
    print('Subtitles are now in s3. Waiting for Translate file creation to complete...')

    # Translates
    for subtitles_line in subtitles_lines :
        translation = tsc.translate(subtitles_line, target_language=TARGET_LANGUAGE)

        subtitles = subtitles.replace(subtitles_line, translation['translatedText'])
    s3.put_object(Body=subtitles.encode(), Bucket=S3_BUCKET_NAME, Key='translate/'+basename(key).split('.')[0]+'.srt')
