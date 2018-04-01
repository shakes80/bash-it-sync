#!/usr/bin/env bash

#######################################################
# SPECIAL FUNCTIONS
#######################################################

# Use the best version of pico installed
edit ()
{
    if [ "$(type -t nano)" = "file" ]; then
        nano "$@"
	echo "YO"
    elif [ "$(type -t pico)" = "file" ]; then
        pico "$@"
	echo "ZO"
    else
#		nano $1
        vim "$@"
    fi
}
sedit ()
{
    if [ "$(type -t nano)" = "file" ]; then
        sudo nano "$@"
    elif [ "$(type -t pico)" = "file" ]; then
        sudo pico "$@"
    else
	#	sudo nano -w "$@"
        sudo vim "$@"
    fi
}

#-------------------------------------------------------------
# Automatic setting of $DISPLAY (if not set already).
# This works for linux - your mileage may vary. ... 
# The problem is that different types of terminals give
# different answers to 'who am i' (rxvt in particular can be
# troublesome).
# I have not found a 'universal' method yet.
#-------------------------------------------------------------

get_xserver ()
{
    case $TERM in
       xterm )
            XSERVER=$(who am i | awk '{print $NF}' | tr -d ')''(' ) 
            # Ane-Pieter Wieringa suggests the following alternative:
            # I_AM=$(who am i)
            # SERVER=${I_AM#*(}
            # SERVER=${SERVER%*)}

            XSERVER=${XSERVER%%:*}
            ;;
        aterm | rxvt)
        # Find some code that works here. ...
            ;;
    esac
}

if [ -z ${DISPLAY:=""} ]; then
    get_xserver
    if [[ -z ${XSERVER}  || ${XSERVER} == $(hostname) || \
      ${XSERVER} == "unix" ]]; then 
        DISPLAY=":0.0"          # Display on local host.
    else
        DISPLAY=${XSERVER}:0.0  # Display on remote host.
    fi
fi

export DISPLAY

# Searches for text in all files in the current folder
ftext ()
{
	# -i case-insensitive
	# -I ignore binary files
	# -H causes filename to be printed
	# -r recursive search
	# -n causes line number to be printed
	# optional: -F treat search term as a literal, not a regular expression
	# optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
	grep -iIHrn --color=always "$1" . | less -r
}

# Copy file with a progress bar
cpp()
{
	set -e
	strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
	| awk '{
	count += $NF
	if (count % 10 == 0) {
		percent = count / total_size * 100
		printf "%3d%% [", percent
		for (i=0;i<=percent;i++)
			printf "="
			printf ">"
			for (i=percent;i<100;i++)
				printf " "
				printf "]\r"
			}
		}
	END { print "" }' total_size=$(stat -c '%s' "${1}") count=0
}

# Copy and go to the directory
cpg ()
{
	if [ -d "$2" ];then
		cp $1 $2 && cd $2
	else
		cp $1 $2
	fi
}

# Move and go to the directory
mvg ()
{
	if [ -d "$2" ];then
		mv $1 $2 && cd $2
	else
		mv $1 $2
	fi
}

# Create and go to the directory
mkdirg ()
{
	mkdir -p $1
	cd $1
}

# Goes up a specified number of directories  (i.e. up 4)
up ()
{
	local d=""
	limit=$1
	for ((i=1 ; i <= limit ; i++))
		do
			d=$d/..
		done
	d=$(echo $d | sed 's/^\///')
	if [ -z "$d" ]; then
		d=..
	fi
	cd $d
}

#Automatically do an ls after each cd
cd ()
 {
 	if [ -n "$1" ]; then
 		builtin cd "$@" && ls -aFh --color=always
 	else
 		builtin cd ~ && ls -aFh --color=always
 	fi
 }

# Returns the last 2 fields of the working directory
pwdtail ()
{
	pwd|awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Show the current distribution
distribution ()
{
	local dtype
	# Assume unknown
	dtype="unknown"
	# First test against Fedora / RHEL / CentOS / generic Redhat derivative
	if [ -r /etc/rc.d/init.d/functions ]; then
		source /etc/rc.d/init.d/functions
		[ zz`type -t passed 2>/dev/null` == "zzfunction" ] && dtype="redhat"
	# Then test against SUSE (must be after Redhat,
	# I've seen rc.status on Ubuntu I think? TODO: Recheck that)
	elif [ -r /etc/rc.status ]; then
		source /etc/rc.status
		[ zz`type -t rc_reset 2>/dev/null` == "zzfunction" ] && dtype="suse"
	# Then test against Debian, Ubuntu and friends
	elif [ -r /lib/lsb/init-functions ]; then
		source /lib/lsb/init-functions
		[ zz`type -t log_begin_msg 2>/dev/null` == "zzfunction" ] && dtype="debian"
	# Then test against Gentoo
	elif [ -r /etc/init.d/functions.sh ]; then
		source /etc/init.d/functions.sh
		[ zz`type -t ebegin 2>/dev/null` == "zzfunction" ] && dtype="gentoo"
	# For Mandriva we currently just test if /etc/mandriva-release exists
	# and isn't empty (TODO: Find a better way :)
	elif [ -s /etc/mandriva-release ]; then
		dtype="mandriva"

	# For Slackware we currently just test if /etc/slackware-version exists
	elif [ -s /etc/slackware-version ]; then
		dtype="slackware"
	fi
	echo $dtype
}

# Show the current version of the operating system
ver ()
{
	local dtype
	dtype=$(distribution)

	if [ $dtype == "redhat" ]; then
		if [ -s /etc/redhat-release ]; then
			cat /etc/redhat-release && uname -a
		else
			cat /etc/issue && uname -a
		fi
	elif [ $dtype == "suse" ]; then
		cat /etc/SuSE-release
	elif [ $dtype == "debian" ]; then
		lsb_release -a
		# sudo cat /etc/issue && sudo cat /etc/issue.net && sudo cat /etc/lsb_release && sudo cat /etc/os-release # Linux Mint option 2
	elif [ $dtype == "gentoo" ]; then
		cat /etc/gentoo-release
	elif [ $dtype == "mandriva" ]; then
		cat /etc/mandriva-release
	elif [ $dtype == "slackware" ]; then
		cat /etc/slackware-version
	else
		if [ -s /etc/issue ]; then
			cat /etc/issue
		else
			echo "Error: Unknown distribution"
			exit 1
		fi
	fi
}

# Automatically install the needed support files for this .bashrc file
install_custom_support ()
{
	local dtype
	dtype=$(distribution)

	if [ $dtype == "redhat" ]; then
		sudo yum install multitail tree joe
	elif [ $dtype == "suse" ]; then
		sudo zypper install multitail
		sudo zypper install tree
#		sudo zypper install joe
	elif [ $dtype == "debian" ]; then
		sudo apt-get install multitail tree
# joe
	elif [ $dtype == "gentoo" ]; then
		sudo emerge multitail
		sudo emerge tree
#		sudo emerge joe
	elif [ $dtype == "mandriva" ]; then
		sudo urpmi multitail
		sudo urpmi tree
#		sudo urpmi joe
	elif [ $dtype == "slackware" ]; then
		echo "No install support for Slackware"
	else
		echo "Unknown distribution"
	fi
}

# Show current network information
netinfo ()
{
	echo "--------------- Network Information ---------------"
	/sbin/ifconfig | awk /'inet addr/ {print $2}'
	echo ""
	/sbin/ifconfig | awk /'Bcast/ {print $3}'
	echo ""
	/sbin/ifconfig | awk /'inet addr/ {print $4}'

	/sbin/ifconfig | awk /'HWaddr/ {print $4,$5}'
	echo "---------------------------------------------------"
}

# IP address lookup
alias whatismyip="whatsmyip"
function whatsmyip ()
{
	# Dumps a list of all IP addresses for every device
	/sbin/ifconfig |grep -B1 "inet addr" |awk '{ if ( $1 == "inet" ) { print $2 } else if ( $2 == "Link" ) { printf "%s:" ,$1 } }' |awk -F: '{ print $1 ": " $3 }';

	# Internal IP Lookup
	#echo -n "Internal IP: " ; /sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'

	# External IP Lookup
	#echo -n "External IP: " ; wget http://smart-ip.net/myip -O - -q
}

##################################################
# Text alignment				 #
##################################################

###### center text in console with simple pipe like
function align_center() { l="$(cat -)"; s=$(echo -e "$l"| wc -L); echo "$l" | while read l;do j=$(((s-${#l})/2));echo "$(while ((--j>0)); do printf " ";done;)$l";done;} #; ls --color=none / | center

###### right-align text in console using pipe like ( command | right )
function align_right() { l="$(cat -)"; [ -n "$1" ] && s=$1 || s=$(echo -e "$l"| wc -L); echo "$l" | while read l;do j=$(((s-${#l})));echo "$(while ((j-->0)); do printf " ";done;)$l";done;} #; ls --color=none / | right 150

##################################################
# Network information and IP address stuff	 #
##################################################

###### get all IPs via ifconfig
function allips()
{
ifconfig | awk '/inet / {sub(/addr:/, "", $2); print $2}'
}

###### clear iptables rules safely
function clearIptables()
{
iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT; iptables -F; iptables -X; iptables -L
}

###### online check
function connected() { ping -c1 -w2 google.com > /dev/null 2>&1; }

function connected_() { rm -f /tmp/connect; http_proxy='http://a.b.c.d:8080' wget -q -O /tmp/connect http://www.google.com; if [[ -s /tmp/connect ]]; then return 0; else return 1; fi; }

###### check if a remote port is up using dnstools.com
# (i.e. from behind a firewall/proxy)
function cpo() { [[ $# -lt 2 ]] && echo 'need IP and port' && return 2; [[ `wget -q "http://dnstools.com/?count=3&checkp=on&portNum=$2&target=$1&submit=Go\!" -O - |grep -ic "Connected successfully to port $2"` -gt 0 ]] && echo OPEN || echo CLOSED; }

###### find an unused unprivileged TCP port
function findtcp()
{
(netstat  -atn | awk '{printf "%s\n%s\n", $4, $4}' | grep -oE '[0-9]*$'; seq 32768 61000) | sort -n | uniq -u | head -n 1
}

###### geoip lookup (need geoip database: sudo apt-get install geoip-bin)
function geoip() {
geoiplookup $1
}

###### geoip information
# requires 'html2text': sudo apt-get install html2text
function geoiplookup() { curl -A "Mozilla/5.0" -s "http://www.geody.com/geoip.php?ip=$1" | grep "^IP.*$1" | html2text; }

###### get IP address of a given interface
# Example: getip lo
# Example: getip eth0	# this is the default
function getip()		{ lynx -dump http://whatismyip.org/; }

###### display private IP
function ippriv()
{
    ifconfig eth0|grep "inet adr"|awk '{print $2}'|awk -F ':' '{print $2}'
}

###### ifconfig connection check
function ips()
{
    if [ "$OS" = "Linux" ]; then
        for i in $( /sbin/ifconfig | grep ^e | awk '{print $1}' | sed 's/://' ); do echo -n "$i: ";  /sbin/ifconfig $i | perl -nle'/dr:(\S+)/ && print $1'; done
    elif [ "$OS" = "Darwin" ]; then
        for i in $( /sbin/ifconfig | grep ^e | awk '{print $1}' | sed 's/://' ); do echo -n "$i: ";  /sbin/ifconfig $i | perl -nle'/inet (\S+)/ && print $1'; done
    fi
}

###### geolocate a given IP address
function ip2loc() { wget -qO - www.ip2location.com/$1 | grep "<span id=\"dgLookup__ctl2_lblICountry\">" | sed 's/<[^>]*>//g; s/^[\t]*//; s/&quot;/"/g; s/</</g; s/>/>/g; s/&amp;/\&/g'; }

###### myip - finds your current IP if your connected to the internet
function myip()
{
lynx -dump -hiddenlinks=ignore -nolist http://checkip.dyndns.org:8245/ | awk '{ print $4 }' | sed '/^$/d; s/^[ ]*//g; s/[ ]*$//g'
}

###### check whether or not a port on your box is open
function portcheck() { for i in $@;do curl -s "deluge-torrent.org/test-port.php?port=$i" | sed '/^$/d;s/<br><br>/ /g';done; }

###### show Url information
# Usage:	url-info "ur"
# This script is part of nixCraft shell script collection (NSSC)
# Visit http://bash.cyberciti.biz/ for more information.
# Modified by Silviu Silaghi (http://docs.opensourcesolutions.ro) to handle
# more ip adresses on the domains on which this is available (eg google.com or yahoo.com)
# Last updated on Sep/06/2010
function url-info()
{
doms=$@
if [ $# -eq 0 ]; then
echo -e "No domain given\nTry $0 domain.com domain2.org anyotherdomain.net"
fi
for i in $doms; do
_ip=$(host $i|grep 'has address'|awk {'print $4'})
if [ "$_ip" == "" ]; then
echo -e "\nERROR: $i DNS error or not a valid domain\n"
continue
fi
ip=`echo ${_ip[*]}|tr " " "|"`
echo -e "\nInformation for domain: $i [ $ip ]\nQuerying individual IPs"
 for j in ${_ip[*]}; do
echo -e "\n$j results:"
whois $j |egrep -w 'OrgName:|City:|Country:|OriginAS:|NetRange:'
done
done
}

##################################################
# Show all strings (ASCII & Unicode) in a file	 #
##################################################

function allStrings() { cat "$1" | tr -d "\0" | strings ; }

##################################################
# Ask						 #
##################################################

function ask()
{
    echo -n "$@" '[y/n] ' ; read ans
    case "$ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
}

##################################################
# Execute a given Linux command on a group of	 #
# files						 #
##################################################

###### Example: batchexec sh ls		# lists all files that have the extension 'sh'
# Example: batchexec sh chmod 755	# 'chmod 755' all files that have the extension 'sh'
function batchexec()
{
find . -type f -iname '*.'${1}'' -exec ${@:2}  {} \; ;
}

##################################################
# What package does that command come from?	 #
##################################################

function cmdpkg() { PACKAGE=$(dpkg -S $(which $1) | cut -d':' -f1); echo "[${PACKAGE}]"; dpkg -s "${PACKAGE}" ;}
##################################################################
# BashTips
##################################################################
function bashtips() {
cat <<EOF
Shell shortcuts

Navigating the Bash shell is easy to do.  But it takes time to learn how to do well.  Below are a number of shortcuts that make the navigation process much more efficient.  

This is a nice reference with more examples and features

Ctrl + a => Return to the start of the command you’re typing
Ctrl + e => Go to the end of the command you’re typing
Ctrl + u => Cut everything before the cursor to a special clipboard
Ctrl + k => Cut everything after the cursor to a special clipboard
Ctrl + y => Paste from the special clipboard that Ctrl + u and Ctrl + k save their data to
Ctrl + t => Swap the two characters before the cursor (you can actually use this to transport a character from the left to the right, try it!)
Ctrl + w => Delete the word / argument left of the cursor
Ctrl + l => Clear the screen
Ctrl + _ => Undo previous key press
Ctrl + xx => Toggle between current position and the start of the line
There are some nice Alt key shortcuts in Linux as well.  You can map the alt key in OSX pretty easily to unlock these shortcuts.

Alt + l => Uncapitalize the next word that the cursor is under (If the cursor is in the middle of the the word it will capitalize the last half of the word).
Alt + u => Capitalize the word that the cursor is under
Alt + t => Swap words or arguments that the cursor is under with the previous
Alt + . => Paste the last word of the previous command
Alt + b => Move backward one word
Alt + f => Move forward one word
Alt + r => Undo any changes that have been done to the current command
Argument tricks

Argument tricks can help to grow the navigation capabilities that Bash shortcuts provide and can even further speed up your effectiveness in the terminal.  Below is a list of special arguments that can be passed to any command that can be expanded into various commands.

Repeating

!! => Repeat the previous (full) command
!foo => Repeat the most recent command that starts with ‘foo‘ (e.g. !ls)
!^ => Repeat the first argument of the previous command
!$ => Repeat the last argument of the previous command
!* => Repeat all arguments of last command
!:<number> => Repeat a specifically positioned argument
!:1-2 => Repeat a range of arguments

Printing

!$:p => Print out the word that !$ would substitute
!*:p => Print out the previous command except for the last word
!foo:p =>Print out the command that !foo would run
Special parameters

When writing scripts , there are a number of special parameters you can feed into the shell.  This can be convenient for doing lots of different things in scripts.  Part of the fun of writing scripts and automating things is discovering creative ways to fit together the various pieces of the puzzle in elegant ways.  The “special” parameters listed below can be seen as pieces of the puzzle, and can be very powerful building blocks in your scripts.

Here is a full reference from the Bash documentation

\$* => Expand parameters. Expands to a single word for each parameter separated by IFS delimeter – think spaces
\$@ => Expand parameters. Each parameter expand to a separate word, enclosed by “” –  think arrays
\$# => Expand the number of parameters of a command
\$? => Expand the exit status of the previous command
\$\$ => Expand the pid of the shell
\$! => Expand the pid of the most recent command
\$0 => Expand the name of the shell or script
\$_ => Expand the last previous argument
EOF
}
