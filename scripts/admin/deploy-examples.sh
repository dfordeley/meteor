#!/bin/bash
set -e

if [ -z $1 ]; then
    echo "This script is to be used in advance of running automated QA on Rainforest"
    echo
    echo "Usage: ./deploy-example.sh RELEASE"
    exit 1
fi

RELEASE=$1

cd `dirname "$0"`/../..
METEOR_ROOT=`pwd`
LOG="$METEOR_ROOT/rainforestqa-deploy.log"
rm $LOG &> /dev/null || true

# Store the original contents in ~/.meteorsession, which contain the
# credentials for the currently logged-in user.  Restore that file if
# this script exits.
METEORSESSION_RESTORE="$METEOR_ROOT/.meteorsession-restore"
cp ~/.meteorsession "$METEORSESSION_RESTORE"
function cleanup {
    echo "Logs can be found at $METEOR_ROOT/rainforestqa-deploy.log"
    cp "$METEORSESSION_RESTORE" ~/.meteorsession
    rm "$METEORSESSION_RESTORE"
}
trap cleanup EXIT

# Now, login as rainforestqa. This way, anyone can access apps
# deployed by this script.
(echo rainforestqa; echo rainforestqa;) | meteor login

PREFIX=rainforest-test
EXAMPLES=`meteor create --list --release $RELEASE | grep '^  ' | cut -c 3-`

# This is where we'll create the example app to be deployed
rm -rf rainforestqa-tmp || true
mkdir rainforestqa-tmp
cd rainforestqa-tmp

for EXAMPLE in $EXAMPLES ; do
    HOSTNAME=$PREFIX-$EXAMPLE.meteor.com

    # `|| true` so that the script doesn't fail if the the app doesn't exist
    meteor deploy -D $HOSTNAME >> $LOG 2>&1 || true
    meteor create --example $EXAMPLE --release $RELEASE $EXAMPLE >> $LOG 2>&1
    cd $EXAMPLE
    echo -n "* Deploying $EXAMPLE to $HOSTNAME... "
    meteor deploy $HOSTNAME >> $LOG 2>&1
    echo DONE
    cd ..
done

