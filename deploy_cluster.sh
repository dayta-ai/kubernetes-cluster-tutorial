#!/bin/bash
GREEN='\033[0;32m'
NC='\033[0;0m'
export PATH=$PATH:$(pwd)
export DNS_ZONE_DASH=$(echo $DNS_ZONE | sed 's/\./-/g')
export S3_BUCKET_PREFIX=$STAGE-$DNS_ZONE_DASH
export NAME=$STAGE.$DNS_ZONE
export ORIGINAL_AWS_PROFILE={your-original-aws-profile}

echo -e "${GREEN}==== Initializing Pre-requisite Terraform ====${NC}"
export KOPS_STATE_STORE=$S3_BUCKET_PREFIX-kstate
export TF_STATE_STORE=$S3_BUCKET_PREFIX-tfstate
mkdir -p ${STAGE}/prereq
cp ./kops_pre_reqs.tf ./${STAGE}/prereq/kops_pre_reqs.tf
cd ${STAGE}/prereq
cat << EOF > main.tf
provider "aws" {
  region      = "${REGION}"
  profile     = "${ORIGINAL_AWS_PROFILE}"
}
EOF
echo -e "${GREEN}==== Done Creating Pre-requisite Terraform Files ====${NC}"
echo ""
echo -e "${GREEN}==== Applying Pre-requisite Terraform ====${NC}"
export TF_VAR_STAGE=$STAGE
export TF_VAR_KOPS_STATE_STORE=$KOPS_STATE_STORE
export TF_VAR_TF_STATE_STORE=$TF_STATE_STORE
terraform init
terraform plan
terraform apply

echo -e "${GREEN}==== Done Deploying Pre-requisite Terraform ====${NC}"
echo ''

export AWS_DEFAULT_REGION=$REGION
export AWS_DEFAULT_OUTPUT=text
export AWS_ACCESS_KEY_ID=$(terraform state show aws_iam_access_key.kops | grep "id" | cut -d= -f2 | awk '{$1=$1};1')
export AWS_SECRET_ACCESS_KEY=$(terraform state show aws_iam_access_key.kops | grep "secret" | cut -d= -f2 | awk '{$1=$1};1')

cd ../

echo -e "${GREEN}==== Creating Keypair ====${NC}"
ssh-keygen -t rsa -C ${NAME} -f ${NAME}.pem
PUBKEY=$(pwd)/${NAME}.pem.pub
aws ec2 import-key-pair --key-name ${NAME} --public-key-material file://${PUBKEY}
echo -e "${GREEN}==== Done Creating Keypair ====${NC}"
echo ''

echo -e "${GREEN}==== Creating Cluster Terraform ====${NC}"
mkdir -p cluster
kops create cluster \
--cloud aws \
--state=s3://${KOPS_STATE_STORE} \
--node-count 3 \
--zones ${REGION}a,${REGION}b,${REGION}c \
--master-zones ${REGION}a,${REGION}b,${REGION}c \
--dns-zone ${DNS_ZONE} \
--node-size t2.medium \
--master-size t2.medium \
--topology private \
--networking calico \
--ssh-public-key=${PUBKEY} \
--bastion \
--authorization RBAC \
--out=cluster \
--target=terraform \
${NAME}
echo -e "${GREEN}==== Done Creating Cluster Terraform ====${NC}"
echo ''

echo -e "${GREEN}==== Deploying Cluster Terraform ====${NC}"
cd cluster
cat << EOF > backend.tf
terraform {
  backend "s3" {
    bucket = "${TF_STATE_STORE}"
    key = "${STAGE}-cluster/terraform.tfstate"
    region = "${REGION}"
  }
}
EOF
terraform init
terraform plan
terraform apply
echo -e "${GREEN}==== Done Deploying Cluster Terraform ====${NC}"
echo ''