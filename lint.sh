#!/bin/sh

#  lint.sh
#  HttpRequestHook
#
#  Created by Tengnäs Nilsson Pontus on 2021-03-21.
#  

if which swiftlint >/dev/null; then
  swiftlint autocorrect && swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
