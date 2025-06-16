#!/bin/bash

# === vpn sh1t helpers ===
NORDVPN_SECURE_SERVER_GROUPS=("Onion_Over_VPN" "Double_VPN")
NORDVPN_SELECTED_SERVER_GROUP=$(printf "%s\n" "${NORDVPN_SECURE_SERVER_GROUPS[@]}" | shuf -n1)
NORDVPN_STATUS_COMMAND="nordvpn status | grep 'Status:' | grep -q 'Connected' && echo connected || echo disconnected"
NORDVPN_CONNECT_COMMAND="nordvpn connect -g $NORDVPN_SELECTED_SERVER_GROUP"

# === get the args from command line ===
SSH_ARGS=("$@")

# === get the vpn status ===
VPN_STATUS=$(eval "$NORDVPN_STATUS_COMMAND")

if [ $# -eq 0 ]; then
    echo -e "\n[!] Nord-SSH is a utility to check if you're connected on your VPN before proceeding with ssh connections."
    echo ""
    echo "When used and NO VPN CONNECTION is identified, this utility allows you to choose between 3 options:"
    echo "  1 - Proceed with my fucking SSH connection"
    echo "  2 - DO NOT proceed with my fucking ssh connection, abort this shit"
    echo "  3 - Connect to NordVPN and proceed with my fucking ssh connection"
    echo ""
    echo "How to use: "
    echo "  $(basename "$0") root@192.168.0.1 <any ssh additional argument>"
    exit 1
else
    if [ "$VPN_STATUS" = "connected" ]; then
        echo "[✓] NordVPN is connected, proceeding with ssh connection..."
        ssh "${SSH_ARGS[@]}"
        exit $?
    else
        echo -e "\n[!] NordVPN is NOT connected."
        echo "Choose option:"
        echo "  1 - Proceed with my fucking SSH connection"
        echo "  2 - DO NOT proceed with my fucking ssh connection, abort this shit"
        echo "  3 - Connect to NordVPN and proceed with my fucking ssh connection"

        read -rp "Type the option number [1/2/3]: " option

        case "$option" in
            1)
                echo "[!] Proceeding even without VPN (you're dumb?)."
                ssh "${SSH_ARGS[@]}"
                exit $?
                ;;
            2)
                echo "[✗] Aborting SSH Connection."
                exit 1
                ;;
            3)
                echo "[~] Trying to connect to NordVPN with $NORDVPN_SELECTED_SERVER_GROUP..."
                eval "$NORDVPN_CONNECT_COMMAND"
                echo
                echo "[~] Checking NordVPN Connection..."
                exec "$0" "${SSH_ARGS[@]}"
                ;;
            *)
                echo "[!] An idiot chose an unknown option, aborting"
                exit 1
                ;;
        esac
    fi
fi
