#!/bin/sh

# install appledoc from here: https://github.com/tomaz/appledoc

appledoc --company-id com.swiftype\
  --project-company='Swiftype, Inc'\
  --project-name=SwiftypeTouch\
  --no-create-docset\
  --index-desc docs/index-desc.md\
  -o docs/\
  ./SwiftypeTouch/
