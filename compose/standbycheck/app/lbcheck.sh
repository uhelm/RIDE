#!/bin/bash
set -o pipefail
set -o nounset

# secret should provide variables. assignments fail if variables don't exist
l_namespace=${NAMESPACE}                            # GoldDR namespace
l_cluster_name=${STANDBY_POSTGRESCLUSTER_NAME}      # name of PostgresCluster object
l_ocp_api_server=${STANDBY_OCP_API_SERVER}          # GoldDR login server
l_serviceaccount_token=${SERVICEACCOUNT_TOKEN}      # GoldDR service account token

status="true"                                       # failsave default for standby_status
failures=0                                          # failure count init

max_failures=3                                      # max failures until we shutdown
sleep=30                                            # sleep duration between checks
login_sleep=30                                      # sleep duration between login attempts
caddy_200_conf="/app/Caddyfile_200"  		        # caddy 200 OK configuration
caddy_503_conf="/app/Caddyfile_503"                 # caddy 503 Error configuration

echodate() {
    echo `date +%Y/%m/%d\ %H:%M:%S`:: $*
}

standby_status() {
    output=$(oc -n ${l_namespace} get postgrescluster ${l_cluster_name} -o jsonpath="{.spec.standby.enabled}")
    
    # add spec.shutdown check

    if [[ $? -eq 0 ]]; then
        echo $output
    else
        echo "unknown"
    fi
}

caddy_reload_config() {
    caddy reload -c $1
    ret=$?
    if [[ $ret -eq 0 ]]; then
        echodate "[NOTICE] Reloaded caddy configuration with: $1"
    else
        echodate "[CRITICAL] Unable to reload caddy configuration with: $1. Returned error code $ret"
    fi
}

while true; do
    oc login --token=$l_serviceaccount_token --server=${l_ocp_api_server}
    if [[ $? -eq 0 ]]; then
        echodate "[NOTICE] Successful login to OpenShift"
        break
    else
        echodate "[CRITICAL] Unable to login to cluster. Check namespace and service accout configuration."
        echodate "[CRITICAL] Assuming standby cluster is TRUE. Responding with HTTP 200. Retry in ${login_sleep}s."
        sleep ${login_sleep}
    fi
done

status=$(standby_status)

echodate "[NOTICE] ${l_namespace}: Starting PostgresCluster standby watch. Current status of ${l_cluster_name}: ${status^^}"

while true; do
    status=$(standby_status)
    case "$status" in
        "true")
            echodate "[NOTICE] ${l_namespace}: Checking standby status for PostgresCluster ${l_cluster_name}: ${status^^}"
            failures=0
			caddy_reload_config ${caddy_200_conf}
        ;;

        "false")
            echodate "[CRITICAL] ${l_namespace}: Checking standby status for PostgresCluster ${l_cluster_name}: ${status^^}"
            echodate "[CRITICAL] ${l_namespace}: GOLDDR cluster is set to primary. Sending HTTP 503 for GOLD load balancer health check."
            
            # fail 3 times before switching
            failures=$((failures+1))
            if [[ $failures -lt 3 ]]; then
                echodate "[CRITCAL] ${l_namespace}: Failure count (${failures}) < max_failure_count (${max_failures})."
                echodate "[CRITCAL] ${l_namespace}: Not switching yet."
                sleep ${sleep}
                continue
            fi
            
            # hit max failures. replace caddy config and reload caddy.
            if [[ $failures -ge $max_failures ]]; then
                echodate "[CRITCAL] ${l_namespace}: Failure count (${failures}) => max_failure_count (${max_failures})."
                echodate "[CRITCAL] ${l_namespace}: DISABLING LOAD BALANCER CHECK. CHANGING caddy CONFIG."
                caddy_reload_config ${caddy_503_conf}
            fi
        ;;

        *)
            echodate "[WARNING] ${l_namespace}: Standby status for ${l_cluster_name} unknown! Assuming healthy."
            caddy_reload_config ${caddy_200_conf}
        ;;
    esac
    sleep ${sleep}
done
