#!/bin/sh

# update_gfwlist.sh

set -o errexit

SOCKS5="127.0.0.1:1080"

WGET="/usr/bin/wget"
GFWLIST_URL="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
GFWLIST_FILE="/tmp/gfwlist.txt"

PROXYCHAINS4_CONFIG="/ttrss_privoxy/proxychains.conf"
PROXYCHAINS4="/usr/bin/proxychains4 -f $PROXYCHAINS4_CONFIG -q"

GFWLIST2PRIVOXY="/usr/local/bin/gfwlist2privoxy"

PRIVOXY_GFW_ACTION_TEMP="/tmp/gfw.action.new"
PRIVOXY_GFW_ACTION="/etc/privoxy/gfw.action"

function get_gfw_action {
    printf "download %s ...... " "$GFWLIST_URL"
    $PROXYCHAINS4 $WGET -q -O $GFWLIST_FILE $GFWLIST_URL
    #$WGET -q -O $GFWLIST_FILE $GFWLIST_URL
    echo "ok"
    printf "convert %s to %s ... " "$GFWLIST_FILE" "$PRIVOXY_GFW_ACTION_TEMP"
    $GFWLIST2PRIVOXY -i $GFWLIST_FILE -f $PRIVOXY_GFW_ACTION_TEMP -p $SOCKS5 -t socks5
    echo "ok"
}

function replace_gfw_action {
    local old_md5=""
    local new_md5=""
    if [[ -s $PRIVOXY_GFW_ACTION ]]; then
        old_md5=$(sed 1,2d "$PRIVOXY_GFW_ACTION" | md5sum | awk '{print $1}')
    fi
    new_md5=$(sed 1,2d "$PRIVOXY_GFW_ACTION_TEMP" | md5sum | awk '{print $1}')
    echo "old md5sum: [$old_md5]"
    echo "new md5sum: [$new_md5]"
    if [[ "x$old_md5" = "x$new_md5" ]]; then
        echo "no need to update"
    else
        echo "mv $PRIVOXY_GFW_ACTION_TEMP to $PRIVOXY_GFW_ACTION"
        mv $PRIVOXY_GFW_ACTION_TEMP $PRIVOXY_GFW_ACTION
        # echo "reload privoxy"
        # /usr/sbin/service privoxy force-reload
    fi
    rm -f $GFWLIST_FILE
}

function main {
    get_gfw_action
    if [[ -s $PRIVOXY_GFW_ACTION_TEMP ]]; then
        replace_gfw_action
        echo "Done."
    else
        echo "$PRIVOXY_GFW_ACTION_TEMP is empty."
        echo "Error."
    fi
}

main