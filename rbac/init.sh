#!/bin/bash
mkdir /usr/local/instruqt

SCRIPT_OUT="/usr/local/instruqt/setup.sh"
NAMESPACES_OUT="/usr/local/instruqt/namespaces.sh"
BIZAPP_OUT="/usr/local/instruqt/bizapp.sh"
ROLES_OUT="/usr/local/instruqt/roles.sh"

cat >> $SCRIPT_OUT << OEF

#HNC_VERSION=v0.8.0
#HNC_PLATFORM=linux_amd64

# echo  https://github.com/kubernetes-sigs/multi-tenancy/releases/download/hnc-v0.8.0/hnc-manager.yaml
# echo  https://github.com/kubernetes-sigs/multi-tenancy/releases/download/hnc-v0.8.0/kubectl-hns_linux_amd64  

kubectl label ns kube-system hnc.x-k8s.io/excluded-namespace=true --overwrite 
kubectl label ns kube-public hnc.x-k8s.io/excluded-namespace=true --overwrite 
kubectl label ns kube-node-lease hnc.x-k8s.io/excluded-namespace=true --overwrite

kubectl apply -f https://github.com/kubernetes-sigs/multi-tenancy/releases/download/hnc-v0.8.0/hnc-manager.yaml

TIME_OUT=60

echo "Taking a break for 60 seconds while Kubernetes refreshes itself..."
sleep 60

# date +"%s" 

cd /usr/local/bin 

pwd

curl -L https://github.com/kubernetes-sigs/multi-tenancy/releases/download/hnc-v0.8.0/kubectl-hns_linux_amd64 -o ./kubectl-hns

chmod +x ./kubectl-hns 
ls -l ./kubectl-hns

kubectl hns
OEF

cat >> $NAMESPACES_OUT << EOF
kubectl create namespace app-one
kubectl hns create company-one -n app-one
kubectl hns create company-one-finance -n company-one
kubectl hns create company-one-hr -n company-one
kubectl hns create company-one-management -n company-one
kubectl hns create company-two -n app-one
kubectl hns create company-two-finance -n company-two
kubectl hns create company-two-hr -n company-two
kubectl hns create company-two-management -n company-two

kubectl create namespace company-three
kubectl create namespace app-two
kubectl hns set company-three --parent app-two
kubectl hns create company-three-finance -n company-three
kubectl hns create company-three-hr -n company-three
kubectl hns create company-three-management -n company-three
EOF

cat >> $BIZAPP_OUT << EOF
kubectl create namespace biz-app
kubectl hns create company-one -n biz-app
kubectl hns create company-one-finance -n company-one
kubectl hns create company-one-hr -n company-one
kubectl hns create company-one-management -n company-one
kubectl hns create company-two -n biz-app
kubectl hns create company-two-finance -n company-two
kubectl hns create company-two-hr -n company-two
kubectl hns create company-two-management -n company-two
kubectl hns tree biz-app
EOF

cat >> $ROLES_OUT << EOF
kubectl -n biz-app create role biz-app-admin --verb=* --resource=pod
kubectl -n company-one create role company-one-sre --verb=update --resource=pod
kubectl -n company-two create role company-two-sre --verb=update --resource=pod
EOF
