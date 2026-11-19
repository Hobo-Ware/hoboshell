#!/bin/sh
set -eu

developer_dir="$(xcode-select -p)"
frameworks="$developer_dir/Library/Developer/Frameworks"
interop_libs="$developer_dir/Library/Developer/usr/lib"
testing_plugins="$developer_dir/usr/lib/swift/host/plugins/testing"

case "$developer_dir" in
  */CommandLineTools)
    exec swift test \
      -Xswiftc -F -Xswiftc "$frameworks" \
      -Xswiftc -plugin-path -Xswiftc "$testing_plugins" \
      -Xlinker -F -Xlinker "$frameworks" \
      -Xlinker -rpath -Xlinker "$frameworks" \
      -Xlinker -rpath -Xlinker "$interop_libs" \
      "$@"
    ;;
  *)
    exec swift test "$@"
    ;;
esac
