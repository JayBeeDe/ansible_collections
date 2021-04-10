#!/bin/bash
# Script d'installation pour imprimantes Brother

. /lib/lsb/init-functions

MODEL_NAME=$1
USER=${SUDO_USER}
DIR=$(pwd)/$(dirname $0)
TEMP_DIR="${DIR}/packages"
CODENAME=$(lsb_release -cs)
ARCH=$(uname -m)
LOGFILE="/tmp/brprinter-installer.log"
LIB_DIR="/usr/lib/${ARCH}-linux-gnu"
URL_INF="http://www.brother.com/pub/bsc/linux/infs"
URL_PKG="http://www.brother.com/pub/bsc/linux/packages"
UDEV_RULES="/lib/udev/rules.d/60-libsane1.rules"
UDEV_DEB="brother-udev-rule-type1-1.0.0-1.all.deb"
UDEV_DEB_URL="http://www.brother.com/pub/bsc/linux/dlf/${UDEV_DEB}"
BLUE="\\033[1;34m"
RED="\\033[1;31m"
RESETCOLOR="\\033[0;0m"

#########################
# PRÉPARATION DU SCRIPT #
#########################
function do_init_script() {
	# On vérifie qu'on lance le script en root
	if [[ ${EUID} != "0" ]]; then
		echo -e ${RED}"Vous devez lancer ce script en tant que root : sudo bash $0"${RESETCOLOR}
		exit 0
	fi
	# Si un log existe déjà on le renomme
	if [[ -e ${LOGFILE} ]]; then
		mv ${LOGFILE} ${LOGFILE}.old
	fi
	touch ${LOGFILE}
	# Si le premier argument est vide on demande le modèle de l'imprimante
	while [[ -z "${MODEL_NAME}" ]]; do
		read -p "Entrez votre modèle : " MODEL_NAME
	done
	MODEL_NAME=$(echo ${MODEL_NAME} | tr [a-z] [A-Z])
	# On demande comment est connectée l'imprimante
	echo "Sélectionner le type de connectivité : [0] USB - [1] Réseau"
	while [[ -z ${CONNECTION} ]]; do
		read -p "Entrez votre choix : "
		case $REPLY in
			0)
				CONNECTION="USB"
			;;
			1)
				CONNECTION="Réseau"
				echo -e ${RED}"Vous devriez vous assurer que votre imprimante possède une adresse IP fixe."${RESETCOLOR}
				echo -e ${RED}"Veuillez consulter le manuel de votre imprimante pour plus de détails : http://support.brother.com/g/b/productsearch.aspx?c=fr&lang=fr&content=ml"${RESETCOLOR}
				read -p "Entrez l'adresse IP de votre imprimante : " IP
				# On valide le format de l'adresse IP de l'imprimante
				IP=$(echo ${IP} | awk -F'[.]' '{w=$1+0; x=$2+0; y=$3+0; z=$4+0; print w"."x"."y"."z}')
			;;
		esac
	done
	echo "# Ubuntu Codename : ${CODENAME}" &>> ${LOGFILE}
	echo "# Architecture : ${ARCH}" &>> ${LOGFILE}
	echo "# Modèle de l'imprimante : ${MODEL_NAME}" &>> ${LOGFILE}
	echo "# Connexion : ${CONNECTION}" &>> ${LOGFILE}
	if [[ ${CONNECTION} == "Réseau " ]]; then
		echo "# Adresse IP : ${IP}" &>> ${LOGFILE}
	fi
}

##############################
# TÉLÉCHARGEMENT DES PILOTES #
##############################
function do_download_drivers() {
	echo -e ${BLUE}"Téléchargement des pilotes de l'imprimante"${RESETCOLOR}
	# On transforme le nom de l'imprimante
	log_action_begin_msg "Recherche des pilotes"
	PRINTER_NAME=$(echo ${MODEL_NAME} | sed -e 's/-//' | tr [a-z] [A-Z])
	# On construit l'URL du fichier contenant les informations
	PRINTER_INFO="${URL_INF}/${PRINTER_NAME}"
	# On vérifie l'URL
	if ! wget -q --spider ${PRINTER_INFO}; then
		log_action_end_msg 1
		echo " - Aucun pilote trouvé" &>> ${LOGFILE}
		echo -e ${RED}"Aucun pilote trouvé. Veuillez vérifier le modèle de votre imprimante ou visitez la page suivante http://support.brother.com/g/b/productsearch.aspx?c=us&lang=en&content=dl afin de télécharger les pilotes et les installer manuellement."${RESETCOLOR}
		exit 1
	fi
	# On vérifie que le fichier fournit les informations
	LNK=$(wget -q ${PRINTER_INFO} -O - | grep LNK - | cut -d\= -f2)
	if [[ ${LNK} ]]; then
		PRINTER_INFO="${URL_INF}/${LNK}"
		echo "# Link to : ${PRINTER_INFO}" &>> ${LOGFILE}
	fi
	echo "# Fichier d'informations : ${PRINTER_INFO}" &>> ${LOGFILE}
	# On récupère le nom des paquets disponibles
	PRINTER_LPD_DEB=$(wget -q ${PRINTER_INFO} -O - | grep PRN_LPD_DEB - | cut -d\= -f2)
	PRINTER_CUPS_DEB=$(wget -q ${PRINTER_INFO} -O - | grep PRN_CUP_DEB - | cut -d\= -f2)
	PRINTER_DRV_DEB=$(wget -q ${PRINTER_INFO} -O - | grep PRN_DRV_DEB - | cut -d\= -f2)
	SCANNER_DEB=$(wget -q ${PRINTER_INFO} -O - | grep SCANNER_DRV - | cut -d\= -f2)
	SCANNER_INFO="${URL_INF}/${SCANNER_DEB}.lnk"
	SCANKEY_DEB=$(wget -q ${PRINTER_INFO} -O - | grep SCANKEY_DRV - | cut -d\= -f2)
	SCANKEY_INFO="${URL_INF}/${SCANKEY_DEB}.lnk"
	# On récupère les pilotes du scanner en fonctionnement de l'architecture du système (32-bits ou 64-bits)
	case ${ARCH} in
		i*86)
			SCANNER_DRV_DEB=$(wget -q ${SCANNER_INFO} -O - | grep DEB32 | cut -d\= -f2)
			SCANKEY_DRV_DEB=$(wget -q ${SCANKEY_INFO} -O - | grep DEB32 | cut -d\= -f2)
		;;
		x86_64)
			SCANNER_DRV_DEB=$(wget -q ${SCANNER_INFO} -O - | grep DEB64 | cut -d\= -f2)
			SCANKEY_DRV_DEB=$(wget -q ${SCANKEY_INFO} -O - | grep DEB64 | cut -d\= -f2)
		;;
		*)
			echo "Architecture inconnue: ${ARCH}" &>> ${LOGFILE}
		;;
	esac
	# On ajoute la liste des pilotes trouvés au fichier de journalisation
	for PKG in ${PRINTER_LPD_DEB} ${PRINTER_CUPS_DEB} ${PRINTER_DRV_DEB} ${SCANNER_DRV_DEB} ${SCANKEY_DRV_DEB}; do
		if [[ ! -z ${PKG} ]]; then
			echo " - Paquet trouvé : ${PKG}" &>> ${LOGFILE}
		fi
	done
	log_action_end_msg 0
	# On crée le dossier de téléchargement des paquets
	if [[ ! -d ${TEMP_DIR} ]]; then
		mkdir ${TEMP_DIR}
	fi
	# On télécharge les pilotes trouvés
	for PKG in ${PRINTER_LPD_DEB} ${PRINTER_CUPS_DEB} ${PRINTER_DRV_DEB} ${SCANNER_DRV_DEB} ${SCANKEY_DRV_DEB}; do
		URL_DEB="${URL_PKG}/${PKG}"
		echo &>> ${LOGFILE}
		echo "# Téléchargement du paquet : ${PKG}" &>> ${LOGFILE}
		log_action_begin_msg "Téléchargement du paquet : ${PKG}"
		wget -cP ${TEMP_DIR} "${URL_DEB}" &>> ${LOGFILE}
		log_action_end_msg $?
	done
	# On télécharge le fichier pour udev pour les scanners
	if [[ ! -z ${SCANNER_DRV_DEB} ]]; then
		echo "# Téléchargement du paquet : brother-udev-rule-type1-1.0.0-1.all.deb" &>> ${LOGFILE}
		log_action_begin_msg "Téléchargement du paquet : ${UDEV_DEB}"
		wget -cP ${TEMP_DIR} "${UDEV_DEB_URL}" &>> ${LOGFILE}
		log_action_end_msg $?
	fi
}

###############################
# VERIFICATION DES PRÉ-REQUIS #
###############################
function do_check_prerequisites() {
	echo -e ${BLUE}"Vérification des pré-requis"${RESETCOLOR}
	echo "# Vérification des pré-requis" &>> ${LOGFILE}
	log_action_begin_msg "Mise à jour de la liste des paquets"
	apt-get update -qq
	log_action_end_msg $?
	# On vérifie que le paquet multiarch-support est installé et on l'installe le cas échéant (Ubuntu 64-bits seulement)
	if [[ "${ARCH}" == "x86_64" ]]; then
		log_action_begin_msg "Recherche du paquet 'multiarch-support' sur votre système"
		if dpkg -s multiarch-support &>/dev/null; then
			log_action_end_msg $?
			echo " - Paquet 'multiarch-support' installé" &>> ${LOGFILE}
		else
			log_action_end_msg 1
			echo " - Paquet 'multiarch-support' non installé" &>> ${LOGFILE}
			log_action_begin_msg "Installation du paquet 'multiarch-support'"
			echo "# Installation de 'multiarch-support'" &>> ${LOGFILE}
			apt-get install -qq multiarch-support &>> ${LOGFILE}
			log_action_end_msg $?
			echo " - Paquet 'multiarch-support' installé" &>> ${LOGFILE}
		fi
		log_action_begin_msg "Recherche du paquet 'lib32stdc++6' sur votre système"
		if dpkg -s lib32stdc++6 &>/dev/null; then
			log_action_end_msg $?
			echo " - Paquet 'lib32stdc++6' installé" &>> ${LOGFILE}
		else
			log_action_end_msg 1
			echo " - Paquet 'lib32stdc++6' non installé" &>> ${LOGFILE}
			log_action_begin_msg "Installation du paquet 'lib32stdc++6'"
			echo "# Installation de 'lib32stdc++6'" &>> ${LOGFILE}
			apt-get install -qq lib32stdc++6 &>> ${LOGFILE}
			log_action_end_msg $?
			echo " - Paquet 'lib32stdc++6' installé" &>> ${LOGFILE}
		fi
	fi
	# On vérifie que le paquet cups est installé et on l'installe le cas échéant
	log_action_begin_msg "Recherche du paquet 'cups' sur votre système"
	if dpkg -s cups &>/dev/null; then
		log_action_end_msg $?
		echo " - Paquet 'cups' installé" &>> ${LOGFILE}
	else
		log_action_end_msg 1
		log_action_begin_msg "Installation du paquet 'cups'"
		echo "# Installation de 'cups'" &>> ${LOGFILE}
		apt-get install -qq cups &>> ${LOGFILE}
		log_action_end_msg $?
		echo " - Paquet 'cups' installé" &>> ${LOGFILE}
	fi
	# Si un pilote pour le scanner a été trouvé on vérifie que sane-utils est installé
	if [[ ! -z ${SCANNER_DEB} ]]; then
		log_action_begin_msg "Recherche du paquet 'sane-utils' sur votre système"
		if dpkg -s sane-utils &>/dev/null; then
			log_action_end_msg $?
			echo " - Paquet 'sane-utils' installé" &>> ${LOGFILE}
		else
			log_action_end_msg 1
			echo " - Paquet 'sane-utils' non installé" &>> ${LOGFILE}
			log_action_begin_msg "Installation du paquet 'sane-utils'"
			echo "# Installation de 'sane-utils'" &>> ${LOGFILE}
			apt-get install -qq sane-utils &>> ${LOGFILE}
			log_action_end_msg $?
			echo " - Paquet 'sane-utils' installé" &>> ${LOGFILE}
		fi
		# On vérifie que libusb-0.1-4:i386 est installé
		if [[ ${CONNECTION} == "USB" ]]; then
			log_action_begin_msg "Recherche du paquet 'libusb-0.1-4' sur votre système"
			if dpkg -s libusb-0.1-4 &>/dev/null; then
				log_action_end_msg $?
				echo " - Paquet 'libusb-0.1-4' installé" &>> ${LOGFILE}
			else
				log_action_end_msg 1
				echo " - Paquet 'libusb-0.1-4' non installé" &>> ${LOGFILE}
				log_action_begin_msg "Installation du paquet 'libusb-0.1-4'"
				echo "# Installation de 'libusb-0.1-4'" &>> ${LOGFILE}
				apt-get install -qq libusb-0.1-4 &>> ${LOGFILE}
				log_action_end_msg $?
				echo " - Paquet 'libusb-0.1-4' installé" &>> ${LOGFILE}
			fi
		fi
	fi
	# On vérifie que le paquet csh est installé et on l'installe le cas échéant (uniquement pour certaines imprimantes)
	for i in DCP-110C DCP-115C DCP-117C DCP-120C DCP-310CN DCP-315CN DCP-340CW FAX-1815C FAX-1820C FAX-1835C FAX-1840C FAX-1920CN FAX-1940CN FAX-2440C MFC-210C MFC-215C MFC-3220C MFC-3240C MFC-3320CN MFC-3340CN MFC-3420C MFC-3820CN MFC-410CN MFC-420CN MFC-425CN MFC-5440CN MFC-5840CN MFC-620CN MFC-640CW MFC-820CW; do
		if [[ ${MODEL_NAME} == "$i" ]]; then
			log_action_begin_msg "Recherche du paquet 'csh' sur votre système"
			if [[ ! -x /bin/csh ]]; then
				log_action_end_msg 1
				log_action_begin_msg "Installation du paquet 'csh'"
				echo "# Installation du paquet 'csh'" &>> ${LOGFILE}
				apt-get install -qq csh &>> ${LOGFILE}
				log_action_end_msg $?
				echo " - Paquet 'csh' installé" &>> ${LOGFILE}
			else
				log_action_end_msg $?
			fi
		fi
	done
	# On vérifie que le dossier /usr/share/cups/model existe et on le crée le cas échéant
	log_action_begin_msg "Recherche du dossier '/usr/share/cups/model' sur votre système"
	if [[ -d /usr/share/cups/model ]]; then
		log_action_end_msg $?
	else
		log_action_end_msg 1
		log_action_begin_msg "Creation du dossier '/usr/share/cups/model'"
		mkdir -p /usr/share/cups/model
		log_action_end_msg $?
	fi
	# On vérifie que le dossier /var/spool/lpd existe et on le crée le cas échéant
	log_action_begin_msg "Recherche du dossier '/var/spool/lpd' sur votre système"
	if [[ -d /var/spool/lpd ]]; then
		log_action_end_msg $?
	else
		log_action_end_msg 1
		log_action_begin_msg "Creation du dossier '/var/spool/lpd'"
		mkdir -p /var/spool/lpd
		log_action_end_msg $?
	fi
	# On vérifie que le lien symbolique /etc/init.d/lpd existe et on le crée le cas échéant (uniquement pour certaines imprimantes)
	for i in DCP-1000 DCP-1400 DCP-8020 DCP-8025D DCP-8040 DCP-8045D DCP-8060 DCP-8065DN FAX-2850 FAX-2900 FAX-3800 FAX-4100 FAX-4750e FAX-5750e HL-1030 HL-1230 HL-1240 HL-1250 HL-1270N HL-1430 HL-1440 HL-1450 HL-1470N HL-1650 HL-1670N HL-1850 HL-1870N HL-5030 HL-5040 HL-5050 HL-5070N HL-5130 HL-5140 HL-5150D HL-5170DN HL-5240 HL-5250DN HL-5270DN HL-5280DW HL-6050 HL-6050D MFC-4800 MFC-6800 MFC-8420 MFC-8440 MFC-8460N MFC-8500 MFC-8660DN MFC-8820D MFC-8840D MFC-8860DN MFC-8870DW MFC-9030 MFC-9070 MFC-9160 MFC-9180 MFC-9420CN MFC-9660 MFC-9700 MFC-9760 MFC-9800 MFC-9860 MFC-9880; do
		if [[ ${MODEL_NAME} == "$i" ]]; then
			log_action_begin_msg "Recherche du lien symbolique '/etc/init.d/lpd ~> /etc/init.d/cups' sur votre système"
			if [[ -L /etc/init.d/lpd ]]; then
				log_action_end_msg 0
			else
				log_action_end_msg 1
				log_action_begin_msg "Creation du lien symbolique '/etc/init.d/lpd ~> /etc/init.d/cups'"
				ln -s /etc/init.d/cups /etc/init.d/lpd
				# On crée un lien symbolique vers cups.service si systemd est utilisé
				if [[ -L /sbin/init ]]; then
					ln -s /lib/systemd/system/cups.service /lib/systemd/system/lpd.service
					systemd-daemon reload
				fi
				log_action_end_msg $?
			fi
		fi
	done
}

############################
# INSTALLATION DES PAQUETS #
############################
function do_install_drivers() {
	echo -e ${BLUE}"Installation des pilotes"${RESETCOLOR}
	for PKG in ${PRINTER_LPD_DEB} ${PRINTER_CUPS_DEB} ${PRINTER_DRV_DEB} ${SCANNER_DRV_DEB} ${SCANKEY_DRV_DEB}; do
		log_action_begin_msg "Installation du paquet : ${PKG}"
		echo &>> ${LOGFILE}
		echo "# Installation du paquet : ${PKG}" &>> ${LOGFILE}
		dpkg -i --force-all "${TEMP_DIR}/${PKG}" &>> ${LOGFILE}
		log_action_end_msg $?
	done
	if [[ ! -z ${SCANNER_DRV_DEB} ]]; then
		log_action_begin_msg "Installation du paquet : ${UDEV_DEB}"
		echo &>> ${LOGFILE}
		echo "# Installation du paquet : ${UDEV_DEB}" &>> ${LOGFILE}
		dpkg -i --force-all "${TEMP_DIR}/${UDEV_DEB}" &>> ${LOGFILE}
		log_action_end_msg $?
	fi
}

#################################
# CONFIGURATION DE L'IMPRIMANTE #
#################################
function do_configure_printer() {
	echo -e ${BLUE}"Configuration de l'imprimante"${RESETCOLOR}
	# On recherche un fichier ppd
	log_action_begin_msg "Recherche d'un fichier PPD sur votre système"
	echo &>> ${LOGFILE}
	echo "# Recherche d'un fichier PPD" &>> ${LOGFILE}
	for PKG in ${PRINTER_CUPS_DEB} ${PRINTER_DRV_DEB}; do
		PPD_FILE=$(dpkg --contents ${TEMP_DIR}/${PKG} | grep ppd | awk '{print $6}' | sed 's/^.//g')
	done
	if [[ -z "${PPD_FILE}" ]]; then
		for FILE in $(find /usr/share/cups/model -type f); do
			if [[ $(grep -i Brother ${FILE} | grep -E "(${MODEL_NAME}|${PRINTER_NAME})") ]]; then
				PPD_FILE=${FILE}
			fi
		done
	fi
	echo " - Fichier PPD : ${PPD_FILE}" &>> ${LOGFILE}
	log_action_end_msg 0
	# On ajoute une nouvelle imprimante
	log_action_begin_msg "Ajout de l'imprimante ${MODEL_NAME}"
	echo &>> ${LOGFILE}
	echo "# Ajout de l'imprimante ${MODEL_NAME}" &>> ${LOGFILE}
	echo " - Backup du fichier /etc/cups/printers.conf.O" &>> ${LOGFILE}
	cp /etc/cups/printers.conf.O ${DIR} &>> ${LOGFILE}
	echo " - Arret du service CUPS" &>> ${LOGFILE}
	systemctl stop cups &>> ${LOGFILE}
	echo " - Restauration du fichier printers.conf" &>> ${LOGFILE}
	cp ${DIR}/printers.conf.O /etc/cups/printers.conf &>> ${LOGFILE}
	echo " - Redémarrage du service CUPS" &>> ${LOGFILE}
	systemctl restart cups &>> ${LOGFILE}
	case ${CONNECTION} in
	"USB")
		sleep 2 && lpadmin -p "${MODEL_NAME}" -E -v usb://dev/usb/lp0 -P "${PPD_FILE}"
	;;
	"Réseau")
		sleep 2 && lpadmin -p "${MODEL_NAME}" -E -v lpd://"${IP}"/binary_p1 -P "${PPD_FILE}"
	;;
	esac
	log_action_end_msg $?
	echo " - Restauration du fichier printers.conf.O" &>> ${LOGFILE}
	cp ${DIR}/printers.conf.O /etc/cups/printers.conf.O &>> ${LOGFILE}
}

############################
# CONFIGURATION DU SCANNER #
############################
function do_configure_scanner() {
	if [[ ! -z ${SCANNER_DEB} ]]; then
		echo -e ${BLUE}"Configuration du scanner"${RESETCOLOR}
		echo &>> ${LOGFILE}
		echo "# Configuration du scanner" &>> ${LOGFILE}
		if [[ ${CONNECTION} == "USB" ]]; then
			# Installation du paquet brother-udev
			dpkg -i --force-all "${TEMP_DIR}/brother-udev-rule-type1-1.0.0-1.all.deb" &>> ${LOGFILE}
			# On ajoute une entrée au fichier udev
			if [[ ! $(grep 'ATTRS{idVendor}=="04f9", ENV{libsane_matched}="yes"' ${UDEV_RULES}) ]]; then
				echo 'Adding ATTRS{idVendor}=="04f9", ENV{libsane_matched}="yes" to ${UDEV_RULES}' &>> ${LOGFILE}
				sed -i '/LABEL="libsane_usb_rules_begin"/a\
				\n# Brother\nATTRS{idVendor}=="04f9", ENV{libsane_matched}="yes"' ${UDEV_RULES}
			else
				echo "Règle udev trouvée dans le fichier ${UDEV_RULES}" &>> ${LOGFILE}
			fi
			# On recharge les règles udev
			udevadm control --reload
		elif [[ ${CONNECTION} == "Réseau" ]]; then
			log_action_begin_msg "Configuration du scanner réseau"
			if [[ -x /usr/bin/brsaneconfig ]]; then
				brsaneconfig -a name="SCANNER" model="${MODEL_NAME}" ip="${IP}" &>> ${LOGFILE}
			elif [[ -x /usr/bin/brsaneconfig2 ]]; then
				brsaneconfig2 -a name="SCANNER" model="${MODEL_NAME}" ip="${IP}" &>> ${LOGFILE}
			elif [[ -x /usr/bin/brsaneconfig3 ]]; then
				brsaneconfig3 -a name="SCANNER" model="${MODEL_NAME}" ip="${IP}" &>> ${LOGFILE}
			elif [[ -x /usr/bin/brsaneconfig4 ]]; then
				sed -i '/Support Model/a\
0x029a, 117, 1, "MFC-8690DW", 133, 4\
0x0279, 14, 2, "DCP-J525W"\
0x027b, 13, 2, "DCP-J725DW"\
0x027d, 13, 2, "DCP-J925DW"\
0x027f, 14, 1, "MFC-J280W"\
0x028f, 13, 1, "MFC-J425W"\
0x0281, 13, 1, "MFC-J430W"\
0x0280, 13, 1, "MFC-J435W"\
0x0282, 13, 1, "MFC-J625DW"\
0x0283, 13, 1, "MFC-J825DW"\
0x028d, 13, 1, "MFC-J835DW"' /opt/brother/scanner/brscan4/Brsane4.ini
				brsaneconfig4 -a name=SCANNER model=${MODEL_NAME} ip=${IP} &>> ${LOGFILE}
			fi
			log_action_end_msg $?
		fi
		# On copie les librairies
		if [[ ${ARCH} == "x86_64" ]] && [[ -d ${LIB_DIR} ]]; then
			log_action_begin_msg "Copie des librairies nécessaires"
			if [[ -e /usr/bin/brsaneconfig ]]; then
				cd ${LIB_DIR}
				cp --force /usr/lib64/libbrcolm.so.1.0.1 .
				ln -sf libbrcolm.so.1.0.1 libbrcolm.so.1
				ln -sf libbrcolm.so.1 libbrcolm.so
				cp --force /usr/lib64/libbrscandec.so.1.0.0 ${LIB_DIR}
				ln -sf libbrscandec.so.1.0.0 libbrscandec.so.1
				ln -sf libbrscandec.so.1 libbrscandec.so
				cd ${LIB_DIR}/sane
				cp --force /usr/lib64/sane/libsane-brother.so.1.0.7 .
				ln -sf libsane-brother.so.1.0.7 libsane-brother.so.1
				ln -sf libsane-brother.so.1 libsane-brother.so
				log_action_end_msg 0
			elif [[ -e /usr/bin/brsaneconfig2 ]]; then
				cd ${LIB_DIR}
				cp --force /usr/lib64/libbrscandec2.so.1.0.0 .
				ln -sf libbrscandec2.so.1.0.0 libbrscandec2.so.1
				ln -sf libbrscandec2.so.1 libbrscandec2.so
				cp --force /usr/lib64/libbrcolm2.so.1.0.1 .
				ln -sf libbrcolm2.so.1.0.1 libbrcolm2.so.1
				ln -sf libbrcolm2.so.1 libbrcolm2.so
				cd ${LIB_DIR}/sane
				cp --force /usr/lib64/sane/libsane-brother2.so.1.0.7 .
				ln -sf libsane-brother2.so.1.0.7 libsane-brother2.so.1
				ln -sf libsane-brother2.so.1 libsane-brother2.so
				log_action_end_msg 0
			elif [[ -e /usr/bin/brsaneconfig3 ]]; then
				cd ${LIB_DIR}
				cp --force /usr/lib64/libbrscandec3.so.1.0.0 .
				ln -sf libbrscandec3.so.1.0.0 libbrscandec3.so.1
				ln -sf libbrscandec3.so.1 libbrscandec3.so
				cd ${LIB_DIR}/sane
				cp --force /usr/lib64/sane/libsane-brother3.so.1.0.7 .
				ln -sf libsane-brother3.so.1.0.7 libsane-brother3.so.1
				ln -sf libsane-brother3.so.1 libsane-brother3.so
				log_action_end_msg 0
			elif [[ -e /usr/bin/brsaneconfig4 ]]; then
				cd ${LIB_DIR}/sane
				cp --force /usr/lib64/sane/libsane-brother4.so.1.0.7 .
				ln -sf libsane-brother4.so.1.0.7 libsane-brother4.so.1
				ln -sf libsane-brother4.so.1 libsane-brother4.so
				log_action_end_msg 0
			else
				log_action_end_msg 1
				echo -e ${RED}"No config binary found."${RESETCOLOR}
			fi
		fi
	fi
}

#################
# FIN DU SCRIPT #
#################
function do_clean() {
	# On supprime le fichier printers.conf.O
	if [[ -e ${DIR}/printers.conf.O ]]; then
		rm ${DIR}/printers.conf.O &>> ${LOGFILE}
	fi
	# On réattribue les droits des dossiers/fichiers crées à l'utilisateur
	chown -R ${USER}: ${TEMP_DIR} ${LOGFILE}
	exit 0
}

do_init_script
do_download_drivers
do_check_prerequisites
do_install_drivers
do_configure_printer
do_configure_scanner
do_clean
