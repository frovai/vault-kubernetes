#!/bin/bash

### SCRIPT TO MANAGE THE VAULT INFRA TERRAFORM FILES, IF NECESSARY TO REPLICATE, RUN THE SAME AND PLAY
# THE FILES GENERATED TO THE PREVIOUS FOLDER, THE KEYS GENERATED IMPORT IN SSM
cp main-tf.template main.tf
### Vars has the values ​​that will be used in the environment, if you want to change any configuration, edit the "vars-tf.template" file as you wish to insert new values ​​into the Vault stack
cp vars-tf.template vars.tf
cp outputs-tf.template outputs.tf
cp terragrunt-hcl.template terragrunt.hcl
gpg --batch --gen-key key-gen-template
## Change the email below if you want to generate the key reference with another access name and --output change the name in front if you want to generate the gpg key with another name
gpg --armor --output public-key.gpg --export MYEMAIL@MYDOMAINNAME.com.br
gpg --output public-key-binary.gpg --export MYEMAIL@MYDOMAINNAME.com.br
## Commands below are used to change the "local_file" reference within the terraform recipe so that it adds the key created at this moment to encrypt the secret_key that will be used by helm when accessing DynamoDB
local="$(pwd)/public-key-binary.gpg"
sed -i "s|GPG_KEY_FILE_LOCAL|$local|g" main.tf

## Creation of resources after preparing the templates:
terragrunt apply -lock=false -input=false

### IMPORTANTE ###
## Run the command below between -- -- after creating the resources to recover the secret_key,
## it will ask for the password previously generated when creating the gpg key for decrypt
# -- terraform output secret_access_key | sed 's/"//g' | base64 -d | gpg --decrypt --
terraform output secret_access_key | sed 's/"//g' | base64 -d | gpg --decrypt

## Create secrets for accessing dynamodb and used by helmchart

##kubectl create namespace vault
ACCESS=$(terraform output access_key_id | sed 's/"//g')
SECRET=$(terraform output secret_access_key | sed 's/"//g' | base64 -d | gpg --decrypt)
kubectl create secret generic vault-access-key --from-literal='AWS_ACCESS_KEY_ID='$ACCESS'' -nvault
kubectl create secret generic vault-secret-access-key --from-literal='AWS_SECRET_ACCESS_KEY='$SECRET'' -nvault

## Create secret and TLS certificate for vault.MYDOMAINNAME.com.br

kubectl apply -f ../k8s/certificate.yaml
kubectl apply -f ../k8s/vault-role.yaml

## Install Vault application with Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
sleep 10
helm install -f ../k8s/values.yaml vault hashicorp/vault --namespace vault

## Init Vault 
kubectl --namespace vault exec -it vault-0 -- vault operator init

## Collect the generated output and register the keys in the SSM Parameter Store
## Below is a commented example of OUTPUT

#### OUTPUT DO INIT DO VAULT ####
#Unseal Key 1: BNhQbHndpsQyIqS6aDBGo2zB8JaiTz0HLeozfGASTCWY
#Unseal Key 2: ifUhHTx7SjYCAQuaeARgmDP4icI8Q3Nh8sf4sK3ysmtX
#Unseal Key 3: 6eCUR+IsETM0WcUrDMnnSzGiAtkwMHjCKBrO0xcJkNOW
#Unseal Key 4: Vix7azWcncYWd4EUPOWx0MVq10uSmJWXfqgvjWULcQUf
#Unseal Key 5: QRkQYyooqOV8FNpMyWHGd/9nyE9AyAl6mqPmUNfdU7am

#Initial Root Token: hvs.839B3SrFcWgKTxxxxxxPgcrt5ihugxxxxx

#Vault initialized with 5 key shares and a key threshold of 3. Please securely
#distribute the key shares printed above. When the Vault is re-sealed,
#restarted, or stopped, you must supply at least 3 of these keys to unseal it
#before it can start servicing requests.

#Vault does not store the generated root key. Without at least 3 keys to
#reconstruct the root key, Vault will remain permanently sealed!

#It is possible to generate new unseal keys, provided you have a quorum of
#existing unseal keys shares. See "vault operator rekey" for more information.

#### VAULT INIT OUTPUT ####

## NEXT >>

## Follow the procedures below manually

##### PERFORM THE UNSEAL PROCESS FROM THE VAULT #####
# Run the command below 3 times, using 3 different keys generated in the previous command

#kubectl --namespace vault exec -it vault-0 -- vault operator unseal
##### PERFORM THE UNSEAL PROCESS FROM THE VAULT #####

## NEXT > 

###### ACTIVATE CLUSTER AUDIT LOG ######
# Log into the POD running, export the VAULT_TOKEN and then run the activation command, as below:

## 1º kubectl exec -it vault-0 /bin/sh -ndefault
## 2º export VAULT_TOKEN="hvs.xxxxxxxxxxxxxxxxxxxx"
## 3º vault audit enable file file_path=stdout

# Output of the configuration made successfully: #

#/ $ vault audit enable file file_path=stdout
#Success! Enabled the file audit device at: file/

###### ACTIVATE CLUSTER AUDIT LOG ######

## NEXT >>  

##### ACTIVATE VAULT AUTO-UNSEAL MODE #####

##
#1 Leave the configmap commented on the lines referring to -- "seal "awskms" {" -- (this repository will be commented by default), go to KMS and copy the ID of the generated key to place in the configmap      #seal "awskms" {
      #  kms_key_id = "xxxxxxxxxxxxxxxxxxxxxxx"
      #  region = "us-east-1"
      #}

#2 Upload the helmchart (this script will also perform this step, you can skip this one, just for documentation purposes)
#3 Configure the Vault init "vault operator init" (this script will also perform this step, if you make sure you have backed up the 5 keys and the Root Token)

#4º Unseal using the "vault operator unseal" (run 3x, placing the keys, this step was explained in the documentation above)
#5 Uncomment the mode lines -- "seal "awskms" {" -- in Configmap (confirm the key ID)
      #seal "awskms" {
      #  kms_key_id = "xxxxxxxxxxxxxxxxxxxxxxx"
      #  region = "us-east-1"
      #}
#6 Take down the POD to reload the Configmap again "kubectl delete pod vault-0 vault-1 vault-2 -nvault"
#7º When uploading the POD, run the command from within the POD or mount the command with kubectl by executing "vault operator unseal -migrate" (run 3x, placing the keys generated in the Vault init)
#8th Migration process for the seal with KMS completed

##Output when running "kubectl logs -f vault-0 -nvault" with success message

#2022-08-12T15:07:10.281Z [INFO]  core: seal migration initiated
#2022-08-12T15:07:10.281Z [INFO]  core: migrating from shamir to auto-unseal: to=awskms
#2022-08-12T15:07:10.394Z [INFO]  core: seal migration complete




