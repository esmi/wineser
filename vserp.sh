#!/bin/bash
_name=$0
LOG_SOCAT=vserp.log


get_device_A() {
  head -n 1 $LOG_SOCAT | sed 's/^.* \//\//g'
}

get_device_B() {
	head -n 2 $LOG_SOCAT | tail -n 1 | sed 's/^.* \//\//g'
}

create_device_link() {
	DEVICE=$1
	MODE=$2
	DEVICE_CODE=`echo $DEVICE | sed 's/^.*\///g'`
	if [ "$DEVICE_CODE". == "". ]; then
	    echo "No such device code: [ $DEVICE_CODE ]!"
	else
		if [ -h /dev/ttyUSB$DEVICE_CODE ] ;then
			echo "Symbolic link [ /dev/ttyUSB$DEVICE_CODE ] has been exist!"	
		else
			#echo device A: $dev_A , device code: $dev_code_A
			#Symlink to a location that RXTX will recognise (/dev/ttyS*, /dev/ttyUSB*, etc)
			echo "Create symbolic link [/dev/ttyUSB$DEVICE_CODE] to device [$DEVICE]."
			sudo ln -s $DEVICE /dev/ttyUSB$DEVICE_CODE
			if [ ! "$MODE", == "". ] ; then
				echo "Create symbolic link [/dev/ttyUSB$MODE] to device [$DEVICE]."
				sudo ln -s $DEVICE /dev/ttyUSB$MODE
			fi
		fi
	fi  
}
drop_device_link() {

	DEVICE=$1
	MODE=$2
	DEVICE_CODE=`echo $DEVICE | sed 's/^.*\///g'`
	if [ "$DEVICE_CODE". == "". ]; then
	    echo "No such device code: [ $DEVICE_CODE ]!"
	else
		if [ -h /dev/ttyUSB$DEVICE_CODE ] ;then
			sudo rm -f /dev/ttyUSB$DEVICE_CODE
			echo "Symbolic link [ /dev/ttyUSB$DEVICE_CODE ] has been dropped!"	
		else
			echo "Symbolic link [ /dev/ttyUSB$DEVICE_CODE ] not exist, drop abort!"	
		fi
		if [ -h /dev/ttyUSB$MODE ] ;then
			sudo rm -f /dev/ttyUSB$MODE
			echo "Symbolic link [ /dev/ttyUSB$MODE ] has been dropped!"	
		else
			echo "Symbolic link [ /dev/ttyUSB$MODE ] not exist, drop abort!"	
		fi
		
	fi  
}

check_device() {

	DEVICE=$1
	DEVICE_CODE=`echo $DEVICE | sed 's/^.*\///g'`
	if [ "$DEVICE_CODE". == "". ]; then
	    echo "No such device code: [ $DEVICE_CODE ]!"
	else
		if [ -h /dev/ttyUSB$DEVICE_CODE ] ;then
			echo "device [ /dev/ttyUSB$DEVICE_CODE ] exist!"	
		fi
	fi  
}

__create() {

	echo "create"
	if [ "`pidof socat`". == "". ] ; then
		if [ -a $LOG_SOCAT ]; then
			rm -f $LOG_SOCAT
		fi
		#Use socat to make the two adapters:
		#socat -lf $LOG_SOCAT -d -d pty,raw,b19200,echo=0, pty,raw,b19200,echo=0 &
		socat -lf $LOG_SOCAT -d -d pty,raw,b19200,echo=0,crnl pty,raw,b19200,echo=0,crnl &
		echo "Virtual serail port create successfully:"
		sleep 2
		cat $LOG_SOCAT
		__link
	else
		echo "System has a socat process, pid is :`pidof socat`."
		echo "Please check to create virtual serial port !!!"
	fi
}
__remove() {
	if [ "`__check`". == "". ] ; then
		if [ "`pidof socat`". == "". ] ; then
			echo "No virtual serial port exist!"
		else
			read -p "Are you should to remove virtual serial port ? [Y/N}_" answer
			echo "Youre answer is : $answer"

			if [ "$answer". == "Y". ] || [ "$answer" == "y" ] ; then

				kill -s 9 `pidof socat`
				if [ "`pidof socat`". == "". ] ; then
					echo "Virtual serial port has been removed!"
				fi
			fi
		fi
	else
		__drop
		__remove
		#echo "beause device exist! You can not remove virtual serial port."
		#echo "using --drop option to drop device link, then --remove it."
		#echo "using --check option to show link info."
	fi
}
__link() {
	if [ -a $LOG_SOCAT ] ; then
		DEVICE=`get_device_A`

		create_device_link $DEVICE Local

		DEVICE=`get_device_B`

		create_device_link $DEVICE Remote 
	else
		echo "Warning: socat not create logfile( $LOG_SOCAT )! "
	fi
}

__drop() {
	if [ -a $LOG_SOCAT ] ; then
		DEVICE=`get_device_A`

		drop_device_link $DEVICE Local

		DEVICE=`get_device_B`

		drop_device_link $DEVICE Remote
	else
		echo "Warning: socat not create logfile( $LOG_SOCAT )! "
	fi
}

__check() {
	if [ -a $LOG_SOCAT ] ; then
		DEVICE=`get_device_A`

		check_device $DEVICE

		DEVICE=`get_device_B`

		check_device $DEVICE
	else
		echo "Warning: socat not create logfile( $LOG_SOCAT )! "
	fi
}

__device_info() {
	if [ "$1". == "". ]; then
		echo "No such device!"
	else
		DEVICE="$1"
		MODE="$2"
		echo DEVICE: $DEVICE

		DEVICE_CODE=`echo $DEVICE | sed 's/^.*\///g'`
		if [ -h /dev/ttyUSB$DEVICE_CODE ] ;then
			echo "LINK:   /dev/ttyUSB$DEVICE_CODE"
		else
			echo "LINK NOT CREATED!"	
		fi
		if [ ! "$MODE". == "". ] ; then
			DEVICE_CODE=`echo $MODE | sed 's/^.*\///g'`
			if [ -h /dev/ttyUSB$DEVICE_CODE ] ;then
				echo "LINK:   /dev/ttyUSB$DEVICE_CODE"
			else
				echo "LINK NOT CREATED!"	
			fi
		fi
	fi
}
__status() {
	if [ "`pidof socat`". == "".  ]; then
		if [ "`__check`". == "". ] ; then
			echo "No any virtual serial port on system!"
		fi	
	else
		echo "Virtual serial port running...(pid: `pidof socat`)"
		__device_info `get_device_A` Local
		__device_info `get_device_B` Remote

		if [ "`__check`". == "". ]; then
		    echo "No symbolic link to virtual serial port!"
			echo "Using --link to create symbolic link."
		fi  
	fi 
}

__show_help() {
	cat <<-_EOF
		${_name} is a Virtual Serial Port utils for socat.

		Usage: ${_name} [ --create | --remove | --link | --drop ] |
		                 [ --status | --check ] | [--help | --version]
						 [ --deviceA | --deviceB ]

		    --create: create virtual serial port.
		    --remove: remove virtual serial port.
		    --link:   link virtual serial port to /dev/ttyUSBXX
		    --drop:	  drop the device links

		    --check:  check device exist ?
		    --status: get the status

		    --device: get device A and B.
		    --deviceA: get device A
		    --deviceB: get device B

		    --help: show this message.	    

		_EOF
}

#Use socat to make the two adapters:
#socat -lf $LOG_SOCAT -d -d pty,raw,echo=0, pty,raw,echo=0 &

COMMON_OP="help,version,debug:"
COMMAND_OP="create,remove,link,drop,check,status"
DEVICE_OP="device,deviceA,deviceB"
ALL_OP="$COMMON_OP,$COMMAND_OP,$DEVICE_OP"
OPT=`getopt -o Dd:,hHvV --long $ALL_OP -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

__SITE=""

eval set -- "$OPT"
if [  $# -eq 1 ] ; then __show_help; fi
set +e
while true ; do
    case "$1" in
	--create)		__create;	shift;;
	--remove)		__remove;	shift;;
	--link)			__link;		shift;;
	--drop)			__drop;		shift;;
	--check)		__check;	shift;;
	--status)		__status;	shift;;
	--device)		get_device_A; get_device_B; shift;;
	--deviceA)		get_device_A; shift;;
	--deviceB)		get_device_B; shift;;
	--version|-v)	__show_version; shift	    ;;
	-h|--help) 	__show_help;    shift;;
        --)		shift   ;	break 	    ;;
	*)		shift 	;;
    esac
done

# I tested using two instances of minicom (one on each port)
#minicom -D /dev/ttyUSB03
#minicom -D /dev/ttyUSB04
