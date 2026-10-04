package hxvlc.flixel;

#if flixel
import flixel.FlxG;

import haxe.io.Bytes;

using StringTools;

/** A wrapper class for displaying video files in HaxeFlixel using the `Video` class. */
class FlxInternalVideo extends hxvlc.openfl.Video
{
	/** The volume adjustment. */
	public var volumeAdjust(default, set):Float = 1.0;

	// ------------------------------------------------------------------
	// Instance tracking + cleanup safety net.
	//
	// Mods create videos through Lua/HScript and frequently never dispose
	// them. Every live instance keeps a libVLC media player decoding frames,
	// so one leaked video per level entry quickly tanks the framerate.
	// `disposeAll()` is a safety net (PlayState.destroy) so no video
	// survives a level switch.
	// ------------------------------------------------------------------

	static var _instances:Array<FlxInternalVideo> = [];

	@:noCompletion private var _disposed:Bool = false;

	/** Dispose every still-alive video instance (idempotent). */
	public static function disposeAll():Void
	{
		if (_instances.length == 0)
			return;

		final copy:Array<FlxInternalVideo> = _instances.copy();

		for (video in copy)
		{
			if (video != null)
			{
				try
				{
					video.dispose();
				}
				catch (e:Dynamic)
				{
					// Never let a leaked video take down the level switch.
				}
			}
		}
	}

	/** Number of live (not yet disposed) video instances - for diagnostics. */
	public static function getLiveCount():Int
	{
		return _instances.length;
	}

	@:noCompletion
	private var resumeOnFocus:Bool = false;

	@:inheritDoc(hxvlc.openfl.Video.new)
	public function new(?instance:hxvlc.impl.Instance, smoothing:Bool = true):Void
	{
		super(instance, smoothing);

		_disposed = false;
		_instances.push(this);
	}

	@:inheritDoc(hxvlc.openfl.Video.load)
	public override function load(location:hxvlc.openfl.Location, ?options:Array<String>):Bool
	{
		final loaded:Bool = super.load(location, options);

		if (loaded)
		{
			if (!FlxG.signals.focusGained.has(onFocusGained))
				FlxG.signals.focusGained.add(onFocusGained);

			if (!FlxG.signals.focusLost.has(onFocusLost))
				FlxG.signals.focusLost.add(onFocusLost);

			#if (FLX_SOUND_SYSTEM && flixel >= version("5.9.0"))
			if (!FlxG.sound.onVolumeChange.has(onVolumeChange))
				FlxG.sound.onVolumeChange.add(onVolumeChange);
			#elseif (FLX_SOUND_SYSTEM && flixel < version("5.9.0"))
			if (!FlxG.signals.postUpdate.has(onVolumeUpdate))
				FlxG.signals.postUpdate.add(onVolumeUpdate);
			#end

			onVolumeChange(#if FLX_SOUND_SYSTEM (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume #else 1 #end);
		}

		return loaded;
	}

	@:inheritDoc(hxvlc.openfl.Video.precache)
	public override function precache(location:hxvlc.openfl.Location, ?options:Array<String>):Bool
	{
		final loaded:Bool = super.precache(location, options);

		if (loaded)
		{
			if (!FlxG.signals.focusGained.has(onFocusGained))
				FlxG.signals.focusGained.add(onFocusGained);

			if (!FlxG.signals.focusLost.has(onFocusLost))
				FlxG.signals.focusLost.add(onFocusLost);

			#if (FLX_SOUND_SYSTEM && flixel >= version("5.9.0"))
			if (!FlxG.sound.onVolumeChange.has(onVolumeChange))
				FlxG.sound.onVolumeChange.add(onVolumeChange);
			#elseif (FLX_SOUND_SYSTEM && flixel < version("5.9.0"))
			if (!FlxG.signals.postUpdate.has(onVolumeUpdate))
				FlxG.signals.postUpdate.add(onVolumeUpdate);
			#end

			onVolumeChange(#if FLX_SOUND_SYSTEM (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume #else 1 #end);
		}

		return loaded;
	}

	@:inheritDoc(hxvlc.openfl.Video.dispose)
	public override function dispose():Void
	{
		if (_disposed)
			return;

		_disposed = true;

		_instances.remove(this);

		if (FlxG.signals.focusGained.has(onFocusGained))
			FlxG.signals.focusGained.remove(onFocusGained);

		if (FlxG.signals.focusLost.has(onFocusLost))
			FlxG.signals.focusLost.remove(onFocusLost);

		#if (FLX_SOUND_SYSTEM && flixel >= version("5.9.0"))
		if (FlxG.sound.onVolumeChange.has(onVolumeChange))
			FlxG.sound.onVolumeChange.remove(onVolumeChange);
		#elseif (FLX_SOUND_SYSTEM && flixel < version("5.9.0"))
		if (FlxG.signals.postUpdate.has(onVolumeUpdate))
			FlxG.signals.postUpdate.remove(onVolumeUpdate);
		#end

		super.dispose();
	}

	@:noCompletion
	private function onFocusGained():Void
	{
		#if !mobile
		if (!FlxG.autoPause)
			return;
		#end

		if (resumeOnFocus)
		{
			resumeOnFocus = false;

			resume();
		}
	}

	@:noCompletion
	private function onFocusLost():Void
	{
		#if !mobile
		if (!FlxG.autoPause)
			return;
		#end

		resumeOnFocus = isPlaying;

		pause();
	}

	#if (FLX_SOUND_SYSTEM && flixel < version("5.9.0"))
	@:noCompletion
	private function onVolumeUpdate():Void
	{
		onVolumeChange(#if FLX_SOUND_SYSTEM (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume #else 1 #end);
	}
	#end

	@:noCompletion
	private function onVolumeChange(vol:Float):Void
	{
		volume = Math.abs(vol * volumeAdjust);
	}

	@:noCompletion
	private function set_volumeAdjust(value:Float):Float
	{
		onVolumeChange(#if FLX_SOUND_SYSTEM (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume #else 1 #end);

		return volumeAdjust = value;
	}
}
#end
