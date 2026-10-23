#!/usr/bin/env bash
#
# build.sh - assemble the Steam Workshop upload bundle.
#
# Usage:  ./build.sh <output-dir>
#
# Copies the committed mod tree and Workshop metadata into <output-dir>, laid
# out the way the in-game Workshop uploader expects. All inputs come from
# committed files; nothing is hardcoded:
#   - Mod id      = the single directory under Contents/mods/
#   - Workshop id = the id= field in workshop-meta/workshop.txt (required)
#   - Mod tree    = Contents/mods/<MODID>/
#   - Metadata    = workshop-meta/{workshop.txt,preview.png,UPLOAD.md}
#
# Output layout:
#   <output-dir>/<MODID>/Contents/mods/<MODID>/...   (mod tree, .gitkeep stripped)
#   <output-dir>/<MODID>/workshop.txt
#   <output-dir>/<MODID>/preview.png
#   <output-dir>/UPLOAD.md
set -euo pipefail
cd "$(dirname "$0")"

OUT="${1:-}"
if [ -z "$OUT" ]; then
    echo "Usage: $0 <output-dir>" >&2
    exit 1
fi

# --- Derive the mod id from the committed tree (bash 3.2 compatible) ---------
MODID=""
count=0
for d in Contents/mods/*/; do
    [ -d "$d" ] || continue
    MODID="$(basename "$d")"
    count=$((count + 1))
done
if [ "$count" -ne 1 ]; then
    echo "ERROR: expected exactly one mod under Contents/mods/, found $count" >&2
    exit 1
fi
echo "== Mod id: $MODID =="

# --- Steam Workshop item id (committed in workshop-meta/workshop.txt) ---------
WORKSHOP_ID="$(grep -E '^id=' workshop-meta/workshop.txt | head -1 | cut -d= -f2)"
if [ -z "$WORKSHOP_ID" ]; then
    echo "WARNING: no Workshop id in workshop-meta/workshop.txt (id= is blank)." >&2
    echo "  This is expected for a FIRST publish -- Steam assigns the id, then" >&2
    echo "  paste it into workshop.txt so future updates target the same item." >&2
else
    echo "== Workshop item id: $WORKSHOP_ID =="
fi

# --- Assemble the bundle into <output-dir> ----------------------------------
DEST="$OUT/$MODID"
echo "== Assembling bundle in $OUT =="
rm -rf "$DEST" "$OUT/UPLOAD.md"
mkdir -p "$DEST/Contents/mods"

cp -R "Contents/mods/$MODID" "$DEST/Contents/mods/$MODID"
find "$DEST/Contents" -name '.gitkeep' -delete

cp workshop-meta/workshop.txt "$DEST/workshop.txt"
cp workshop-meta/preview.png  "$DEST/preview.png"
cp workshop-meta/UPLOAD.md    "$OUT/UPLOAD.md"

find "$OUT" -name '.DS_Store' -delete

echo "== Done =="
echo "  $DEST"
