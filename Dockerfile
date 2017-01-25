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

# Download, install and patch
RUN git clone https://github.com/zhicwu/GateOne.git -b $GATEONE_VERSION --single-branch $GATEONE_HOME \
	&& (find . -name "*.htm?" | xargs sed -i -e 's|.google-analytics.com/|.localhost/|' || true) \
	&& (find . -name "*.js" | xargs sed -i -e 's|.google-analytics.com/|.localhost/|' || true) \
	&& (find . -name "ssh_connect.py" | xargs sed -i -e 's|\(            args.insert(3, "-i%s" % identity)\)|            if not os.path.normpath(identity).startswith(users_ssh_dir):\n                continue\n\1|' || true) \
	&& (find . -name "authentication.py" | xargs sed -i -e 's|\(import os, re, logging, json\)|\1, base64|' || true) \
	&& (find . -name "authentication.py" | xargs sed -i -e "s|\(        user = {'upn': 'ANONYMOUS'}\)|\1\n        basic_auth = self.request.headers.get('Authorization', '').replace('Basic', '').strip()\n        if len(basic_auth) > 0:\n            user['upn'] = base64.b64decode(basic_auth).split(':', 1)[0]|" || true) \
	&& (find . -name "bookmarks.py" | xargs sed -i -e 's|\(import os, sys, time, json, socket\)|\1, shutil|' || true) \
	&& (find . -name "bookmarks.py" | xargs sed -i -e "s|\(        if not os.path.exists(self.bookmarks_path):\)|\1\n            shared_bookmarks = os.path.join(self.user_dir, '../bookmarks.json')\n            if os.path.isfile(shared_bookmarks):\n                shutil.copyfile(shared_bookmarks, self.bookmarks_path)\n\1|" || true) \
	&& (find . -name "bookmarks.js" | xargs sed -i -e "s|            bmSearch.onchange |            bmSearch.onpropertychange = bmSearch.oninput |" || true) \
	&& (find . -name "server.py" | xargs sed -i -e "s|\(            if user\['upn'\] != 'ANONYMOUS':\)|# \1\n            if len(user['upn']) == 0:|" || true) \
	&& (find . -name "server.py" | xargs sed -i -e 's|\(        ssl_options=ssl_options\)|\1, xheaders=True|' || true) \
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
