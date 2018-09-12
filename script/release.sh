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

exit 0
