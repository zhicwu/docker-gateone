#
# This is a custom image based on 
# https://github.com/liftoff/GateOne/blob/master/docker/Dockerfile
#

# Pull base image
FROM phusion/baseimage:latest

# Maintainer
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set Locale and general environment variables
RUN locale-gen en_US.UTF-8
ENV LANG="en_US.UTF-8" \
	LANGUAGE="en_US.UTF-8" \
	LC_ALL="en_US.UTF-8" \
	TERM=xterm \
	DEBIAN_FRONTEND=noninteractive

# Set default timezone - see more on https://github.com/docker/docker/issues/12084
# and http://stackoverflow.com/questions/22800624/will-docker-container-auto-sync-time-with-the-host-machine
RUN echo "America/Los_Angeles" > /etc/timezone \
	&& ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime \
	&& dpkg-reconfigure -f noninteractive tzdata

# Set environment variables for GateOne
ENV GATEONE_HOME=/gateone GATEONE_USER=gateone GATEONE_VERSION=2016

# Upgrade operation system
RUN apt-get update --fix-missing && apt-get -y upgrade

# Install dependencies
RUN apt-get -y install dtach python-pip python-imaging python-setuptools \
	python-mutagen python-pam python-dev git telnet openssh-client \
	&& apt-get -y clean \
	&& apt-get -q -y autoremove \
	&& pip install --upgrade pip \
	&& pip install --upgrade futures tornado cssmin slimit psutil virtualenv \
	&& rm -rf /var/lib/apt/lists/* ~/.cache

# Download and install GateOne
RUN git clone https://github.com/zhicwu/GateOne.git -b $GATEONE_VERSION --single-branch $GATEONE_HOME \
	&& useradd -Md $GATEONE_HOME -s /bin/bash $GATEONE_USER

# Change work directory and expose port
WORKDIR $GATEONE_HOME
EXPOSE 8000

# Add entry point and installation script
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY install_gateone.sh ./install_gateone.sh
RUN chmod +x /docker-entrypoint.sh ./install_gateone.sh
ENTRYPOINT ["/sbin/my_init", "--", "/docker-entrypoint.sh"]
CMD ["gateone"]
