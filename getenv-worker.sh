#!/bin/bash

# Bootstrap
REMOVE_AFTER="2"
BASENAME=${0##*/}
ENVDATA=${0%/*}
LTAG=${BASENAME%%-*}
GROUP="$2"

# Parent Process (CMD executing this script), including all params
full_parent_command=$(ps -f -o cmd= -p $$ | awk '{print $2,$3}')

# Extract the last two path components
# transform this: /home/core.mb_docker-2uYU8Eix/_common/getenv/getenv-worker.sh /home/core.mb_docker-2uYU8Eix/traefik/Makefile
# to this: traefik/Makefile
last_component="${full_parent_command##* }"
parent_path="${last_component%/*}"
second_last_component="${parent_path##*/}"
caller="${second_last_component}/${last_component##*/}"

# some random
random="$RANDOM$RANDOM$RANDOM"

# base functions
log () { logger -t "$LTAG" "[$1] $2"; }
err () { logger -t "$LTAG" "ERROR: $1"; echo "!!! ERROR: $1"; }
wrn () { logger -t "$LTAG" "WARNING: $1"; echo "??? Warning: $1"; }

# load the correct env file if exists
case $caller in
	traefik/Makefile)
	    log "authorized" "$second_last_component"
	    env_file="${ENVDATA}/env.$second_last_component"
	    assigned_env_file="$parent_path/.env_${second_last_component}.${random}"

	    if [ -f "$env_file" ]; then
		log "$second_last_component" "assigning env vars with id $random"
		cp "$env_file" "$assigned_env_file" || err "Failed to assign env variables to caller (id: $random)."
		chmod 640 "$assigned_env_file" || err "Failed to chmod assigned env variables (id: $random)."
		chown "$(whoami):$GROUP" "$assigned_env_file" || err "Failed to chown assigned env variables (id: $random)."
		# returning the random id, so makefile can include the env file
		echo $random
		# calling script to remove the file with X (REMOVE_AFTER) second(s) timeout.
		nohup bash -c "sleep $REMOVE_AFTER; shred -u \"$assigned_env_file\"; logger -t \"$LTAG\" \"[$second_last_component] shredding env vars with id $random after $REMOVE_AFTER second(s)\"" &>/dev/null &
		# return to caller
		exit 0
	    else 
  	        log "$second_last_component" "has no env file available ($env_file)"
	    fi
	;;
	*)
	    log "unauthorized" "$second_last_component"
	    exit 1
	;;
esac
exit 0
