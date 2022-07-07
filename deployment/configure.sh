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
#set -o nounset
if [[ "${DEBUG:-false}" == "true" ]]; then
    set -o xtrace
fi

function get_version {
    local type="$1"
    local name="$2"
    local version=""
    local attempt_counter=0
    readonly max_attempts=5

    until [ "$version" ]; do
        version=$("_get_latest_$type" "$name")
        if [ "$version" ]; then
            break
        elif [ ${attempt_counter} -eq ${max_attempts} ];then
            echo "Max attempts reached"
            exit 1
        fi
        attempt_counter=$((attempt_counter+1))
        sleep $((attempt_counter*2))
    done

    echo "${version#v}"
}

function _get_latest_docker_tag {
    curl -sfL "https://registry.hub.docker.com/v1/repositories/$1/tags" | python -c 'import json,sys,re;versions=[obj["name"] for obj in json.load(sys.stdin) if re.match("^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$",obj["name"])];print("\n".join(versions))' | uniq | sort -rn | head -n 1
}

# get_status() - Print the current status of the cluster
function get_status {
    printf "CPU usage: "
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage " %"}'
    printf "Memory free(Kb):"
    awk -v low="$(grep low /proc/zoneinfo | awk '{k+=$2}END{print k}')" '{a[$1]=$2}  END{ print a["MemFree:"]+a["Active(file):"]+a["Inactive(file):"]+a["SReclaimable:"]-(12*low);}' /proc/meminfo
    echo "Kubernetes Events:"
    kubectl get events -A --sort-by=".metadata.managedFields[0].time"
    echo "Kubernetes Resources:"
    kubectl get all -A -o wide
    echo "Kubernetes Pods:"
    kubectl describe pods
    echo "Kubernetes Nodes:"
    kubectl describe nodes
}

# NOTE: Plain rust application mimicking WASM app(https://github.com/second-state/wasmedge_wasi_socket/tree/main/examples/http_server)
if [ -z "$(sudo docker images rust/hello-world:0.0.1 -q)" ]; then
    pushd .. > /dev/null
    sudo docker build --tag rust/hello-world:0.0.1 .
    popd > /dev/null
fi

if [ -z "$(sudo docker images avengermojo/http_server:with-wasm-annotation -q)" ]; then
    sudo docker pull avengermojo/http_server:with-wasm-annotation
fi

if [ -z "$(sudo docker images kindest/node:crun -q)" ]; then
    pushd "${RUNTIME_MANAGER:-containerd}" > /dev/null
    sudo docker build --tag kindest/node:crun --build-arg version="$(get_version docker_tag kindest/node)" .
    popd > /dev/null
fi

trap get_status ERR
if ! sudo "$(command -v kind)" get clusters | grep -e k8s; then
    newgrp docker <<EONG
    kind create cluster --name k8s --config=./${RUNTIME_MANAGER:-containerd}/kind-config.yml
    kind load docker-image rust/hello-world:0.0.1 --name k8s
    kind load docker-image avengermojo/http_server:with-wasm-annotation --name k8s
EONG
fi

# Wait for node readiness
for node in $(kubectl get node -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
    kubectl wait --for=condition=ready "node/$node" --timeout=3m
done

cat <<EOF | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: crun
handler: crun
EOF
