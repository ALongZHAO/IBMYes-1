#! /bin/bash

cd $(dirname $0)

IBMCLOUD=$(pwd)/Bluemix_CLI/bin/ibmcloud
CF=~/.bluemix/cfcli/cf
#BLUE="\e[00;34m"
#RED="\e[00;31m"
#END="\e[0m"
BLUE=""
RED=""
END="==================================="

if [ ! -f "$IBMCLOUD" ]; then
    echo "${BLUE}download ibm-cloud-cli-release${END}"
    ver=$(curl -s https://github.com/IBM-Cloud/ibm-cloud-cli-release/releases/latest | grep -Po "(\d+\.){2}\d+")
    #ver=1.1.0
    wget -q -Oibm_cli.tgz https://clis.cloud.ibm.com/download/bluemix-cli/$ver/linux64
    if [ $? -eq 0 ]; then
        tar xzf ibm_cli.tgz
    else
        echo "${RED}download new version failed!${END}"
        exit 1
    fi
    rm -fv ibm_cli.tgz
fi

# set default env
IBM_MEMORY=${IBM_MEMORY:-"256M"}
BIN_NAME=${BIN_NAME:-"test"}
V2_ID=${V2_ID:-"d007eab8-ac2a-4a7f-287a-f0d50ef08680"}
V2_PATH=${V2_PATH:-"path"}
ALTER_ID=${ALTER_ID:-"1"}
mkdir -p $BIN_NAME

if [ ! -f "./config/v2ray" ]; then
    echo "${BLUE}download v2ray${END}"
    pushd ./config
    new_ver=$(curl -s https://github.com/v2fly/v2ray-core/releases/latest | grep -Po "(\d+\.){2}\d+")
    wget -q -Ov2ray.zip https://github.com/v2fly/v2ray-core/releases/download/v${new_ver}/v2ray-linux-64.zip
    if [ $? -eq 0 ]; then
        7z x v2ray.zip v2ray v2ctl
        chmod 700 v2ctl v2ray
    else
        echo "${RED}download new version failed!${END}"
        exit 1
    fi
    rm -fv v2ray.zip
    popd
fi

# cloudfoundry config
cp -rvf ./config/manifest.yml ./$BIN_NAME/
sed "s/BIN_NAME/${BIN_NAME}/" ./$BIN_NAME/manifest.yml -i
sed "s/IBM_APP_NAME/${IBM_APP_NAME}/" ./$BIN_NAME/manifest.yml -i
sed "s/IBM_MEMORY/${IBM_MEMORY}/" ./$BIN_NAME/manifest.yml -i

# v2ray config
cp -vf ./config/v2ray ./$BIN_NAME/$BIN_NAME
cp -vf ./config/v2ctl ./$BIN_NAME/
cp -vf ./d.sh ./$BIN_NAME/
sed "s/1111/${V2_ID}/" ./$BIN_NAME/d.sh -i
sed "s/2222/${V2_PATH}/" ./$BIN_NAME/d.sh -i
sed "s/3333/${ALTER_ID}/" ./$BIN_NAME/d.sh -i

cat ./$BIN_NAME/d.sh

#echo "${BLUE}ibmcloud login${END}"
#$IBMCLOUD login -r us-south <<EOF
#$IBM_ACCOUNT
#n
#EOF

#if [ -n "$RESOURSE_ID" ]; then
#    echo "${BLUE}ibmcloud set RESOURSE_ID${END}"
#    $IBMCLOUD target -g $RESOURSE_ID
#fi

if [ ! -f "$HOME/.bluemix/cfcli/cf" ]; then
    echo "${BLUE}ibmcloud cf install${END}"
    $IBMCLOUD cf install
    #$IBMCLOUD target --cf-api 'https://api.us-south.cf.cloud.ibm.com'
fi
#$IBMCLOUD target --cf

echo "${BLUE}cf login${END}"
$CF login -a https://api.us-south.cf.cloud.ibm.com <<EOF
$IBM_ACCOUNT
EOF

cd ./$BIN_NAME
#echo "${BLUE}ibmcloud cf push${END}"
#$IBMCLOUD cf push
echo "${BLUE}cf push${END}"
$CF push

if [ $? -ne 0 ]; then
    echo "${BLUE}print error${END}"
    $CF logs $IBM_APP_NAME --recent
    exit 1
fi
