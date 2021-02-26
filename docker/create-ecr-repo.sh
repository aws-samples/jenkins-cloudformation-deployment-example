#!/bin/bash

# Please ensure that you have the correct AWS credentials configured.
# Enter the name for the image repository you want to create, then enter the name of the region.

if [ $# -ne 2 ]; then
    echo "Enter repository name & region name."
    exit 0
else
    REPOSITORY_NAME=$1
    REGION=$2
fi

aws ecr create-repository \
--repository-name $REPOSITORY_NAME \
--image-scanning-configuration scanOnPush=true \
--region $REGION

# You must replace and enter the name of the ACCOUNT ID in the JSON permission policy.
aws ecr set-repository-policy \
--repository-name $REPOSITORY_NAME \
--policy-text file://ecr-permission-policy.json \
--region $REGION
