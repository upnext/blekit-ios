#!/bin/sh

if [ -f /usr/local/bin/appledoc ]
then
/usr/local/bin/appledoc \
--project-name BLEKit \
--project-company "UP-NEXT"  \
--company-id com.up-next \
--no-create-docset \
--no-repeat-first-par \
--create-html \
--logformat xcode \
--output docs \
--explicit-crossref \
--exclude-output BLEKit/Private \
BLEKit
fi