FROM alpine

LABEL name="task-connector-action"
LABEL repository="https://github.com/Green-Hub-Tools/task-connector"
LABEL homepage="https://github.com/Green-Hub-Tools/task-connector"
LABEL org.opencontainers.image.source="https://github.com/Green-Hub-Tools/task-connector"

LABEL "com.github.actions.name"="puppet-lint-action"
LABEL "com.github.actions.description"="GitHub Action for puppet-lint"
LABEL "com.github.actions.icon"="share-2"
LABEL "com.github.actions.color"="orange"

LABEL "maintainer"="Green Hub Tools <contact@ghubtools.io>"

RUN apk --no-cache add curl jq wget bash
RUN gem install puppet-lint --no-document

COPY entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["./"]
