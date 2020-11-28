#!/bin/bash
# This opt_attack_range.sh script is supposed to be run from  #
# Jenkins with OPERATION (build, status, start, stop, destroy #
# or similate as value) as the first command line argument.   #
#                                                             #
# Owner: Optimoz, Inc.                                        #
#-------------------------------------------------------------#
cd /apps/attack_range
. ./venv/bin/activate

AR_STATUS=1
OPERATION=${1}
OPERATIONS="stop start destroy simulate"

EXISTS=$(ls -l conf/${ATTACK_RANGE_NAME}-attack_range.conf 2>/dev/null|wc -l)

if [[ ${OPERATIONS} =~ (^|[[:space:]])${OPERATION}($|[[:space:]]) ]]
then
  [[ ${EXISTS} -eq 0 ]] && echo "Attack Range ${ATTACK_RANGE_NAME} doesn't exist!" && exit 1
else
  [[ ${OPERATION} = "build1" ]] && [[ ${EXISTS} -eq 1 ]] && \
  echo "Attack Range ${ATTACK_RANGE_NAME} already exists!" && exit 1
fi

case "${OPERATION}" in

"build") 
  echo "Building : ${ATTACK_RANGE_NAME}"

  [[ ${AWS_REGION} = "" ]] && AWS_REGION="us-east-1"
  [[ ${ATTACK_RANGE_NAME} = "" ]] && ATTACK_RANGE_NAME="esi"
  [[ ${ATTACK_RANGE_PASSWORD} = "" ]] && ATTACK_RANGE_PASSWORD="Electr0Cyb3r"
  [[ ${EC2_KEY_NAME} = "" ]] && EC2_KEY_NAME="esiar"
  [[ ${IP_WHITELIST} = "" ]] && IP_WHITELIST="0.0.0.0/0"
  [[ ${EC2_INSTANCE_TYPE} = "" ]] && EC2_INSTANCE_TYPE="t3.large"
  [[ ${PHANTOM_SERVER} = "Yes" ]] && PHANTOM_SERVER="1" || PHANTOM_SERVER="0"
  [[ ${PHANTOM_COMMUNITY_USERNAME} = "" ]] && PHANTOM_COMMUNITY_USERNAME="user" 
  [[ ${PHANTOM_COMMUNITY_PASSWORD} = "" ]] && PHANTOM_COMMUNITY_PASSWORD="password" 
  [[ ${WINDOWS_DOMAIN_CONTROLLER} = "Yes" ]] && WINDOWS_DOMAIN_CONTROLLER="1" || WINDOWS_DOMAIN_CONTROLLER="0"
  [[ ${WINDOWS_SERVER} = "Yes" ]] && WINDOWS_SERVER="1" || WINDOWS_SERVER="0"
  [[ ${KALI_MACHINE} = "Yes" ]] && KALI_MACHINE="1" || KALI_MACHINE="0"
  [[ ${WINDOWS_CLIENT} = "Yes" ]] && WINDOWS_CLIENT="1" || WINDOWS_CLIENT="0"
  [[ ${WINDOWS_CLIENT_AMI} = "" ]] && WINDOWS_CLIENT_AMI="import-ami-0bfa8347c6efcf8f2"
  [[ ${ZEEK_SENSOR} = "Yes" ]] && ZEEK_SENSOR="1" || ZEEK_SENSOR="0"

  mkdir -p conf
  conf_template=$(cat opt_attack_range_conf.tpl)
  eval "echo \"${conf_template}\"" > conf/${ATTACK_RANGE_NAME}-attack_range.conf

  python attack_range.py -c conf/${ATTACK_RANGE_NAME}-attack_range.conf build
  AR_STATUS=$?
  ;;

"status") 
  COUNT=$(ls -l conf/*.conf 2>/dev/null|wc -l)

  if [ ${COUNT} -gt 0 ]
  then
    for conf in conf/*.conf
    do
      echo "Checking status on ${conf}"
      python attack_range.py -c ${conf} show
      AR_STATUS=$?
    done
  else
    echo "There is no active Attack Range in place."
  fi
  ;;

"stop") 
  echo "Stopping ${ATTACK_RANGE_NAME}"
  python attack_range.py -c conf/${ATTACK_RANGE_NAME}-attack_range.conf stop
  AR_STATUS=$?
  ;;

"start") 
  echo "Resuming ${ATTACK_RANGE_NAME}"
  python attack_range.py -c conf/${ATTACK_RANGE_NAME}-attack_range.conf resume
  AR_STATUS=$?
  ;;

"destroy") 
  if [ ${DESTROY} = "Yes" ]
  then
    echo "Destroying ${ATTACK_RANGE_NAME}"
    python attack_range.py -c conf/${ATTACK_RANGE_NAME}-attack_range.conf destroy
    AR_STATUS=$?
    rm conf/${ATTACK_RANGE_NAME}-attack_range.conf
  fi
  ;;

"simulate") 
  echo "Simulating using ${ATTACK_RANGE_NAME}"
  python attack_range.py -c conf/${ATTACK_RANGE_NAME}-attack_range.conf simulate \
  -st ${SIMULATION_TECHNIQUES} -t ${ATTACK_TARGET}
  AR_STATUS=$?
  ;;

esac

exit ${AR_STATUS}
