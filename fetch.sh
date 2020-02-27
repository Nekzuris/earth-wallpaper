json=`curl -s https://epic.gsfc.nasa.gov/api/natural`
date=`echo "$json" | jq '.[-1].date'`
img=`echo "$json" | jq '.[-1].image' | tr -d '"'`

if [ -f "$img.png" ]
then
	exit
fi

rm -f epic_*.png
curl -s "https://epic.gsfc.nasa.gov/archive/natural/${date:1:4}/${date:6:2}/${date:9:2}/png/$img.png" > $img.png
convert $img.png -resize 1080x1080 -gravity center -background black -extent 1920x1080 wallpaper.png
gsettings set org.gnome.desktop.background picture-options 'scaled'
gsettings set org.gnome.desktop.background picture-uri file://`pwd`/wallpaper.png
