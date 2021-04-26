# Build Docker Images

Build the custom docker images for the Jenkins Manager and the Jenkins Agent, then push to the images to AWS ECR Repository. You must navigate to the `docker/` directory, then execute the command according to the required parameters with the AWS account ID, repository name, region, and the build folder name `jenkins-manager/` or `jenkins-agent/` that resides in the current docker directory. The custom docker images will contain a set of starter package installations.

- Build a docker image and push to the AWS ECR Repository. Replace the Repository Name and Region for Jenkins Manager.

```bash
~ export LC_CTYPE=C
~ HASH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)

~ AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
~ REPOSITORY_NAME="test-jenkins-manager"
~ REGION="us-east-1"
~ FOLDER_NAME="jenkins-manager/"
~ IMG_TAG=$HASH

# Docker Login | ECR Login
~ aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# # Build Image
~ REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME
~ docker build -t $REPOSITORY_URI:latest $FOLDER_NAME

# # Tag Image
~ docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMG_TAG

# # Push Image
~ docker push $REPOSITORY_URI:latest
~ docker push $REPOSITORY_URI:$IMG_TAG
```

- Build a docker image and push to the AWS ECR Repository. Replace the Repository Name and Region for the Jenkins Agent.

```bash
~ export LC_CTYPE=C
~ HASH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)

~ AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
~ REPOSITORY_NAME="test-jenkins-agent"
~ REGION="us-east-1"
~ FOLDER_NAME="jenkins-agent/"
~ IMG_TAG=$HASH

# Docker Login | ECR Login
~ aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# # Build Image
~ REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME
~ docker build -t $REPOSITORY_URI:latest $FOLDER_NAME

# # Tag Image
~ docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMG_TAG

# # Push Image
~ docker push $REPOSITORY_URI:latest
~ docker push $REPOSITORY_URI:$IMG_TAG
```
