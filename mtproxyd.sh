#!/bin/bash

### BEGIN INIT INFO
# Provides:          mtproxy
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     1 2 3 4 5
# Default-Stop:
# Short-Description: Starts MTProxy Server
# Description:       starts MTProxy Server
### END INIT INFO

echo ""

script_name=$0
function usage () {
    echo "usage : "
    echo "$(basename ${script_name}) { start | stop | restart } "
    echo ""
}

### Check args
if [[ $# != 1 || ( "$1" != "start" && "$1" != "stop" && "$1" != "restart" ) ]]; then
    usage;
    exit 1;
fi

function read_yes_no () {
    printf "[yes|no] "
    read yesno;
    while [[ "${yesno}" != "yes" && "${yesno}" != "no" ]]
    do
        printf "please answer [yes|no] "
        read yesno;
    done

    if [[ "${yesno}" == "no" ]]; then
        return 1;
    else
        return 0;
    fi
}

function ask_question () {
    question=$1
    default=$2
    key=$3
    printf "${question}"
    printf "\n"
    if [[ "${default}" != "" && "${default}" != "nodefault" ]] ; then
        printf "[default: ${default} ] "
    elif [[ "${key}" != "" ]]; then
        printf "[${key}]: "
    fi
}

function get_mtproxy_dir () {
    question="Where is your mtproxy script?"
    default=${default_mtproxy_dir}
    ask_question "${question}" "${default}"
    read mtproxy_dir
    if [[ "${mtproxy_dir}" == "" ]]; then
        mtproxy_dir=${default}
    fi

    if [[ -d ${mtproxy_dir} && -f ${mtproxy_dir}/mtproxyd ]]; then
        echo
        echo "It seems that you have already downloaded mtproxy script in ${mtproxy_dir}."
        echo "Would you like to use the existing mtproxy script?"
        if ! read_yes_no; then
            echo "You have chosen not to use existing mtproxy script in ${mtproxy_dir}"
            echo "You need to specify a different mtproxy script directory or remove ${mtproxy_dir} before continuing."
            get_mtproxy_dir
        else
            use_existing_mtproxy="true"
        fi
    elif [[ -d ${mtproxy_dir} && $(ls -A ${mtproxy_dir}) != "" ]]; then
        echo 
        echo "${mtproxy_dir} is an existing non-empty directory. Please specify a different directory"
        echo 
        get_mtproxy_dir
    elif [[ ! ${mtproxy_dir} =~ ^/ ]]; then
        echo 
        echo "\"${mtproxy_dir}\" is not an absolute path. Please specify an absolute path."
        echo 
        get_mtproxy_dir
    elif [[ ! -d $(dirname ${mtproxy_dir}) ]]; then
        echo 
        echo "The path $(dirname ${mtproxy_dir}) does not exist."
        echo 
        get_mtproxy_dir
    fi
    echo
}

function download_script {
	cd $INSTALLPATH
    wget -O https://phar.madelineproto.xyz/mtproxyd && chmod +x mtproxyd
	echo "Script downloaded"
	sleep .5
}

if [[ ${use_existing_mtproxy} != "false" ]]; then
	download_script;
else
	restart_mtproxy_server;
fi

function get_secret_word () {
    question="Type desired secret word"
	hint="syncret is default secret word"
	default="syncret"
    ask_question "${question}\n${hint}" "${default}"
    read SECRETWORD
    if [[ "${SECRETWORD}" == "" ]]; then
        SECRETWORD="${default}"
	elif [[ ! ${SECRETWORD} =~ ^[a-zA-Z0-9_-]{3,14}$ ]]; then
        printf "\n\033[33m${SECRETWORD}\033[m is not a valid name.\n"
        get_secret_word
    fi
    echo
}

function get_port () {
    question="Type desired port?" 
    hint="443 is the recommended port."
    default="443"
    ask_question "${question}\n${hint}" "${default}"
    read PORTNUM
    if [[ "${PORTNUM}" == "" ]]; then
        PORTNUM="${default}"
    fi
    if [[ ! ${PORTNUM} =~ ^[0-9]+$ ]]; then
        echo "\"${PORTNUM}\" is not a valid port number. "
        get_port
    fi
    echo
}

function wipe_working_folder {
    rm -rfv $MADELINEFILES
	echo "Deleted old Madeline files"
	sleep .5
}

#####################################################################

use_existing_mtproxy="false"
MADELINEFILES=$INSTALLPATH/*madeline*
INSTALLPATH=$get_mtproxy_dir
SCRIPT="$INSTALLPATH/mtproxyd"

function start_mtproxy_server () {
    get_secret_word;
	get_port;

    echo "Starting MTProxy server, please wait..."
	
    exec 3< <($SCRIPT $SECRETWORD $PORTNUM >&2)
	while read hash_string; do
		case "$hash_string" in
		*Secret*)
			echo "$hash_string"
			sleep 3
			;;
		*)
		esac
	done <&3
	exec 3<&-

	while read started_string; do
		case "$started_string" in
		*Listening*)
			bg
			;;
		*)
		esac
	done <&3
	exec 3<&-

    echo "MTProxy server started successfully"
    echo
}

function kill_all () {
    pkill -f "php ./mtproxyd *"
	wipe_working_folder;
}

function stop_mtproxy_server () {
    if ! pgrep -f "php ./mtproxyd *" 2>/dev/null 1>&2; then
        echo "MTProxy server not running yet"
        kill_all
        return 1
    fi

    echo "Stopping MTProxy server..."
    pkill -SIGTERM -f "php ./mtproxyd *"
    kill_all

    return 0
}

function restart_mtproxy_server () {
    stop_mtproxy_server;
    sleep 5
    start_mtproxy_server;
}

case $1 in
    "start" )
        start_mtproxy_server;
        ;;
    "stop" )
        stop_mtproxy_server;
        ;;
    "restart" )
        restart_mtproxy_server;
esac

echo "Done."
