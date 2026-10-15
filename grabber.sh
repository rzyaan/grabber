œ#!/bin/bash
# ============================================================
# Script : grabber2.sh
# Auteur : Rayan Aktas
# Date   : 2025-12-12
# Version: 0.0.6
#
# Description :
#  Récupère diverses informations système et les enregistre dans des fichiers
#
# Usage :
#   ./grabber.sh
#
# Dépendances :
#   - inxi
#   - droits d’écriture dans le dossier /opt/grabber et /var/log/grabber
#
# ============================================================

#DATE_FORMAT=$(date +"%Y-%m-%d_%H-%M-%S")
#DIRECTORY_NAME="logs_$DATE_FORMAT"


BASE_GRABBER="$HOME/workspace/grabber"

DIR="$BASE_GRABBER/$DIRECTORY_NAME"
SUCCESS_LOG="$BASE_GRABBER/output/log/grabber-success.log"
ERROR_LOG="$BASE_GRABBER/output/log/grabber-error.log"
SUM="$BASE_GRABBER/output/summary.txt"
: > "$SUM"

mkdir -p $DIR

# SUCCESS_LOG and ERROR_LOG already set above

# Affichage du texte de démarrage
tee $SUCCESS_LOG $ERROR_LOG <<EOF1
++++++++++++++++++++++++
Démarrage du script Grabber
++++++++++++++++++++++++
========================
Récupération des informations sur les paquets
========================
EOF1

# Fichier /etc/apt/sources.list
tee -a $SUCCESS_LOG $ERROR_LOG <<EOF2
----------------------------------------------------------------------------
Copie du fichier de configuration /etc/apt/sources.list
-------------------
EOF2
cat /etc/apt/sources.list 2> >(tee -a $ERROR_LOG) > "$DIR/sources-list.file"
#cat et déclaration des files //passwd group ssh config /etc/ 
# Commande apt list --installed
tee -a $SUCCESS_LOG $ERROR_LOG <<EOF3
----------------------------------------------------------------------------
Récupération de la liste des paquets installés
--------------------
EOF3
apt list --installed 2> >(tee -a $ERROR_LOG) > "$DIR/apt-installed.cmd" \
    && echo "[OK]: Fichier apt-installed.cmd généré" |tee -a $SUCCESS_LOG \
    || echo "[ECHEC]: Erreur à la génération de apt-installed.cmd" |tee -a $ERROR_LOG

#.file arrays
FILES=(
    ["sources-list"]="/etc/apt/sources.list"
    ["passwd"]="/etc/passwd"
    ["group"]="/etc/group"
    ["ssh_config"]="/etc/ssh/ssh_config"
    ["sshd_config"]="/etc/ssh/sshd_config"
)

#.cmd array
declare -A CMD

CMD=(
	["$DIR/systemd-analyze.cmd"]="systemd-analyze"
	["$DIR/systemd-blame.cmd"]="systemd-analyze blame"
	["$DIR/lspci.cmd"]="lspci"
	["$DIR/lsmem.cmd"]="lsmem --output-all"
	["$DIR/lscpu.cmd"]="lscpu"
	["$DIR/lsusb.cmd"]="lsusb"
	["$DIR/apt-installed.cmd"]="apt list --installed"
)
declare -a DEVICES
mapfile -t DEVICES < <(lsblk -dn -o NAME |grep -v loop)

declare -A PARTITIONS_BY_DISK

for disk in ${DEVICES[@]}; do
    disk_path="/dev/$disk"
    disk_parts=$(lsblk -nr -o PKNAME,PATH $disk_path |grep -vE "^\ " | cut -d' ' -f 2) 
    PARTITIONS_BY_DISK[$disk]="${disk_parts[@]}"
done

for disk in ${!PARTITIONS_BY_DISK[@]}; do
	echo "PARTS_$disk=$(printf '%s ' ${PARTITIONS_BY_DISK[$disk]})" >> $DIR/status.log
done

#Initialize logs files
treat_file() {
	cat "$2" | grep -v '^#' | grep -v '^$' > "$DIR/$1" 
	if [ $? -eq 0 ]; then
		echo "[OK]: Fichier $1 généré" >> $SUCCESS_LOG
	else
		echo "[ECHEC]: Erreur à la génération de $1 => Code de sortie $?" >> $ERROR_LOG
	fi
}

for file in "${!FILES[@]}"; do
	treat_file $file "${FILES[$file]}"
done

treat_cmd() {
	eval "$2" > $1 2> >(tee -a $ERROR_LOG)
	if [ $? -eq 0 ]; then
		echo "[OK]: Fichier $1 généré" >> $SUCCESS_LOG
	else
		echo "[ECHEC]: Erreur à la génération de $1 => Code de sortie $?" >> $ERROR_LOG
	fi
}

for f in "${!CMD[@]}"; do
	treat_cmd $f "${CMD[$f]}"
done

#DECLARATION HARDWARE -----------------------------------------------------
MAC_ADDRESS=$(ip link show | grep ether | head -n1 | awk '{print $2}')
CPU=$(lscpu -eMODELNAME | tail -n1 | cut -d' ' -f1,2,3,4)
CPU_ID=$(sudo dmidecode -t processor | grep ID | cut -d: -f2 | sed 's/^ *//')
RAM_SIZE=$(lsmem | grep "Mémoire partagée" | cut -d: -f2 | sed 's/\ *//')
RAM_GEN=$(sudo dmidecode -t memory | grep Type: | grep -v Unknown | tail -n1 | cut -d: -f2 | sed 's/\ //')
SIZES=$(lsblk -dnb | grep -v loop | grep -v boot | tr -s " " | cut -d' ' -f4)
MB_SERIAL=$(sudo dmidecode | grep -A 4 "Base Board" | tail -n1 | cut -d: -f2 | sed 's/\ //')
CPU_FREQUENCY_MIN=$(lscpu | grep MHz | cut -d: -f2 | sed -n '3p' | tr -s " " | sed 's/\ //' | cut -d, -f1)
CPU_FREQUENCY_CUR=$(sudo dmidecode | grep "MHz" | cut -d: -f2 | sed -n '3p' | sed 's/\ //')
CPU_FREQUENCY_MAX=$(sudo dmidecode | grep "MHz" | cut -d: -f2 | sed -n '2p' | sed 's/\ //')
GPU_MODEL=$(lspci | grep VGA | cut -d: -f3 | sed 's/^ *//')
CHASSIS_SERIAL=$(sudo dmidecode | grep -A 5 "Chassis" | tail -n1 | cut -d: -f2 | sed 's/\ //')
CPU_CORES_NUMBER=$(inxi | grep core | cut -d' ' -f2 | sed 's/-core//')
CPU_THREADS_NUMBER=$(nproc)
RAM_NUMBER=$(sudo dmidecode --type memory | grep 'Rank' | wc -l)
RAM_SLOTS_NUMBER=$(sudo dmidecode --type memory | grep "Number Of Devices" | cut -d: -f2 | sed 's/\ //')

RAM_SIZE=$(free -h |awk 'NR==2{print $2}')

RAM_GEN=$(sudo dmidecode -t memory |grep 'Type:' |grep -v Unknown |tail -n1 |cut -d: -f2 |sed 's/\ //g')

sizes=($(lsblk -dn -o SIZE |grep -v loop |grep -v boot))

total=0

for size in "${sizes[@]}"; do

  bytes=$(numfmt --from iec "$size" 2>/dev/null || echo 0)

  total=$((total + bytes))

done

STOCKAGE_TOTAL=$(numfmt --to iec $total 2>/dev/null || echo "N/A")

#DECLARATION SOFTWARE -----------------------------------------------------
OS=$(lsb_release -a | grep Description | cut -f2)
ARCH=$(uname -a | cut -d' ' -f10)
KERNEL=$(uname -r)
DESKTOP=$XDG_CURRENT_DESKTOP" >> $SUM

WM=$XDG_SESSION_TYPE" >> $SUM




#checker fonctionnement code files et arguments
 #voir ordre des arguments du treat file avec sources
#========================================================================================================================================
#ATTENTION AUX ESPACES AVEC LE PIPE | ESPACE AVANT |PAS APRES ! // rev donne le résultat à l'envers // bouger tout


declare -A PARTITIONS_BY_DISK
for disk in "${DEVICES[@]}";do
PARTITIONS_BY_DISK[$disk]=""
done
for disk in "${DEVICES[@]}"; do
    disk_path=$(printf '/dev/%s' "$disk")
    disk_parts=$(lsblk -nr -o PKNAME,PATH $disk_path |grep -vE "^ " |cut -d' ' -f2)

PARTITIONS_BY_DISK[$disk]="${disk_parts[*]}" 
    PARTITIONS_BY_DISK[$disk]=${disk_parts[@]}
done
echo "Combien de disques sur l'ordinateur ? ${#DEVICES[@]}"
echo "${#DEVICES[@]}"
echo "${#FILES[@]}"
echo "keys: ${!PARTITIONS_BY_DISK[@]}"
echo "values: ${PARTITIONS_BY_DISK[@]}"
echo "DEVICES=${DEVICES[@]}" >$DIR/database.txt
for disk in ${!PARTITIONS_BY_DISK[@]};do
echo "PARTS_$disk=$(printf '%s ' ${PARTITIONS_BY_DISK[$disk]})" >>$DIR/database.txt
done




#ajouter récupérations d'infos réseau

hardware() {
	echo "" >> $SUM
	echo "[HARDWARE]" >> $SUM
  echo "MAC_ADDRESS=$MAC_ADDRESS" >> $SUM
	echo "MB_SERIAL=$MB_SERIAL" >> $SUM
	echo "CHASSIS_SERIAL=$CHASSIS_SERIAL" >> $SUM
	echo "CPU=$CPU" >> $SUM
	echo "CPU_ID=$CPU_ID" >> $SUM
	echo "CPU_CORES_NUMBER=$CPU_CORES_NUMBER" >> $SUM
	echo "CPU_THREADS_NUMBER=$CPU_THREADS_NUMBER" >> $SUM
	echo "CPU_FREQUENCY_MIN=$CPU_FREQUENCY_MIN" >> $SUM
	echo "CPU_FREQUENCY_CUR=$CPU_FREQUENCY_CUR" >> $SUM
	echo "CPU_FREQUENCY_MAX=$CPU_FREQUENCY_MAX" >> $SUM
	echo "GPU_MODEL=$GPU_MODEL" >> $SUM
	echo "RAM_SLOTS_NUMBER=$RAM_SLOTS_NUMBER" >> $SUM
	echo "RAM_NUMBER=$RAM_NUMBER" >> $SUM
	echo "RAM_SIZE=$RAM_SIZE" >> $SUM
	echo "RAM_GEN=$RAM_GEN" >> $SUM
	echo "RAM=$RAM_SIZE $RAM_GEN" >> $SUM
}

software() {
    echo "" >> $SUM
	echo "[SOFTWARE]" >> $SUM
	echo "OS=$OS" >> $SUM
	echo "ARCH=$ARCH" >> $SUM
	echo "DESKTOP=$XDG_CURRENT_DESKTOP" >> $SUM
	echo "WM=$XDG_SESSION_TYPE" >> $SUM
	echo "KERNEL=$KERNEL" >> $SUM 
}
software

hardware
HOSTNAME=$(hostname)
# Construire le JSON
json_data=$(jq -n \
    --arg hostname "$HOSTNAME" \
    --arg mac_address "$MAC_ADDRESS" \
    --arg mb_serial "$MB_SERIAL" \
    --arg chassis_serial "$CHASSIS_SERIAL" \
    --arg cpu "$CPU" \
    --arg cpu_id "$CPU_ID" \
    --arg cpu_cores_number "$CPU_CORES_NUMBER" \
    --arg cpu_threads_number "$CPU_THREADS_NUMBER" \
    --arg cpu_frequency_min "$CPU_FREQUENCY_MIN" \
    --arg cpu_frequency_cur "$CPU_FREQUENCY_CUR" \
    --arg cpu_frequency_max "$CPU_FREQUENCY_MAX" \
    --arg gpu_model "$GPU_MODEL" \
    --arg ram_slots_number "$RAM_SLOTS_NUMBER" \
    --arg ram_number "$RAM_NUMBER" \
    --arg ram_size "$RAM_SIZE" \
    --arg ram_gen "$RAM_GEN" \
    --arg stockage_total "$STOCKAGE_TOTAL" \
    --arg os "$OS" \
    --arg arch "$ARCH" \
    --arg desktop "$DESKTOP" \
    --arg wm "$WM" \
    --arg kernel "$KERNEL" \
    '{ 
       HARDWARE : {
        HOSTNAME: $hostname,
        MAC_ADDRESS: $mac_address,
        MB_SERIAL: $mb_serial,
        CHASSIS_SERIAL: $chassis_serial,
        CPU: $cpu,
        CPU_ID: $cpu_id,
        CPU_CORES_NUMBER: $cpu_cores_number,
        CPU_THREADS_NUMBER: $cpu_threads_number,
        CPU_FREQUENCY_MIN: $cpu_frequency_min,
        CPU_FREQUENCY_CUR: $cpu_frequency_cur,
        CPU_FREQUENCY_MAX: $cpu_frequency_max,
        GPU_MODEL: $gpu_model,
        RAM_SLOTS_NUMBER: $ram_slots_number,
        RAM_NUMBER: $ram_number,
        RAM_SIZE: $ram_size,
        RAM_GEN: $ram_gen,
        STOCKAGE_TOTAL: $stockage_total
         }, 
       SOFTWARE : {
        OS: $os,
        ARCH: $arch,
        DESKTOP: $desktop,
        WM: $wm,
        KERNEL: $kernel
         }
    }' 
)
 echo $json_data
  # SIMPLE LOCAL S
   curl -X POST http://localhost:8000/endpoint \
 -H "Content-Type: application/json" \
 -d "$json_data" \