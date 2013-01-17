#!/bin/sh
#
#
# Notice: THIS DOES _NOT_ (!!!) USE A SECURE CONNECTION!
#         It is plain HTTP.
#
#
# This variant uses the system's ping command instead of gethostip.
#


dyndns_servername="members.dyndns.org";
dyndns_serverport=80;

ip_cache_file="cached_ip.txt";
ip_list_file="ip_list.txt"
dyndns_name="booze.dyndns.org";
credentials_file="credentials.txt"


echo "Requesting router IP ..."
my_router_ip=$(wget http://www.int2byte.de/your_ip_is.php -q -O -)

ec="$?"
if [ "$ec" -ne "0" ]; then
    echo "Failed. Exit code $ec"
    exit 1
fi

echo "  >> $my_router_ip"




echo "Retrieving current dyndns host IP ..."
# Unfortunetaly the 'gethostbyip' is not included in the bind9 packackages of raspbian :(
# current_dyndns_ip=$(gethostip -d $dyndns_name)

# That's why I retrieve the IP using ping
working_dir=$(dirname $0)
# echo "working_dir=$working_dir"
current_dyndns_ip=$($working_dir/getipfromping.sh $dyndns_name)

ec="$?"
if [ "$ec" -ne "0" ]; then
    echo "Failed. Exit code $ec"
    exit 1
fi

echo "  >> $current_dyndns_ip"



# Is there really the need to continue
if [ "$my_router_ip" != "$current_dyndns_ip" ]; then

    echo "Router IP and dyndns IP differ ... going to update."

# elif [ $# -gt 0 -a $1 = '-f' ]; then
elif [ $# -gt 0 ]; then

    if [ $1 = '-f' ]; then

	echo "Router IP and dyndns IP are equal but '-f' argument was passed."

    else

	echo "Unknown option $1"
	exit 3;

    fi

else 

    echo "Router IP and dyndns IP are equal. No need to update."
    exit 0;

fi




#if [ $(test -e $ip_cache_file) ]; then
if [ -f $ip_cache_file ]; then
    echo "Reading last configured roter ip from cache ..."
    read cached_ip < $ip_cache_file;
    echo "Cached ip was $cached_ip."
else
    echo "No cache file found. Skipping."
fi


echo "Writing current router IP to cache file ..."
echo $my_router_ip > $ip_cache_file



echo "Retrieving localhost's inet address ..."
my_local_address=$(/sbin/ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
echo "  >> $my_local_address"



echo "Reading IP list file ..."
next_ip=0;
line_no=0;

# This whole read-lines-from-file-then-filter-comments is totally messed up! I give up.
# I just read through a grep-filter now :)
# while read line; do

grep -v '^[[:space:]]*#' $ip_list_file | while read line; do

    line_no=`expr $line_no + 1`;
    

    echo "  >> entry #$line_no: $line";

    if [ "$line" != "$my_local_address" ]; then
	
	echo "  >> Check whether the machine $line is online ..."

	ping_result=$(ping -c 1 $line)
	ec="$?"
	if [ "$ec" -eq "0" ]; then
	  
	    echo "     The machine seems to be ONLINE."
	    echo "     Stopping due to lower priority."
	    exit 0

        else

	    echo "     The machine seems to be OFFLINE."

	fi

    else

	echo "  >> This is my local IP in the priority list."
	echo "     Seems no one with higher prio is online."
	break;

    fi

    
done # < "ip_list.txt"


# Prepare dyndns-update: fetch credentials (from file or stdin)
dyndns_host=""
dyndns_user=""
dyndns_b64=""
if [ ! -f $credentials_file ]; then

    echo "Credentials file $credentials_file not found."
    echo "Please tell me your login data (will not be stored)."

    echo -n "User: "
    read user

    echo -n "Password: "    
    # The stty command disables the realtime echo for input
    stty -echo
    read pass
    stty echo
    # Force a line break
    echo ""

    # echo $pass	

else

    echo "Read credentials from config ..."
    
    line_no=0;
    line=""
    # THIS version of the loop will not work! The forked process has its own environment
    # so the (global) vars cannot be changed!
    # grep -v '^[[:space:]]*#' $credentials_file | while read line; do

    # Use a regular loop instead (no comments in file allowed)
    while read line; do

	line_no=`expr $line_no + 1`;
    
	# echo "  >> entry #$line_no: $line";

	if [ $line_no -eq 1 ]; then
	    dyndns_host=$line;
	elif [ $line_no -eq 2 ]; then
	    dyndns_user=$line
	elif [ $line_no -eq 3 ]; then
	    dyndns_b64=$line
	fi

    done < $credentials_file
fi


# echo "Host = $dyndns_host"
# echo "User = $dyndns_user"
# echo "b64  = $dyndns_b64"

# For testing with a fake IP (dyndns routing should fail after update)
# my_router_ip="204.13.248.111";

# How the f*** do I assign a multi-line string in a shell script?!
# This solution is definitely un-readable
dyndns_headers="GET /nic/update?hostname=$dyndns_host&myip=$my_router_ip&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG HTTP/1.0\nHost: members.dyndns.org\nAuthorization: Basic $dyndns_b64\nUser-Agent: Self Destructive Corp. - DynDNSsoft alpha - 0.1\n\n";



echo "Going to send update request:" 
echo $dyndns_headers
update_result=$(echo $dyndns_headers | telnet $dyndns_servername $dyndns_serverport)

echo "Update result: $update_result"








