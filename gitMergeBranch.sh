#!/bin/bash

if [ "$#" -eq 2 ]; then
  git merge --no-ff --no-commit $1
  git reset HEAD lib/utils/algolia_const.dart
  git checkout -- lib/utils/algolia_const.dart

  git reset HEAD android/app/google-services.json
  git checkout -- android/app/google-services.json

  git reset HEAD ios/Runner/GoogleService-Info.plist
  git checkout -- ios/Runner/GoogleService-Info.plist

  git commit -m "$2"
  echo Merged Succesfully
else
  echo Please provide the name of the branch and a commit message
fi