# Initial Setup

You'll need a public github project to own the releases for Carthage to consume using this approach.  Create a new repository and add at least a README to the project.

I am using the `hub` command line tool for publishing the release, it can be installed with `brew install hub`.

Last, you'll need a configuration specified in the configs/ directory.

# Producing

    ./distribute-for-carthage.sh <owner> <repos> <ref> <env> <version>

    owner - The code.hq.twilio.com organization, e.g. 'client'
    repos - The code.hq.twilio.com project, e.g. 'twilio-chat-ios'
    ref - The git ref, e.g. 'master' or 'release-1.0.0'
    env - An environment, e.g. 'prod' or 'stage'
    verison - The version to release as, e.g. '1.0.0' or '2.0.0-rc1'

At least two config files must live in your project, carthage.config and at least one carthage-<env>.config.

In carthage.config, the expected variables defined are along the lines of:

    PRODUCT_KEY="accessmanager" # lower case product name, e.g. accessmanager, chat, sync, video, voice
    PRODUCT_NAME="Access Manager" # human readable name, used for git release comment
    DEST_FILENAME="TwilioAccessManager.framework.zip" # eventual filename for carthage zip file, recomended as frameworkname.zip
    SOURCE="twilio-${PRODUCT_KEY}-ios-${RELEASE_VERSION}.tar.bz2" # the filename pattern distributed to the cdn that will be downloaded

In each carthage-&lt;env&gt;.config, you will declare the destination github repository for the release and the CDN path to obtain the release from.

An example carthage-prod.config is:

    DEST_GIT_REPOS="git@github.com:twilio/twilio-${PRODUCT_KEY}-ios.git"
    CDN_URL="https://media.twiliocdn.com/sdk/ios/${PRODUCT_KEY}/releases/${RELEASE_VERSION}/${SOURCE}"

An example carthage-stage.config is:

    DEST_GIT_REPOS="git@github.com:twilio/twilio-${PRODUCT_KEY}-ios-internal.git"
    CDN_URL="https://stage.twiliocdn.com/sdk/ios/${PRODUCT_KEY}/releases/${RELEASE_VERSION}/${SOURCE}"

At the moment, hub will create a draft release so it can be examined before
fully releasing.  We can make this optional or make it always release
immediately.

# Consuming

Download the Chat iOS Demo application:

    wget https://github.com/twilio/twilio-chat-demo-ios/archive/master.zip

Create a Cartfile:

    cat > Cartfile << _DONE_
    github "rbeiter/twilio-chat-ios"
    github "rbeiter/twilio-accessmanager-ios"
    _DONE_

Or for Sync:

    cat > Cartfile << _DONE_
    github "rbeiter/twilio-sync-ios"
    _DONE_

Boostrap carthage:

    brew install carthage # if needed
    carthage bootstrap

Since Carthage only manages versions and the download of the framework, not integration of it, you'll need to complete the process using the manual integration steps found at:  https://www.twilio.com/docs/api/chat/sdks#manual-integration

Internal RC's:

Internal RC's can be supported by distributing to a private github repository.  The release gets published the same way but instead of the github lines specified above, the following is used:

This requires the username and password (or [auth token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)) to either be included in the Cartfile as part of the url "user:pass@github.com" or previously stored in the keychain:

    git config --global credential.helper osxkeychain
    git checkout https://github.com/...
    # log in using username and password or username and auth token

From this point, carthage should use your keychain for the credentials.
