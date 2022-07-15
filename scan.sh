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
  export BOOST_EXEC_COMMAND=${INPUT_EXEC_COMMAND:-}

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

  if [ -z "${BOOST_EXEC_COMMAND:-}" ]; then
    log.error "the 'exec_command' option must be defined when in exec mode"
    exit 1
  fi

  if [ -z "${BOOST_STEP_NAME:-}" ]; then
    log.error "the 'step_name' option must be defined in exec mode"
    exit 1
  fi
  export BOOST_EXEC_COMMAND="docker run -v %CWD%:/src slef05/boost-semgrep:latest"
  exec ${BOOST_EXE} scan exec ${BOOST_CLI_ARGUMENTS:-} --command "${BOOST_EXEC_COMMAND}"
}

case "${INPUT_ACTION:-scan}" in
  boost-registry)   main.registry ;;
  *)        log.error "invalid action ${INPUT_ACTION}"
            exit 1
            ;;
esac
