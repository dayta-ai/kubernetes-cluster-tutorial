#!/bin/bash
GREEN='\033[0;32m'
NC='\033[0;0m'
# install kubectl
echo -e "${GREEN}==== INSTALLING KUBECTL ====${NC}"
brew install kubectl
echo -e "${GREEN}==== SUCCESSFULLY INSTALLED KUBECTL ====${NC}"
echo ''
# install kops
echo -e "${GREEN}==== INSTALLING KOPS ====${NC}"
brew install kops
echo -e "${GREEN}==== SUCCESSFULLY INSTALLED KOPS ====${NC}"
echo ''
# install aws
echo -e "${GREEN}==== INSTALLING AWS ====${NC}"
pip install --user awscli
export PATH=$PATH:$HOME/.local/bin
chmod +x ./aws
echo -e "${GREEN}==== SUCCESSFULLY INSTALLED AWS ====${NC}"
echo ''
# install terraform
echo -e "${GREEN}==== INSTALLING TERRAFORM ====${NC}"
brew install terraform
echo -e "${GREEN}==== SUCCESSFULLY INSTALLED TERRAFORM ====${NC}"
echo ''