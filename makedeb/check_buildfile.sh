#!/bin/dash
OLDLANG=$LANG
LANG=C
export MAKEFLAGS="-j$(expr $(nproc) \* 2 - 1) -l $(nproc)"
scriptdir="$(dirname "$(readlink -f "${0}")")"
buildfiledir=${scriptdir}/build_files
########################################################################
aptitudecmd="aptitude -R"
aptgetcmd="apt-get install -f"
sutoroot="su-to-root"
# SET ALL SCRIPTDIRS/VARS ##############################################
set_dirs() {
	msg="setting basedirs"; msg
	if [ ! -z "$pkgname" ]; then
		tmpdir=/tmp/${pkgname}.$$
		basedir="${tmpdir}"
		builddir="${basedir}"/build
		debdir="${basedir}"/debian
		filedir="${basedir}"/files
		tmpinstdir=/tmp/tmp_install_dir
		mkdir -p "${basedir}" "${debdir}"/source "${filedir}"
	fi
}
# write a simple msg ###################################################
msg() {
	if [ ! -z "$msg" ]; then
		printf "\n\t###\n\t### $msg\n\t###\n\n"
	fi
}
# rm stuff #############################################################
remove_dir_contents() {
	if [ ! -z "$dir" ]; then
		if [ -d "$dir" ]; then
			find -P "$dir" -print | grep -v "$dir$" | xargs -I{} rm -rvf {}
		fi
	fi
}
remove_empty_dir() {
	if [ ! -z "$dir" ]; then
		if [ -d "$dir" ]; then
			find -P "$dir" -print | xargs -I{} rmdir -v {}
		fi
	fi
}
# INSTALL MOST COMMON DEPENDS SCRIPTDEPENDS & CO #######################
install_basedepends() {
	msg="Installing most common dependencies"; msg
	commondepends="debhelper
dpkg-dev
fakeroot
build-essential
autoconf
automake
autopoint
autotools-dev
pkg-config
libtool
intltool
gettext
grep
binutils
coreutils
curl
equivs
wget
cmake"
	# see what is currently installed and install script/common depends
	dpkg --get-selections | awk '{if ($2 == "install") print $1}' | uniq > /tmp/pre-installed
	$sutoroot -c "$aptitudecmd install $(echo $commondepends)"
}
# SOURCE BUILD FILE ####################################################
source_buildfile() {
	chmod +x "${pkgbuildfile}"
	. "${pkgbuildfile}"
	set_dirs
	if [ -z "${pkgversion}" ]; then
		pkgversion=$(date -u +%Y%m%d.%H%M)-1
	fi
	if [ -z "${pkgpkgsection}" ]; then
		pkgpkgsection=misc
	fi
	if [ -z "${pkgshortdesc}" ]; then
		pkgshortdesc="${pkgname}"
	fi
	printf "${pkgmakedepends}\n" > ${basedir}/pkgmakedepends
	printf "${pkgdepends}\n" > ${basedir}/pkgdepends
	if [ ! -z "${pkgfakes}" ]; then
		printf "${pkgfakes}\n" >> ${basedir}/pkgdepends
	fi
	printf "${pkgconflicts}\n" > ${basedir}/pkgconflicts
	printf "${pkgreplaces}\n" > ${basedir}/pkgreplaces
	printf "${pkgprovides}\n" > ${basedir}/pkgprovides
	printf "${pkgrecommends}\n" > ${basedir}/pkgrecommends
	printf "${pkgsuggests}\n" > ${basedir}/pkgsuggests
}
# INSTALL BUILDDEPENDS #################################################
install_pkgmakedepends() {
	$sutoroot -c "$aptitudecmd install $(echo $(cat ${basedir}/pkgmakedepends))"
}
clean_distro() {
	cd "${buildfiledir}"
	msg="Cleaning!"; msg
	sleep 2
	if [ -f /tmp/pre-installed ]; then 
		if [ ! -f /tmp/post-installed ]; then
			dpkg --get-selections | awk '{if ($2 == "install") print $1}' | uniq > /tmp/post-installed
		fi
		pkgdiff=$(diff /tmp/pre-installed /tmp/post-installed | grep ">" | tr "\n" " " | sed -e 's/> //' -e 's/ > / /g')
		if [ ! -z "$(echo $pkgdiff)" ]; then
			$sutoroot -c "$aptitudecmd remove $(echo $pkgdiff)"
		fi
		rm -fv /tmp/post-installed /tmp/pre-installed
	fi
}
########################################################################
# START HERE ###########################################################
########################################################################
if [ ! -t 0 ]; then
	x-terminal-emulator -e "$0"
	exit 0
fi
###scriptdepends or things to get the buildfile list
command -v su-to-root >/dev/null 2>&1 || \
{ echo >&2 "I require menu, but it's not installed. aborting!";exit 1;}
command -v yad >/dev/null 2>&1 || \
{ echo >&2 "I require yad, but it's not installed. aborting!";exit 1;}
command -v aptitude >/dev/null 2>&1 || \
{ echo >&2 "I require aptitude, but it's not installed. aborting!";exit 1;}
command -v git >/dev/null 2>&1 || \
{ echo >&2 "I require git, but it's not installed. aborting!";exit 1;}
command -v sed >/dev/null 2>&1 || \
{ echo >&2 "I require sed, but it's not installed. aborting!";exit 1;}
command -v awk >/dev/null 2>&1 || \
{ echo >&2 "I require gawk, but it's not installed. aborting!";exit 1;}
command -v find >/dev/null 2>&1 || \
{ echo >&2 "I require findutils, but it's not installed. aborting!";exit 1;}
pkgbuildfile=$(cd ${buildfiledir};yad --file --file-filter="*.makedeb" --geometry 640x480)
if [ ! -z "$pkgbuildfile" ]; then
	install_basedepends
	cd "${buildfiledir}"
	source_buildfile
	if [ ! -z "$pkgmakedepends" ]; then
		$sutoroot -c "$aptitudecmd install $(echo $(cat ${basedir}/pkgmakedepends))"
	fi
	mkdir "${builddir}"
	cd "${builddir}"
	msg="Running Build file"; msg
	while [ 1 ]; do
		source_buildfile
		pkg_build
		printf "\n$(pwd)\n"
		printf "\n\n\t### Failed? Missing something? Re-run? [Y/n] ###\t\n\n"
		read input
			case $input in
				[nN])
					break;;
				*)
					continue;;
			esac	
	done
fi
clean_distro
dir="${tmpdir}"; remove_dir_contents
dir="${tmpdir}"; remove_empty_dir
