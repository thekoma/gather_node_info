#!/bin/bash
ENVIRONMENT="virtual" # physical|virtual

command -v bc >/dev/null 2>&1 || { echo >&2 "Serve BC per continuare (yum install -y bc)"; exit 99; }
oc whoami >/dev/null 2>&1 || { echo >&2 "Non sei collegato ad un server esegui il login (oc login)"|tee $LOG; exit 100; }
LOG="$(mktemp -d)/out.log"
echo "Output verrà salvato in $LOG"
echo "Sei collegato come $(oc whoami) al server $(oc whoami --show-server)"|tee -a $LOG

function calc_mem() {
    kind=${1:-worker}
    if [ "$(oc get nodes -l node-role.kubernetes.io/${kind}='' 2>/dev/null|wc -l)" -eq 0 ]; then
        echo 0
    else
        workers="$(oc get nodes -o=jsonpath='{.items[*].status.capacity.memory}' -l node-role.kubernetes.io/${kind}='')"
        workers_Ki=$(echo "${workers//Ki/+}0"|bc)
        workers_Gi=$(echo "${workers_Ki}/1024/1024"|bc)
        echo "$workers_Gi"
    fi
}

function calc_cpu() {
    kind=${1:-worker}
    if [ "$(oc get nodes -l node-role.kubernetes.io/${kind}='' 2>/dev/null|wc -l)" -eq 0 ]; then
        echo 0
    else
        kind=${1:-worker}
        workers="$(oc get nodes -o=jsonpath='{.items[*].status.capacity.cpu}' -l node-role.kubernetes.io/${kind}='')"
        workers="${workers// /+}+0"
        num_cpu=$(echo "$workers"|bc)
        echo "$num_cpu"
    fi
}
unset ENT
unset VCPU
unset WCPU
for type in $(oc get nodes|grep -v ^NAME|awk '{print $3}'|sed 's/,/ /g'|sort -u); do
    unset CPU
    unset RAM
    CPU=$(calc_cpu $type)
    RAM=$(calc_mem $type)
    if [ "$type" == "worker" ]; then
        if [ "$ENVIRONMENT" == "virtual" ]; then
            if [ $(($CPU%2)) -eq 0 ]; then
                VCPU=$(($CPU/2))
            else
                VCPU=$(($CPU/2))
                ((VCPU++))
            fi
            ENT="Entitlements:$VCPU"
            OUTWORKER="Total entitelments needed for $CPU virtual CPU (physical count $VCPU): $ENT"
        else
            CPU=$(calc_cpu $type)
            ENT="Entitlements:$CPU"
            OUTWORKER="Total entitelments needed for $CPU physical CPU : $ENT"
        fi
    fi
    echo "[$type] CPU:$CPU RAM:${RAM}Gi ${ENT}"|tee -a $LOG
done
echo "[ENTITLEMENT] $OUTWORKER"