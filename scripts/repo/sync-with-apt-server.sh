#!/bin/bash

AWS_SHARED_CREDENTIALS_FILE=aws/credentials aws s3 sync deeprey s3://deeprey-apt-repo-storage
