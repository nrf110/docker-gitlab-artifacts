#!/bin/bash

# This script promotes artifacts from child pipelines up to the parent to allow
# Code coverage and test results at root
#
# Grabbed from here: https://gitlab.com/gitlab-org/gitlab/-/issues/215725#note_732899964

set -o errexit -o pipefail -o nounset

API="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}"
AUTH_HEADER="PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}"

CHILD_PIPELINES=$(curl -sS --header "${AUTH_HEADER}" "${API}/pipelines/${CI_PIPELINE_ID}/bridges")

echo "$CHILD_PIPELINES" | jq . > bridges-$CI_PIPELINE_ID.json

CHILD_PIPELINES=$(echo $CHILD_PIPELINES | jq ".[].downstream_pipeline.id") 

echo "$CHILD_PIPELINES" | while read cp
do
    # Fetch the IDs of their "build:*" jobs that completed successfully
    JOBS=$(curl -sS --header "${AUTH_HEADER}" "${API}/pipelines/$cp/jobs?scope=success")

    echo "$JOBS" | jq . >> job-$cp.json

    JOBS=$(echo "$JOBS" | jq '.[] | select(([.name] | inside(["test", "coverage"])) and .artifacts_file != null) | .id')

    [[ -z "$JOBS" ]] && echo "No jobs in $cp" && continue
    echo "$JOBS" | while read job 
    do
        echo "DOWNLOADING ARTIFACT: $job"
        curl -sS -L --header "${AUTH_HEADER}" --output artifacts-$job.zip "${API}/jobs/$job/artifacts"
    done
done

if ls artifacts-*.zip >/dev/null
then
    unzip -o artifacts-\*.zip
else
    echo "No artifacts"
fi

