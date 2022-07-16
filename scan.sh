#!/bin/bash

set -e
set -o pipefail
set -u

export BOOST_TMP_DIR=${BOOST_TMP_DIR:-${WORKSPACE_TMP:-${TMPDIR:-/tmp}}}
export BOOST_EXE=${BOOST_EXE:-${BOOST_TMP_DIR}/boost/cli/latest/boost.sh}


log.info ()
{ # $@=message
  printf "$(date +'%H:%M:%S') [\033[34m%s\033[0m] %s\n" "INFO" "${*}";
}

log.error ()
{ # $@=message
  printf "$(date +'%H:%M:%S') [\033[31m%s\033[0m] %s\n" "ERROR" "${*}";
}

init.config ()
{
  log.info "initializing configuration"

  export BOOST_CLI_URL=${BOOST_CLI_URL:-https://assets.build.boostsecurity.io}
         BOOST_CLI_URL=${BOOST_CLI_URL%*/}
  export BOOST_DOWNLOAD_URL=${BOOST_DOWNLOAD_URL:-${BOOST_CLI_URL}/boost/get-boost-cli}

  export BOOST_FORCE_COLORS="true"
  export DOCKER_COPY_REQUIRED=false
}

init.cli ()
{
  if [ -f "${BOOST_BIN:-}" ]; then
    return
  fi

  mkdir -p "${BOOST_TMP_DIR}"
  curl --silent "${BOOST_DOWNLOAD_URL}" | bash
}


main.registry ()
{
  init.config
  init.cli

  export BASE_REGISTRY="https://raw.githubusercontent.com/stlef14-community/registry/main/"
  export MODULE_DATA_URL=${BASE_REGISTRY}${INPUT_MODULE}"/module.yaml"
  export MODULE_COMMAND=`curl --silence ${MODULE_DATA_URL} | grep 'command' | awk -F\" '{print $2}'`

  echo "Running Module ${MODULE_COMMAND}"
  if [ -z "${BOOST_STEP_NAME:-}" ]; then
    log.error "the 'step_name' option must be defined in exec mode"
    exit 1
  fi
  exec ${BOOST_EXE} scan exec ${BOOST_CLI_ARGUMENTS:-} --command "${MODULE_COMMAND}"
}

case "${INPUT_ACTION:-scan}" in
  boost-registry)   main.registry ;;
  *)        log.error "invalid action ${INPUT_ACTION}"
            exit 1
            ;;
esac
