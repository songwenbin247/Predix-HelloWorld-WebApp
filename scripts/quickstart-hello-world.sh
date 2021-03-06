#!/bin/bash
set -e
function local_read_args() {
  while (( "$#" )); do
  opt="$1"
  case $opt in
    -h|-\?|--\?--help)
      PRINT_USAGE=1
      QUICKSTART_ARGS="$SCRIPT $1"
      break
    ;;
    -b|--branch)
      BRANCH="$2"
      QUICKSTART_ARGS+=" $1 $2"
      shift
    ;;
    -o|--override)
      QUICKSTART_ARGS=" $SCRIPT"
    ;;
    --skip-setup)
      SKIP_SETUP=true
    ;;
    *)
      QUICKSTART_ARGS+=" $1"
      #echo $1
    ;;
  esac
  shift
  done

  if [[ -z $BRANCH ]]; then
    echo "Usage: $0 -b/--branch <branch> [--skip-setup]"
    exit 1
  fi
}



BRANCH="master"
PRINT_USAGE=0
SKIP_SETUP=false
#ASSET_MODEL="-amrmd predix-ui-seed/server/sample-data/predix-asset/asset-model-metadata.json predix-ui-seed/server/sample-data/predix-asset/asset-model.json"
SCRIPT="-script cloud-basics.sh -script-readargs cloud-basics-readargs.sh"
QUICKSTART_ARGS="$SCRIPT"
IZON_SH="https://raw.githubusercontent.com/PredixDev/izon/$BRANCH/izon.sh"
VERSION_JSON="version.json"
PREDIX_SCRIPTS=predix-scripts
REPO_NAME=Predix-HelloWorld-WebApp
VERSION_JSON="version.json"
APP_NAME="Predix Hello World"
TOOLS="Cloud Foundry CLI, Git, Predix CLI"
TOOLS_SWITCHES="--cf --git --predixcli"

local_read_args $@
VERSION_JSON_URL=https://raw.githubusercontent.com/PredixDev/$REPO_NAME/$BRANCH/version.json


function check_internet() {
  set +e
  echo ""
  echo "Checking internet connection..."
  curl "http://google.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy"
    echo "If you are behind a corporate proxy, set the 'http_proxy' and 'https_proxy' environment variables."
    exit 1
  fi
  echo "OK"
  echo ""
  set -e
}

function init() {
  currentDir=$(pwd)
  if [[ $currentDir == *"scripts" ]]; then
    echo 'Please launch the script from the root dir of the project'
    exit 1
  fi

  check_internet
  #if needed, get the version.json that resolves dependent repos from another github repo
  if [ ! -f "$VERSION_JSON" ]; then
    if [[ $currentDir == *"$REPO_NAME" ]]; then
      if [[ ! -f manifest.yml ]]; then
        echo 'We noticed you are in a directory named $REPO_NAME but the usual contents are not here, please rename the dir or do a git clone of the whole repo.  If you rename the dir, the script will get the repo.'
        exit 1
      fi
    fi
    echo $VERSION_JSON_URL
    curl -s -O $VERSION_JSON_URL
  fi
  
  #get the script that reads version.json
  eval "$(curl -s -L $IZON_SH)"
  #get the url and branch of the requested repo from the version.json
  __readDependency "local-setup" LOCAL_SETUP_URL LOCAL_SETUP_BRANCH
  #get the predix-scripts url and branch from the version.json
  __readDependency $PREDIX_SCRIPTS PREDIX_SCRIPTS_URL PREDIX_SCRIPTS_BRANCH
  if [ ! -d "$PREDIX_SCRIPTS" ]; then
    echo "Cloning predix script repo ..."
    git clone --depth 1 --branch $PREDIX_SCRIPTS_BRANCH $PREDIX_SCRIPTS_URL
  else
      echo "Predix scripts repo found reusing it..."
  fi
  source $PREDIX_SCRIPTS/bash/scripts/local-setup-funcs.sh
}

if [[ $PRINT_USAGE == 1 ]]; then
  init
  __print_out_standard_usage
else
  if $SKIP_SETUP; then
    init
  else
    init
    __standard_mac_initialization
  fi
fi

echo "quickstart_args=$QUICKSTART_ARGS"
source $PREDIX_SCRIPTS/bash/quickstart.sh $QUICKSTART_ARGS


__append_new_line_log "Successfully completed $APP_NAME installation!" "$quickstartLogDir"
