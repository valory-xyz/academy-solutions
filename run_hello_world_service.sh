#!/usr/bin/env bash

set -e

# Aux function to gets all addresses from a keys.json file as an array ["addr1", ...]
get_all_participants() {
    local keys_json_path="$1"

    if [ ! -f "$keys_json_path" ]; then
        exit_with_error "File not found: $keys_json_path."
    fi

    local addresses=($(awk -F'"' '/"address":/ {print "\"" $4 "\""}' "$keys_json_path"))
    echo "[$(IFS=", "; echo "${addresses[*]}")]"
}

# Init virtualenv
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Warning: This script should be run within a pipenv shell."
    echo "Please, execute the following commands before running the script:"
    echo "pipenv shell"
    echo "pipenv lock"
    echo "pipenv install --dev"
    exit 1
fi

# Init the framework
autonomy init --reset --author valory --remote --ipfs --ipfs-node "/dns/registry.autonolas.tech/tcp/443/https"

# Sync packages, in case they are not present in current repository
make clean
AUTONOMY_VERSION=v$(autonomy --version | grep -oP '(?<=version\s)\S+')
AEA_VERSION=v$(aea --version | grep -oP '(?<=version\s)\S+')
autonomy packages sync --source valory-xyz/open-aea:$AEA_VERSION --source valory-xyz/open-autonomy:$AUTONOMY_VERSION --update-packages

# Lock the packages
autonomy packages lock

# Push packages to IPFS
autonomy push-all

# If necessary, create the keys.json file
if [ ! -f "keys.json" ]; then
    echo "Creating new keys..."
    autonomy generate-key ethereum -n 4
fi

# Delete previous deployments
sudo rm -rf hello_world_service

# Fetch the service
autonomy fetch --local --service valory/hello_world --alias hello_world_service

cd hello_world_service

# Build the image
autonomy build-image

# Copy keys and build the deployment
cp ../keys.json ./keys.json

# Define the service-specific env variables. 'ALL_PARTICIPANTS' is required for all services.
export ALL_PARTICIPANTS=$(get_all_participants "./keys.json")

# Add as many variables as required. Environment variables override the values in the file service.yaml.
# export MY_OWNER_ADDRESS_0='0x0123000000000000000000000000000000000000'
# export MY_OWNER_ADDRESS_1='0x0123000000000000000000000000000000000001'
# export MY_OWNER_ADDRESS_2='0x0123000000000000000000000000000000000002'
# export MY_OWNER_ADDRESS_3='0x0123000000000000000000000000000000000003'

# Build the deployment
autonomy deploy build -ltm

# Run the deployment
autonomy deploy run --build-dir abci_build/ --detach

echo "--------------------------------------------------------------------------------"
echo ""
echo "Helpful commands:"
echo ""
echo "To stop the service, execute:"
echo "    autonomy deploy stop --build-dir ./hello_world_service/abci_build/"
echo ""
echo "To view the FSM transitions of an agent, execute:"
echo "    autonomy analyse logs --from-dir ./hello_world_service/abci_build/persistent_data/logs/ --agent aea_0 --fsm --reset-db"
echo ""
echo "To view a running agent logs, execute:"
echo "    docker logs --follow helloworld_abci_0"
echo ""
echo "To view all running agent logs, execute:"
echo "    cd hello_world_service/abci_build; docker compose logs -f; cd ../.."
echo ""
echo "--------------------------------------------------------------------------------"
