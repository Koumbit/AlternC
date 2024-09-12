#!/usr/bin/env bash
if [ -z "$TARGET" ] ; then
    TARGET='/target'
fi
if [ -n "$CLOVER" ] ; then
    CLOVER="--coverage-clover=$CLOVER"
fi
if [ -n "$JUNIT" ] ; then
    JUNIT="--log-junit=$JUNIT"
fi

cd $TARGET/phpunit || exit 1
phpunit "$CLOVER" "$JUNIT"
