# SeiunEngine hxvlc — stable fork (2.3.1)

Local fork of [hxvlc 2.3.1](https://github.com/MAJigsaw77/hxvlc) (upstream `main`,
commit `6f78d99`) kept working for this project's toolchain and requirements
instead of the previous 2.2.5 fork.

* Haxe **4.3.7**
* hxcpp **git (haxe-4.3 branch)**
* lime 8.0.1 / openfl 9.2.1 (project forks)
* libVLC **3.0.23** (bundled)

## Why 2.3.1 and not 2.2.5

2.2.5 is the last version whose `Video` class can push decoded frames into a
CPU `BitmapData`, but its frame path is otherwise worse:

| | 2.2.5 (old fork) | 2.3.1 (this fork) |
|---|---|---|
| decoded-frame copy | runs on **VLC's own thread**, writing into the OpenFL bitmap while the main thread renders it | marshalled to the **main thread** (`MainLoop.runInMainThread`) — upstream's own fix for the flixel/OpenFL crashes |
| `load()` on a missing file | returns `true` (silent black screen) | returns `false` |
| libVLC | 3.0.21 | 3.0.23 |
| internals | monolith `Video` | `hxvlc.impl.{Instance,Media,MediaPlayer,VideoOutput,AudioOutput}` |
| `initAsync` | fork-only patch | native upstream API |

## Patches vs upstream 2.3.1

1. `source/hxvlc/openfl/Video.hx` — **restored the CPU `BitmapData` render path**.
   Upstream is texture-only: with no `Stage3D` context `onFormatSetup` never
   fires (permanent black screen) and `bitmapData.image == null` so mods doing
   `loadGraphic(video.bitmapData)` get black frames. Added
   `Video.useTexture` (static) and `Video.forceRendering`; when
   `useTexture = false` (or the stage has no Context3D) frames are copied into
   the bitmap's lime `BGRA32` image, which matches VLC's `RV32` byte layout, so
   the copy is a straight `Bytes.blit` into the existing buffer (no per-frame
   allocation).
2. `source/hxvlc/util/Handle.hx` — `initAsync()` is deduplicated with a mutex +
   `asyncStarting` flag. Two concurrent calls could both see `loading == false`
   and create two libVLC instances.
3. `source/hxvlc/flixel/FlxInternalVideo.hx` — instance registry with
   `disposeAll()` / `getLiveCount()` and an idempotent `dispose()`, so a video
   leaked by a mod cannot survive a level switch.
4. `source/hxvlc/impl/Instance.hx` — `--file-caching=0` for local cutscenes
   (opt out with `-DHXVLC_NO_FILE_CACHING_ZERO`).
5. `haxelib.json` — empty `dependencies` entries removed; otherwise haxelib
   resolves `hxcpp`/`lime`/`openfl` to their latest releases and drags the toolchain
   off the pinned versions.

## Usage

`hmm.json` / `Project.xml` expect the library through haxelib. Point it at this
checkout while developing:

```
haxelib dev hxvlc <path-to-this-folder>
```

To make it permanent, push this branch and update the `hxvlc` entry in
`hmm.json` (currently `https://github.com/mohong2/hxvlc.git`).

## Verification

See `../hxvlc-tests/` for the A/B benchmark harness and its measured results.
```
