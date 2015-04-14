#!/bin/sh
# a simple shell script to upload multiple/many files to openclipart.org!

##### example gmail muttrc:
#set from = "<USERNAME>@gmail.com"
#set realname = "<REALNAME>"
#set smtp_url = "smtp://<LOGIN>@smtp.gmail.com:587/"
#set smtp_pass = "<SMTPPASS>@gmail.com"
#set move = no 
#####

##### USAGE:
# ./upload2openclipart.sh <FILES>
# or
# ./upload2openclipart.sh ./*.svg
#####

##if i ever want to use this a filemanager action...
if [ ! -t 0 ]; then
	x-terminal-emulator -e "$0"
	exit 0
fi
command -v mutt >/dev/null 2>&1 || { echo >&2 "I require Mutt but it's not installed.  Aborting."; exit 1; }
command -v sed >/dev/null 2>&1 || { echo >&2 "I require Sed but it's not installed.  Aborting."; exit 1; }
###if svg try to clean them with svg cleaner and inkscape!
clean_svgs()
{
	if type inkscape >/dev/null 2>&1; then
		inkscape -z --export-text-to-path --vacuum-defs --export-plain-svg="$file" "$file"
	else
		printf "Inkscape isn't installed - cleaning might be incomplete\n"
		sleep 3
	fi
	if type svgcleaner-cli >/dev/null 2>&1; then
		svgcleaner-cli "$file" "$file" --preset=basic --remove-prolog --remove-comments --remove-version --remove-metadata-elts --remove-nonsvg-elts --remove-sodipodi-elts --remove-ai-elts --remove-corel-elts --remove-msvisio-elts --remove-invisible-elts --remove-outside-elts --colors-to-rrggbb --rrggbb-to-rgb --trim-ids --remove-inkscape-atts --remove-sodipodi-atts
	else
		printf "SVGCleaner (http://sourceforge.net/projects/svgcleaner/) isn't installed - cleaning might be incomplete\n"
		sleep 3
	fi
}
###if png clean them with optipng
clean_pngs()
{
	if type optipng >/dev/null 2>&1; then
		optipng -nx -strip all $file
	else
		printf "OptiPNG is missing - png cleaning is unavailable\n"
		sleep 3
	fi
}

##upload...
read -p "Please enter a Description: " DESCRIPTION
read -p "Please enter some space seperated tags, don't forget the hash! (eg: #TAG1 #TAG2...):" TAGS
###double check desc before uploading
printf "\nThe following description and tags will be added to all files!\n"
printf "$DESCRIPTION $TAGS\n\n"
read -p "Press y to proceed, anything else to abort!" REPLY
printf "\n"
if [ "`echo $REPLY`" = "y" ]; then
	printf "uploading now!"
else
	printf "Aborting..."
	exit 1
fi
while [ $# -gt 0 ]; do
	file=$1
	if [ `echo "$1" | sed 's/.*\.//'` = "svg" ]; then
		clean_svgs
	fi
	if [ `echo "$1" | sed 's/.*\.//'` = "png" ]; then
		clean_pngs
	fi
	filename=`echo "$file" | sed  's/\(.*\)\..*/\1/'  | sed 's#./##g' | sed 's/_/ /g' | sed 's/-/ /g'`
	FILENAMETAGS=`echo "#$file" | sed  's/\(.*\)\..*/\1/' | sed 's#./##g' | sed 's/_/ /g' | sed 's/-/ /g' | sed 's/ / #/g'`
	description="$DESCRIPTION $FILENAMETAGS $TAGS"
	echo "$description" | mutt -s "$filename" -a "$file" -- "upload@openclipart.org"
	shift
done 
