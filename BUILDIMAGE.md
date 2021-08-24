# Dockerfiles

## Jenkins Manager

```Dockerfile
# Jenkins Manager
FROM jenkins/jenkins:2.298

USER root

# install packages
RUN apt-get -y update \
    && apt-get -y upgrade \
    && apt-get -y install sudo curl bash jq python3 python3-pip

# install AWS CLI
RUN set +x \
  && pip3 install awscli --upgrade

# list installed software versions
RUN set +x \
    && echo ''; echo '*** INSTALLED SOFTWARE VERSIONS ***';echo ''; \
    cat /etc/*release; python3 --version; \
    pip3 --version; aws --version;

# copy plugins to /usr/share/jenkins
COPY plugins/plugins.txt /usr/share/jenkins/plugins.txt
COPY plugins/plugins_dev.txt /usr/share/jenkins/plugins_dev.txt

# install Recommended Plugins
RUN set +x \
    && /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt

# install Additional Plugins
RUN set +x \
    && /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins_dev.txt

# change directory owner for jenkins home
RUN chown -R jenkins:jenkins /var/jenkins_home

# drop back to the regular jenkins user - good practice
USER jenkins
```

## Jenkins Agent

```Dockerfile
# Jenkins Agent
FROM jenkins/inbound-agent:4.7-1

USER root

# install packages
RUN apt-get -y update \
    && apt-get -y upgrade \
    && apt-get -y install sudo curl bash jq python3 python3-pip

# install AWS CLI
RUN set +x \
  && pip3 install awscli --upgrade
```

# Build Docker Images

Build the custom docker images for the Jenkins Manager and the Jenkins Agent, and then push the images to AWS ECR Repository. Navigate to the `docker/` directory, then execute the command according to the required parameters with the AWS account ID, repository name, region, and the build folder name `jenkins-manager/` or `jenkins-agent/` that resides in the current docker directory. The custom docker images will contain a set of starter package installations.

- Build a docker image and push to the AWS ECR Repository. Replace the Repository Name and Region for Jenkins Manager.

```bash
~ LC_CTYPE=C HASH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)

~ AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
~ REPOSITORY_NAME="test-jenkins-manager"
~ REGION="us-east-1"
~ FOLDER_NAME="jenkins-manager/"
~ IMG_TAG=$HASH
~ LATEST_TAG=latest

# Docker Login | ECR Login
~ aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build Image
~ REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME
~ docker build -t $REPOSITORY_URI:$LATEST_TAG $FOLDER_NAME

# Tag Image
~ docker tag $REPOSITORY_URI:$LATEST_TAG $REPOSITORY_URI:$IMG_TAG

# Push Image
~ docker push $REPOSITORY_URI:$LATEST_TAG
~ docker push $REPOSITORY_URI:$IMG_TAG
```

- Build a docker image and push to the AWS ECR Repository. Replace the Repository Name and Region for the Jenkins Agent.

```bash
~ LC_CTYPE=C HASH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)

~ AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
~ REPOSITORY_NAME="test-jenkins-agent"
~ REGION="us-east-1"
~ FOLDER_NAME="jenkins-agent/"
~ IMG_TAG=$HASH
~ LATEST_TAG=latest

# Docker Login | ECR Login
~ aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build Image
~ REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME
~ docker build -t $REPOSITORY_URI:$LATEST_TAG $FOLDER_NAME

# Tag Image
~ docker tag $REPOSITORY_URI:$LATEST_TAG $REPOSITORY_URI:$IMG_TAG

# Push Image
~ docker push $REPOSITORY_URI:$LATEST_TAG
~ docker push $REPOSITORY_URI:$IMG_TAG
```
