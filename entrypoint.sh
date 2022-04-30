#!/bin/bash -eu

TASKS_IDS="$(echo ${message:-} | sed -E 's/\(#[0-9]+\)//g' | grep -oP '[0-9]{2,}' | xargs)"
if [ -z "${TASKS_IDS}" ]; then
    echo "No tasks found! Abort."
    exit 0
fi
echo "OK Task(s) found! Starting notifications..."
link="PR <a href=\"https://github.com/${repo_name}/pull/${pull_number}\">${repo_name}#${pull_number}</a>"
if [ "${{ github.event_name }}" = "pull_request" ]; then
    if [ "${{ github.event.action }}" = "review_requested" ]; then
        ghLogins="$(echo ${requested_reviewers} | jq '.[].login' | tr -d '\"' | xargs)"
        if [ ! -z "${ghLogins}" ]; then
            serverUsers=""
            for ghLogin in ${ghLogins}; do
                response=$(curl -s -f -L -u ${SERVER_USERNAME}:${SERVER_PASSWORD} -XGET "${SERVER_GAMGH_CONNECTOR_REST_URL}/users/${ghLogin}" || echo "")
                [ -z "${response}" ] || serverUsers="${serverUsers} @${response}"
            done
            if [ ! -z "${serverUsers}" ]; then
                echo "Requested reviewers are: $(echo ${serverUsers} | tr -d '@')."
                msg="💭 $link requested a review from ${serverUsers} ."
            else
                echo "Could not get Meeds Builders users' identifiers! Abort"
                exit 0
            fi
        else
            echo "No Github reviewers' identifiers were found! Abort!"
            exit 0
        fi
        elif [ "${{ github.event.pull_request.merged }}" = "true" ]; then
        msg="🌟 $link has been merged into ${base_branch_name}."
    else
        msg="ℹ️ $link has been ${{ github.event.action }}."
    fi
    elif [ "${{ github.event_name }}" = "pull_request_review" ] && [ "${{ github.event.action }}" = "submitted" ]; then
    mentionCreator=""
    response=$(curl -s -f -L -u ${SERVER_USERNAME}:${SERVER_PASSWORD} -XGET "${SERVER_GAMGH_CONNECTOR_REST_URL}/users/${creator}" || echo "")
    [ -z "${response}" ] || mentionCreator=" FYI @${response} "
    if [ "${{ github.event.review.state }}" = "changes_requested" ]; then
        msg="🛠️ $link requires some changes.${mentionCreator}"
        elif [ "${{ github.event.review.state }}" = "approved" ]; then
        msg="✅ $link has been ${{ github.event.review.state }}.${mentionCreator}"
    else
        msg="ℹ️ $link has been ${{ github.event.review.state }}."
    fi
fi
echo "*** Message is:"
echo ${msg}
echo "***"
for TASK_ID in ${TASKS_IDS}; do
    echo "Commenting to Task #${TASK_ID}..."
    curl -s -L -u ${SERVER_USERNAME}:${SERVER_PASSWORD} -XPOST --data-urlencode "<p>${msg}</p>" "${SERVER_TASK_REST_PREFIXE_URL}/comments/${TASK_ID}"
done