#!/bin/bash
set -e

: ${HOST_USER_ID:=""}
: ${URL_PREFIX:="/"}

fix_permission() {
	echo "Fixing permissions..."
	
	if [ "$HOST_USER_ID" != "" ]; then
		# based on https://github.com/schmidigital/permission-fix/blob/master/tools/permission_fix
		UNUSED_USER_ID=21338

		# Setting User Permissions
		DOCKER_USER_CURRENT_ID=`id -u $GATEONE_USER`

		if [ "$DOCKER_USER_CURRENT_ID" != "$HOST_USER_ID" ]; then
		  DOCKER_USER_OLD=`getent passwd $HOST_USER_ID | cut -d: -f1`

		  if [ ! -z "$DOCKER_USER_OLD" ]; then
			usermod -o -u $UNUSED_USER_ID $DOCKER_USER_OLD
		  fi

		  usermod -o -u $HOST_USER_ID $GATEONE_USER || true
		fi
	fi
	
	chown -R $GATEONE_USER $GATEONE_HOME
}

init() {
	if [ ! -d $GATEONE_HOME/venv ]; then
		echo "Initializing..."
		exec /sbin/setuser $GATEONE_USER ./install_gateone.sh &
		for job in `jobs -p`
		do
			wait $job || echo "Faild to wait job $job."
		done
		
		sed -i -e 's|\("url_prefix":\) .*|\1 "'"$URL_PREFIX"'",|' /$GATEONE_HOME/.gateone/conf.d/10server.conf \
			&& sed -i -e 's|\("js_init":\) .*|\1 "{'"'theme': 'white'"'}",|' /$GATEONE_HOME/.gateone/conf.d/10server.conf \
			&& sed -i -e "s|--sshfp -a '|-a '-oStrictHostKeychecking=no |" /$GATEONE_HOME/.gateone/conf.d/50terminal.conf
	fi
}

# start GateOne
if [ "$1" = 'gateone' ]; then
	fix_permission
	init

	# now start GateOne
	echo "Starting GateOne..."
	exec /sbin/setuser $GATEONE_USER /gateone/venv/bin/gateone > /dev/null 2>&1
fi

exec "$@"
