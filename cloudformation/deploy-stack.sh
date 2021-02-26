#!/bin/bash

# Please ensure that you have the correct AWS credentials configured.
# Enter the name of the stack, the parameters file name, the template name, then changeset condition, and finally the region name.

if [ $# -ne 5 ]; then
    echo "Enter stack name, parameters file name, template file name to create, set changeset value (true or false), and enter region name. "
    exit 0
else
    STACK_NAME=$1
    PARAMETERS_FILE_NAME=$2
    TEMPLATE_NAME=$3
    CHANGESET_MODE=$4
    REGION=$5
fi

if [ ! -f "cloudformation/$TEMPLATE_NAME.yaml" ]; then
    echo "CloudFormation template $TEMPLATE_NAME.yaml does not exist"
    exit 0
fi

if [ ! -f "parameters/$PARAMETERS_FILE_NAME.properties" ]; then
    echo "CloudFormation parameters $PARAMETERS_FILE_NAME.properties does not exist"
    exit 0
fi

if [[ $CHANGESET_MODE == true ]]; then
    aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --template-file cloudformation/$TEMPLATE_NAME.yaml \
    --parameter-overrides file://parameters/$PARAMETERS_FILE_NAME.properties \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION
else
    aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --template-file cloudformation/$TEMPLATE_NAME.yaml \
    --parameter-overrides file://parameters/$PARAMETERS_FILE_NAME.properties \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-execute-changeset
fi