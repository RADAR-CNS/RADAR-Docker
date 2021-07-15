#!/bin/bash
# Check whether services are healthy. If not, restart them and notify the maintainer.

cd "$( dirname "${BASH_SOURCE[0]}" )/.."

. lib/util.sh
. ./.env
stack="docker-compose -f ../$COMPONENT_NAME/docker-compose.yml"

function slack_notify() {
    # Send notification via Slack, if configured.
    if [ "$HEALTHCHECK_SLACK_NOTIFY" == "yes" ] ; then
        if [ -z "$HEALTHCHECK_SLACK_WEBHOOK_URL" ] ; then
            echo "Error: Slack notifications are enabled, but \$HEALTHCHECK_SLACK_WEBHOOK_URL is undefined. Unable to send Slack notification."
            exit 1
        fi

        channel=${HEALTHCHECK_SLACK_CHANNEL:-#radar-ops}
        color=$1
        body=$2
        curl -X POST --data-urlencode "payload={\"channel\": \"$channel\", \"username\": \"radar-healthcheck\", \"icon_emoji\": \":hospital:\", \"attachments\": [{\"color\": \"$color\", \"fallback\": \"$body\", \"fields\": [{\"title\": \"Health update\", \"value\": \"$body\"}]}]}" \
            $HEALTHCHECK_SLACK_WEBHOOK_URL
    fi
}

unhealthy=()

# get all human-readable service names
# see last line of loop
while read service; do
    # check if a container was started for the service
    container=$(sudo-linux $stack ps -q $service)
    if [ -z "${container}" ]; then
        # no container means no running service
        continue
    fi
    health=$(sudo-linux docker inspect --format '{{.State.Health.Status}}' $container 2>/dev/null || echo "null")
    if [ "$health" = "unhealthy" ]; then
        echo "Service $service is unhealthy. Restarting."
        unhealthy+=("${service}")
        sudo-linux $stack restart ${service}
    fi
done <<< "$(sudo-linux $stack config --services)"

display_host="${COMPONENT_NAME} ($(hostname -f), $(curl -s http://ipecho.net/plain))"

if [ "${#unhealthy[@]}" -eq 0 ]; then
    if [ -f .unhealthy ]; then
         rm -f .unhealthy
         slack_notify good "All services on ${display_host} are healthy again"
    fi
    echo "All services are healthy"
else
    echo "$unhealthy services were unhealthy and have been restarted."

    # Check if swaks program exists for sending mail
    if([[ -n $(command -v swaks) ]]); then
      # Send notification to MAINTAINER
      SAVEIFS=$IFS
      IFS=,
      display_services="[${unhealthy[*]}]"
      IFS=$SAVEIFS
      body="Services on ${display_host} are unhealthy. Services $display_services have been restarted. Please log in for further information."
      echo "Sent notification to $MAINTAINER_EMAIL"
      if([[ -n ${FROM_EMAIL} ]]); then
        swaks --to $MAINTAINER_EMAIL --server ${SMTP_SERVER_HOST:-localhost} --from ${FROM_EMAIL} --h-Subject "[RADAR] Services on ${COMPONENT_NAME} unhealthy." --body "$body"
      else
        swaks --to $MAINTAINER_EMAIL --server ${SMTP_SERVER_HOST:-localhost} --h-Subject "[RADAR] Services on ${COMPONENT_NAME} unhealthy." --body "$body"
      fi
    else
      echo "Can't send email notification since the program 'SWAKS' is not installed. Please install it first using 'sudo apt-get install -y swaks'"
    fi
    echo "${unhealthy[@]}" > .unhealthy

    slack_notify danger "$body"

    exit 1
fi
