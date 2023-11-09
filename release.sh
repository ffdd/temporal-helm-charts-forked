#!/usr/bin/env bash

while read row
do
  url=$(echo $row | jq -r '.url')
  sha256=$(echo $row | jq -r '.sha256')
  chart=$(echo $row | jq -r '.chart')
  version=$(echo $row | jq -r '.version')

  echo "Downloading $chart-$version from $url"

  curl "$url" -LOs

  shasum -a 256 -c <<< "${sha256} *${chart}-${version}.tgz"

  if [ $? -eq 1 ]; then
    echo "Checksum failed. Please check $chart-$version.tgz"
    exit 1
  fi

done < <(jq -c '.charts[]' mirrored-charts.json)

for chart in $(ls -d */); do helm dependency update $chart; done;

git diff --exit-code
if [ $? -eq 1 ]; then
  echo "Git diff exist. Please run 'helm dependency update' and commit changes."
  exit 1
fi

helm package *

for chart in $(ls | grep .tgz); do helm push $chart $REPO_URL; done;
