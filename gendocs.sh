#!/bin/sh

# install appledoc from here: https://github.com/tomaz/appledoc

appledoc --company-id com.swiftype\
  --project-company=Swiftype\
  --project-name=SwiftypeTouch\
  --no-create-docset\
  -o docs/\
  API/SwiftypeTouch/SwiftypeTouch/
