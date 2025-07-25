#!/usr/bin/env bash

## Author  : Aditya Shakya (adi1090x)
## Github  : @adi1090x
#
## Applets : MPD (music)

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash

type="$HOME/.config/rofi/applets/type-5"
style='style-4.rasi'
theme="$type/$style"

LONGSTRING=""
SONGSTRING=""
SONGFILE=""
SONGDIR=""
COVERFILE=""
STREAMURL=""
OUTPUT_NAME=""
MPD_MUSIC_BASE="${HOME}/Music"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cd "${SCRIPT_DIR}"
# checking if MPD_HOST is set or exists in .bashrc
# if neither is set, will just go with defaults (which will fail if 
# password is set.) 
if [ "$MPD_HOST" == "" ];then
    export MPD_HOST=$(cat ${HOME}/.bashrc | grep MPD_HOST | awk -F '=' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' )
fi
if [ "$STREAMURL" == "" ];then
    export STREAMURL=$(cat ${HOME}/.bashrc | grep STREAMURL | awk -F '"' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi
if [ "$OUTPUT_NAME" == "" ];then
    export OUTPUT_NAME=$(cat ${HOME}/.bashrc | grep OUTPUT_NAME | awk -F '"' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi
if [ "$MPD_MUSIC_BASE" == "" ];then
    export MPD_MUSIC_BASE=$(cat ${HOME}/.bashrc | grep MPD_MUSIC_BASE | awk -F '"' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ "$MPD_MUSIC_BASE" == "" ];then
        MPD_MUSIC_BASE="${HOME}/Music"
    fi
fi

##############################################################################
# Create our cache
##############################################################################

if [ -z "${XDG_CACHE_HOME}" ];then
    export XDG_CACHE_HOME="${HOME}/.cache"
fi

ROFI_CACHE="${XDG_CACHE_HOME}/rofi"
if [ ! -d "${ROFI_CACHE}" ];then
    echo "Making cache directory"
    mkdir -p "${ROFI_CACHE}"
fi

dedupe_mpd_queue() {
  # Get the current playlist with position and file
  mapfile -t playlist < <(mpc --host "$MPD_HOST"  -f '%position%:%file%' playlist)

  declare -A seen
  declare -a new_playlist

  for entry in "${playlist[@]}"; do
    pos="${entry%%:*}"
    file="${entry#*:}"

    if [[ -z "${seen[$file]}" ]]; then
      seen["$file"]=1
      new_playlist+=("$file")
    fi
  done

  # Save the deduplicated playlist to a temp playlist
  mpc --host "$MPD_HOST"  clear
  for track in "${new_playlist[@]}"; do
    mpc --host "$MPD_HOST"  add "$track"
  done

  echo "Removed duplicates. New queue length: ${#new_playlist[@]}"
} 

# input filepath, title, artist, album
function get_cover_image (){
    local filepath="${1}"
    local title="${2}"
    local artist="${3}"
    local album="${4}"
    SONGFILE="${MPD_MUSIC_BASE}/${filepath}"
    SONGSTRING=$(echo "${artist} - ${album} - ${title}")
    # taking out any "feat etc in parentheses"
    SONGSTRING=$(echo "${SONGSTRING}" | sed -e 's/([^)]*)//g' )    
    SONGDIR=$(dirname "${SONGFILE}")
    bob=$(cat "${ROFI_CACHE}/songinfo")
    # TEST HERE; if it's the same, then bounce back
    if [[ "${SONGSTRING}" != "${bob}" ]]; then 
        SAME_SONG=0
        echo "${SONGSTRING}" > "${ROFI_CACHE}/songinfo"
        LONGSTRING=$(echo "${SONGSTRING}" | awk -F ' - ' '{print "🎤"$1" - 💿"$2" - 🎶"$3}')

        LYRICSFILE="${SONGFILE%.*}.lrc"
        if [ "$LYRICSFILE" == "" ] || [ ! -f "${LYRICSFILE}" ];then
            LYRICSFILE="${SONGFILE%.*}.txt"
            if [ "$LYRICSFILE" == "" ] || [ ! -f "${LYRICSFILE}" ];then
                # use the default cover in the script directory
                # So need a default lyrics file.... SCRIPT_DIR
                LYRICSFILE="${SCRIPT_DIR}/default_lyrics.md"
            fi
        else
            # lrc can have timestamps
            if [ ! -f "${SONGFILE%.*}.txt" ];then
                sed 's/\[.*\]//g' "${LYRICSFILE}" > "${SONGFILE%.*}.txt"
            fi
            LYRICSFILE="${SONGFILE%.*}.txt"
        fi
        if [ -f "${LYRICSFILE}" ];then
            cp -f "${LYRICSFILE}" "${ROFI_CACHE}/nowplaying.lyrics.md"
        else
            cp -f "$HOME/.config/rofi/applets/shared/default_lyrics.md" "${ROFI_CACHE}/nowplaying.lyrics.md"
        fi

        if [ -f "$SONGDIR"/folder.jpg ];then
            COVERFILE="$SONGDIR"/folder.jpg
        else
            if [ -f "$SONGDIR"/cover.jpg ];then
                COVERFILE="$SONGDIR"/cover.jpg
            fi
        fi
        if [ "$COVERFILE" == "" ];then
            COVERFILE=$(printf "%s\n" "$HOME/.config/rofi/images/j.jpg" "$HOME/.config/rofi/images/b.png" "$HOME/.config/rofi/images/a.png" | shuf -n1)
        fi
        convert "${COVERFILE}" -resize "900x900" "${ROFI_CACHE}/nowplaying.album.png"
    else
        SAME_SONG=1
    fi    
 }
 
 now_album(){
    local album=""
    artist=$(mpc --host "$MPD_HOST" current --format "%artist%")
    album=$(mpc --host "$MPD_HOST" current --format "%album%")
    if [[ -z "$artist" || -z "$album" ]]; then
        echo "No song is currently playing."
    else
        mpc --host "$MPD_HOST" clear -q
        mpc --host "$MPD_HOST" search album "${album}" | mpc add
        mpc --host "$MPD_HOST" play
    fi
}
    
now_artist(){
    local album_artist=""
    album_artist=$(mpc --host "$MPD_HOST" current --format "%albumartist%")
    if [[ -z "$album_artist" ]]; then
        albumartist=$(mpc --host "$MPD_HOST" current --format "%artist%")
    fi
    if [[ -z "$album_artist" ]]; then
        echo "No song is currently playing or no album artist information available."
    else
        mpc --host "$MPD_HOST" clear -q
        mpc --host "$MPD_HOST" search albumartist "${album_artist}" | mpc add
        mpc --host "$MPD_HOST" play
    fi
}   
 
  now_genre(){
    local genre=""
    genre=$(mpc --host "$MPD_HOST" current --format "%genre%")
    if [[ -z "$genre" ]]; then
        echo "No song is currently playing."
    else
        mpc --host "$MPD_HOST" clear -q
        mpc --host "$MPD_HOST" search genre "${genre}" | mpc add
        mpc --host "$MPD_HOST" play
    fi
}

show_tools() {
    
    # no dupes
    # add_replace album
    # add_replace artist
    # add_replace genre
    # nowtags
    option_sub1="Dedupe"
    option_sub2="Add Album"
    option_sub3="Add Artist"
    option_sub4="Add Genre"
    option_sub5="Nowtags"
    option_sub6="Playlist"
    style='style-6.rasi'
    theme="$type/$style"
    
    prompt=$(cat "${ROFI_CACHE}/songinfo")
    choice=$(echo -e "$option_sub1\n$option_sub2\n$option_sub3\n$option_sub4\n$option_sub5\n$option_sub6" | \
        rofi -theme-str "listview {columns: 2; lines: 1;}" \
                -theme-str 'textbox-prompt-colon {str: "";}' \
                -dmenu \
                -p "${prompt}" \
                -mesg "${mesg}" \
                ${active}  \
                -markup-rows \
                -theme ${theme} )

    
 
    case ${choice} in
    $option_sub1)
                dedupe_mpd_queue
        ;;
    $option_sub2)
                now_album
        ;;
    $option_sub3)
                now_artist
        ;;
    $option_sub4)
                now_genre
        ;;
    $option_sub5)
                nowtrack=$("${HOME}"/.config/rofi/applets/bin/edit_current_mp3tags.sh);QT_STYLE_OVERRIDE=qt5ct-style puddletag "${nowtrack}"
        ;;
    $option_sub6)
                choice=$(mpc --host "$MPD_HOST" lsplaylists | \
                rofi -theme-str "listview {columns: 2; lines: 1;}" \
                -theme-str 'textbox-prompt-colon {str: "";}' \
                -dmenu \
                -p "${prompt}" \
                -mesg "${mesg}" \
                ${active}  \
                -markup-rows \
                -theme ${theme} )
                notify-send "${choice}"
                if [ "${choice}" != "" ];then
                    mpc clear
                    while IFS= read -r playlist; do
                        mpc --host "$MPD_HOST" load "$playlist" 
                        mpc --host "$MPD_HOST" play
                    done <<< "$choice"
                fi                
        ;;        
    esac
    
    
    # return us back
    ( $HOME/.config/rofi/applets/bin/mpd.sh ) &
    exit

}

show_info() {
    style='style-5.rasi'
    theme="$type/$style"
    prompt=$(cat "${ROFI_CACHE}/songinfo")   
    head -n 37 "${ROFI_CACHE}/nowplaying.lyrics.md" | \
    rofi -theme-str "listview {columns: 1; lines: 37;}" \
        -theme-str 'textbox-prompt-colon {str: "";}' \
        -dmenu \
        -p "${prompt}" \
        ${active} ${urgent} \
        -markup-rows \
        -theme ${theme}
    # so it takes you "back" when done
    ( $HOME/.config/rofi/applets/bin/mpd.sh ) &
    exit
}

# Theme Elements
status=$(mpc --host "$MPD_HOST" status  --format "%artist%§%album%§%title%§%file%" | sed 's/&/and/g')
    myartist=$(echo "$status" | head -n1 | awk -F '§' '{print $1}')
    myalbum=$(echo "$status" | head -n1 | awk -F '§' '{print $2}')
    mytitle=$(echo "$status" | head -n1 | awk -F '§' '{print $3}')
    myfile=$(echo "$status" | head -n1 | awk -F '§' '{print $4}')
if [[ -z "$status" ]]; then
        prompt='Offline'
        mesg="MPD is Offline"
else
        prompt=$(echo "${mytitle}")
        mesg=$(echo "by ${myartist} on ${myalbum}")
fi

if [[ ( "$theme" == *'type-1'* ) || ( "$theme" == *'type-3'* ) || ( "$theme" == *'type-5'* ) ]]; then
        list_col='2'
        list_row='6'
elif [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
        list_col='6'
        list_row='2'
fi

# Options
layout=`cat ${theme} | grep 'USE_ICON' | cut -d'=' -f2`
if [[ "$layout" == 'NO' ]]; then
            if [[ ${status} == *"[playing]"* ]]; then
                    option_1=" Pause"
            else
                    option_1=" Play"
            fi
        option_2=" Stop"
        option_3=" Previous"
        option_4=" Next"
        option_5=" Repeat"
        option_6=" Random"
        option_7="⚒️ Tools"
        option_8="👍 Like"
        option_9="📜 info"
        option_10="📡 snapserver"
        option_11="📻 radio"
        option_12="🗑️ consume"
else
        if [[ ${status} == *"[playing]"* ]]; then
                option_1=""
        else
                option_1=""
        fi
        option_2=""
        option_3=""
        option_4=""
        option_5=""
        option_6=""
        option_7="⚒️"
        option_8="👍"
        option_9="📜"
        option_10="📡"
        option_11="📻"
        option_12="🗑️"
fi

# Toggle Actions
active=''
urgent=''
# Liked
liked=$(mpc --host "$MPD_HOST" sticker "${myfile}" get like 2>/dev/null| awk -F '=' '{print $2}')  
if [[ "${liked}" == "2" ]];then
    active="-a 7"
fi
# Repeat
if [[ ${status} == *"repeat: on"* ]]; then
    active="-a 4"
elif [[ ${status} == *"repeat: off"* ]]; then
    urgent="-u 4"
else
    option_5=" Parsing Error"
fi
# Random
if [[ ${status} == *"random: on"* ]]; then
    [ -n "$active" ] && active+=",5" || active="-a 5"
elif [[ ${status} == *"random: off"* ]]; then
    [ -n "$urgent" ] && urgent+=",5" || urgent="-u 5"
else
    option_6=" Parsing Error"
fi

# Snapcast
if [ $(mpc --host "$MPD_HOST" outputs | grep "${OUTPUT_NAME}" | grep -c "is enabled") -eq 1 ];then
        [ -n "$active" ] && active+=",9" || active="-a 9"
fi

# radio
mplayer_PID=$(ps aux | grep -v "grep" | grep -e "play ${STREAMURL}" | awk '{ print $2 }')
if [[ $mplayer_PID -gt 0 ]];then 
    [ -n "$active" ] && active+=",10" || active="-a 10"
fi

# Consume
if [[ ${status} == *"consume: on"* ]]; then
    [ -n "$active" ] && active+=",11" || active="-a 11"
elif [[ ${status} == *"consume: off"* ]]; then
    [ -n "$urgent" ] && urgent+=",11" || urgent="-u 11"
else
    option_12=" Parsing Error"
fi
# getting, updating cover image
get_cover_image "${myfile}" "${mytitle}" "${myartist}" "${myalbum}"



# Rofi CMD
rofi_cmd() { 
        rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
                -theme-str 'textbox-prompt-colon {str: "";}' \
                -dmenu \
                -p "${prompt}" \
                -mesg "${mesg}" \
                ${active} ${urgent} \
                -markup-rows \
                -theme ${theme}
}

# Pass variables to rofi dmenu
run_rofi() {
        echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6\n$option_7\n$option_8\n$option_9\n$option_10\n$option_11\n$option_12" | rofi_cmd
}

# Execute Command
run_cmd() {
        if [[ "$1" == '--opt1' ]]; then
                mpc --host "$MPD_HOST"  -q toggle && notify-send -u low -t 1000 " `mpc --host "$MPD_HOST"  current`"
        elif [[ "$1" == '--opt2' ]]; then
                mpc --host "$MPD_HOST"  -q stop
        elif [[ "$1" == '--opt3' ]]; then
                mpc --host "$MPD_HOST"  -q prev && notify-send -u low -t 1000 " `mpc --host "$MPD_HOST"  current`"
        elif [[ "$1" == '--opt4' ]]; then
                mpc --host "$MPD_HOST"  -q next && notify-send -u low -t 1000 " `mpc --host "$MPD_HOST"  current`"
        elif [[ "$1" == '--opt5' ]]; then
                mpc --host "$MPD_HOST"  -q repeat
        elif [[ "$1" == '--opt6' ]]; then
                mpc --host "$MPD_HOST"  -q random
        elif [[ "$1" == '--opt7' ]]; then
                show_tools
        elif [[ "$1" == '--opt8' ]]; then
                myfile=$(mpc --host "$MPD_HOST" current --format %file%)
                liked=$(mpc --host "$MPD_HOST"  sticker "${myfile}" get like 2>/dev/null| awk -F '=' '{print $2}') 
                # We are using myMPD's version of "like"
                if [ "$liked" == "2" ];then
                    mpc --host "$MPD_HOST"  sticker "${myfile}" set like 1
                else
                    mpc --host "$MPD_HOST"  sticker "${myfile}" set like 2
                fi
        elif [[ "$1" == '--opt9' ]]; then
                show_info
        elif [[ "$1" == '--opt10' ]]; then
                enabled=$(mpc --host "$MPD_HOST" outputs | grep "${OUTPUT_NAME}" | grep -c enabled)
                if [ $enabled -gt 0 ];then
                    mpc --host "$MPD_HOST" disable "${OUTPUT_NAME}"
                else
                    mpc --host "$MPD_HOST"   enable "${OUTPUT_NAME}"
                fi
        elif [[ "$1" == '--opt11' ]]; then
                mplayer_PID=$(ps aux | grep -v "grep" | grep -e "play https://.*/mpd.mp3" | awk '{ print $2 }')

                if [[ $mplayer_PID -gt 0 ]];then 
                    notify-send --icon radio "Ending stream"
                    kill $mplayer_PID
                    # this is needed so it doesn't accidentally say it's up when it's just been switched off
                    sleep 1
                else
                    notify-send --icon radio "Beginning stream"
                    nohup /usr/bin/play "${STREAMURL}" >/dev/null 2>&1 &
                fi
                
        elif [[ "$1" == '--opt12' ]]; then
                mpc --host "$MPD_HOST"  -q consume
        fi
        
    # so it takes you "back" when done
    ( $HOME/.config/rofi/applets/bin/mpd.sh ) &
    exit

}


# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $option_1)
                run_cmd --opt1
        ;;
    $option_2)
                run_cmd --opt2
        ;;
    $option_3)
                run_cmd --opt3
        ;;
    $option_4)
                run_cmd --opt4
        ;;
    $option_5)
                run_cmd --opt5
        ;;
    $option_6)
                run_cmd --opt6
        ;;
    $option_7)
                run_cmd --opt7
        ;;
    $option_8)
                run_cmd --opt8
        ;;
    $option_9)
                run_cmd --opt9
        ;;                      
    $option_10)
                run_cmd --opt10
        ;;
    $option_11)
                run_cmd --opt11
        ;;
    $option_12)
                run_cmd --opt12
        ;;
esac
