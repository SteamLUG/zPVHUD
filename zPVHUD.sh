#!/bin/bash
# zPVHUD, a Zenity-powered PVHUD update script by meklu

# First cd'ing to the dir we reside in
cd "$(dirname "$0")"

# Zenity stuff
ZENITY="zenity"
[[ -f pvhud/zenity_provider ]] && \
	ZENITY="$(cat pvhud/zenity_provider)"

# PVHUD download url
PV_URL="http://dl.dropbox.com/u/1565165/pvhud_dl.html"

# Functions

# look at installation status
pv_getlocalstatus() {
	PV_LOCAL_VER=0
	[[ -f pvhud/HUDversion.txt ]] && \
		PV_LOCAL_VER="$(cat pvhud/HUDversion.txt)"
	printf "Local: ${PV_LOCAL_VER}\n"
}
# grab the html
pv_gethtml() {
	PV_HTML="$(wget -q -O - "${PV_URL}" \
		2>("${ZENITY}" --title="zPVHUD" --text="Checking PVHUD updates..." --progress --auto-close --auto-kill))"
}
# parse it
pv_parsehtml() {
	PV_ZIP_URL="$(printf "${PV_HTML}" | \
			grep -B 1 DOWNLOAD | \
			head -n 1 | \
			sed "s/<a href='//g;s/'>//g")"
	printf "Archive URL: ${PV_ZIP_URL}\n"
	PV_REMOTE_VER="$(printf "${PV_HTML}" | \
			grep "^PVHUD v" | \
			awk '{print $2}' | \
			sed 's/v//g;s/,//g')"
	printf "Remote: ${PV_REMOTE_VER}\n"
}
# main view
pv_mainview() {
	PV_REINSTALL=0
	if [ $PV_LOCAL_VER = 0 ]; then
		PV_VERSTRING="<span foreground=\"#ff0000\">none</span>"
		PV_QUESTIONSTRING="Would you like to install?"
	elif [ $PV_LOCAL_VER -lt $PV_REMOTE_VER ]; then
		PV_VERSTRING="<span foreground=\"#cc8000\">$PV_LOCAL_VER</span>"
		PV_QUESTIONSTRING="Would you like to update?"
	else
		PV_VERSTRING="<span foreground=\"#00cc00\">$PV_LOCAL_VER</span>"
		PV_QUESTIONSTRING="Would you like to re-install?"
		PV_REINSTALL=1
	fi
	"${ZENITY}" --title="zPVHUD Updater" --question --text="Local version:\t\t${PV_VERSTRING}\nRemote version:\t${PV_REMOTE_VER}\n\n${PV_QUESTIONSTRING}"
	return $?
}
# are we re-installing?
pv_chkdl() {
	mkdir -p pvhud
	if [ $PV_REINSTALL = 1 ]; then
		"${ZENITY}" --title="zPVHUD Updater" --question --text="Would you like to re-download the HUD as well?"
		return $?
	else
		return 0
	fi
}
# download the HUD and show a dialog
pv_dlhud() {
	pv_chkdl
	if [ $? = 0 ]; then
		wget --progress=bar:force -O pvhud/HUDfiles.zip "${PV_ZIP_URL}" 2>&1 | \
		"${ZENITY}" --title="zPVHUD" --text="Downloading the HUD..." --progress --auto-close --auto-kill
		return $?
	else
		printf "Skipping download...\n"
		return 0
	fi
}
# install the HUD
pv_installhud() {
	unzip -qo pvhud/HUDfiles.zip -d custom/ && \
		"${ZENITY}" --title="zPVHUD" --info --text="Successfully installed PVHUD!"
	printf "${PV_REMOTE_VER}" > pvhud/HUDversion.txt
}
# un-install the HUD
pv_uninstallhud() {
	if [ $PV_LOCAL_VER != 0 ]; then
		"${ZENITY}" --title="zPVHUD" --question --text="Would you like to un-install the HUD?" && \
		rm -rf pvhud/ && \
		"${ZENITY}" --title="zPVHUD" --info --text="Successfully un-installed PVHUD!"
	fi
}

pv_getlocalstatus
pv_gethtml
pv_parsehtml
pv_mainview
if [ $? = 0 ]; then
	pv_dlhud && \
	pv_installhud
else
	pv_uninstallhud
fi
exit 0
