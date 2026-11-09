#!/usr/bin/env bash
# Builds dist/<id>-<version>.plasmoid, the file to upload to the KDE Store.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
read -r id ver < <(python3 -c 'import json,sys; m=json.load(open(sys.argv[1]))["KPlugin"]; print(m["Id"], m["Version"])' "$here/plasmoid/metadata.json")
mkdir -p "$here/dist"
out="$here/dist/$id-$ver.plasmoid"
rm -f "$out"
(cd "$here/plasmoid" && zip -r -X -q "$out" metadata.json contents -x '*.bak*' '*~' '*.orig')
echo "built $out"
unzip -l "$out"
