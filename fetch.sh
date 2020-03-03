#!/bin/bash
[ "$1" = '-log' ] && date
# initialization
cd /usr/share/backgrounds/earth
ID=`pgrep -f gnome-session`
export "`grep -z DBUS_SESSION_BUS_ADDRESS /proc/$ID/environ | tr -d '\000'`"
export "`grep -z XDG_RUNTIME_DIR /proc/$ID/environ | tr -d '\000'`"
export DISPLAY=:0
if [ -f running ]
then
	exit 1
fi
echo PID $$ > running

# fetch info
if ! curl -s -m 30 'https://epic.gsfc.nasa.gov/api/natural' > json
then
	echo Connection error
	rm -f running
	exit 2
fi
[ "$1" = '-log' ] && echo "json downloaded"
date=`jq '.[-1].date' json`
img=`jq '.[-1].image' json | tr -d '"'`
rm -f json

# download image
if [ ! -f "$img.png" ]
then
	rm -f epic_*.png
	if ! curl -s -m 500 "https://epic.gsfc.nasa.gov/archive/natural/${date:1:4}/${date:6:2}/${date:9:2}/png/$img.png" > "$img.png"
	then
		echo Image download error
		rm -f running "$img.png"
		exit 3
	fi
	rm -f wallpaper.png
	[ "$1" = '-log' ] && echo "image downloaded"
fi

# resize image
if [ -f "$img.png" -a ! -f wallpaper.png ]
then
	dims=`xdpyinfo | awk '/dimensions/{print $2}'`
	width=`echo $dims | cut -d 'x' -f1`
	height=`echo $dims | cut -d 'x' -f2`
	if [ $height -lt $width ]; then min=$height; else min=$width; fi
	convert "$img.png" -resize ${min}x${min} -gravity center -background black -extent $dims wallpaper.png
	[ "$1" = '-log' ] && echo "wallpaper resized"
fi

# set wallpaper
gsettings set org.gnome.desktop.background picture-options 'scaled'
gsettings set org.gnome.desktop.background picture-uri '' # to force update
gsettings set org.gnome.desktop.background picture-uri file://`pwd`/wallpaper.png
[ "$1" = '-log' ] && echo "wallpaper set"

rm -f running
