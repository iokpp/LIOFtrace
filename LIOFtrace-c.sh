#!/usr/bin/env bash
# Copyright (C) Micron Semiconductor Corp., 2018
#
# This is a shell script file which is used to generate trace log for Linux IO trace tool LIO.
#
# 2018-Jun-1: Initial version by Bean Huo <beanhuo@micron.com>
#


source ./trace-cfg   # load configure file

export OP="record"
export CMD="NULL"
export ENABLE=1
export DISABLE=0
export TraceFs="/sys/kernel/debug/tracing"  # the tracefs folder by default
export DEBUG=$ENABLE
export LogFile="./trace.dat" # Trace log file name by default
export tracer="nop"  # Tracer by default
export buffer=65536 # trace buffer by default
export opt=""
export gz=0

function print() {
	if [ $DEBUG -eq $ENABLE ]; then
	local msg=$1
	echo $msg
	fi
}

function usage() {
cat << EOF
Usage:
$0 [-o <file>] [-O flag] [-c "command"] ...
	-o <file> : Trace log location
	-p <tracer> : Which tracer do you want to deploy.
	-O <flag string> : Add new command option parameters for trace log
	-m <buffer size in byte> : Set the trace buffer size per cpu
	-c "command" : The running command while tracing. Use -c before
            command if using command options that could be confused
            with options. If this option is not specified, tool will go
            into "monitor" mode.
	-h|-H : Show usage infor.

    eg:
		./LIOFtrace-c.sh -o ./trace.log -O nooverwrite -m 65536 -c "/data/iozone -eco ..."
EOF
}

function check_env() {

if type ${Trace_C} >/dev/null 2>&1; then
	echo ""
else
	usage
	echo "${Trace_C} doesn't work!"
	echo "I require trace-cmd, but it's not installed. Please install firstly. Or"
	echo " using -l option to specify it."
	echo " Aborting."
	exit
fi
}

function search_for_tracefs() {

	TraceFs=`sed -ne 's/^tracefs \(.*\) tracefs.*/\1/p' /proc/mounts | tail -1`

    if [ -z ${TraceFs} ];then
        echo -e "System doesn't enable Ftrace"
        exit 2
    fi
	print "The TraceFs location is  ${TraceFs}"
}

function enable_event() {
    #enable static event trace point
    if [ -f "${TraceFs}/available_events" ]; then

        set +e #Prevent grep from exiting in case of nomatch

        trace_point="$(grep -w $1 ${TraceFs}/available_events)"

        if [ $? -eq 0 ]; then
            IFS=':'
            read -ra array <<< "$trace_point"
            event_folder=${array[0]}
            if [ -d ${TraceFs}/events/${event_folder} ]; then
                echo 1 | sudo tee  ${TraceFs}/events/${event_folder}/${array[1]}/enable > /dev/null
            fi
        else
            echo "$1 is not in the available event list"
        fi
        set -e #Cancel grep from exiting in case of nomatch
    else
         echo "available_events does not exist."
         exit 1
    fi
}

function enable_trace_point() {
    #Parse the trace points and enable them
    local OPTIND
    while getopts ":e:f:" opt ; do
        case "$opt" in
            e ) # default character to display if no weather, leave empty for none
                event="$OPTARG"
                enable_event $event
                ;;
            \? )
                echo "Invalid option: -$OPTARG" >&2
                ;;
            : )
                echo "Option -$OPTARG requires an argument." >&2
                exit 1
                ;;
        esac

    done
    #shift $((OPTIND-1))
}

# trap  Ctrl-C
function trap_ctrl_c ()
{
    # perform cleanup here
    echo "Stop monitor mode..."
    echo ""
    echo 0 | tee ${TraceFs}/tracing_on > /dev/null

    if [ $? -eq 0 ]; then
      cat ${TraceFs}/trace > ${LogFile}
    fi
    exit 2
}

#############################
######### Main() ############
#############################

export opts="m:p:o:O:Hhb:c:"

search_for_tracefs  #look for the tracefs folder

while getopts ${opts}  OPTION;do
	case $OPTION in
	o )
	LogFile=$OPTARG
	print "Output file specified is  ${LogFile}"
	;;
	p )
	tracer=$OPTARG
	print "tracer specified is  ${tracer}"
	;;
	O )
	opt+=" $OPTARG"
	;;
	m )
	buffer=$OPTARG
	print "Buffer size specified is ${buffer} per CPU"
	;;
	c )
	CMD=$OPTARG
	print "Command specified is ${CMD}"
	;;
	h|H )
	usage
	exit 1
	;;
	* )
	usage
	exit 1
	;;
	esac
done

if [ ! -z ${opt} ]; then
    print "trace_options : ${opt}"
    echo ${opt} | tee ${TraceFs}/trace_options > /dev/null
fi

echo 0 | tee ${TraceFs}/tracing_on > /dev/null
echo 0 | tee ${TraceFs}/trace > /dev/null
echo  | tee ${TraceFs}/set_event > /dev/null
echo ${tracer} | tee ${TraceFs}/current_tracer > /dev/null

enable_trace_point ${TRACE_POINTS}

if ! [ -x "$(command -v gzip)" ]; then
    echo 'Error: gzip is not installed.' >&2
else
    gz=1
fi

echo 1 | tee ${TraceFs}/tracing_on > /dev/null

if [ ${CMD} == "NULL" ]; then
  trap "trap_ctrl_c" 2
  echo "Entering monitor mode, and exit monitor mode please use ctrl+C"
  while true; do
    sleep 3
    echo -n "."
  done
else
  eval ${CMD}
  echo 0 | tee ${TraceFs}/tracing_on > /dev/null

  if [ $? -eq 0 ]; then
        if [ ${gz} == 1 ]; then
            cat ${TraceFs}/trace | gzip > ${LogFile}.gz
        else
            cat ${TraceFs}/trace > ${LogFile}
        fi
  fi
fi
