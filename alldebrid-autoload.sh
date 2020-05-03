#!/bin/bash

ALLDEBRID_TOKEN="XXX"
TYPE="magnets"
PUSHOVER_TOKEN="XXX"
PUSHOVER_USER="XXX"

# ------

weblogs=/var/www/html/autoload.txt
LOCKFILE=/tmp/autoload-$TYPE.pid
if [ -z "$1" ]; then
  if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    exit
  fi
  # make sure the lockfile is removed when we exit and then claim it
  trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
  echo $$ > ${LOCKFILE}
fi

rootdirectory="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd "$rootdirectory/$1"

nb=0
while read file; do
  url="https://myfiles.alldebrid.com/$ALLDEBRID_TOKEN/$TYPE/$1/$file"
  if [[ $file =~ /$ ]]; then
    mkdir -p "$file"
    bash "$0" "$1/$file"
    find "$file" -type d -empty -delete
  else
    if grep -Fxq "$url" "$rootdirectory/files.lst"; then
      sleep 0 # echo "$url has been already downloaded !"
    else
      echo "$url to download..."
      echo "$(date '+%Y-%m-%d %H:%M:%S') - DL START : $file" | cat - $weblogs > temp && mv temp $weblogs
      size=$(wget "$url" --spider --server-response -O - 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}')
      sizeh=$(numfmt --to=iec-i --suffix=B --padding=7 $size)
      curl https://api.pushover.net/1/messages.json --form-string "token=$PUSHOVER_TOKEN" --form-string "user=$PUSHOVER_USER" --form-string "title=ALLDEBRID START" --form-string "message=$file

Taille du fichier : $sizeh" --form-string "url=$url"
      if [ -e /var/www/html/dl_active_flag ]; then
        wget --trust-server-names -c -nv "$url"
        curl https://api.pushover.net/1/messages.json --form-string "token=$PUSHOVER_TOKEN" --form-string "user=$PUSHOVER_USER" --form-string "title=ALLDEBRID END" --form-string "message=$file

$(df -h /mnt/SAMSUNG)" --form-string "url=$url"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - DL END : $file" | cat - $weblogs > temp && mv temp $weblogs
      else
        curl https://api.pushover.net/1/messages.json --form-string "token=$PUSHOVER_TOKEN" --form-string "user=$PUSHOVER_USER" --form-string "title=ALLDEBRID END (IGNORED)" --form-string "message=$file

IGNORED!" --form-string "url=$url"
      fi
      echo "END"
      echo "$url" >> "$rootdirectory/files.lst"
      echo "ask plex to reload section..."
      # https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/
      curl -sL http://localhost:32400/library/sections/1/refresh?X-Plex-Token=V2A98G4Arv5_wZTif4y6
      curl -sL http://localhost:32400/library/sections/2/refresh?X-Plex-Token=V2A98G4Arv5_wZTif4y6
      nb=$((nb+1))
    fi
  fi
done < <(curl "https://myfiles.alldebrid.com/$ALLDEBRID_TOKEN/$TYPE/$1" -skL | grep -oP '<a [^>]+>' |  grep -oP '"(.*)"' | sed "s/\"//g" | grep -ve "\.\./$")

if [ $nb -gt 0 ] && ls *.part*.rar 1>/dev/null 2>&1; then
  (
    curl https://api.pushover.net/1/messages.json --form-string "token=$PUSHOVER_TOKEN" --form-string "user=$PUSHOVER_USER" --form-string "title=ALLDEBRID UNRAR START" --form-string "message=$(pwd)" --form-string "url=$url"
    unar -f $(ls *.part*.rar | head -1) && rm *.rar
    curl -sL http://localhost:32400/library/sections/1/refresh?X-Plex-Token=V2A98G4Arv5_wZTif4y6
    curl -sL http://localhost:32400/library/sections/2/refresh?X-Plex-Token=V2A98G4Arv5_wZTif4y6
    curl https://api.pushover.net/1/messages.json --form-string "token=$PUSHOVER_TOKEN" --form-string "user=$PUSHOVER_USER" --form-string "title=ALLDEBRID UNRAR END" --form-string "message=$(pwd)" --form-string "url=$url"
  ) &
fi

if [ -z "$1" ]; then
  rm -f ${LOCKFILE}
fi

