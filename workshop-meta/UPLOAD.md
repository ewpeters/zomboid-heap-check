# Uploading Heap Warning to the Steam Workshop

`build.sh <output-dir>` assembles a ready-to-publish Workshop bundle into
`<output-dir>/HeapWarning/` plus `UPLOAD.md` at the top.

## First publish (new item)

1. Build the bundle:  `./build.sh /tmp/heapwarning`  (id is blank -> prints a warning, that's expected)
2. Copy the `HeapWarning/` folder into your PZ Workshop staging dir:
   `C:\Users\<you>\Zomboid\Workshop\HeapWarning\`
3. In Project Zomboid: **Main Menu -> Workshop -> Create and Update Mods**,
   pick `HeapWarning`, set a preview image, publish.
4. Steam assigns the item id. Paste it back into `workshop-meta/workshop.txt`
   (`id=<number>`) and commit, so future updates target the same item instead
   of creating a new one.

## Updates

Re-run `./build.sh <dir>`, refresh the staging folder's `Contents/` from the new
build, keep the existing `workshop.txt` (with the real `id=`), and re-run the
in-game uploader.

## Verify the heap read first

The heap value is read by reflecting into `java.lang.Runtime.getRuntime():maxMemory()`.
There's no vanilla Lua precedent for this, so confirm it works in-game before
trusting the warning. In the in-game Lua console (or debug console) run:

    HeapWarning.debugPrintHeap()

It prints `[HeapWarning] debug: readMaxHeapMB() = <N> MB`. If it prints `nil`,
the reflection path isn't available on this runtime and the mod stays silent
(it never shows a false warning). On connect, the mod also logs
`[HeapWarning] max heap = <N> MB, minimum = <M> MB` to the console/log.

## Notes

- `preview.png`, `poster.png`, `icon.png` are placeholders - replace with real art.
- Build 42 loads sandbox translations from `Sandbox.json` (not the B41
  `Sandbox_EN.txt`). If labels show as raw `Sandbox_...` keys, that file is
  missing or malformed.
- Default threshold is 4096 MB (4 GB). Set the sandbox option to 0 to disable.
