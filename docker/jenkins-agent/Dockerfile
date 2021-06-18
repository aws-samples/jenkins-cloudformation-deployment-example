# Pull base image.
FROM jenkins/inbound-agent:4.7-1

USER root

# install packages
RUN apt-get -y update \
    && apt-get -y upgrade \
    && apt-get -y install sudo curl bash jq python3 python3-pip

# install AWS CLI
RUN set +x \
  && pip3 install awscli --upgrade