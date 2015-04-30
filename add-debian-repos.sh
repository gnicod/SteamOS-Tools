#!/bin/bash

# -----------------------------------------------------------------------
# Author: 	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	add-debian-repos.sh
# Script Ver:	0.1.7
# Description:	This script automatically enables debian repositories
#		The script must be run as root to add the source list
#		lines to system directory locations.
#
#		See: https://wiki.debian.org/AptPreferences#Pinning
#
# Usage:	sudo ./add-debian-repos [install|uninstall|--help]
# ------------------------------------------------------------------------

# remove old custom files
rm -f "log.txt"

# set default action if no args are specified
install="yes"

# check for and set install status
if [[ "$1" == "install" ]]; then
	install="yes"
elif [[ "$1" == "uninstall" ]]; then
    	install="no"
fi

funct_set_vars()
{
	# Set default user options
	reponame="wheezy"
	backports_reponame="wheezy-backports"
	
	sourcelist="/etc/apt/sources.list.d/${reponame}.list"
	backports_sourcelist="/etc/apt/sources.list.d/${backports_reponame}.list"
	
	prefer="/etc/apt/preferences.d/${reponame}"
	backports_prefer="/etc/apt/preferences.d/${backports_reponame}"
	steamos_prefer="/etc/apt/preferences.d/steamos"
}

show_help()
{
	clear
	echo "###########################################################"
	echo "Usage instructions"
	echo "###########################################################"
	echo -e "\nYou can run this script as such," 
	echo -e "\n\n'sudo add-debian-repos.sh\n"
	
}

funct_show_warning()
{
	# Warn user script must be run as root
	if [ "$(id -u)" -ne 0 ]; then
		clear
		printf "\nScript must be run as root! Try:\n\n"
		printf "'sudo $0 install'\n\n"
		printf "OR\n"
		printf "\n'sudo $0 uninstall'\n\n"
		exit 1
	fi
}

main()
{
	#####################################################
	# Install/Uninstall process
	#####################################################
	
	if [[ "$install" == "yes" ]]; then
		clear
		echo -e "==> Adding Debian ${reponame} and ${backports_reponame} repositories\n"
		sleep 1s
		
		# Check for existance of /etc/apt/preferences file (deprecated, see below)
		if [[ -f "/etc/apt/preferences" ]]; then
			# backup preferences file
			echo -e "==> Backing up /etc/apt/preferences to /etc/apt/preferences.bak\n"
			mv "/etc/apt/preferences" "/etc/apt/preferences.bak"
			sleep 1s
		fi
		
		# Check for existance of /etc/apt/preferences.d/{steamos_prefe} file
		if [[ -f ${steamos_prefer} ]]; then
			# backup preferences file
			echo -e "==> Backing up ${steamos_prefer} to ${steamos_prefer}.bak\n"
			mv ${steamos_prefer} ${steamos_prefer}.bak
			sleep 1s
		fi
		
		# Check for existance of /etc/apt/preferences.d/{prefer} file
		if [[ -f ${prefer} ]]; then
			# backup preferences file
			echo -e "==> Backing up ${prefer} to ${prefer}.bak\n"
			mv ${prefer} ${prefer}.bak
			sleep 1s
		fi
		
		# Check for existance of /etc/apt/preferences.d/{backports_prefer} file
		if [[ -f ${backports_prefer} ]]; then
			# backup preferences file
			echo -e "==> Backing up ${backports_prefer} to ${backports_prefer}.bak\n"
			mv ${backports_prefer} ${backports_prefer}.bak
			sleep 1s
		fi
	
		# Create and add required text to preferences file
		cat <<-EOF > ${prefer}
		Package: *
		Pin: release l=Debian
		Pin-Priority:110
		EOF
		
		cat <<-EOF > ${backports_prefer}
		Package: *
		Pin: release a=wheezy-backports
		Pin-Priority:150
		EOF
	
		cat <<-EOF > ${steamos_prefer}
		Package: *
		Pin: release l=SteamOS
		Pin-Priority: 900
		EOF
		
		#####################################################
		# Check for lists in repos.d
		#####################################################
		
		# If it does not exist, create it
		
		if [[ -f ${sourcelist} ]]; then
	        	# backup sources list file
	        	echo -e "==> Backing up ${sourcelist} to ${sourcelist}.bak\n"
	        	mv ${sourcelist} ${sourcelist}.bak
	        	sleep 1s
		fi
		
		if [[ -f ${backports_sourcelist} ]]; then
	        	# backup sources list file
	        	echo -e "==> Backing up ${backports_sourcelist} to ${backports_sourcelist}.bak\n"
	        	mv ${backports_sourcelist} ${backports_sourcelist}.bak
	        	sleep 1s
		fi
	
		#####################################################
		# Create and add required text to wheezy.list
		#####################################################

		# Debian wheezy
		cat <<-EOF > ${sourcelist}
		# Debian-wheezy repo
		deb ftp://mirror.nl.leaseweb.net/debian/ wheezy main contrib non-free
		deb-src ftp://mirror.nl.leaseweb.net/debian/ wheezy main contrib non-free
		EOF
		
		# Debian wheezy-backports
		cat <<-EOF > ${backports_sourcelist}
		deb http://http.debian.net/debian wheezy-backports main
		EOF

		# Update system
		echo -e "==> Updating index of packages...\n"
		sleep 2s
		apt-get update
	
		#####################################################
		# Remind user how to install
		#####################################################
		clear
		echo -e "\n###########################################################"
		echo "How to use"
		echo -e "###########################################################"
		echo -e "\nYou can now not only install package from the SteamOS repository," 
		echo -e "but also from the Debian repository with either:\n\n"
		echo -e "'sudo apt-get install <package_name>'"
		echo -e "'sudo apt-get -t [wheezy|wheezy-backports] install <package_name>'\n"
		echo -e "Warning: If the apt package manager seems to want to remove a lot"
		echo -e "of packages you have already installed, be very careful about proceeding.\n"
	
	elif [[ "$install" == "no" ]]; then
		clear
		echo -e "\n==> Removing debian repositories...\n"
		sleep 2s
		rm -f ${sourcelist}
		rm -f ${backports_sourcelist}
		rm -f ${prefer}
		rm -f ${steamosprefer}
		echo -e "Updating index of packages...\n"
		sleep 2s
		apt-get update
		echo "Done!"
	fi
}

#Show help if requested
if [[ "$1" == "--help" ]]; then
        show_help
	exit 0
fi
#####################################################
# handle prerequisite software
#####################################################

funct_set_vars
funct_show_warning

#####################################################
# MAIN
#####################################################
main | tee log_temp.txt

#####################################################
# cleanup
#####################################################

# convert log file to Unix compatible ASCII
strings log_temp.txt > log.txt

# strings does catch all characters that I could 
# work with, final cleanup
sed -i 's|\[J||g' log.txt

# remove file not needed anymore
rm -f "log_temp.txt"
