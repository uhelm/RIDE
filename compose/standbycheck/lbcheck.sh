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
nginx_200_conf="/etc/nginx/default_200.conf"        # nginx 200 OK configuration
nginx_503_conf="/etc/nginx/default_503.conf"        # nginx 503 Error configuration
nginx_runtime_conf="/etc/nginx/conf.d/default.conf" # nginx runtime config

echodate() {
    echo `date +%y/%m/%d_%H:%M:%S`:: $*
}

standby_status() {
    output=$(oc -n ${l_namespace} get postgrescluster ${l_cluster_name} -o jsonpath="{.spec.standby.enabled}")
    
    // add spec.shutdown check

    if [[ $? -eq 0 ]]; then
        echo $output
    else
        echo "unknown"
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
            
            # hit max failures. replace nginx config and reload nginx.
            if [[ $failures -ge $max_failures ]]; then
                echodate "[CRITCAL] ${l_namespace}: Failure count (${failures}) => max_failure_count (${max_failures})."
                echodate "[CRITCAL] ${l_namespace}: DISABLING LOAD BALANCER CHECK. CHANGING NGINX CONFIG."
                cp -v ${nginx_503_conf} ${nginx_runtime_conf}
                nginx -s reload
            fi
        ;;

        *)
            echodate "[WARNING] ${l_namespace}: Standby status for ${l_cluster_name} unknown! Assuming healthy."
        ;;
    esac
    sleep ${sleep}
done