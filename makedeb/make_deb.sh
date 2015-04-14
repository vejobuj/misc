#!/bin/dash
###############################################################################
#NTMS: keep it simple!
##############################################################################
_mdpreinstalled=/tmp/pre-installed
_mdpostinstalled=/tmp/post-installed
_mdaptpreferences=/tmp/aptpreferences
#_mdpreinstalled=/tmp/pre-installed.$$
#_mdpostinstalled=/tmp/post-installed.$$
#_mdaptpreferences=/tmp/aptpreferences.$$
_mdscriptdir="$(dirname "$(readlink -f "${0}")")"
if command -v gcc; then
	gcctriplet=$(gcc -print-multiarch)
else
	gcctriplet="$(arch)-linux-gnu"
fi
##############################################################################
###### Functions #############################################################
##############################################################################
set_prefs() {
## set script prefs ##################################################
## show apt messages - if running this thing as a cronj in a chroot this should be false...
	_mdisinteractive=1
## Create/update the local Apt repo (this is important if something depends on a prev build)
	_mdaddlocalrepo=0
## remove or keep a/la libs
	_mdkeepalibs=1
	_mdkeeplalibs=1
## the basic dirs
# where the *.makedeb files are
	_mdbuildfiledir="$_mdscriptdir"/build_files
# all *.makedeb files in the dir will be built
	_mdnoibuildfiledir="$_mdscriptdir"/build_files-noi
# the place for the finished debpkgs its also the path for the local repo
	_mdfinisheddebdir="$_mdscriptdir"/deb_files
# the dir for logs
	_mdlogdir="$_mdscriptdir"/log_files
# don't do ldd checks to find pkgdepends
	_mdnolddcheck=0
# FLAGS stuff
	LANG=C
	export MAKEFLAGS="-j$(expr $(nproc) \* 2 - 1) -l $(nproc)"
	#export CFLAGS="$CFLAGS"
	#export CXXFLAGS="$CXXFLAGS"
	#export CPATH="/usr/include"
	#export CPLUS_INCLUDE_PATH="$CPATH"
	#export LIBRARY_PATH=/usr/lib/$gcctriplet
	#export LD_LIBRARY_PATH=/usr/lib/$gcctriplet
}
# write a simple msg ###########################################################
msg() {
	if [ ! -z "$msg" ]; then
		printf "\n\t###\n\t### $msg\n\t###\n\n"
	fi
}
msgsub() {
	if [ ! -z "$msgsub" ]; then
		printf "\n\n\n$msgsub...\n\n\n"
	fi
}
# sets all _mdscriptdirs ##########################################################
set_dirs() {
	msg="Setting dirs"; msg
	if [ ! -z "$pkgname" ]; then
		if [ -z "$pkg_tmpdir" ]; then
			pkg_tmpdir=/tmp/"$pkgname".$$
			msgsub="setting tmpdir to $pkg_tmpdir"; msgsub
		fi
		dir="$pkg_tmpdir"; mk_dir
		pkg_builddir="$pkg_tmpdir"/build
		pkg_debdir="$pkg_tmpdir"/debian
		pkg_filedir="$pkg_tmpdir"/files
		dir="$pkg_debdir"/source; mk_dir
		dir="$pkg_filedir"; mk_dir
	fi
	if [ ! -z "$_mdfinisheddebdir" ];then
		dir="$_mdfinisheddebdir"; mk_dir
		dir="$_mdlogdir"; mk_dir
	else
		exit 1
	fi
}
# rm stuff ###################################################################
rm_dir_contents() {
	if [ ! -z "$dir" ]; then
		if [ -d "$dir" ]; then
			msgsub="removing all files in $dir"; msgsub
			find -P "$dir" -print|grep -v "$dir$"|xargs -I{} rm -rf {}
		fi
	fi
}
rm_empty_dir() {
	if [ ! -z "$dir" ]; then
		if [ -d "$dir" ]; then
			msgsub="removing $dir"; msgsub
			find -P "$dir" -print|xargs -I{} rmdir {}
		fi
	fi
}
# mkdir ######################################################################
mk_dir() {
	if [ ! -d "$dir" ]; then
		msgsub="creating $dir"; msgsub
		mkdir -p "$dir"
	fi
}
# update #####################################################################
update_script() {
	msg="Updating script"; msg
	if [ -d ${_mdscriptdir}/.git ]; then
		git pull
	else
		git clone https://github.com/sixsixfive/MakeDeb.git "$_mdscriptdir"
		#relaunch the script
		x-terminal-emulator -e "$_mdscriptdir"/build.sh
		exit 0
	fi
}
# fallback ###################################################################
create_dpkgfallback() {
	if [ ! -f "$_mdpreinstalled" ]; then
		msg="Creating rollback point"; msg
	else
		msgsub="!!! $_mdpreinstalled already exists" ; msgsub
		ask_to_kill
	fi
	dpkg --get-selections|awk '{if ($2 == "install") print $1}' > "$_mdpreinstalled"
}
# install makedepends ########################################################
install_pkgmakedepends() {
	msg="Installing build dependencies"; msg
	if [ ! -z "$commondepends" ]; then
		toinstallpkgmakedepends="$commondepends $(cat ${pkg_tmpdir}/pkgmakedepends|tr '\n' ' ')"
		su-to-root -c "$aptupdatecmd;$aptinstallcmd $toinstallpkgmakedepends"
		unset commondepends
	else
		toinstallpkgmakedepends="$(cat ${pkg_tmpdir}/pkgmakedepends|tr '\n' ' ')"
		su-to-root -c "$aptinstallcmd $toinstallpkgmakedepends"
	fi
}
# debian needed files ########################################################
create_debfiles() {
if [ "$_mdkeepalibs" != "1" ]; then
	msgsub="removing all static(*.a) libraries"; msgsub
	find -P "$pkg_filedir" -name "*.a" -exec rm -rvf {} \;
fi
if [ "$_mdkeeplalibs" != "1" ]; then
	msgsub="removing all libtool(*.la) libraries"; msgsub
	find -P "$pkg_filedir" -name "*.la" -exec rm -rvf {} \;
fi
	msg="Creating debian specifc files"; msg
	cat <<EOF > "$pkg_debdir"/control
Source: $pkgname
Section: $pkgsection
Priority: optional
Maintainer: $USER <$USER@$(cat /etc/hostname)>
Build-Depends: debhelper (>= 9) 
Standards-Version: 3.9.6

Package: $pkgname
Architecture: $(dpkg-architecture -qDEB_HOST_ARCH)
Conflicts: $(if [ -f $pkg_tmpdir/pkgconflicts ];then cat $pkg_tmpdir/pkgconflicts|uniq|tr '\n' ','|sed -e 's+,+, +g' -e s'/, $//';fi)
Replaces: $(if [ -f $pkg_tmpdir/pkgreplaces ];then cat $pkg_tmpdir/pkgreplaces|uniq|tr '\n' ','|sed -e 's+,+, +g' -e s'/, $//';fi)
Depends: $(if [ -f $pkg_tmpdir/pkgdepends ];then cat $pkg_tmpdir/pkgdepends|uniq|tr '\n' ','|sed -e 's+,+, +g' -e s'/, $//';fi;)
Recommends: $(if [ -f $pkg_tmpdir/pkgrecommends ];then cat $pkg_tmpdir/pkgrecommends|uniq|tr '\n' ','|sed -e 's+,+, +g' -e s'/, $//';fi)
Suggests: $(if [ -f $pkg_tmpdir/pkgsuggests ];then cat $pkg_tmpdir/pkgsuggests|uniq|tr '\n' ','|sed -e 's+,+, +g' -e s'/, $//';fi)
Provides: $(if [ -f $pkg_tmpdir/pkgprovides ];then cat $pkg_tmpdir/pkgprovides|uniq|tr '\n' ','|sed -e 's+,+, +g' -e s'/, $//';fi)
Description: $pkgshortdesc
EOF
	cat <<EOF > "$pkg_debdir"/rules
#!/usr/bin/make -f

build: build-arch build-indep
build-arch: build-stamp
build-indep: build-stamp

build-stamp: 
	dh_testdir
	touch build-stamp

clean:
	dh_testdir
	dh_testroot
	rm -fv build-stamp 
	dh_clean

install: build
	dh_testdir
	dh_testroot
	dh_prep
	dh_installdirs
	mv -v "${pkg_filedir}"/* "${pkg_debdir}/${pkgname}"

binary-indep: build install
	dh_testdir
	dh_testroot
	dh_installdocs
	dh_installchangelogs 
	dh_fixperms
	dh_compress
	dh_installdeb
	dh_gencontrol
	dh_md5sums
	dh_builddeb -- -Zgzip -z0

binary: binary-indep binary-arch
.PHONY: build clean binary-indep binary-arch binary install
EOF
	cldate=$(date '-R')
	cat <<EOF > "$pkg_debdir"/changelog
$pkgname ($pkgversion) experimental; urgency=low
   new upsteam release
 -- $USER <$USER@$(cat /etc/hostname)>  $cldate
EOF
	chmod +x "$pkg_debdir"/rules
	printf "3.0 (native)\n" > "$pkg_debdir"/source/format
	printf "7\n" > "$pkg_debdir"/compat
}
# source a build file ########################################################
load_buildfile() {
	chmod +x "${pkgbuildfile}"
	. "${pkgbuildfile}"
	set_dirs
	if [ -z "$pkgversion" ]; then
		pkgversion=$utc_date
	fi
	###remove some dpkg breaking characters
	pkgversion=$(echo $pkgversion|sed 's#[:;#*~_§$&/()=? ]##g')
	if [ -z "$pkgpkgsection" ]; then
		pkgpkgsection=misc
	fi
	if [ -z "${pkgshortdesc}" ]; then
		pkgshortdesc="$pkgname"
	fi
	printf "$pkgmakedepends\n" > "$pkg_tmpdir"/pkgmakedepends
	printf "$pkgdepends\n" > "$pkg_tmpdir"/pkgdepends
	if [ ! -z "$pkgfakes" ]; then
		printf "$pkgfakes\n" >> "$pkg_tmpdir"/pkgdepends
	fi
	printf "$pkgconflicts\n" > "$pkg_tmpdir"/pkgconflicts
	printf "$pkgreplaces\n" > "$pkg_tmpdir"/pkgreplaces
	printf "$pkgprovides\n" > "$pkg_tmpdir"/pkgprovides
	printf "$pkgrecommends\n" > "$pkg_tmpdir"/pkgrecommends
	printf "$pkgsuggests\n" > "$pkg_tmpdir"/pkgsuggests
}
# build the debs #############################################################
build_deb() {
	msg="Building main package"; msg
	pkgmaindeb="${pkg_tmpdir}/../${pkgname}_${pkgversion}_$(dpkg-architecture -qDEB_HOST_ARCH).deb"
	cd "$pkg_tmpdir"
	fakeroot debian/rules binary
	mv -v "$pkgmaindeb" "$_mdfinisheddebdir"
	if [ "$(id -u)" = "0" ]; then
		chmod 777 "$_mdfinisheddebdir"/${pkgname}_${pkgversion}_$(dpkg-architecture -qDEB_HOST_ARCH).deb
	fi
}
build_deb_fakes() {
	pkgmaindeb="${_mdfinisheddebdir}/${pkgname}_${pkgversion}_$(dpkg-architecture -qDEB_HOST_ARCH).deb"
	if [ -f "${pkgmaindeb}" ]; then
		msg="Creating fake packages"; msg
		if [ ! -z "pkgfakes" ]; then
			cd "$_pkg_tmpdir"
			for fakepkg in $(echo $pkgfakes); do
				msgsub="Creating fakepkg"; msgsub
				equivs-control "$pkg_tmpdir"/${fakepkg}
				sed -i "/Package: /c\Package: $fakepkg" "$pkg_tmpdir"/${fakepkg}
				sed -i "/# Version:/c\Version: $pkgversion" "$pkg_tmpdir"/${fakepkg}
				sed -i "/# Depends:/c\Depends: $pkgname (=$pkgversion)" "$pkg_tmpdir"/${fakepkg}
				sed -i "/# Section: misc/c\Section: $pkgsection" "$pkg_tmpdir"/${fakepkg}
				sed -i "/Description:/c\Description: fake" "$pkg_tmpdir"/${fakepkg}
				#build the pkg and grep those warning msgs
				equivs-build -a$(dpkg-architecture -qDEB_HOST_ARCH) "$pkg_tmpdir"/$fakepkg|\
				grep -Ev '(Attention|dpkg-deb|not in)'
				rm -fv "$pkg_tmpdir"/$fakepkg
				mv -v "$pkg_tmpdir"/${fakepkg}_${pkgversion}_$(dpkg-architecture -qDEB_HOST_ARCH).deb "$_mdfinisheddebdir"
				if [ "$(id -u)" = "0" ]; then
					chmod 777 "$_mdfinisheddebdir"/${fakepkg}_${pkgversion}_$(dpkg-architecture -qDEB_HOST_ARCH).deb
				fi
			done
		fi
	fi
}
check_debs() {
	if [ ! -z "$pkgfakes" ]; then
		debpackages="$(echo $pkgfakes $pkgname)"
	else
		debpackages=$pkgname
	fi
	for debpackage in $debpackages; do
		debpackage="${debpackage}_${pkgversion}"_$(dpkg-architecture -qDEB_HOST_ARCH).deb
		if [ ! -f "${_mdfinisheddebdir}/${debpackage}" ]; then
			msgsub="!!! build of $debpackage failed"; msgsub
			printf "$utc_date - Build of $debpackage has failed!\n" >> ${_mdlogdir}/buildfails.log
			ask_to_kill
		fi
	done
}
# the dangerous stuff ########################################################
set_aptcmds() {
	if [ "$_mdisinteractive" != "0" ]; then
		aptupdatecmd="aptitude --allow-untrusted update" 
		aptinstallcmd="aptitude -R --allow-untrusted install"
		aptcleancmd="apt-get -m remove"
	else
		aptupdatecmd="env DEBIAN_FRONTEND=noninteractive apt-get -y update" 
		aptinstallcmd="env DEBIAN_FRONTEND=noninteractive aptitude -Ry --allow-untrusted install"
		aptcleancmd="env DEBIAN_FRONTEND=noninteractive apt-get -my remove"
	fi
}
# clean ######################################################################
clean_distro() {
	msg="Cleaning!"; msg
	sleep 2
	if [ -f "$_mdpreinstalled" ]; then 
		if [ ! -f "$_mdpostinstalled" ]; then
			dpkg --get-selections|awk '{if ($2 == "install") print $1}' > "$_mdpostinstalled"
		fi
		pkgdiff=$(diff ${_mdpreinstalled} ${_mdpostinstalled}|grep ">"|tr "\n" " "|sed -e 's/> //' -e 's/ > / /g')
		if [ ! -z "$pkgdiff" ]; then
			su-to-root -c "$aptcleancmd $pkgdiff"
		fi
		rm -vf ${_mdpostinstalled}
		mv ${_mdpreinstalled} ${_mdpreinstalled}.bak
	fi
}
# LDD CHECK ##################################################################
###fixme: improove this
###this takes ages but it's a good way to add missing depends
###maybe add some more checks like if gtk dont check for gdk glib....
check_extra_depends() {
	msg="checking for extra dependencies"; msg
	#don't check those libs since they are generic  
	_grepextralibs="not|:|libX|ld-linux|x11|linux-vdso|libpthread|libdl.so|libGL.so.1|libasound.so|libglapi"
	for lib in $(echo $lddchecks); do
		ldd ${pkg_filedir}/${lib}|awk '{print $1}'|grep -Ev "($(echo $_grepextralibs))" > ${pkg_tmpdir}/lddlibs
	done
	#filter some sub packages
	_grepextrapkgs="udeb|dbg|dev|data|common"
	if  [ $(dpkg-architecture -qDEB_HOST_ARCH) = "amd64" ]; then
		_grepextrapkgs="$(echo $_grepextrapkgs)|i386|x32|lib32"
	fi
	awk '{print $1}' ${pkg_tmpdir}/lddlibs|sort|uniq > ${pkg_tmpdir}/lddlibs_
	while read looklib; do
		printf "\tadding ${looklib} as dependency...\n"
		apt-file search "${looklib}"|sed 's#:##'|awk '{print $1}'|uniq|grep -Ev "$(echo $_grepextrapkgs)" >> "$pkg_tmpdir"/pkgdepends 
	done <"${pkg_tmpdir}"/lddlibs_
	#maybe we dont want to add a specific package to the depends
	if [ ! -z "${pkgnodepend}" ]; then
		for rmpkgdep in $(echo $pkgnodepend); do
			printf "\t\tremoving ${rmpkgdep} from depends as wished\n"
			sed -i "/${rmpkgdep}/d" "$pkg_tmpdir"/pkgdepends 
		done
	fi
	rm -fv "$pkg_tmpdir"/lddlibs "$pkg_tmpdir"/lddlibs_
}
# SELECT SCRIPTS #############################################################
select_scripts() {
	if [ "$_mdisinteractive" != "1" ]; then
		pkgbuildfiles=$(find $_mdnoibuildfiledir -name "*.makedeb" -type f|sort|tr '\n' ' ')
	else
		makefiles=$(find ${_mdbuildfiledir} -name "*.makedeb"|sort|\
		sed -e "s#$_mdbuildfiledir/##g" -e 's#/#-->#g' -e 's/.makedeb$/ OFF/')
		selections=$(whiptail --title "Make Your Choice" --noitem --separate-output \
		--clear --checklist "" 24 80 18 $(echo $makefiles) 3>&1 1>&2 2>&3)
		pkgbuildfiles=$(printf "$selections"|sed -e "s#^#$_mdbuildfiledir/#g" \
		-e 's#-->#/#g' -e 's/$/.makedeb/'|tr '\n' ' ')
	fi
}
# kill this script ###########################################################
ask_to_kill() {
	if [ "$_mdisinteractive" != "1" ]; then
		msgsub="continuing"; msgsub
	else
		pid=$(ps x|grep "${0}"|awk 'NR == 1 {print $1}')
		printf "Would you like to continue? [N/y]"; read ny
		while [ 1 ]; do
			case $ny in
				[Yy])
					msgsub="continuing"; msgsub
					break;;
				[Nn])
					msgsub="aborting"; msgsub
					clean_distro
					dir="${pkg_tmpdir}"; rm_dir_contents
					dir="${pkg_tmpdir}"; rm_empty_dir
					msg="Killing this script in 5 seconds!"; msg
					sleep 5; exit 1; kill ${pid};;
			esac
		done
	fi
}
# ADD REPO IF VAR IS SET ###############################################
add_local_repo() {
	if [ "$_mdaddlocalrepo" = "1" ]; then
		msg="Adding/Updating local repo"; msg
		set_dirs
		###rm duplicates add pin prioritys
		pkgs=$(find ${_mdfinisheddebdir} -name '*.deb' -printf "%f\n"|cut -d'_' -f1|sort|uniq)
		for pkg in $(echo $pkgs); do
			printf "Package: $pkg\nPin: origin \042\042\nPin-Priority: 1001\n\n" >> ${_mdaptpreferences}
			pkg=$(basename $pkg)_
			printf "\n\tsearching and removing old versions of package $pkg...\n"
			find ${_mdfinisheddebdir} -name "$pkg*"|sort|sed -e '$ d'|xargs -I{} rm -fv "{}"
		done
		cd "$_mdfinisheddebdir"
		printf "\n\tcreating Packages.gz...\n\n"
		dpkg-scanpackages -m . /dev/null|gzip -1c > ${_mdfinisheddebdir}/Packages.gz
		if [ "$(id -u)" = "0" ]; then
			chmod 777 ${_mdfinisheddebdir}/Packages.gz
		fi
		if [ -f "$_mdaptpreferences" ]; then
			printf "\n\tupdating local repository and package cache...\n\n"
			mvprefasroot="mv -f $_mdaptpreferences /etc/apt/preferences.d/pinmakedeb; $aptupdatecmd"
			su-to-root -c "printf deb\ file:${_mdfinisheddebdir}\ ./ > /etc/apt/sources.list.d/debbuilds.list;$mvprefasroot"
		fi
	else
		msg="!!! Warning local repository is disabled"; msg
	fi
}
##############################################################################
# START HERE #################################################################
##############################################################################
## some checks
if [ "$_mdisinteractive" = "1" ]; then
	if [ ! -t 0 ]; then
		x-terminal-emulator -e "$0"
		exit 0
	fi
	echo ""
fi
if [ "$_mdisinteractive" = "0" ]; then
	if [ "$(id -u)" != "0" ]; then
		msg="!!! You need to run this script as root !!!"
		exit 1
	fi
	if [ "$(id -u)" = "0" ]; then
		msg="!!! Warning, running non interactive as root !!!"
	fi
fi
command -v su-to-root >/dev/null 2>&1 || \
{ echo >&2 "I require menu, but it's not installed. aborting!";exit 1;}
command -v whiptail >/dev/null 2>&1 || \
{ echo >&2 "I require whiptail, but it's not installed. aborting!";exit 1;}
command -v aptitude >/dev/null 2>&1 || \
{ echo >&2 "I require aptitude, but it's not installed. aborting!";exit 1;}
command -v sed >/dev/null 2>&1 || \
{ echo >&2 "I require sed, but it's not installed. aborting!";exit 1;}
command -v awk >/dev/null 2>&1 || \
{ echo >&2 "I require gawk, but it's not installed. aborting!";exit 1;}
command -v dpkg-scanpackages >/dev/null 2>&1 || \
{ echo >&2 "I require dpkg-dev, but it's not installed. aborting!";exit 1;}
commondepends="debhelper fakeroot apt-file build-essential equivs curl \
autoconf automake autopoint autotools-dev libtool intltool gettext binutils \
pkg-config libfile-fcntllock-perl cmake gcc gawk sed grep"
utc_date=$(date -u +%Y%m%d.%H%M%S)
set_prefs
#update_script
select_scripts
create_dpkgfallback
set_dirs
{
	set_aptcmds
	if [ ! -z "$pkgbuildfiles" ]; then
		set_dirs
		add_local_repo
		for pkgbuildfile in $pkgbuildfiles; do
			set_prefs
			load_buildfile
			set_dirs
			msg="Building $pkgname $pkgversion!"; msg
			install_pkgmakedepends
			msg="Running build file"; msg
			dir="$pkg_builddir"; mk_dir
			cd "$pkg_builddir"
			builddir="$pkg_builddir"
			filedir="$pkg_filedir"
			pkg_build
			unset builddir
			unset filedir
			set_dirs
			cd "$pkg_tmpdir"
			case $(find "${pkg_filedir}" -maxdepth 0 -empty -exec echo empty \;) in
				empty)
					msgsub="!!! Build Of $pkgname failed"; msgsub
					printf "$utc_date - Build of $pkgname has failed!\n" \
					>> ${_mdlogdir}/buildfails.log
					ask_to_kill;;
				*)
					builddir="$pkg_builddir"
					filedir="$pkg_filedir"
					pkg_extra_ldddepends
					unset builddir
					unset filedir
					if [ "$_mdnolddcheck" != "1" ]; then
						msgsub="ldd checks are enabled"; msgsub
						if [ ! -z "$lddchecks" ]; then
							check_extra_depends
						fi
					fi
					create_debfiles
					build_deb
					if [ ! -z "$pkgfakes" ]; then
						build_deb_fakes
					fi
					check_debs
					dir=${pkg_tmpdir}; rm_dir_contents
					dir=${pkg_tmpdir}; rm_empty_dir;;
			esac
			add_local_repo
			unset pkgversion
			unset pkgpkgsection
			unset pkgshortdesc
			unset pkgmakedepends
			unset pkgdepends
			unset pkgfakes
			unset pkgconflict
			unset pkgreplaces
			unset pkgprovides
			unset pkgrecommends
			unset pkgsuggests
			unset pkgname
			unset pkg_tmpdir
			unset pkgbuildfile
		done
    cd ~
		clean_distro
	else
		msg="No *.build File Selected"; msg
	fi
	dir=${pkg_tmpdir}; rm_dir_contents
	dir=${pkg_tmpdir}; rm_empty_dir
	msg='All Done (or failed)!'; msg
}  2>&1 | tee "${_mdlogdir}/makedeb_${utc_date}.log"
sleep 5
exit 0
