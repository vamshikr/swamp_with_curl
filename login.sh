#! /bin/bash

readonly SWAMP_URL="https://swampiab3.local"
readonly SWAMP_API_SERVER="$SWAMP_URL/swamp-web-server/public"

# Fill in these SWAMP_USER, SWAMP_PASSWORD
readonly SWAMP_USER=
readonly SWAMP_PASSWORD=
readonly COOKIE_JAR="csa-cookie-jar.txt"


function die {
    echo "$@"
    exit 1;
}

if [[ -z "$SWAMP_USER" || -z "$SWAMP_PASSWORD" ]]; then
   die "Fill in SWAMP_USER, SWAMP_PASSWORD"
fi

function is_os_mac {
	[[ "$(uname -s)" == "Darwin" ]]
}

function check_config {

    local URL="$SWAMP_URL/config/config.json"
    local SED_REGEX="-r"

    is_os_mac && SED_REGEX="-E"
    
    local API_URL=$(curl --silent --insecure -f "$URL" | sed -n "$SED_REGEX" 's@"web".+"([^"]+)"@\1@p' | tr -d '[:space:]')

    
    if [[ "$API_URL" != "$SWAMP_API_SERVER" ]]; then
        die "api server has a different url"
    fi
    
}

function login {
    local LOGIN_URL="$SWAMP_API_SERVER/login"
    local USER_INFO="user_info.txt"

    printf "\n****** Tying SWAMP login ******\n"
    
    local http_code=$(curl --silent \
                           -f \
                           -c "$COOKIE_JAR" \
                           -H "Content-Type: application/json; charset=UTF-8" \
                           -w "%{http_code}\n" \
                           -X POST \
                           -o "$USER_INFO" \
                           -d "{\"username\":\"$SWAMP_USER\",\"password\":\"$SWAMP_PASSWORD\"}" \
                           "$LOGIN_URL")

    if [[ "$http_code" == 200 ]]; then
        echo "SWAMP login successful"
        cat "$USER_INFO"
    else
        echo "SWAMP login failed"
    fi

    # for function return value
    [[ "$http_code" == 200 ]]
}

function user_info {
    local INFO_URL="$SWAMP_API_SERVER/users/current"
    local USER_INFO="user_info_detailed.txt"

    printf "\n****** Getting SWAMP User info ******\n"
    
    local http_code=$(curl --silent \
                           -f \
                           -b "$COOKIE_JAR" \
                           -c "$COOKIE_JAR" \
                           -H "Content-Type: application/json; charset=UTF-8" \
                           -w "%{http_code}\n" \
                           -o "$USER_INFO" \
                           "$INFO_URL")

    if [[ "$http_code" == 200 ]]; then
        echo "SWAMP user info:"
        cat "$USER_INFO"
    else
        echo "SWAMP user info call failed"
    fi

    # for function return value
    [[ "$http_code" == 200 ]]
}

function main {
    check_config
    login && user_info
    
}

#set -x;

main $@
