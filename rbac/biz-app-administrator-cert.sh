#!/bin/bash

CLUSTERNAME=default
NAMESPACE=biz-app
USERNAME=biz-app-administrator
GROUPNAME=admins

openssl genrsa -out $USERNAME.key 2048

CSR_FILE=$USERNAME.csr
KEY_FILE=$USERNAME.key

openssl req -new -key $KEY_FILE -out $CSR_FILE -subj "/CN=$USERNAME/O=$GROUPNAME"

CERTIFICATE_NAME=$USERNAME.$NAMESPACE

# Dump the CSR to file for education's sake
cat >  $USERNAME-csr.yaml <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $CERTIFICATE_NAME 
spec:
  signerName: kubernetes.io/kube-apiserver-client
  groups:
  - system:authenticated
  request: $(cat $CSR_FILE | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF

kubectl apply -f $USERNAME-csr.yaml

:'
cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $CERTIFICATE_NAME 
spec:
  signerName: kubernetes.io/kube-apiserver-client
  groups:
  - system:authenticated
  request: $(cat $CSR_FILE | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
'
kubectl certificate approve $CERTIFICATE_NAME

CRT_FILE=$USERNAME.crt

kubectl get csr $CERTIFICATE_NAME -o jsonpath='{.status.certificate}'  | base64 --decode > $CRT_FILE

kubectl config set-credentials $USERNAME \
  --client-certificate=$(pwd)/$CRT_FILE \
  --client-key=$(pwd)/$KEY_FILE

kubectl config set-context $USERNAME-context --cluster=$CLUSTERNAME --namespace=$NAMESPACE --user=$USERNAME
