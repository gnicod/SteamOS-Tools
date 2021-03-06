#!/bin/bash

# -------------------------------------------------------------------------------
# Author:    	Michael DeGuzis
# Git:	    	https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-deb-from-PPA.sh
# Script Ver:	0.4.5
# Description:	Attempts to build a deb package from a PPA
#
# See also:	Generate a source list: http://repogen.simplylinux.ch/
#		Command 'rmadison' from devscripts to see arch's
#		Command 'apt-cache madison <PKG>'
#
# Usage:	./build-deb-from-PPA.sh
#		source ./build-deb-from-PPA.sh
#		./build-deb-from-PPA.sh --ignore-deps
# -------------------------------------------------------------------------------

####################################################
# Notes regarding some sources
####################################################

# Ubuntu packages are not "PPA's" so example deb-src lines are:
# deb-src http://archive.ubuntu.com/ubuntu vivid main restricted universe multiverse
# GPG-key(s): 437D05B5, C0B21F32



arg1="$1"
scriptdir=$(pwd)
ignore_deps="no"
build_source_dir="Not applicable"

show_help()
{
	clear
	cat <<-EOF
	####################################################
	Usage:	
	####################################################
	./build-deb-from-PPA.sh
	./build-deb-from-PPA.sh --help
	./build-deb-from-PPA.sh --ignore-deps
	source ./build-deb-from-PPA.sh
	
	The fourth option, preeceded by 'source' will 
	execute the script in the context of the calling 
	shell and preserve vars for the next run.
	
	IF you see the message:
	WARNING: The following packages cannot be authenticated!...
	Look above in the output for apt-get update. You will see a
	line for 'NO_PUBKEY 3B4FE6ACC0B21F32'. Import this key string
	by issuing 'gpg_import.sh <key>' from the extra DIR of this repo.
	
	EOF
	
}

if [[ "$arg1" == "--help" ]]; then
	
	#show help
	show_help
	exit 1
	
elif [[ "$arg1" == "--ignore-deps" ]]; then

	# There are times when another package provides what we want in Debian
	ignore_deps="yes"

fi

install_prereqs()
{

	clear
	# set scriptdir
	scriptdir="$HOME/SteamOS-Tools"
	
	echo -e "==> Checking for Debian sources..."
	
	# check for repos
	sources_check=$(sudo find /etc/apt -type f -name "jessie*.list")
	
	if [[ "$sources_check" == "" ]]; then
                echo -e "\n==INFO==\nSources do *NOT* appear to be added at first glance. Adding now..."
                sleep 2s
                "$scriptdir/add-debian-repos.sh"
        else
                echo -e "\n==INFO==\nJessie sources appear to be added."
                sleep 2s
        fi

}

main()
{
	
	build_dir="/home/desktop/build-deb-temp"
	
	# remove previous dirs if they exist
	if [[ -d "$build_dir" ]]; then
		sudo rm -rf "$build_dir"
	fi
	
	# create build dir and enter it
	mkdir -p "$build_dir"
	cd "$build_dir"
	
	# Ask user for repos / vars
	echo -e "\n==> Please enter or paste the deb-src URL now:"
	echo -e "    [Press ENTER to use last: $repo_src]\n"
	
	# set tmp var for last run, if exists
	repo_src_tmp="$repo_src"
	if [[ "$repo_src" == "" ]]; then
		# var blank this run, get input
		read -ep "deb-src URL: " repo_src
	else
		read -ep "deb-src URL: " repo_src
		# user chose to keep var value from last
		if [[ "$repo_src" == "" ]]; then
			repo_src="$repo_src_tmp"
		else
			# keep user choice
			repo_src="$repo_src"
		fi
	fi
	
	echo -e "\n==> Use a public key string or URL to public key file [s/u]?"
	echo -e "    [Press ENTER to use string (default)\n"
	sleep .2s
	read -erp "Type: " gpg_type
	
	echo -e "\n==> Please enter or paste the GPG key/url for this repo now:"
	echo -e "    [Press ENTER to use last: $gpg_pub_key]\n"
	gpg_pub_key_tmp="$gpg_pub_key"
	if [[ "$gpg_pub_key" == "" ]]; then
		# var blank this run, get input
		read -ep "GPG Public Key: " gpg_pub_key
	else
		read -ep "GPG Public Key: " gpg_pub_key
		# user chose to keep var value from last
		if [[ "$gpg_pub_key" == "" ]]; then
			gpg_pub_key="$gpg_pub_key_tmp"
		else
			# keep user choice
			gpg_pub_key="$gpg_pub_key"
		fi
	fi
	
	echo -e "\n==> Please enter or paste the desired package name now:"
	echo -e "    [Press ENTER to use last: $target]\n"
	target_tmp="$target"
	if [[ "$target" == "" ]]; then
		# var blank this run, get input
		read -ep "Package Name: " target
	else
		read -ep "Package Name: " target
		# user chose to keep var value from last
		if [[ "$target" == "" ]]; then
			target="$target_tmp"
		else
			# keep user choice
			target="$target"
		fi
	fi
	
	# prechecks
	echo -e "\n==> Attempting to add source list"
	sleep 2s
	
	# check for existance of target, backup if it exists
	if [[ -f /etc/apt/sources.list.d/${target}.list ]]; then
		echo -e "\n==> Backing up ${target}.list to ${target}.list.bak"
		sudo mv "/etc/apt/sources.list.d/${target}.list" "/etc/apt/sources.list.d/${target}.list.bak"
	fi
	
	# add source to sources.list.d/
	echo ${repo_src} > "${target}.list.tmp"
	sudo mv "${target}.list.tmp" "/etc/apt/sources.list.d/${target}.list"
	
	echo -e "\n==> Adding GPG key:\n"
	sleep 2s
	
	if [[ "$gpg_type" == "s" ]]; then
	
		# add gpg key by string from keyserver
		sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $gpg_pub_key
		
	elif [[ "$gpg_type" == "u" ]]; then
	
		# add key by specifying URL to public.key equivalent file
		wget -q -O- $gpg_pub_key | sudo apt-key add -
		
	else
	
		# add gpg key by string from keyserver (fallback default)
		sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $gpg_pub_key
		
	fi
	
	echo -e "\n==> Updating system package listings...\n"
	sleep 2s
	sudo apt-key update
	sudo apt-get update
	
	
	# assign value to build folder for exit warning below
	build_folder=$(ls -l | grep "^d" | cut -d ' ' -f12)
	
	# assess if depdencies should be ignored
	if [[ "$ignore_deps" == "no" ]]; then
	
		echo -e "\n==> Attempting to auto-install build dependencies\n"
	
		# attempt to get build deps
		if sudo apt-get build-dep ${target} -y; then
		
			echo -e "\n==INFO==\nSource package dependencies successfully installed."
			
		else
			
			echo -e "\n==ERROR==\nSource package dependencies coud not be installed!"
			echo -e "Press CTRL+C to exit now. Exiting in 15 seconds."
			sleep 15s
			exit 1
			
		fi
	
		# Attempt to build target
		echo -e "\n==> Attempting to build ${target}:\n"
		sleep 2s
	
		# build normally using apt-get source
		if apt-get source --build ${target}; then
			
			echo -e "\n==INFO==\nBuild successfull"
			
		else
		
			echo -e "\n==INFO==\nBuild FAILED"
			
		fi
	
	elif [[ "$ignore_deps" == "yes" ]]; then
	
		# There are times when specific packages are specific in the depends lines
		# of Ubuntu control files are satisfied by other packages.
		
		# One example is libstdc++6.4.4-dev, which seems to be satisfiable by 
		# libstdc6 in Jessie, where only higher ver. dbg packages are available
		# Ex. https://packages.debian.org/search?suite=jessie&searchon=names&keywords=libstdc%2B%2B6
	
		echo -e "\n==INFO==\nIgnoring depedencies for build\n"
		sleep 2s
		
		# download source 
		apt-get source ${target}
		
		# identify folder
		cd $build_dir
		build_source_dir=$(ls -d */)
	
		# build using typicaly commands + override option
		cd ${build_source_dir} && dpkg-buildpackage -b -rfakeroot -us -uc -d
	
	fi
	
	# back out of build temp to script dir if called from git clone
	if [[ "$scriptdir" != "" ]]; then
		cd "$scriptdir/utilities/build-scripts"
	else
		cd "$HOME"
	fi
	
	# inform user of packages
	echo -e "\n###################################################################"
	echo -e "If package was built without errors you will see it below."
	echo -e "If you do not, please check build dependcy errors listed above."
	echo -e "You could also try manually building outside of this script with"
	echo -e "the following commands (at your own risk!)\n"
	echo -e "cd $build_dir"
	echo -e "cd $build_folder"
	echo -e "sudo dpkg-buildpackage -b -d -uc"
	echo -e "###################################################################\n"
	
	ls "/home/desktop/build-deb-temp"
	
	echo -e "\n==> Would you like to trim tar.gz, dsc files, and folders for uploading? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " trim_choice
	
	if [[ "$trim_choice" == "y" ]]; then
		
		# cut files so we just have our deb pkg
		rm -f $build_dir/*.tar.gz
		rm -f $build_dir/*.dsc
		rm -f $build_dir/*.changes
		rm -f $build_dir/*-dbg
		rm -f $build_dir/*-dev
		rm -f $build_dir/*-compat
		
		# remove source directory that was made
		find $build_dir -mindepth 1 -maxdepth 1 -type d -exec rm -r {} \;
		
	elif [[ "$trim_choice" == "n" ]]; then
	
		echo -e "File trim not requested"
	fi

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " transfer_choice
	
	if [[ "$transfer_choice" == "y" ]]; then
	
		# cut files
		scp $build_dir/*.deb mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming
		
	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi
	
	echo -e "\n==> Would you like to purge this source list addition? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " purge_choice
	
	if [[ "$purge_choice" == "y" ]]; then
	
		# remove list
		sudo rm -f /etc/apt/sources.list.d/${target}.list
		sudo apt-get update
		
	elif [[ "$purge_choice" == "n" ]]; then
	
		echo -e "Purge not requested\n"
	fi

	
}

#prereqs
install_prereqs

# start main
main
