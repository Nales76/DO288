#!/bin/bash
####################################################
#                  WEBHOOK.SH
#---------------------------------------------------
#   Enable WebHook on a BuildConfig
#---------------------------------------------------
# Author: Cesar Delgado 
# Date  : 14-Jun-2021
####################################################

####################################################
#  ENVIRONMENT
####################################################

#--------------------------------
#  GENERAL PARAMETERS
#--------------------------------
ERROR="1"
OK="0"

#--------------------------------
#  DEFAULT VALUES
#--------------------------------
BUILD_CONFIG="mijava"
WEBHOOK_TYPE="Generic"

####################################################
#  FUNCTIONS
####################################################

#===================================================
#   Function: help
#---------------------------------------------------
#  Private Function
#
#  Shows command options
#===================================================
helpWebhook() {
   echo " webhook.sh -[hgib:] <opcion> "

   # Opciones Generales
   echo "  -h                         : Shows this help"
   echo "  -b <BUILD_CONFIG> [mijava] : Set Build Config Name"
   echo "  -i                         : Set GitHub WebHook"
   echo "  -g                         : Get Generic WebHook"
   echo ""
}

#===================================================
#   Function: buildURL
#---------------------------------------------------
#  Private Function
#
#  Build Webhook URL
#===================================================
buildURL() {

	# => 1.- Tipo de WebHook 
	local WEBHOOK_PATTERN=$(echo ${WEBHOOK_TYPE} | tr '[A-Z]' '[a-z]' )

	# => 2.- Capture Secret 
	local WEBHOOK_SECRET=$(oc get bc ${BUILD_CONFIG} -o jsonpath="{.spec.triggers[*].${WEBHOOK_PATTERN}.secret}{'\n'}")
	local WEBHOOK_SECRET=$(echo ${WEBHOOK_SECRET} | tr -d ' ')

	# => 3.- Capture URL
	local WEBHOOK_URL=$(oc describe bc ${BUILD_CONFIG} | awk "/Webhook ${WEBHOOK_TYPE}/ {getline; print $1}")
	local WEBHOOK_URL=${WEBHOOK_URL#*:}
	local WEBHOOK_URL=$(echo ${WEBHOOK_URL} | tr -d ' ')

	# => 4.- Replace Secret within URL
	if [ ! -z "${WEBHOOK_URL}" ] ; then
		if [ ! -z "${WEBHOOK_SECRET}" ] ; then
			WEBHOOK=${WEBHOOK_URL/<secret>/${WEBHOOK_SECRET}}
		fi
	fi


	# => 5.- Dump variables
	echo "===================================="
	echo " ENVIRONMENT"
	echo "===================================="
	echo ".... WEBHOOK_TYPE=[${WEBHOOK_TYPE}]"
	echo ". WEBHOOK_PATTERN=[${WEBHOOK_PATTERN}]"
	echo "..... WEBHOOK_URL=[${WEBHOOK_URL}]"
	echo ".. WEBHOOK_SECRET=[${WEBHOOK_SECRET}]"
	echo "......... WEBHOOK=[${WEBHOOK}]"
}

#===================================================
#   Function: enableWebhook
#---------------------------------------------------
#  Private Function
#
#  Shoot API Call to enable webhook
#===================================================
enableWebhook() {
	echo "===================================="
	echo " API CALL"
	echo "===================================="
	local OUT=$OK
	
	if [ ! -z ${WEBHOOK} ] ; then
	    echo "curl -X POST -k ${WEBHOOK}"
	    curl -X POST -k ${WEBHOOK} 
	    OUT=$?	
	else 
	    echo "WebHook URL coudn't be built"
	    OUT=$ERROR
	fi
	
	return $OUT
}
####################################################
#  CAPTURE INPUT PARAMETERS
####################################################
while getopts "hgib:" OPCION ; do
     case "$OPCION" in
	     h) helpWebhook
		    exit "$ERROR" ;;
         b) if [ -n "$OPTARG" ] ; then  BUILD_CONFIG="$OPTARG"  ;  fi ;;
         i) WEBHOOK_TYPE="GitHub" ;;
         g) WEBHOOK_TYPE="Generic" ;;
       [?]) echo " ERROR | webhook.sh -> Option not found "
	        helpWebhook ;;
      esac
done

####################################################
#  ACTIONS
####################################################

echo "=============================================================="
echo "| WEBHOOK.SH : enable hook for a given BuildConfig  "
echo "=============================================================="
echo " Build Config     = ${BUILD_CONFIG}"
echo " WebHook Type     = ${WEBHOOK_TYPE}"
echo ""
buildURL
enableWebhook
OUT="$?"

echo ""
echo "WEBHOOK.SH : exiting  $OUT (OK=$OK ; ERROR=$ERROR)   "
echo "=============================================================="
exit "$OUT"