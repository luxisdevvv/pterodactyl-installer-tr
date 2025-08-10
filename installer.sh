#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Proje 'pterodactyl-installer'                                                      #
#                                                                                    #
# Orijinal telif hakkı (C) 2018 - 2025, Vilhelm Prytz, <vilhelm@prytznet.se>          #
#                                                                                    #
#   Bu program özgür yazılımdır: yeniden dağıtabilir ve/veya değiştirebilirsiniz.    #
#   Bunu GNU Genel Kamu Lisansı koşulları altında yapabilirsiniz;                    #
#   ya sürüm 3 ya da (tercihinize bağlı) daha sonraki sürümler.                      #
#                                                                                    #
#   Bu program, kullanışlı olacağı umuduyla dağıtılmaktadır, fakat                   #
#   HİÇBİR GARANTİSİ YOKTUR; SATILABİLİRLİK veya                                     #
#   BELİRLİ BİR AMACA UYGUNLUK garantisi de vermez.                                   #
#   Daha fazla detay için GNU Genel Kamu Lisansına bakın.                             #
#                                                                                    #
#   GNU Genel Kamu Lisansının bir kopyasını bu programla almış olmalısınız.          #
#   Aksi halde <https://www.gnu.org/licenses/> adresini ziyaret edin.                 #
#                                                                                    #
# Orijinal proje bağlantısı:                                                         #
# https://github.com/pterodactyl-installer/pterodactyl-installer                     #
#                                                                                    #
# Bu script resmi Pterodactyl projesi ile bağlantılı değildir.                       #
#                                                                                    #
# Türkçe çeviri: LuxisDev                                                            #
######################################################################################

export GITHUB_SOURCE="v1.1.1"
export SCRIPT_RELEASE="v1.1.1"
export GITHUB_BASE_URL="https://raw.githubusercontent.com/luxisdevvv/pterodactyl-installer-tr"

LOG_PATH="/var/log/pterodactyl-installer.log"

# curl kontrolü
if ! [ -x "$(command -v curl)" ]; then
  echo "* Bu scriptin çalışması için curl gereklidir."
  echo "* Debian ve türevlerinde apt, CentOS’ta yum/dnf ile yükleyebilirsiniz."
  exit 1
fi

# lib.sh dosyasını her zaman silip yeniden indir
[ -f /tmp/lib.sh ] && rm -rf /tmp/lib.sh
curl -sSL -o /tmp/lib.sh "$GITHUB_BASE_URL"/main/lib.sh
# shellcheck source=lib/lib.sh
source /tmp/lib.sh

execute() {
  echo -e "\n\n* pterodactyl-yükleyici $(date) \n\n" >>$LOG_PATH

  [[ "$1" == *"canary"* ]] && export GITHUB_SOURCE="master" && export SCRIPT_RELEASE="canary"
  update_lib_source
  run_ui "${1//_canary/}" |& tee -a $LOG_PATH

  if [[ -n $2 ]]; then
    echo -e -n "* $1 kurulumu tamamlandı. $2 kurulumuna devam etmek ister misiniz? (e/H): "
    read -r CONFIRM
    if [[ "$CONFIRM" =~ [YyEe] ]]; then
      execute "$2"
    else
      error "$2 kurulum iptal edildi."
      exit 1
    fi
  fi
}

welcome ""  # Hoş geldiniz mesajı lib.sh içinden geliyor

done=false
while [ "$done" == false ]; do
  options=(
    "Paneli kur"
    "Wings kur"
    "Aynı makinede hem panel hem wings kur (önce panel, sonra wings)"
    "Paneli canary (geliştirme) sürümü ile kur (kararsız olabilir!)"
    "Wings’i canary (geliştirme) sürümü ile kur (kararsız olabilir!)"
    "Aynı makinede hem [3] hem [4] kur (önce panel, sonra wings)"
    "Panel veya wings’i canary sürümü ile kaldır (kararsız olabilir!)"
  )

  actions=(
    "panel"
    "wings"
    "panel;wings"
    "panel_canary"
    "wings_canary"
    "panel_canary;wings_canary"
    "uninstall_canary"
  )

  output "Ne yapmak istersiniz?"

  for i in "${!options[@]}"; do
    output "[$i] ${options[$i]}"
  done

  echo -n "* 0-$((${#actions[@]} - 1)) arası bir sayı girin: "
  read -r action

  [ -z "$action" ] && error "Bir seçim yapmanız gerekiyor." && continue

  valid_input=("$(for ((i = 0; i <= ${#actions[@]} - 1; i += 1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "Geçersiz seçenek."
  [[ " ${valid_input[*]} " =~ ${action} ]] && done=true && IFS=";" read -r i1 i2 <<<"${actions[$action]}" && execute "$i1" "$i2"
done

rm -rf /tmp/lib.sh
