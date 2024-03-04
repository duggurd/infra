#!/bin/bash

user="$1"
group="$2"

if [[ -z "$user" || -z "$group" ]]; then
    echo "Usage: $0 <user> <group>"
    echo "Please provide both user and group."
    exit 1
fi

# Rest of your code here


echo "Creating user $user in group $group"
echo "Generating private key and csr"

key=openssl genrsa 2048
csr=openssl req -new -key $key -out $user.csr -subj "/CN=$user/O=$group"


echo "requesting signing off cert"

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
name: myuser
spec:
request: $(cat $user.csr | base64 | tr -d '\n')
signerName: kubernetes.io/kube-apiserver-client
expirationSeconds: 986400  # one day
usages:
- client auth
EOF

if [[ $? -eq 0 ]]; then
    echo "CSR created successfully"
else
    echo "Failed to create CSR"
    exit 1
fi


echo "Approving CSR"

kubectl certificate approve $user

if [[ $? -eq 0 ]]; then
    echo "CSR approved successfully"
else
    echo "Failed to approve CSR"
    exit 1
fi

signed_cert=$(kubectl get csr $user -o jsonpath='{.status.certificate}')

kubectl config set-credentials $user --client-key=$key --client-certificate=$signed_cert --embed-certs=true


kubectl config set-context $user --cluster=kubernetes --user=$user