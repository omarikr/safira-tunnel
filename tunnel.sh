aLSO how'd i configure this
#!/bin/bash

# TunnelBeam - Lightweight SSH reverse port forwarder with CLI commands

REMOTE_SERVER="tunnel.flexnodes.uk"
REMOTE_USER="root"
REMOTE_PORT="65535"

LOG_DIR="/tmp/tbeam_logs"
mkdir -p "$LOG_DIR"

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'

print_usage() {
    echo -e "${BOLD}TunnelBeam - SSH Reverse Tunnel Tool${RESET}"
    echo -e "${CYAN}Usage:${RESET} $0 <action> [arguments]\n"
    echo "Available actions:"
    echo -e "  ${CYAN}start <local_port>${RESET}        Open a tunnel from your localhost"
    echo -e "  ${CYAN}status${RESET}                  View active tunnels"
    echo -e "  ${CYAN}stop <pid>${RESET}             Terminate a specific tunnel"
    echo -e "  ${CYAN}stop-all${RESET}               Terminate all running tunnels"
    echo -e "  ${CYAN}help${RESET}                   Show this help message"
    echo
}

generate_remote_port() {
    echo $(( RANDOM % 50000 + 10000 ))
}

start_tunnel() {
    local_port=$1

    if ! [[ "$local_port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error:${RESET} Local port must be a number."
        exit 1
    fi

    remote_port=$(generate_remote_port)
    log_file="${LOG_DIR}/tunnel_${remote_port}.log"

    echo "[*] Starting tunnel: localhost:${local_port} -> ${REMOTE_SERVER}:${remote_port}"
    echo "[*] Log: ${log_file}"

    nohup ssh -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 \
        -N -R ${remote_port}:localhost:${local_port} \
        ${REMOTE_USER}@${REMOTE_SERVER} -p ${REMOTE_PORT} &> "$log_file" &

    sleep 1
    pid=$!

    if ps -p $pid > /dev/null; then
        echo -e "${GREEN}[+] Tunnel active.${RESET} PID: $pid, URL: http://${REMOTE_SERVER}:${remote_port}"
    else
        echo -e "${RED}[-] Tunnel failed to start.${RESET} Check log: $log_file"
        [ ! -s "$log_file" ] && rm "$log_file"
    fi
}

list_tunnels() {
    matches=$(pgrep -af "ssh.*-R.*${REMOTE_SERVER}")
    if [[ -z "$matches" ]]; then
        echo -e "${GREEN}[✓] No active tunnels.${RESET}"
        return
    fi

    echo -e "${BOLD}PID    Remote Port    Local Port${RESET}"
    echo "$matches" | while read -r line; do
        pid=$(echo "$line" | awk '{print $1}')
        rport=$(echo "$line" | sed -n 's/.*-R \([0-9]*\):.*/\1/p')
        lport=$(echo "$line" | sed -n 's/.*localhost:\([0-9]*\).*/\1/p')
        echo -e "$pid    $rport            $lport"
    done
}

stop_tunnel() {
    pid=$1
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error:${RESET} Invalid PID."
        exit 1
    fi

    if ps -p $pid > /dev/null; then
        kill $pid
        echo -e "${GREEN}[✓] Tunnel process $pid terminated.${RESET}"
    else
        echo -e "${RED}[-] No process with PID $pid found.${RESET}"
    fi
}

stop_all_tunnels() {
    pids=$(pgrep -f "ssh.*-R.*${REMOTE_SERVER}")
    if [[ -z "$pids" ]]; then
        echo -e "${GREEN}[✓] No active tunnels to stop.${RESET}"
        return
    fi

    echo "[!] The following tunnels will be stopped:"
    pgrep -af "ssh.*-R.*${REMOTE_SERVER}"
    read -p "Proceed? (y/N): " confirm
    if [[ "$confirm" =~ ^[yY]$ ]]; then
        kill $pids
        echo -e "${GREEN}[✓] All tunnels terminated.${RESET}"
    else
        echo -e "${CYAN}[-] Operation cancelled.${RESET}"
    fi
}

# --- Dispatch CLI Actions ---

cmd=$1
shift

case "$cmd" in
    start)
        start_tunnel "$@"
        ;;
    status)
        list_tunnels
        ;;
    stop)
        stop_tunnel "$@"
        ;;
    stop-all)
        stop_all_tunnels
        ;;
    help|"")
        print_usage
        ;;
    *)
        echo -e "${RED}Unknown command:${RESET} $cmd"
        print_usage
        ;;
esac
to a vps and run the ssh of a dhcp vps
and also what to rename this file
