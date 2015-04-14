#!/bin/sh
########################################################################
# very simpe (and poor) script to setup / configure emulationstation,
# beause it's a PITA to set it up or migrate the current roms, saves
# to a usb key / other system, cheers - ssf
########################################################################
#
#To the extent possible under law,
#the person who associated CC0
#with this work has waived all copyright and related or neighboring
#rights to this work.
#
#You should have received a copy of the CC0 legalcode along with this
#work. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
#
########################################################################
esuserpath="$HOME/.emulationstation"
essystemcfg="$esuserpath/es_systems.cfg"
rompath="$esuserpath/roms"
biospath="$esuserpath/biosdir"
artworkpath="$esuserpath/downloaded_images"
homeenv="$esuserpath/homedir"
libretropath="$(getconf PATH | sed -e 's/\/bin//g' -e 's/://g')/lib/libretro"
retroarchconf="$homeenv"/.config/retroarch/retroarch.cfg
########################################################################
### standalone emus
########################################################################

###Emulator binarys
emubins="desmume
dgen
dolphin-emu
fceux
gambatte-qt
gambatte-sdl
generator-gtk
gvbam
huexpress
m64py
mupen64plus
nestopia
osmose
pcsxr
PPSSPPSDL
sh
snes9x
vbam
wxvbam
yabause
z26"

###what they do or how they launch
add_system() {
case "$emu" in
	desmume)
		name="Nintendo DS ($emu)"
		mime=".nds"
		platform="nds"
		theme="nds"
		args="%ROM%";;
	dgen)
		name="SEGA Mega Drive ($emu)"
		mime=".zip .bin .md .gen"
		platform="megadrive"
		theme="megadrive"
		args="%ROM%";;
	dolphin-emu)
			name="Nintendo Wii ($emu)"
			mime=".elf .dol .wbfs .ciso .wad"
			platform="wii"
			theme="wii"
			args="--exec=%ROM%"
			ask_foremu
		name="Nintendo GameCube ($emu)"
		mime=".elf .dol .gcm .ciso .gcz"
		platform="gc"
		theme="gc"
		args="--exec=%ROM%";;
	fceux)
		name="Nintendo NES ($emu)"
		mime=".zip .fds .nsf .nes"
		platform="nes"
		theme="nes"
		args="--4buttonexit 1 --fullscreen 1 --keepratio 1 --nogui %ROM%";;
	gambatte-sdl)
			name="Nintendo Game Boy Color ($emu)"
			mime=".zip .gz .gbc .dmg"
			platform="gbc"
			theme="gbc"
			args="-f %ROM%"
			ask_foremu
		name="Nintendo Game Boy ($emu)"
		mime=".zip .gz .gb .sgb .dmg"
		platform="gb"
		theme="gb"
		args="-f %ROM%";;
	gambatte-qt)
			name="Nintendo Game Boy Color ($emu)"
			mime=".zip .gz .gbc .dmg"
			platform="gbc"
			theme="gbc"
			args="-f %ROM%"
			ask_foremu
		name="Nintendo Game Boy ($emu)"
		mime=".zip .gz .gb .sgb .dmg"
		platform="gb"
		theme="gb"
		args="-f %ROM%";;
	generator-gtk)
		name="SEGA Mega Drive ($emu)"
		mime=".rom .smd"
		platform="megadrive"
		theme="megadrive"
		args="-a %ROM%";;
	gvbam)
				name="Nintendo Game Boy ($emu)"
				mime=".zip .gb"
				platform="gb"
				theme="gb"
				args="%ROM%"
				ask_foremu
			name="Nintendo Game Boy Color ($emu)"
			mime=".zip .gbc"
			platform="gbc"
			theme="gbc"
			args="%ROM%"
			ask_foremu
		name="Nintendo Game Boy Advance ($emu)"
		mime=".zip .gba"
		platform="gba"
		theme="gba"
		args="%ROM%";;
	huexpress)
		name="PCEngine ($emu)"
		mime=".pce .iso .zip"
		platform="pcengine"
		theme="pcengine"
		args=" %ROM% -f";;
	m64py)
		name="Nintendo 64 ($emu)"
		mime=".zip .z64 .n64 .v64"
		platform="n64"
		theme="n64"
		args="--sdl2 %ROM%";;
	mupen64plus)
		name="Nintendo 64 ($emu)"
		mime=".zip .z64 .n64 .v64"
		platform="n64"
		theme="n64"
		args="--fullscreen %ROM%";;
	nestopia)
		name="Nintendo NES ($emu)"
		mime=".zip .nes"
		platform="nes"
		theme="nes"
		args="-d -f -p -n %ROM%";;
	osmose)
			name="SEGA Master System ($emu)"
			mime=".zip .sms"
			platform="mastersystem"
			theme="mastersystem"
			ask_foremu
			args="%ROM%"
		name="SEGA Game Gear ($emu)"
		mime=".zip .gg"
		platform="gamegear"
		theme="gamegear"
		args="%ROM%";;
	pcsxr)
		name="Sony PlayStation ($emu)"
		mime=".bin .img .iso"
		platform="psx"
		theme="psx"
		args="-nogui -cdfile %ROM%";;
	PPSSPPSDL)
		name="Sony PlayStation Portable ($emu)"
		mime=".iso"
		platform="psp"
		theme="psp"
		args="--fullscreen %ROM%";;
	sh)
		name="IBM PC ($emu)"
		mime=".sh"
		platform="pc"
		theme="pc"
		args="%ROM%";;
	snes9x)
		name="Nintendo SNES ($emu)"
		mime=".zip .sfc .gz .Z .smc"
		platform="snes"
		theme="snes"
		args="%ROM%";;
	vbam)
				name="Nintendo Game Boy ($emu)"
				mime=".zip .gb"
				platform="gb"
				theme="gb"
				args="-F %ROM%"
				ask_foremu
			name="Nintendo Game Boy Color ($emu)"
			mime=".zip .gbc"
			platform="gbc"
			theme="gbc"
			args="-F %ROM%"
			ask_foremu
		name="Nintendo Game Boy Advance ($emu)"
		mime=".zip .gba"
		platform="gba"
		theme="gba"
		args="-F %ROM%";;
	wxvbam)
				name="Nintendo Game Boy ($emu)"
				mime=".zip .gb"
				platform="gb"
				theme="gb"
				args="-f %ROM%"
				ask_foremu
			name="Nintendo Game Boy Color ($emu)"
			mime=".zip .gbc"
			platform="gbc"
			theme="gbc"
			args="-f %ROM%"
			ask_foremu
		name="Nintendo Game Boy Advance ($emu)"
		mime=".zip .gba"
		platform="gba"
		theme="gba"
		args="-f %ROM%";;
	yabause)
		name="SEGA Saturn ($emu)"
		mime=".iso .bin .mds"
		platform="saturn"
		theme="saturn"
		args="-a -f --iso=%ROM%";;
	z26)
		name="Atari 2600 ($emu)"
		mime=".bin"
		platform="atari2600"
		theme="atari2600"
		args="%ROM%";;
esac
}

########################################################################
### the same stuff for the retroarch section
########################################################################

###Retroarch Cores
libretros="libretro-bnes.so
libretro-bsnes.so
libretro-desmume.so
libretro-dosbox.so
libretro-fba-neogeo.so
libretro-fceumm.so
libretro-fmsx.so
libretro-gambatte.so
libretro-genplus.so
libretro-handy.so
libretro-hatari.so
libretro-mame.so
libretro-mednafen-gba.so
libretro-mednafen-ngp.so
libretro-mednafen-pce.so
libretro-pcsx-rearmed.so
libretro-snes9x.so
libretro-virtualjaguar.so"
###not supported by es
#libretro-mednafen-pcfx.so
####what they do 
add_libretrosystem() {
case "$libretro" in
	libretro-bnes.so)
		name="Nintendo NES ($libretro)"
		platform="nes"
		theme="nes";;
	libretro-bsnes.so)
		name="Nintendo SNES ($libretro)"
		platform="snes"
		theme="snes";;
	libretro-desmume.so)
		name="Nintendo DS ($libretro)"
		platform="nds"
		theme="nds";;
	libretro-dosbox.so)
		name="Microsoft DOS ($libretro)"
		platform="pc"
		theme="pc";;
	libretro-fba-neogeo.so)
		name="SNK Neo Geo ($libretro)"
		platform="neogeo"
		theme="neogeo";;
	libretro-fceumm.so)
		name="Nintendo NES ($libretro)"
		platform="nes"
		theme="nes";;
	libretro-fmsx.so)
		name="Microsoft MSX ($libretro)"
		platform="msx"
		theme="msx";;
	libretro-genplus.so)
#					#SG1000
#					name="SEGA SG-1000 ($libretro)"
#					platform="sg1000"
#					theme="sg1000"
#					ask_forlibretro
				name="SEGA Master System ($libretro)"
				platform="mastersystem"
				theme="mastersystem"
				ask_forlibretro
			name="SEGA Mega Drive ($libretro)"
			platform="megadrive"
			theme="megadrive"
			ask_forlibretro
		name="SEGA Game Gear ($libretro)"
		platform="gamegear"
		theme="gamegear";;
	libretro-gambatte.so)
			name="Nintendo Game Boy Color ($libretro)"
			platform="gbc"
			theme="gbc"
			ask_forlibretro
		name="Nintendo Game Boy ($libretro)"
		platform="gb"
		theme="gb";;
	libretro-handy.so)
		name="Atari Lynx ($libretro)"
		platform="atarilynx"
		theme="atarilynx";;
	libretro-hatari.so)
		name="Atari ST ($libretro)"
		platform="atarist"
		theme="atarist";;
	libretro-mame.so)
		name="Arcade ($libretro)"
		platform="arcade"
		theme="mame";;
	libretro-mednafen-gba.so)
		name="Nintendo Game Boy Advance ($libretro)"
		platform="gba"
		theme="gba";;
	libretro-mednafen-ngp.so)
			name="SNK Neo Geo Pocket Color ($libretro)"
			platform="ngpc"
			theme="ngpc"
			ask_forlibretro
		name="SNK Neo Geo Pocket ($libretro)"
		platform="ngp"
		theme="ngp";;
	libretro-mednafen-pce.so)
		name="NEC PCEngine ($libretro)"
		platform="pcengine"
		theme="pcengine";;
#	libretro-mednafen-pcfx.so)
#		name="NEC PC-FX ($libretro)"
#		platform="pcfx"
#		theme="pcfx";;
	libretro-pcsx-rearmed.so)
		name="Sony PlayStation ($libretro)"
		platform="psx"
		theme="psx";;
	libretro-snes9x.so)
		name="Nintendo SNES ($libretro)"
		platform="snes"
		theme="snes";;
	libretro-virtualjaguar.so)
		name="Atari Jaguar ($libretro)"
		platform="atarijaguar"
		theme="atarijaguar";;
esac
}
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########## the touching might break something section ##################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
########################################################################
add_configscript() {
##add a config script!
cat <<EOF > "$esuserpath"/"$emu"_config.sh
#!/bin/sh
env HOME=$homeenv $emu
EOF
}
create_system() {
cat <<EOF >> "$essystemcfg"
	<system>
		<name>$(echo $platform)_$(echo $emu)</name>
		<fullname>$name</fullname>
		<path>$rompath/$platform</path>
		<extension>$mime</extension>
		<command>env HOME=$homeenv $emu $args</command>
		<platform>$platform</platform>
		<theme>$theme</theme>
	</system>
EOF
	mkdir -p "$rompath"/$platform
	mkdir -p "$artworkpath"/$platform
	if [ ! -L "$artworkpath"/$(echo $platform)_$(echo $emu) ]; then
		ln -s "$artworkpath"/$platform "$artworkpath"/$(echo $platform)_$(echo $emu)
	fi
	add_configscript
	chmod a+x "$esuserpath"/"$emu"_config.sh
####well there are a few third party tools
	if [ "$emu" = "mupen64plus" ]; then
		if $(command -v mupen64plus-qt >/dev/null 2>&1); then
			emu=mupen64plus-qt
			add_configscript
			chmod a+x "$esuserpath"/"$emu"_config.sh
		fi
		
	fi
}
create_libretrosystem() {
	libretromime=".$(cat "$libretropath"/$(echo "$libretro" | sed 's/\.so$/\.info/') | grep extensions | awk '{print $3}' | sed 's#|# .#g' | sed 's#"##g')"
cat <<EOF >> "$essystemcfg"
	<system>
		<name>$(echo $platform)_$(echo $libretro)</name>
		<fullname>$name</fullname>
		<path>$rompath/$platform</path>
		<extension>$libretromime</extension>
		<command>env HOME=$homeenv retroarch -f -L $libretropath/$libretro %ROM%</command>
		<platform>$platform</platform>
		<theme>$theme</theme>
	</system>
EOF
	mkdir -p "$rompath"/$platform
	mkdir -p "$artworkpath"/$platform
	if [ ! -L "$artworkpath"/$(echo $platform)_$(echo $libretro) ]; then
		ln -s "$artworkpath"/$platform "$artworkpath"/$(echo $platform)_$(echo $libretro)
	fi
}
ask_foremu() {
	if $(yad --geometry 520x120 --image=dialog-question \
			--text="\nWould you like to add <b>$emu</b> for <b>$(echo $name | sed 's#(.*##g')</b> emulation?\n"); then
		create_system
	else
		printf "$emu skipped\n"
	fi
}
ask_forlibretro() {
	if $(yad --geometry 520x120 --image=dialog-question \
			--text="\nWould you like to add <b>$libretro</b> for <b>$(echo $name | sed 's#(.*##g')</b> emulation?\n"); then
		create_libretrosystem
	else
		printf "$libretro skipped\n"
	fi
}

########################################################################
###the actual script
########################################################################
if [ ! -t 0 ]; then
	x-terminal-emulator -e "$0"
	exit 0
fi
command -v yad >/dev/null 2>&1 || { echo >&2 "I require YAD but it's not installed.  Aborting."; exit 1; }
command -v emulationstation >/dev/null 2>&1 || { echo >&2 "I require Emulationstation but it's not installed.  Aborting."; exit 1; }
yadoutput=$(yad --form --separator=',' --geometry 520x210 \
	--title="You Can Set Some Variables" \
	--text="<b>NOTE:</b> if you set the HOME variable to something other than <b>$HOME</b> you will need to launch the emulators with their config scripts in <b>$esuserpath</b> to modify any settings!" \
	--field="The Rom Directory" "$rompath" \
	--field="The BIOS/System Directory" "$biospath" \
	--field="The HOME env Variable" "$homeenv")
rompath=$(printf "$yadoutput" | cut -f1 -d',')
biospath=$(printf "$yadoutput" | cut -f2 -d',')
homeenv=$(printf "$yadoutput" | cut -f3 -d',')
mkdir -p "$rompath"
mkdir -p "$biospath"
if [ -f "$essystemcfg" ];then
	mv -f "$essystemcfg" "$essystemcfg.bak"
fi
rm -f "$esuserpath"/*_config.sh
printf "<systemList>\n" >"$essystemcfg"
for emubin in $emubins; do
	if $(command -v $emubin >/dev/null 2>&1); then
		emu=$(echo "$emubin" | sed 's#.*bin/##')
		add_system
		ask_foremu
	else
		emu=$(echo "$emubin" | sed 's#.*bin/##')
		printf "$emu not found\n"
	fi
done
for libretro in $libretros; do
	if [ -f "$libretropath/$libretro" ]; then
		add_libretrosystem
		ask_forlibretro
	else
		printf "$libretro not found\n"
	fi
done
####create a retroarch script
if $(command -v retroarch >/dev/null 2>&1); then
	cat <<EOF >> "$esuserpath"/retroarch_config.sh
#!/bin/sh
env HOME=$homeenv retroarch -f --menu
EOF
	chmod a+x "$esuserpath"/retroarch_config.sh
####some basic retroarch configuration
	if [ ! -f "$retroarchconf" ]; then
		mkdir -p $(echo "$retroarchconf" | sed 's#retroarch.cfg##g')
	fi
	if [ -f "$retroarchconf" ]; then
		sed -i '/system_directory/d' "$retroarchconf"
		sed -i '/libretro_directory/d' "$retroarchconf"
		sed -i '/libretro_info_path/d' "$retroarchconf"
	fi
	printf "system_directory = \042$biospath\042\n" >> "$retroarchconf"
	printf "libretro_directory = \042$libretropath\042\n" >>"$retroarchconf"
	printf "libretro_info_path = \042$libretropath\042\n" >>"$retroarchconf"
fi
printf "</systemList>\n" >> "$essystemcfg"
###useles_configs
rm -f "$esuserpath/sh_config.sh"
rm -f "$esuserpath/mupen64plus_config.sh"
rm -f "$esuserpath/gambatte-sdl_config.sh"
rm -f "$esuserpath/vbam_config.sh"
exit 0
