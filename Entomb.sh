#! /bin/sh
# maybe change the above line for more compatability
#example code to detect the default package manager
#declare -A osInfo;
#osInfo[/etc/redhat-release]=yum
#osInfo[/etc/arch-release]=pacman
#osInfo[/etc/gentoo-release]=emerge
#osInfo[/etc/SuSE-release]=zypp
#osInfo[/etc/debian_version]=apt-get
#osInfo[/etc/alpine-release]=apk
#
#for f in ${!osInfo[@]}
#do
#    if [[ -f $f ]];then
#        echo Package manager: ${osInfo[$f]}
#    fi
#done
title='Entomber'
re1='^Exec.*'
re2='[^= ]+\.\w*\.\w*'
re3='[^= /]+$'
if [[ "$@" == '' ]]
then files=$(kdialog --title $title --getopenfilename . "Desktop Files(*.desktop) @2>>/dev/null")
else files="$(readlink -f "$@")"
fi
for file in "$files"
do
  cp "$file" "$file".tmp
  while read -r line
  do
    #repeats the uninstall in case there are multiple apps in the .desktop file
    if [[ "$line" =~ $re1 ]]
    then
      for i in "${!BASH_REMATCH[@]}"
      do
        line=$(echo "${BASH_REMATCH[0]}")
        #anything that matches re2 isassumed to be a flatpak
        if [[ "$line" =~ $re2 ]]
        then
          appid="$BASH_REMATCH"
          sed -i "s#$line#Exec=konsole -e appstreamcli install $appid \&\& ${line:6}#g" "$file".tmp
          path="$(flatpak info --show-location $appid)"
          cp -r $path/files/share/icons /tmp/icons.bak
          konsole -e appstreamcli remove $appid
          mv /tmp/icons.bak $path/files/share/icons
        else if [[ "$line" =~ $re3 ]]
        then
          appid="$BASH_REMATCH"
          sed -i "s#$line#Exec=konsole -e sudo -S pacman -S $appid \&\& ${line:6}#g" "$file".tmp
          readarray -t icons1 < <(pacman -Qlq "$appid" | grep "/usr/share/icons/.*[^/]$")
          for j in $icons1; do cp -r "$j" "$j".bak; done;
          readarray -t icons2 < <(pacman -Qlq "$appid" | grep "~/.local/share/icons.*[^/]$")
          for j in $icons2; do cp -r "$j" "$j".bak; done;
          konsole -e sudo $(which pacman) -Ru "$appid"
          for j in $icons1; do mv "$j".bak "$j"; done;
          for j in $icons2; do mv "$j".bak "$j"; done;
        fi
        fi
      done
    fi
  done < "$file"
  mv "$file".tmp "$file"
done
