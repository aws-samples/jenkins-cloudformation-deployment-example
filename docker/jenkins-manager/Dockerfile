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