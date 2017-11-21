# Build depndencies

In order to have dependencies that are runnable by Lambda, we need to compile them in in an AmazonLinux environment.
We use a local Docker image to do so, which uses Python 3.6:

	docker build -t python-lambda .

Then, we need to install dependencies in the volume we mount:

    docker run -v /path/to/AutoSub/code/SpeechExtractor/lib:/app/lib python-lambda rm -rf /app/lib/* && pip3.6 install -t /app/lib -r /app/requirements.txt

We are now able to package the Lambda and uplaod it!
