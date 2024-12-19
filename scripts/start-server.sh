#!/bin/bash
export DISPLAY=:99
export XDG_RUNTIME_DIR="/tmp/runtime-enpass"
export XAUTHORITY=${DATA_DIR}/.Xauthority

CUR_V="$(find ${DATA_DIR} -name instv* | cut -d 'v' -f2)"
LAT_V="$(wget -qO- https://github.com/ich777/versions/raw/master/Enpass | grep LATEST | cut -d '=' -f2)"

if [ -z "$LAT_V" ]; then
	if [ ! -z "$CUR_V" ]; then
		echo "---Can't get latest version of Enpass falling back to v$CUR_V---"
		LAT_V="$CUR_V"
	else
		echo "---Something went wrong, can't get latest version of Enpass, putting container into sleep mode---"
		sleep infinity
	fi
fi

echo "---Version Check---"
if [ -z "$CUR_V" ]; then
	echo "---Enpass not installed, installing---"
    cd ${DATA_DIR}
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/Enpass-v$LAT_V.tar.gz https://github.com/ich777/enpass-unraid/releases/download/$LAT_V/Enpass-v$LAT_V.tar.gz ; then
    	echo "---Sucessfully downloaded Enpass---"
    else
    	echo "---Something went wrong, can't download Enpass, putting container in sleep mode---"
        sleep infinity
    fi
	tar -C ${DATA_DIR} -xf ${DATA_DIR}/Enpass-v$LAT_V.tar.gz
	rm -R ${DATA_DIR}/Enpass-v$LAT_V.tar.gz
	touch ${DATA_DIR}/instv$LAT_V
elif [ "$CUR_V" != "$LAT_V" ]; then
	echo "---Version missmatch, installed v$CUR_V, downloading and installing latest v$LAT_V...---"
    cd ${DATA_DIR}
    find . -maxdepth 1 -type f -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/Enpass-v$LAT_V.tar.gz https://github.com/ich777/enpass-unraid/releases/download/$LAT_V/Enpass-v$LAT_V.tar.gz ; then
    	echo "---Sucessfully downloaded Enpass---"
    else
    	echo "---Something went wrong, can't download Enpass, putting container in sleep mode---"
        sleep infinity
    fi
	tar -C ${DATA_DIR} -xf ${DATA_DIR}/Enpass-v$LAT_V.tar.gz
	rm -R ${DATA_DIR}/Enpass-v$LAT_V.tar.gz
	touch ${DATA_DIR}/instv$LAT_V
elif [ "$CUR_V" == "$LAT_V" ]; then
	echo "---Enpass v$CUR_V up-to-date---"
fi

echo "---Preparing Server---"
if [ ! -d /tmp/runtime-enpass ]; then
	mkdir -p /tmp/runtime-enpass
	chmod -R 0700 /tmp/runtime-enpass
fi
echo "---Resolution check---"
if [ -z "${CUSTOM_RES_W} ]; then
	CUSTOM_RES_W=1024
fi
if [ -z "${CUSTOM_RES_H} ]; then
	CUSTOM_RES_H=768
fi

if [ "${CUSTOM_RES_W}" -le 1023 ]; then
	echo "---Width to low must be a minimal of 1024 pixels, correcting to 1024...---"
    CUSTOM_RES_W=1024
fi
if [ "${CUSTOM_RES_H}" -le 767 ]; then
	echo "---Height to low must be a minimal of 768 pixels, correcting to 768...---"
    CUSTOM_RES_H=768
fi
echo "---Checking for old logfiles---"
find $DATA_DIR -name "XvfbLog.*" -exec rm -f {} \;
find $DATA_DIR -name "x11vncLog.*" -exec rm -f {} \;
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Checking for old display lock files---"
rm -rf /tmp/.X99*
rm -rf /tmp/.X11*
rm -rf ${DATA_DIR}/.vnc/*.log ${DATA_DIR}/.vnc/*.pid
if [ -f ${DATA_DIR}/.vnc/passwd ]; then
	chmod 600 ${DATA_DIR}/.vnc/passwd
fi
screen -wipe 2&>/dev/null

echo "---Starting TurboVNC server---"
vncserver -geometry ${CUSTOM_RES_W}x${CUSTOM_RES_H} -depth ${CUSTOM_DEPTH} :99 -rfbport ${RFB_PORT} -noxstartup -noserverkeymap ${TURBOVNC_PARAMS} 2>/dev/null
sleep 2
echo "---Starting Fluxbox---"
screen -d -m env HOME=/etc /usr/bin/fluxbox
sleep 2
echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem ${NOVNC_PORT} localhost:${RFB_PORT}
sleep 2

echo "---Starting Enpass---"
cd ${DATA_DIR}
${DATA_DIR}/Enpass 2>/dev/null