# Initial Setup

You'll need a public github project to own the releases for Carthage to consume using this approach.  Create a new repository and add at least a README to the project.

I am using the `hub` command line tool for publishing the release, it can be installed with `brew install hub`.

Last, you'll need a configuration specified in the configs/ directory.

# Producing

Publishing a release requires authenticating with github (or code.hq).  To do this, we will use github auth tokens.  To create one, visit one of the following URLs:

[code.hq](https://code.hq.twilio.com/settings/tokens/new)

[github](https://github.com/settings/tokens/new)

And create a new token with only the `repo` checkbox ticked.

Distributing a release:

    GITHUB_OAUTH_TOKEN=<token_from_above> ./distribute-for-carthage.sh <owner> <repos> <ref> <env> <version>
    
    owner - The code.hq.twilio.com organization, e.g. 'client'
    repos - The code.hq.twilio.com project, e.g. 'twilio-chat-ios'
    ref - The git ref, e.g. 'master' or 'release-1.0.0'
    env - An environment, e.g. 'prod' or 'stage'
    verison - The version to release as, e.g. '1.0.0' or '2.0.0-rc1'
    
    Example:
    GITHUB_OAUTH_TOKEN=<code-hq-token> ./distribute-for-carthage.sh client video-ios 2.0 prod 2.0.0-preview8

At least two config files must live in your project, carthage.config and at least one `carthage-<env>.config`.

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
    github "twilio/twilio-chat-ios"
    github "twilio/twilio-accessmanager-ios"
    _DONE_

Or for Sync:

    cat > Cartfile << _DONE_
    github "twilio/twilio-sync-ios"
    _DONE_

Boostrap carthage:

    brew install carthage # if needed
    carthage bootstrap

Since Carthage only manages versions and the download of the framework, not integration of it, you'll need to complete the process using the manual integration steps found at:  https://www.twilio.com/docs/api/chat/sdks#manual-integration

Internal RC's:

Internal RC's can be supported by distributing to a private github repository.  The release gets published the same way but instead of the github lines specified above, the following is used:

    cat > Cartfile << _DONE_
    github "twilio/twilio-chat-ios-internal"
    github "twilio/twilio-accessmanager-ios-internal"
    _DONE_

This requires the username and [auth token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) to either be included in the Cartfile as part of the url "user:pass@github.com" or previously stored in the keychain:

    git config --global credential.helper osxkeychain
    git clone https://github.com/<anyproject> /tmp/anyproject-temp # this is just to force github to authenticate you
    # log in using username and auth token, the auth token is the same as is generated above as part of the producing step.

From this point, carthage should use your keychain for the credentials and your `carthage bootstrap` should work.

