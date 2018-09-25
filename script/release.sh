#!/bin/bash

current_tag=${CI_COMMIT_TAG}
prev_tag=$(git tag | sort --version-sort | grep -B 1 ${CI_COMMIT_TAG} | head -1)

change_log_header="# ${CI_PROJECT_NAME} (${current_tag}) RELEASED\n"
change_log_changes=$(git log ${prev_tag}..${current_tag} --oneline --no-merges --format='  * %s' | sort | uniq | sed 's/$/\\n/' | tr -d \"\'\\n)
change_log_authors=$(git log ${prev_tag}.."$current_tag" --format='* %aN\n' | sort -u | tr -d \"\'\\n)

cat << EOF > release.json
{
  "tag_name": "$current_tag",
  "description": "$change_log_header\n$change_log_changes\nAuthors\n\n$change_log_authors"
}
EOF

RET=$(curl -s -o /dev/null -w "%{http_code}" -XPOST \
  -H "PRIVATE-TOKEN: $GL_PRIVATE_TOKEN" \
  -H 'Content-type: application/json' \
  -d @release.json \
  https://gitlab.eman.cz/api/v4/projects/${CI_PROJECT_ID}/repository/tags/${CI_COMMIT_TAG}/release)

[ $RET -eq 409 ] && RET=$(curl -s -o /dev/null -w "%{http_code}" -XPUT \
  -H "PRIVATE-TOKEN: $GL_PRIVATE_TOKEN" \
  -H 'Content-type: application/json' \
  -d @release.json \
  https://gitlab.eman.cz/api/v4/projects/${CI_PROJECT_ID}/repository/tags/${CI_COMMIT_TAG}/release)

exit 0
