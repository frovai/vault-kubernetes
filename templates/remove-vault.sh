#!/bin/bash
terragrunt destroy -lock=false -input=false
rm -rf .terraform
rm public-key-binary.gpg
rm public-key.gpg
rm vars.tf
rm main.tf
rm outputs.tf
rm terragrunt.hcl
helm uninstall vault -nvault
kubectl delete -f ../k8s/certificate.yaml
kubectl delete -f ../k8s/vault-role.yaml
kubectl delete secret vault-access-key -nvault
kubectl delete secret vault-ca-secrets -nvault
kubectl delete secret vault-secret-access-key -nvault

