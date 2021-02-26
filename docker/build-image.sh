#!/bin/bash

# Please ensure that you have the correct AWS credentials configured.
# Replace the following for the *Repository URI* as necessary which should reflect the correct *AWS Account ID*, *AWS Region*,
# and the name of the *Reposity Image Name*.

export LC_CTYPE=C

HASH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)

if [ $# -ne 4 ]; then
    echo "Refer to the AWS Account where the ECR Repository. Pass the following: Image Repository Name (Repository URI), AWS Account ID, Region Name, Image Tag, and finally enter the name of the folder for the image you want to build. (Jenkins-Manager / Jenkins-Agent)"
    exit 0
else
    AWS_ACCOUNT_ID=$1
    REPOSITORY_NAME=$2
    REGION=$3
    FOLDER_NAME=$4
    IMG_TAG=$HASH
fi

# Docker Login | ECR Login
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# # Build Image
REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME
docker build -t $REPOSITORY_URI:latest $FOLDER_NAME

# # Tag Image
docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMG_TAG

# # Push Image
docker push $REPOSITORY_URI:latest
docker push $REPOSITORY_URI:$IMG_TAG