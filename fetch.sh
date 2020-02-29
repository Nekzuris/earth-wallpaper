#!/bin/bash
cd /usr/share/backgrounds/earth
ID=`pgrep -f gnome-session`
export "`grep -z DBUS_SESSION_BUS_ADDRESS /proc/$ID/environ | tr -d '\000'`"
export "`grep -z XDG_RUNTIME_DIR /proc/$ID/environ | tr -d '\000'`"

if [ -f running ]
then
	exit 1
fi
echo PID $$ > running

if ! curl -s -m 30 https://epic.gsfc.nasa.gov/api/natural > json
then
	echo Connection error
	rm -f running
	exit 2
fi
date=`jq '.[-1].date' json`
img=`jq '.[-1].image' json | tr -d '"'`
rm -f json

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
fi

if [ -f "$img.png" -a ! -f wallpaper.png ]
then
	convert "$img.png" -resize 1080x1080 -gravity center -background black -extent 1920x1080 wallpaper.png
fi

gsettings set org.gnome.desktop.background picture-options 'scaled'
gsettings set org.gnome.desktop.background picture-uri '' # to force update
gsettings set org.gnome.desktop.background picture-uri file://`pwd`/wallpaper.png

rm -f running
