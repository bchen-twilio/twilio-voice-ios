#!/bin/bash -ex

if [ "$#" -ne 5 ]; then
    echo "Usage: ${0} <owner> <repos> <ref> <env> <version>"
    echo "owner - The code.hq.twilio.com organization, e.g. 'client'"
    echo "repos - The code.hq.twilio.com project, e.g. 'twilio-chat-ios'"
    echo "ref - The git ref, e.g. 'master' or 'release-1.0.0'"
    echo "env - An environment, e.g. 'prod' or 'stage'"
    echo "verison - The version to release as, e.g. '1.0.0' or '2.0.0-rc1'"
    exit 1
fi

export GITHUB_OWNER="${1}"
export GITHUB_REPOSITORY="${2}"
export GITHUB_REF="${3}"
export RELEASE_ENV="${4}"
export RELEASE_VERSION="${5}"

export SOURCE_TYPE="${SOURCE_TYPE:-codehq}"

rm -rf tmp
mkdir tmp

cd tmp

for CONFIG_FILENAME in "carthage.config" "carthage-${RELEASE_ENV}.config"; do
  if [ "${SOURCE_TYPE}" = "codehq" ]; then
    export DOWNLOAD_URL="https://code.hq.twilio.com/api/v3/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/contents/${CONFIG_FILENAME}?ref=${GITHUB_REF}"
  elif [ "${SOURCE_TYPE}" = "github" ]; then
    export DOWNLOAD_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/contents/${CONFIG_FILENAME}?ref=${GITHUB_REF}"
  else
    echo "Unknown SOURCE_TYPE '${SOURCE_TYPE}'"
    exit 1
  fi
  curl -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" -H 'Accept: application/vnd.github.v3.raw' -o ${CONFIG_FILENAME} -L ${DOWNLOAD_URL}
  if [ -f "${CONFIG_FILENAME}" ]; then
    source "${CONFIG_FILENAME}"
  fi
done

PARAMS_OK=1
for PARAM in "RELEASE_VERSION" "PRODUCT_KEY" "PRODUCT_NAME" "DEST_FILENAME" "SOURCE" "DEST_GIT_REPOS" "CDN_URL"; do
  if [ -z "${!PARAM}" ]; then
    echo "Missing configuration for '${PARAM}'"
    PARAMS_OK=0
  fi
done
if [ ${PARAMS_OK} -eq 0 ]; then
  exit 1
fi

curl -O -L "${CDN_URL}"

mkdir source
cd source
tar xvzf ../${SOURCE}
cd ..

mkdir dest
cd dest
mkdir -p Build/iOS
mv ../source/twilio-${PRODUCT_KEY}-ios/* Build/iOS/
zip -r ../${DEST_FILENAME} *
cd ..

git clone ${DEST_GIT_REPOS} git
cd git
hub release create -d -a ../${DEST_FILENAME} -m "Releasing Twilio ${PRODUCT_NAME} iOS ${RELEASE_VERSION}" v${RELEASE_VERSION}
cd ..

