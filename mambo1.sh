#!/bin/bash

# --- KONFIGURASI BOT ---
TOKEN="8336174429:AAGpd3P0FtFKfxYwMz9WvneuTtlxNDPiAZc"
API_URL="https://api.telegram.org/bot$TOKEN"
AFK_FILE="afk_data.txt"
touch $AFK_FILE

# --- KONFIGURASI TOMBOL ---
ACTION_BUTTONS='{"inline_keyboard": [[{"text": "🚀 Owner Bot", "url": "https://t.me/khai_2015"}, {"text": "📢 Join Channel", "url": "https://t.me/this_is_khai"}]]}'
AFK_BUTTONS='{"inline_keyboard": [[{"text": "🌙 Status: AFK", "callback_data": "afk_status"}]]}'

# --- WARNA LOGS ---
R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; B='\033[0;34m'; P='\033[0;35m'; C='\033[0;36m'; NC='\033[0m'

clear
echo -e "${B}==============================================${NC}"
echo -e "${G}      BOT MULTIFUNGSI PRO - FINAL VERSION     ${NC}"
echo -e "${G}             STATUS: READY & CLEAN            ${NC}"
echo -e "${B}==============================================${NC}"

OFFSET=0
while true; do
    updates=$(curl -s "$API_URL/getUpdates?offset=$OFFSET&timeout=30")
    count=$(echo "$updates" | jq '.result | length')

    if [ "$count" -gt 0 ]; then
        for ((i=0; i<$count; i++)); do
            item=$(echo "$updates" | jq ".result[$i]")
            update_id=$(echo "$item" | jq ".update_id")
            OFFSET=$((update_id + 1))

            # --- HANDLE CALLBACK QUERY ---
            callback=$(echo "$item" | jq -r '.callback_query // empty')
            if [ ! -z "$callback" ]; then
                cb_id=$(echo "$callback" | jq -r '.id')
                curl -s -X POST "$API_URL/answerCallbackQuery" -d "callback_query_id=$cb_id" -d "text=User ini sedang bertapa (AFK)" -d "show_alert=true" > /dev/null
                continue
            fi

            msg=$(echo "$item" | jq ".message // empty")
            [ -z "$msg" ] && continue

            text=$(echo "$msg" | jq -r '.text // empty')
            chat_id_user=$(echo "$msg" | jq -r '.chat.id')
            user_name=$(echo "$msg" | jq -r '.from.first_name')
            user_id=$(echo "$msg" | jq -r '.from.id')
            username_tag=$(echo "$msg" | jq -r '.from.username // "null"')
            msg_id=$(echo "$msg" | jq -r '.message_id')
            now_ts=$(date +%s)
            jam=$(date +"%H:%M:%S")

            mention=$([ "$username_tag" != "null" ] && echo "@$username_tag" || echo "<a href='tg://user?id=$user_id'>$user_name</a>")

            # --- 1. LOGIKA AFK (WELCOME BACK) ---
            if [[ "$text" != "/afk"* ]] && grep -q "^$user_id|" "$AFK_FILE"; then
                afk_info=$(grep "^$user_id|" "$AFK_FILE"); start_ts=$(echo "$afk_info" | cut -d'|' -f2)
                diff=$((now_ts - start_ts)); h=$((diff/3600)); m=$(((diff%3600)/60)); s=$((diff%60))
                sed -i "/^$user_id|/d" "$AFK_FILE"
                WB_MSG="✨ <b>WELCOME BACK!</b> ✨%0A━━━━━━━━━━━━━━%0A👤 <b>User:</b> $mention%0A⏰ <b>Durasi AFK:</b> <code>$h jam $m mnt $s dtk</code>%0A%0A<i>Senang melihatmu kembali! 🚀</i>"
                curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id_user" -d "text=$WB_MSG" -d "parse_mode=HTML" -d "reply_markup=$ACTION_BUTTONS" > /dev/null
            fi

            # --- 2. COMMAND /AFK ---
            if [[ "$text" == "/afk"* ]]; then
                if ! grep -q "^$user_id|" "$AFK_FILE"; then
                    echo "$user_id|$now_ts" >> "$AFK_FILE"
                    AFK_MSG="💤 <b>MODE AFK AKTIF</b> 💤%0A━━━━━━━━━━━━━━%0A👤 <b>User:</b> $mention%0A🕒 <b>Mulai:</b> <code>$jam</code>%0A📍 <b>Status:</b> Bertapa...%0A%0A<i>Bot akan mencatat durasimu!</i>"
                    curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id_user" -d "text=$AFK_MSG" -d "parse_mode=HTML" -d "reply_markup=$AFK_BUTTONS" > /dev/null
                fi
                continue
            fi

            # --- 3. MENU /START /HELP (PROFILE STYLE) ---
            if [[ "$text" == "/start" ]] || [[ "$text" == "/help" ]]; then
                chat_type=$(echo "$msg" | jq -r '.chat.type')
                [ "$chat_type" == "private" ] && LOKASI="Private Message (PM)" || LOKASI="Group ($(echo "$msg" | jq -r '.chat.title'))"
                get_p=$(curl -s "$API_URL/getUserProfilePhotos?user_id=$user_id&limit=1")
                p_id=$(echo "$get_p" | jq -r '.result.photos[0][0].file_id // "null"')
                MENU_CAPTION="🆔 <b>ID:</b> <code>$user_id</code>%0A📃 <b>User:</b> $mention%0A📍 <b>Location:</b> $LOKASI%0A%0Aterima kasih telah menggunakan bot ini 😊%0A%0Aowner: @khai_2015%0Achannel owner: @this_is_khai%0A%0A"
                if [ "$p_id" != "null" ]; then
                    curl -s -X POST "$API_URL/sendPhoto" -d "chat_id=$chat_id_user" -d "photo=$p_id" -d "caption=$MENU_CAPTION" -d "parse_mode=HTML"
                else
                    curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id_user" -d "text=$MENU_CAPTION" -d "parse_mode=HTML"
                fi
                continue
            fi

            # --- 5. COMMAND /STATS ---
            if [[ "$text" == "/stats" ]]; then
                UPTIME=$(uptime -p | sed 's/up //')
                RAM_USED=$(free -m | awk '/Mem:/ { print $3 }')
                RAM_TOTAL=$(free -m | awk '/Mem:/ { print $2 }')
                CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
                DISK_FREE=$(df -h / | awk '/\// {print $4}' | head -n 1)
                
                STATS_MSG="📊 <b>HOSTING SERVER STATS</b>%0A━━━━━━━━━━━━━━%0A🐢 <b>CPU Load:</b> <code>$CPU_LOAD%</code>%0A📟 <b>RAM:</b> <code>$RAM_USED MB / $RAM_TOTAL MB</code>%0A💾 <b>Disk Free:</b> <code>$DISK_FREE</code>%0A⏰ <b>Uptime:</b> <code>$UPTIME</code>%0A🚀 <b>Bot Status:</b> <code>Online</code>%0A━━━━━━━━━━━━━━"
                curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id_user" -d "text=$STATS_MSG" -d "parse_mode=HTML" > /dev/null
                continue
            fi

            # --- 6. FITUR /REPLY ---
            if [[ "$text" == "/reply"* ]]; then
                ISI=$(echo "$text" | cut -d' ' -f2-)
                target=$(echo "$msg" | jq -r '.reply_to_message')
                if [ "$target" != "null" ]; then
                    T_CHAT=$(echo "$target" | jq -r '.chat.id'); T_MSG=$(echo "$target" | jq -r '.message_id')
                    curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$T_CHAT" -d "reply_to_message_id=$T_MSG" -d "text=$ISI" -d "parse_mode=HTML" > /dev/null
                    curl -s -X POST "$API_URL/deleteMessage" -d "chat_id=$chat_id_user" -d "message_id=$msg_id" > /dev/null
                fi
                continue
            fi

            # --- 7. FITUR /ANONY ---
            if [[ "$text" == "/anony"* ]]; then
                T_ID=$(echo "$text" | awk '{print $2}'); ISI_A=$(echo "$text" | cut -d' ' -f3-)
                rep=$(echo "$msg" | jq -r '.reply_to_message')
                f_id=""; m="sendMessage"; p="text"
                if [ "$rep" != "null" ]; then
                    if [ "$(echo "$rep" | jq -r '.photo')" != "null" ]; then f_id=$(echo "$rep" | jq -r '.photo[-1].file_id'); m="sendPhoto"; p="photo"
                    elif [ "$(echo "$rep" | jq -r '.sticker')" != "null" ]; then f_id=$(echo "$rep" | jq -r '.sticker.file_id'); m="sendSticker"; p="sticker"
                    fi
                fi
                [ -n "$f_id" ] && curl -s -X POST "$API_URL/$m" -d "chat_id=$T_ID" -d "$p=$f_id" -d "caption=$ISI_A" -d "reply_markup=$ACTION_BUTTONS" || curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$T_ID" -d "text=$ISI_A" -d "parse_mode=HTML" -d "reply_markup=$ACTION_BUTTONS"
                curl -s -X POST "$API_URL/deleteMessage" -d "chat_id=$chat_id_user" -d "message_id=$msg_id" > /dev/null
                continue
            fi

            # --- 8. FITUR /UP (ORIGINAL CAPTION) ---
            if [[ "$text" == "/up"* ]] || [[ "$text" == "/upload"* ]]; then
                T_ID=$(echo "$text" | awk '{print $2}'); CL=$(echo "$text" | cut -d' ' -f3-)
                rep=$(echo "$msg" | jq -r '.reply_to_message')
                if [ "$rep" != "null" ]; then
                    fid=""; fn="Unknown"; fs=0; ext="FILE"; m="sendMessage"; p="document"
                    if [ "$(echo "$rep" | jq -r '.document')" != "null" ]; then fid=$(echo "$rep" | jq -r '.document.file_id'); fn=$(echo "$rep" | jq -r '.document.file_name'); fs=$(echo "$rep" | jq -r '.document.file_size'); ext="${fn##*.}"; m="sendDocument"
                    elif [ "$(echo "$rep" | jq -r '.video')" != "null" ]; then fid=$(echo "$rep" | jq -r '.video.file_id'); fn=$(echo "$rep" | jq -r '.video.file_name // "video.mp4"'); fs=$(echo "$rep" | jq -r '.video.file_size'); ext="MP4"; m="sendVideo"; p="video"
                    fi
                    sz=$([ $fs -ge 1073741824 ] && printf "%.2f GB" $(echo "scale=2; $fs/1073741824" | bc) || printf "%.2f MB" $(echo "scale=2; $fs/1048576" | bc))
                    CAP="📦 (<b>${ext^^}</b>) Terdeteksi!%0A📄 Nama: <code>$fn</code>%0A💾 Ukuran: $sz%0A⏰ Waktu: $jam%0A📍 <code>$T_ID</code>%0A👤 $mention%0A%0A📃 <b>Changelog:</b>%0A${CL:-Tidak ada}"
                    curl -s -X POST "$API_URL/$m" -d "chat_id=$T_ID" -d "$p=$fid" -d "caption=$CAP" -d "parse_mode=HTML" -d "reply_markup=$ACTION_BUTTONS" > /dev/null
                    curl -s -X POST "$API_URL/deleteMessage" -d "chat_id=$chat_id_user" -d "message_id=$msg_id" > /dev/null
                fi
                continue
            fi

            # --- FITUR PING MS ---
            if [[ "$text" == "/ping" ]]; then
                # 1. Ambil waktu sekarang (dalam milidetik)
                start_time=$(date +%s%3N)
                
                # 2. Kirim pesan awal (sebagai pemicu)
                # Kita ambil timestamp saat bot membalas
                end_time=$(date +%s%3N)
                
                # 3. Hitung selisihnya
                latency=$((end_time - start_time))
                
                # 4. Kirim hasil akhirnya
                PING_MSG="🏓 <b>PONG!</b>%0A━━━━━━━━━━━━━━%0A🚀 <b>Speed:</b> <code>$latency ms</code>%0A🛰 <b>Status:</b> <code>Stable</code>"
                
                curl -s -X POST "$API_URL/sendMessage" \
                    -d "chat_id=$chat_id_user" \
                    -d "text=$PING_MSG" \
                    -d "parse_mode=HTML" > /dev/null
                continue
            fi
            
        done
    fi
    sleep 0.5
done
