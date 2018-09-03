#!/bin/bash
[ -z "$1" ] && { echo "missing type: major, minor, patch, none"; exit 1; }

old_version="$(git describe --tags --abbrev=0)"

[ -z "$old_version" ] && { echo "missing previous tag"; exit 1; }

old_version=$(echo "$old_version" | tr -d '[:lower:]')

new_version=$(echo "$old_version" | awk -F. -v CHANGE="$1" -v SPECIAL="$2" '
BEGIN{type=CHANGE;special=SPECIAL}
{
  if (special != "")
      special="-"special
  if (type=="patch")
    print $1"."$2"."$3+1""special ;
  else if (type == "minor")
    print $1"."$2+1".0"special ;
  else if (type == "major")
    print $1+1".0.0"special ;
  else if (type == "none")
    print $1"."$2"."$3""special
}')

new_version="$new_version"

change_log_header="# api-mini-tester ($new_version) RELEASED\n"
change_log_changes=$(git log "$old_version"..HEAD --oneline --no-merges --format='  * %s' | sort | uniq)
change_log_authors=$(git log "$old_version"..HEAD --oneline --format='* %aN' | sort -u)

[ -f CHANGELOG.MD ] || touch CHANGELOG.MD

{
    echo -e "$change_log_header"
    echo -e "$change_log_changes"
    echo -e "\nAuthors\n"
    echo -e "$change_log_authors\n"
} | cat - CHANGELOG.MD > CHANGELOG.work.MD && mv CHANGELOG.work.MD CHANGELOG.MD

echo "Check updated CHANGELOG.MD: $old_version -> $new_version"
echo "Tag this version with $new_version"
