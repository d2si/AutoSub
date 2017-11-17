# AutoSub

Proof Of Concept based on Serverless generating subtitles from a video.

** Warning ** For this POC to work, we need a < 1minute-length video, as the Google Speech API Call we use
only accepts videos of such length. For longer videos, we would need to use the long_running_recognize function,
which is for technical reasons not working on Lambda, due to multithreading and Semaphores.

## Requirements

* [Terraform](https://terraform.io)
* [Google Cloud SDK](https://cloud.google.com/sdk)

You will need to set up a Google Account and create a related project along with an AWS account.

## Credentials

In order to interact with Google Cloud Storage, Google Speech & Google Translate, you will need to create a Service Account Key.
Now, put it into the `code/SpeechExtractor` directory under a file named `.credentials.json`. Then, `terraform apply` the project and you should be all set!
