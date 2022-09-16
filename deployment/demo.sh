#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o errexit
set -o nounset
if [[ ${DEBUG:-false} == "true" ]]; then
    set -o xtrace
fi
# get_status() - Print the current status of the cluster
function get_status {
    info "CPU usage: $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage " %"}')"
    info "Memory free(Kb): $(awk -v low="$(grep low /proc/zoneinfo | awk '{k+=$2}END{print k}')" '{a[$1]=$2}  END{ print a["MemFree:"]+a["Active(file):"]+a["Inactive(file):"]+a["SReclaimable:"]-(12*low);}' /proc/meminfo)"
    info "Kubernetes Events:"
    kubectl get events --sort-by=".metadata.managedFields[0].time"
    info "Kubernetes Resources:"
    kubectl get all -o wide
    info "Kubernetes Pods:"
    kubectl describe pods
    info "Traffic generator logs"
    kubectl logs --selector=job-name=traffic-generator --tail=25
}

# error() - This function prints an error message in the standard output
function error {
    _print_msg "ERROR" "$1"
    get_status
    exit 1
}

# info() - This function prints an information message in the standard output
function info {
    _print_msg "INFO" "$1"
}

function _print_msg {
    printf "\n%s - %s: %s\n" "$(date +%H:%M:%S)" "$1" "$2"
}

function run_test {
    local scenario="$1"
    attempt_counter=0
    max_attempts=6

    info "Running $scenario test"

    # shellcheck disable=SC2064
    trap "kubectl delete --ignore-not-found -f $scenario-test.yml --wait" RETURN
    kubectl apply -f "$scenario-test.yml"
    sleep 30
    pods=$(kubectl get pods --selector=job-name="$scenario-traffic-generator" --output=jsonpath='{.items[*].metadata.name}')
    until kubectl logs "$pods" | grep -q "http_req_connecting"; do
        if [ ${attempt_counter} -eq ${max_attempts} ]; then
            error "Max attempts reached"
        fi
        attempt_counter=$((attempt_counter + 1))
        sleep $((attempt_counter * 1))
    done

    kubectl logs --selector=job-name="$scenario-traffic-generator" --tail=21 | grep http_req
}

function cleanup {
    kubectl delete --ignore-not-found -f http-server.yml
    kubectl delete pods --all
    kubectl delete jobs --all
}

trap get_status ERR
trap cleanup EXIT
kubectl apply -f http-server.yml

kubectl rollout status deployment wasm-server

info "Starting traffic tests"
run_test rust
run_test wasm
