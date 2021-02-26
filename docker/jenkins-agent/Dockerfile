# Pull base image.
FROM jenkins/inbound-agent:latest

USER root

# install packages
RUN apt-get -y update \
    && apt-get -y upgrade \
    && apt-get -y install sudo curl bash jq python3 python3-pip

# install AWS CLI
RUN set +x \
  && pip3 install awscli --upgrade