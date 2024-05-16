#!/bin/zsh

ARCHIVE_PATH="build/appbundler.xcarchive"

xcodebuild archive \
    -configuration Release \
    -scheme AppBundler \
    -archivePath $ARCHIVE_PATH

xcodebuild -exportArchive \
     -archivePath $ARCHIVE_PATH \
     -exportPath "build/" \
     -exportOptionsPlist AppBundler/Info.plist

