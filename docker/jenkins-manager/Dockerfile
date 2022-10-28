FROM jenkins/jenkins:2.375

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
FROM jenkins/jenkins:lts-jdk11
COPY --chown=jenkins:jenkins plugins/plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY --chown=jenkins:jenkins plugins/plugins_dev.txt /usr/share/jenkins/ref/plugins_dev.txt


# install Recommended Plugins
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# install Additional Plugins
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins_dev.txt

# change directory owner for jenkins home
RUN chown -R jenkins:jenkins /var/jenkins_home

# drop back to the regular jenkins user - good practice
USER jenkins