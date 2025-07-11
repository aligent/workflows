#!/usr/bin/env bash
#
set -e

export SUCCESS_TEXT=("Everything up-to-date" "Deployment completed" "Warmed up page" "Opening environment" "re-deploying routes only")
export FAIL_TEXT=("Deploy was failed" "Post deploy is skipped" "Unable to build application")
export REDEPLOY_TEXT=("Connection refused")

export FAIL_FLAG=$(mktemp)
export REDEPLOY_FLAG=$(mktemp)

source "$(dirname "$0")/common.sh"

validate() {
     DEBUG=${DEBUG:=false}

     if [ -z ${MAGENTO_CLOUD_REMOTE} ]; then
          fail "No MAGENTO_CLOUD_REMOTE configured."
     fi
}

setup_ssh_creds() {
     # Setup pipeline SSH
     INJECTED_SSH_CONFIG_DIR="/opt/atlassian/pipelines/agent/ssh"
     IDENTITY_FILE="${INJECTED_SSH_CONFIG_DIR}/id_rsa_tmp"
     KNOWN_SERVERS_FILE="${INJECTED_SSH_CONFIG_DIR}/known_hosts"
     if [ ! -f ${IDENTITY_FILE} ]; then
          info "No default SSH key configured in Pipelines.\n These are required to push to Magento cloud. \n These should be generated in bitbucket settings at Pipelines > SSH Keys."
          return
     fi
     mkdir -p ~/.ssh
     touch ~/.ssh/authorized_keys
     cp ${IDENTITY_FILE} ~/.ssh/pipelines_id

     if [ ! -f ${KNOWN_SERVERS_FILE} ]; then
          fail "No SSH known_hosts configured in Pipelines."
     fi
     cat ${KNOWN_SERVERS_FILE} >> ~/.ssh/known_hosts
     if [ -f ~/.ssh/config ]; then
          debug "Appending to existing ~/.ssh/config file"
     fi
     echo "IdentityFile ~/.ssh/pipelines_id" >> ~/.ssh/config

     echo "Host *" >> ~/.ssh/config
     echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> ~/.ssh/config

     chmod -R go-rwx ~/.ssh/
}

redeploy () {
    echo "Previous deployment failed with a transient error. Triggering re-deployment"
    OUTFILE="/tmp/redeploy_output"
    MC_PROJECT=$(echo ${MAGENTO_CLOUD_REMOTE} | cut -d@ -f1)
    MAGENTO_CLOUD_CLI_TOKEN=${MAGENTO_CLOUD_CLI_TOKEN} magento-cloud environment:redeploy --project ${MC_PROJECT} --environment ${BITBUCKET_BRANCH} --yes 2>&1 | tee ${OUTFILE} >/dev/stderr

    for text in "${FAIL_TEXT[@]}"
    do
        cat $OUTFILE | grep -iqE "${text}" && return 1
    done

    for text in "${SUCCESS_TEXT[@]}"
    do
        cat $OUTFILE | grep -iqE "${text}" && return 0
    done

    return 1
}

push_to_secondary_remote() {
    echo "Pushing to Magento Cloud"
    git config --global --add safe.directory /opt/atlassian/pipelines/agent/build
    git remote add secondary-remote ${MAGENTO_CLOUD_REMOTE}
    # Fail pipeline on Magento Cloud failure (no appropriate status codes from git push)
    # and print output to bitbucket pipeline stream.
    OUTFILE="/tmp/git_push_output"
    BRANCH="${BITBUCKET_BRANCH}${REMOTE_BRANCH:+:$REMOTE_BRANCH}"
    git push secondary-remote ${BRANCH} 2>&1 | tee ${OUTFILE} >/dev/stderr

    for text in "${FAIL_TEXT[@]}"
    do
        cat $OUTFILE | grep -iqE "${text}" && echo "Failed text: ${text}" | tee -a ${FAIL_FLAG}
    done

    # Test if a redeployment is required. Use flag files to try redeploy only once
    if [[ -s ${FAIL_FLAG} ]]; then
        echo "FAIL_FLAG is set. Checking Redeploy condition...."
        for text in "${REDEPLOY_TEXT[@]}"
        do
          echo "Looking for \"${text}\" in the log..."
          cat $OUTFILE | grep -iqE "${text}" && [[ ${MAGENTO_CLOUD_CLI_TOKEN} ]] && echo "Caught redeploy text: ${text}" | tee -a "${REDEPLOY_FLAG}"
        done
    # If a redepoy is needed, return the redepoy function's return value. Otherwise, return 1
        if [[ -s ${REDEPLOY_FLAG} ]]; then
          redeploy
          return $?
        else
          echo "Skipping redeploy. Deploy failed."
          return 1
        fi
    fi

    for text in "${SUCCESS_TEXT[@]}"
    do
        cat $OUTFILE | grep -iqE "${text}" && return 0
    done

    echo "Reached default failure mode"
    cat ${FAIL_FLAG}
    return 1
}

mute_nr_alerts() {
     if [[ ${NR_ALERT_MUTING_RULE_ID} && ${NR_ACCOUNT_ID} && ${NR_USER_KEY} ]]; then
          sed "s/NR_ACCOUNT_ID/${NR_ACCOUNT_ID}/g" $(dirname "$0")/nr-muting-rule.json.template | \
          sed "s/NR_ALERT_MUTING_RULE_ID/${NR_ALERT_MUTING_RULE_ID}/g" | \
          sed "s/RULE_ENABLED/true/" > nr-muting-rule.json # Enable the mute rule
          curl -s https://api.newrelic.com/graphql -H 'Content-Type: application/json' \
          -H "Api-Key: ${NR_USER_KEY}" -d @nr-muting-rule.json -w "\n"
     fi
}

create_nr_deploy_marker() {
     if [[ ${NR_APP_ID} && ${NR_USER_KEY} ]]; then
          export COMMIT=MC-$(git rev-parse --short=7 HEAD)
          jq '."deployment"."revision" = env.COMMIT' "$(dirname "$0")/nr-deployment.json.template" > nr-deployment.json
          curl -s https://api.newrelic.com/v2/applications/${NR_APP_ID}/deployments.json -H "Api-Key: ${NR_USER_KEY}" -w "\n"\
          -H "Content-Type: application/json" -d @nr-deployment.json -w "\n"
     fi
}

unmute_nr_alerts() {
     if [[ ${NR_ALERT_MUTING_RULE_ID} && ${NR_ACCOUNT_ID} && ${NR_USER_KEY} ]]; then
          sed "s/NR_ACCOUNT_ID/${NR_ACCOUNT_ID}/g" /nr-muting-rule.json.template | \
          sed "s/NR_ALERT_MUTING_RULE_ID/${NR_ALERT_MUTING_RULE_ID}/g" | \
          sed "s/RULE_ENABLED/false/" > nr-muting-rule.json # Disable the mute rule
          curl -s https://api.newrelic.com/graphql -H 'Content-Type: application/json' \
          -H "Api-Key: ${NR_USER_KEY}" -d @nr-muting-rule.json -w "\n"
     fi
}

deploy() {
    if [[ "${PIPELINE_REDEPLOY}" == "true" ]]; then
      redeploy # Triggered by schedule-redeploy pipeline via Bitbucket Pipeline Schedules
    else
      push_to_secondary_remote 
    fi
}

validate
setup_ssh_creds
mute_nr_alerts
deploy && (create_nr_deploy_marker; unmute_nr_alerts ) || (unmute_nr_alerts; false) # Place a marker only when deployment was successful. Otherwise return false in the end
