#!/usr/bin/env bash
if [ -z "$TARGET" ] ; then
    TARGET=/target
fi
grep --exclude-dir=.git --exclude-dir=vendor -l -r -e '#!/bin/[bash|sh]' $TARGET | uniq | xargs shellcheck -f checkstyle
