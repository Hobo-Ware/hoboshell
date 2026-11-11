#!/bin/sh
set -eu

developer_dir="$(xcode-select -p)"
frameworks="$developer_dir/Library/Developer/Frameworks"
interop_libs="$developer_dir/Library/Developer/usr/lib"

case "$developer_dir" in
  */CommandLineTools)
    exec swift test \
      -Xswiftc -F -Xswiftc "$frameworks" \
      -Xlinker -F -Xlinker "$frameworks" \
      -Xlinker -rpath -Xlinker "$frameworks" \
      -Xlinker -rpath -Xlinker "$interop_libs" \
      "$@"
    ;;
  *)
    exec swift test "$@"
    ;;
esac
