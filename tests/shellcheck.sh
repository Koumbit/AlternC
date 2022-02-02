#!/usr/bin/env bash
if [ -z "$TARGET" ] ; then
    TARGET=/target
fi
grep --exclude-dir=$TARGET/.git/ --exclude-dir=$TARGET/vendor/ -l -r -e '#!/bin/[bash|sh]' $TARGET | uniq | xargs shellcheck -f checkstyle '{}+'
