#!/usr/bin/env bash
#
# bb

# BASH MODES
set -u
set -o pipefail

# CONSTANTS
readonly HOME_DIR="$( cd "$( dirname $0 )" ; pwd )"
readonly INCLUDES_DIR="${HOME_DIR}/includes"

# INCLUDES
source "${INCLUDES_DIR}/bp.sh"
source "${INCLUDES_DIR}/bb_vars.sh"
source "${INCLUDES_DIR}/bb_functions.sh"
source "${HOME_DIR}/bb.conf"

# MAIN
main() {

  [ $# -lt 1 ] && { usage; exit 1 ;}

  bp::check_dependencies
  bb::setup

  # Seperate option and parameters
  OPT="$1" ; shift
  PARMS="$@"

  # Parse options
  case $OPT in
    "new"|"create") min_args $# 1 && post::create $@ || usage ;;
    "edit") req_args $# 1 && post::edit $1 ;;
    "set") req_args $# 2 && post::setstatus $1 $2 || usage ;;
    "delete") req_args $# 1 && post::delete $1 ;;
    "generate") post::generate_index ;;
    "list") post::list ;;
    "push") post::push ;;
    *) usage ;;
  esac
}

main $@
