#!/bin/bash

echo '{' > libraries.json
echo '"libraries":[' >> libraries.json
comma=""
bundle show | tr -d '()' | sed 1d | awk '{print $2" "$3}' | while read gem version; do
    echo "    $comma{\"bundle\": \"$gem\", \"version_code\": \"$version\", \"type\": \"Gem\"}"
    comma="," 
done >> libraries.json
echo ']' >> libraries.json
echo '}' >> libraries.json

curl -H "X-App-Token: ${KRAKEN_APP_TOKEN}" \
  -H "X-App-Version: ${CI_COMMIT_TAG}" \
  -H "Content-Type: application/json" \
  -X POST -d @libraries.json https://versions.eman.cz/api/packages

