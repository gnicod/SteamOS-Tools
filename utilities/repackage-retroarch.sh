# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name: 	repackage-retroarch.sh
# Script Ver:	0.1.5
# Description:	Overall goal of script is to automate rebuilding pkgs from
#               https://launchpad.net/~libretro/+archive/ubuntu/stable?field.series_filter=trusty
#
# Usage:	repackage-retroarch.sh
#
# Warning:	You MUST have the Debian repos added properly for
#		nstallation of the pre-requisite packages.
# -------------------------------------------------------------------------------

# Should be able to make use of utilities/build-deb-from-ppa.sh

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
	
	echo -e "\n==> Installing pre-requisites for building...\n"
	
	sleep 1s
	# install needed packages
	sudo apt-get install git devscripts build-essential checkinstall \
	debian-keyring debian-archive-keyring cmake

}

main()
{
	
	# build dir
	build_dir="/home/desktop/build-retroarch-temp"
	
	# remove previous dirs if they exist
	if [[ -d "$build_dir" ]]; then
		sudo rm -rf "$build_dir"
	fi
	
	# create build dir and enter it
	mkdir -p "$build_dir"
	cd "$build_dir"
	
	# set source
	repo_src="deb-src http://ppa.launchpad.net/libretro/stable/ubuntu trusty main"

  # GPG key
	gpg_pub_key="ECA3745F"
	
	# set target
	target="libretro-stable"
	
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
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $gpg_pub_key
	#"$scriptdir/utilities.sh ${gpg_pub_key}"
	
	echo -e "\n==> Updating system package listings...\n"
	sleep 2s
	sudo apt-key update
	sudo apt-get update
	
	# Get listing of PPA packages
  pkg_list=$(awk '$1 == "Package:" { print $2 }' /var/lib/apt/lists/ppa.launchpad.net_libretro*)
  
  # Rebuild all items in pkg_list
  for pkg in ${pkg_list}; 
  do
	
  	# Attempt to build target
  	echo -e "\n==> Attempting to build ${pkg}:\n"
  	sleep 2s
  	apt-get source --build ${pkg}
  	
  	# test only
  	#echo ${pkg}
  	#sleep 1s

	done
	exit 1
	
	# assign value to build folder for exit warning below
	build_folder=$(ls -l | grep "^d" | cut -d ' ' -f12)
	
	# back out of build temp to script dir if called from git clone
	if [[ "$scriptdir" != "" ]]; then
		cd "$scriptdir"
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
	
	ls "/home/desktop/build-retroarch-temp"
	
	echo -e "\n==> Would you like to trim out the tar.gz and dsc files for uploading? [y/n]"
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
		
		# remove directories from builds so we only are left with deb pkgs
		find $build_dir -mindepth 1 -maxdepth 1 -type d -exec rm -r {} \;
		
	elif [[ "$trim_choice" == "n" ]]; then
	
		echo -e "File trim not requested"
	fi

	echo -e "\n==> Would you like to upload any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " upload_choice
	
	if [[ "$upload_choice" == "y" ]]; then
	
		# set vars for upload
		sourcedir="$build_dir"
		user="thelinu2"
		host='libregeek.org'
		destdir="/home2/thelinu2/public_html/SteamOS-Extra/build-tmp"
		
		# perform upload
		scp -r $sourcedir $user@$host:$destdir
		
		echo -e "\n"
		
	elif [[ "$upload_choice" == "n" ]]; then
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
