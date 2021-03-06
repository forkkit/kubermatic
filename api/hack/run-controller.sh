#!/usr/bin/env bash

# Copyright 2020 The Kubermatic Kubernetes Platform contributors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -exuo pipefail

cd $(go env GOPATH)/src/github.com/kubermatic/kubermatic/api
# Deploy a user-cluster/ipam-controller for which we actuallly
# have a pushed image
export KUBERMATICCOMMIT="${KUBERMATICCOMMIT:-$(git rev-parse origin/master)}"
make seed-controller-manager

KUBERMATIC_WORKERNAME=${KUBERMATIC_WORKERNAME:-$(uname -n)}
KUBERMATIC_DEBUG=${KUBERMATIC_DEBUG:-true}
PPROF_PORT=${PPROF_PORT:-6600}

./_build/seed-controller-manager \
  -dynamic-datacenters=true \
  -namespace=kubermatic \
  -datacenter-name=europe-west3-c \
  -kubeconfig=../../secrets/seed-clusters/dev.kubermatic.io/kubeconfig \
  -versions=../config/kubermatic/static/master/versions.yaml \
  -updates=../config/kubermatic/static/master/updates.yaml \
  -kubernetes-addons-path=../addons \
  -kubernetes-addons-file=../config/kubermatic/static/master/kubernetes-addons.yaml \
  -openshift-addons-path=../openshift_addons \
  -openshift-addons-file=../config/kubermatic/static/master/openshift-addons.yaml \
  -feature-gates=OpenIDAuthPlugin=true \
  -worker-name="$(tr -cd '[:alnum:]' <<< $KUBERMATIC_WORKERNAME | tr '[:upper:]' '[:lower:]')" \
  -external-url=dev.kubermatic.io \
  -backup-container=../config/kubermatic/static/store-container.yaml \
  -cleanup-container=../config/kubermatic/static/cleanup-container.yaml \
  -docker-pull-config-json-file=../../secrets/seed-clusters/dev.kubermatic.io/.dockerconfigjson \
  -oidc-ca-file=../../secrets/seed-clusters/dev.kubermatic.io/caBundle.pem \
  -oidc-issuer-url=$(vault kv get -field=oidc-issuer-url dev/seed-clusters/dev.kubermatic.io) \
  -oidc-issuer-client-id=$(vault kv get -field=oidc-issuer-client-id dev/seed-clusters/dev.kubermatic.io) \
  -oidc-issuer-client-secret=$(vault kv get -field=oidc-issuer-client-secret dev/seed-clusters/dev.kubermatic.io) \
  -monitoring-scrape-annotation-prefix='kubermatic.io' \
  -log-debug=$KUBERMATIC_DEBUG \
  -log-format=Console \
  -max-parallel-reconcile=10 \
  -pprof-listen-address=":${PPROF_PORT}" \
  -logtostderr \
  -v=4 # Log-level for the Kube dependencies. Increase up to 9 to get request-level logs.
