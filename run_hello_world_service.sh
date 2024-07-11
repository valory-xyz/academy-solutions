#!/usr/bin/env bash
# This script has been only tested in Linux (Ubuntu)

set -e

# -------------------------------------------------------------------
# Update these variables accordingly
# -------------------------------------------------------------------
service_name="Hello World"
service_id="valory/hello_world"
service_version="0.1.0"
service_alias="hello_world_service"
packages_json_path="./packages/packages.json"
# To generate a keys file, use: autonomy generate-key ethereum -n 4
keys_json_path="./keys.json"
# -------------------------------------------------------------------


# Aux function to gets all addresses from a keys.json file as an array ["addr1", ...]
get_all_participants() {
    local keys_json_path="$1"

    if [ ! -f "$keys_json_path" ]; then
        echo "ERROR: The file $keys_json_path does not exist. Please generate it using the command"
        echo "  autonomy generate-key ethereum -n 4"
        echo "and run this script again."
        echo ""
        exit 1
    fi

    local addresses=($(awk -F'"' '/"address":/ {print "\"" $4 "\""}' "$keys_json_path"))
    echo "[$(IFS=", "; echo "${addresses[*]}")]"
}


echo "-------------------"
echo "$service_name service"
echo "-------------------"
echo ""
echo "This script will guide you to run the $service_name service on a local deployment."
echo ""


if [ -z "$VIRTUAL_ENV" ]; then
    echo "ERROR: This script must be run inside a Python virtual environment."
    echo ""
    echo "Example:"
    echo "  pipenv shell"
    echo "  pipenv lock"
    echo "  pipenv install"
    echo ""
    exit 1
fi


echo "--- Display version information ---"
autonomy --version
aea --version
docker --version
# To install a specific version of Docker, please visit
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
echo ""


echo "--- Setting up the framework ---"
autonomy init --reset --author valory --remote --ipfs --ipfs-node "/dns/registry.autonolas.tech/tcp/443/https"
echo ""


echo "--- Syncing third-party packages locally ---"
echo "This will ensure that you are using the latest third-party pacakges corresponding to the installed framework version."
make clean
AUTONOMY_VERSION=v$(autonomy --version | grep -oP '(?<=version\s)\S+')
AEA_VERSION=v$(aea --version | grep -oP '(?<=version\s)\S+')
autonomy packages sync --source valory-xyz/open-aea:$AEA_VERSION --source valory-xyz/open-autonomy:$AUTONOMY_VERSION --update-packages
echo ""


echo "--- Locking dev packages ---"
echo "You need to execute these steps if you have changed the source code."
echo "(This should have no effect if you haven't made any change to the code.)"
autonomy analyse fsm-specs --package ./packages/valory/skills/hello_world_abci --app-class HelloWorldAbciApp --update
autonomy analyse docstrings --update
autonomy packages lock
echo ""


echo "--- Pushing packages to IPFS ---"
autonomy push-all
echo ""


echo "--- Deleting previous deployments (you might be prompted sudo password) ---"
sudo rm -rf $service_alias
echo ""


echo "--- Fetching the service ---"
# OPTION A: Fetch the service from IPFS using a hash
# You need to provide a hash.
# Get the hash of the service from the packages.json file
hash=$(jq -r ".dev[\"service/$service_id/$service_version\"]" $packages_json_path)
echo "Hash found in $packages_json_path: $hash"
# If you know the hash already, uncomment this line instead.
#hash="bafybeigh2m7udulqoy35qhg75ptnxekw2q2rra4aweqsbh5iilj5lkdgbu"
# Fetch the service from IPFS
autonomy fetch $hash --service --alias $service_alias

# OR

# OPTION B: Fetch the service from the local repository (folder ./packages) instead.
# autonomy fetch "$service_id:$service_version" --local --service --alias $service_alias
echo ""


echo "--- Building the image ---"
autonomy build-image --service-dir $service_alias
echo ""


echo "--- Setting up environment variables ---"
# All services must define the ALL_PARTICIPANS variable containing all agent addresses
export ALL_PARTICIPANTS=$(get_all_participants $keys_json_path)

# Define any other variable required by your service here
export HELLO_WORLD_STRING_0="Agent 0 says Hello World!!!!"
export HELLO_WORLD_STRING_1="Agent 1 says Hello World!!!!"
export HELLO_WORLD_STRING_2="Agent 2 says Hello World!!!!"
export HELLO_WORLD_STRING_3="Agent 3 says Hello World!!!!"
# export MY_OWNER_ADDRESS_0='0x0123000000000000000000000000000000000000'
# export MY_OWNER_ADDRESS_1='0x0123000000000000000000000000000000000001'
# export MY_OWNER_ADDRESS_2='0x0123000000000000000000000000000000000002'
# export MY_OWNER_ADDRESS_3='0x0123000000000000000000000000000000000003'
echo ""


echo "--- Building the local deployment (Docker Compose)---"
cd $service_alias
autonomy deploy build "../$keys_json_path" -ltm
echo ""


echo "--- Run the deployment ---"
autonomy deploy run --build-dir abci_build/ --detach
echo ""


echo "--------------------------------------------------------------------------------"
echo ""
echo "Helpful commands:"
echo ""
echo "To stop the service, execute:"
echo "    autonomy deploy stop --build-dir $service_alias/abci_build"
echo ""
echo "To view the FSM transitions of an agent, execute:"
echo "    autonomy analyse logs --from-dir ./$service_alias/abci_build/persistent_data/logs/ --agent aea_0 --fsm --reset-db"
echo ""
echo "To view a running agent logs, execute:"
echo "    docker logs --follow helloworld_abci_0"
echo ""
echo "To view all running agent logs, execute:"
echo "    docker-compose -f ./$service_alias/abci_build/docker-compose.yaml logs --tail=0 --follow helloworld_abci_0 helloworld_abci_1 helloworld_abci_2 helloworld_abci_3"""
echo ""
echo "--------------------------------------------------------------------------------"