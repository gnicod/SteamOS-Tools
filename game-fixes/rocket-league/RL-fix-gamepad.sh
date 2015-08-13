#!/bin/bash

main ()
{
  
  clear
  echo -e "==> Patching Rocket Leage (Steam) for Windows...\n"
  
  
  	echo -e "\n#############################################################"
  	echo -e "Setting mouse control for available gamepads"
  	echo -e "#############################################################"
  
  	# prompt user For controller type if they wish to enable gp mouse control
  	echo -e "\nPlease choose your controller type for this patch"
  	echo "(1) Xbox 360 (wired)"
  	echo "(2) Xbox 360 (wireless)"
  	echo ""
  	
  	# the prompt sometimes likes to jump above sleep
  	sleep 0.5s
  
  	read -ep "Choice: " gp_mouse_choice
  
  	case "$gp_mouse_choice" in
  
  		1)
  		gp_type="xb360-wired"
  		patch_rl
  		;;
  
  		2)
  	  gp_type="xb360-wireless"
  	  patch_rl
  		;;
  		 
  		*)
  		echo -e "\n==ERROR==\nInvalid Selection!"
  		sleep 1s
  		continue
  		;;
  	esac

}

if [[ -d "/home/desktop/.PlayOnLinux" ]]; then

  echo -e "PlayOnLinux detected"
  
  if [[ "$gp_type" =="xb360-wireless" ]];then
  
    cp xb360-wireless/x360ce.ini "/home/desktop/.PlayOnLinux/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"
    cp xb360-wireless/xinput1_3.dll "/home/desktop/.PlayOnLinux/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"

  elif [[ "$gp_type" =="xb360-wired" ]];then
  
    cp xb360-wired/xinput1_3.dll "/home/desktop/.PlayOnLinux/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"
    cp xb360-wired/xinput9_1_0.dll "/home/desktop/.PlayOnLinux/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"

  fi

elif [[ -d "/home/desktop/.cxoffice" ]]; then

  echo -e "Crossover detected"
  
  if [[ "$gp_type" =="xb360-wireless" ]];then
  
    cp xb360-wireless/x360ce.ini "/home/desktop/.cxoffice/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"
    cp xb360-wireless/xinput1_3.dll "/home/desktop/.cxoffice/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"

  elif [[ "$gp_type" =="xb360-wired" ]];then
  
    cp xb360-wired/xb360-wired/xinput1_3.dll "/home/desktop/.cxoffice/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"
    cp xb360-wired/xb360-wired/xinput9_1_0.dll "/home/desktop/.PlayOncxofficeLinux/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"

  fi

elif [[ -d "/home/desktop/.wine" ]]; then

  echo -e "Vanilla Wine detected"
  
    if [[ "$gp_type" =="xb360-wireless" ]];then
  
    cp xb360-wireless/x360ce.ini "/home/desktop/.wine/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"
    cp xb360-wireless/xinput1_3.dll "/home/desktop/.wine/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"

  elif [[ "$gp_type" =="xb360-wired" ]];then
  
    cp xb360-wired/xinput1_3.dll "/home/desktop/.wine/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"
    cp xb360-wired/xinput9_1_0.dll "/home/desktop/.wine/wineprefix/Steam/drive_c/Program Files/Steam/steamapps/common/rocketleague/Binaries/Win32/"

  fi

fi

echo -e "Patch applied\n"

echo -e "Please restart Steam for Windows under the dekstop user\n"
echo -e "This is intended only for wired/wireless XB360 controllers"
echo -e "Note that Rocket League launches in background, so you will need to ALT-TAB to it!\n"

