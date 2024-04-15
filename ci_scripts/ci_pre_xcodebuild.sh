#!/bin/bash
if [[ $CI_XCODEBUILD_ACTION = 'build' ]]; then
    if which swiftlint >/dev/null; then
        (cd $PROJECT_DIR; swiftlint --strict)
    else
        echo "warning: swiftlint not installed!"
    fi
fi

