#!/bin/bash

OCTOOLSBIN=$(dirname $0)

# ==============================================================================================================================
usage () {
  cat <<-EOF
  ========================================================================================
  Runs one-off commands inside the container of a pod.
  
  You can accomplish the same results by using regular commands from OpenShift.
  This script is just wrapping calls to 'oc exec' to make it a little more
  convenient to use. In the future, the 'oc' cli tool might incorporate changes
  that make this script obsolete.
  
  Related GitHub issues:
  - https://github.com/GoogleCloudPlatform/kubernetes/issues/8876
  - https://github.com/openshift/origin/issues/2001
  
  ----------------------------------------------------------------------------------------
  Usage:
  
  ${0} [options] <PodName> [PodIndex] "<command>"
  
  Where:
   - <PodName> is the name of the pod.
   - [PodIndex] is the index of the pod instance, and is optional.
   - '<command>' is the command to run on the pod.
     It's a good idea to wrap the command in quotes as shown.
     You may need to use single or double quotes depending on the command.
     Any additional quotes in the command may need to be escaped.
     See examples for details.
  
  Options:
    
    -s the shell to use when running the test. Defaults to bash if omitted.
  
  Examples:
  ----------------------------------------------------------------------------------------
  Database Information:
  ${0} postgresql 'psql -c "\l"'
  ${0} postgresql 'psql -c "\du"'
  
  Drop and recreate database; Explicitly:
  ${0} postgresql "psql -c 'DROP DATABASE "TheOrgBook_Database";'"
  ${0} postgresql "psql -c 'CREATE DATABASE "TheOrgBook_Database";'"
  ${0} postgresql "psql -c 'GRANT ALL ON DATABASE "TheOrgBook_Database" TO "TheOrgBook_User";'"
  
  Drop and recreate database; Dynamically using environment variables:
  ${0} postgresql 'psql -ac "DROP DATABASE \\"\${POSTGRESQL_DATABASE}\\";"'
  ${0} postgresql 'psql -ac "CREATE DATABASE \\"\${POSTGRESQL_DATABASE}\\";"'
  ${0} postgresql 'psql -ac "GRANT ALL ON DATABASE \\"\${POSTGRESQL_DATABASE}\\" TO \\"\${POSTGRESQL_USER}\\";"'
  
  Running Python commands:
  ${0} django 'python ./manage.py migrate'
  ${0} django 'python ./manage.py createsuperuser'
  ${0} django 'python ./manage.py shell'
  ${0} django 'python ./manage.py rebuild_index --noinput'

  Running Python commands using sh as shell interpreter:
  ${0} -s sh django 'python ./manage.py migrate'
  ========================================================================================
EOF
exit 1
}

exitOnError () {
  rtnCd=$?
  if [ ${rtnCd} -ne 0 ]; then
	echo "An error has occurred while attempting to run a command in a pod!  Please check the previous output message(s) for details."
    exit ${rtnCd}
  fi
}
# ==============================================================================================================================
while getopts s: FLAG; do
  case $FLAG in
    s) export SHELL_CMD=$OPTARG ;;
    \?) #unrecognized option - show help
      echo -e \\n"Invalid script option"\\n
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${SHELL_CMD}" ]; then
  SHELL_CMD="bash"
fi

if [ -z "${1}" ]; then
  usage
elif [ -z "${2}" ]; then
  usage
elif [ ! -z "${4}" ]; then
  usage
else
  POD_NAME=${1}
fi

if [ ! -z "${3}" ]; then
  POD_INDEX=${2}
  COMMAND=${3}
else
  POD_INDEX="0"
  COMMAND=${2}
fi

# Get name of a currently deployed pod by label and index
POD_INSTANCE_NAME=$(getPodByName.sh ${POD_NAME} ${POD_INDEX})
exitOnError

echo
echo "Executing command on ${POD_INSTANCE_NAME}:"
echo -e "\t${COMMAND:-echo Hello}"
echo

# Run command in a container of the specified pod:
oc exec "$POD_INSTANCE_NAME" -- ${SHELL_CMD} -c "${COMMAND:-echo Hello}"
exitOnError
