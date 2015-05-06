#!/bin/bash

pipeline_name=$1; shift
pipeline=$1; shift
stub=$1; shift
trigger_job=$1; shift
set -e

fly_target=${fly_target:-"bosh-lite"}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
echo "Concourse API $ATC_URL"

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

usage() {
  echo "USAGE: run-pipeline.sh name pipeline.yml credentials.yml [trigger-job]"
  exit 1
}

if [[ "${stub}X" == "X" ]]; then
  usage
fi
stub=$(realpath $stub)
if [[ ! -f ${stub} ]]; then
  usage
fi

pushd $DIR
  yes y | fly -t ${fly_target} configure -c ${pipeline} --vars-from ${stub} ${pipeline_name}
  if [[ "${trigger_job}X" != "X" ]]; then
    curl $ATC_URL/jobs/${trigger_job}/builds -X POST
    fly -t ${fly_target} watch -j ${trigger_job}
  fi
popd
