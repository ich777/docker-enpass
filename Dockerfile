FROM ich777/novnc-baseimage

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/ich777/docker-enpass"

RUN export TZ=Europe/Rome && \
	apt-get update && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	apt-get -y install --no-install-recommends libxkbcommon-x11-0 curl libcups2 libgtk-3-0 libpulse0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-xinerama0 && \
	rm -rf /var/lib/apt/lists/* && \
	sed -i '/    document.title =/c\    document.title = "Enpass - noVNC";' /usr/share/novnc/app/ui.js && \
	rm /usr/share/novnc/app/images/icons/*


ENV DATA_DIR=/enpass
ENV CUSTOM_RES_W=1024
ENV CUSTOM_RES_H=768
ENV CUSTOM_DEPTH=16
ENV NOVNC_PORT=8080
ENV RFB_PORT=5900
ENV TURBOVNC_PARAMS="-securitytypes none"
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="enpass"

RUN mkdir $DATA_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	mkdir /etc/.fluxbox && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
#COPY /icons/* /usr/share/novnc/app/images/icons/
COPY /conf/ /etc/.fluxbox/
RUN chmod -R 770 /opt/scripts/ && \
	chown -R ${UID}:${GID} /etc/.fluxbox && \
	chmod -R 770 /etc/.fluxbox

EXPOSE 8080

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]