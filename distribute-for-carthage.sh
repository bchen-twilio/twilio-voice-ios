#!/bin/bash -e

if [ "$#" -ne 1 ]; then
    echo "Usage: ${0} <config>"
    exit 1
fi

CONFIG_NAME="${1}"

if [ ! -f "configs/${CONFIG_NAME}" ]; then
  echo "Usage: ${0} <config>"
  exit 1
fi

source "configs/${CONFIG_NAME}"

if [ -z "${VERSION}" -o -z "${PRODUCT_KEY}" -o -z "${PRODUCT_NAME}" -o -z "${DEST}" -o -z "${GIT_REPOS}" -o -z "${SOURCE}" ]; then
  echo "Configuration in configs/${CONFIG_NAME} is invalid, please verify it."
  exit 1
fi

mkdir tmp || true
cd tmp

if [ ! -f ${SOURCE} ]; then
  wget https://media.twiliocdn.com/sdk/ios/${PRODUCT_KEY}/releases/${VERSION}/${SOURCE}
fi

rm -rf source dest git
rm -f ./${DEST}

mkdir source
cd source
tar xvzf ../${SOURCE}
cd ..

mkdir dest
cd dest
mkdir -p Build/iOS
mv ../source/twilio-${PRODUCT_KEY}-ios/* Build/iOS/
zip -r ../${DEST} *
cd ..

git clone ${GIT_REPOS} git
cd git
hub release create -d -a ../${DEST} -m "Releasing Twilio ${PRODUCT_NAME} iOS ${VERSION}" v${VERSION}
cd ..
