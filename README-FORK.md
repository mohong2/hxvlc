# SeiunEngine hxvlc fork (2.2.5)

Local git-managed fork of [hxvlc 2.2.5](https://github.com/MAJigsaw77/hxvlc)
kept compatible with this project's pinned toolchain:

* Haxe **4.2.5**
* hxcpp **4.2.1**
* lime 8.0.1 / openfl 9.2.1

## Patches vs upstream 2.2.5

1. `source/hxvlc/openfl/Video.hx`
   - `Lib.current.stage?.context3D` -> null-safe check without `?.`
     (`?.` is Haxe 4.3+ syntax)
   - `LibVLC.media_player_set_time(mediaPlayer.raw, value)` -> `cast value`
     (`haxe.Int64` is not implicitly convertible to `LibVLC_Time_T`)
2. `source/hxvlc/util/Handle.hx`
   - Replaced `cpp.StdVector<ConstCharStar>` with a concrete
     `@:native('std::vector<const char*>')` extern. Haxe 4.2.5's cpp codegen
     drops the template argument of generic `@:native` extern classes,
     producing invalid `std::vector` code; the concrete binding fixes it.

## Usage

Referenced from `hmm.json` as a git dependency:

```json
{ "name": "hxvlc", "type": "git", "url": "./hxvlc-local", "ref": "master" }
```

To redistribute, push this folder to a Git host and update the `url` in
`hmm.json` accordingly.
