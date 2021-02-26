#!/bin/bash

# Please ensure that you have the correct AWS credentials configured.
# Enter the name of the stack you want to delete, then enter the name of the region.

if [ $# -ne 2 ]; then
    echo "Enter stack name to delete & region name."
    exit 0
else
    STACK_NAME=$1
    REGION=$2
fi

aws cloudformation delete-stack \
--stack-name $STACK_NAME \
--region $REGION

aws cloudformation wait stack-delete-complete \
--stack-name $STACK_NAME \
--region $REGION