#!/bin/bash
# Created with package:mono_repo v1.2.1

if [ -z "$PKG" ]; then
  echo -e '\033[31mPKG environment variable must be set!\033[0m'
  exit 1
fi

if [ "$#" == "0" ]; then
  echo -e '\033[31mAt least one task argument must be provided!\033[0m'
  exit 1
fi

pushd $PKG
pub upgrade || exit $?

EXIT_CODE=0

while (( "$#" )); do
  TASK=$1
  case $TASK in
  command_0) echo
    echo -e '\033[1mTASK: command_0\033[22m'
    echo -e 'pub run pre_commit 0'
    pub run pre_commit 0 || EXIT_CODE=$?
    ;;
  command_1) echo
    echo -e '\033[1mTASK: command_1\033[22m'
    echo -e 'pub run pre_commit 1'
    pub run pre_commit 1 || EXIT_CODE=$?
    ;;
  command_2) echo
    echo -e '\033[1mTASK: command_2\033[22m'
    echo -e 'pub run pre_commit 2'
    pub run pre_commit 2 || EXIT_CODE=$?
    ;;
  command_3) echo
    echo -e '\033[1mTASK: command_3\033[22m'
    echo -e 'pub run build_runner test'
    pub run build_runner test || EXIT_CODE=$?
    ;;
  *) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
    EXIT_CODE=1
    ;;
  esac

  shift
done

exit $EXIT_CODE
