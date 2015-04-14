#!/bin/sh
if [ ! -t 0 ]; then
x-terminal-emulator -e "$0"
exit 0
fi
basedir=`dirname "$(readlink -f "${0}")"`
cd ${basedir}
git add .
git commit -m "the commit msg for the lazy"
git push origin master
echo "done"
sleep 5
exit