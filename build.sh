#!/bin/bash
xcodebuild -project AeroIndicator.xcodeproj -scheme AeroIndicator -configuration Release -derivedDataPath build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO &&
    rm -rf /opt/homebrew/opt/aeroIndicator/AeroIndicator.app &&
    cp -r build/Build/Products/Release/AeroIndicator.app /opt/homebrew/opt/aeroIndicator/ &&
    ln -sf /opt/homebrew/opt/aeroIndicator/AeroIndicator.app/Contents/MacOS/AeroIndicator /opt/homebrew/bin/aeroindicator &&
    aeroindicator --restart-service
