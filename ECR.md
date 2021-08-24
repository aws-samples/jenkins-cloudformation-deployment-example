# Create AWS ECR Repository

Create an AWS ECR Repository for the Jenkins Manager and Jenkins Agent by referencing the [ECR repository policy example](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html#IAM_within_account) that allows permission to push and pull images from the AWS Shared Services account. You must update the [ecr-permission-policy.json](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/docker/ecr-permission-policy.json) key/value with the AWS Account ID before executing commands.

```json
{
    "Principal": {
        "AWS": "arn:aws:iam::<AWS-ACCOUNT-ID>:root"
    }
}
```

- Replace the Repository Name and Region to create an AWS ECR Repository with repository permissions for Jenkins Manager

```bash
~ REPOSITORY_NAME="test-jenkins-manager"
~ REGION="us-east-1"

~ aws ecr create-repository \
--repository-name $REPOSITORY_NAME \
--image-scanning-configuration scanOnPush=true \
--region $REGION

# You must replace and enter the ACCOUNT ID in the JSON permission policy.
~ aws ecr set-repository-policy \
--repository-name $REPOSITORY_NAME \
--policy-text file://ecr-permission-policy.json \
--region $REGION
```

- Replace the Repository Name and Region to create an AWS ECR Repository with repository permissions for Jenkins Agent

```bash
~ REPOSITORY_NAME="test-jenkins-agent"
~ REGION="us-east-1"

~ aws ecr create-repository \
--repository-name $REPOSITORY_NAME \
--image-scanning-configuration scanOnPush=true \
--region $REGION

# You must replace and enter the ACCOUNT ID in the JSON permission policy.
~ aws ecr set-repository-policy \
--repository-name $REPOSITORY_NAME \
--policy-text file://ecr-permission-policy.json \
--region $REGION
```
