#!/usr/bin/env python

import re

input_text = "Input/coucou.mp4"
regex_pattern = re.search('.*\/(.+)\.', input_text)
video_name = regex_pattern.group(1)
print (video_name)
