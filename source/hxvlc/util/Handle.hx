package hxvlc.util;

import hxvlc.impl.Instance;
import hxvlc.impl.externs.LibVLC;

/** This class manages the global instance of LibVLC used by the library. */
class Handle
{
	/** The instance of LibVLC that is used globally. */
	public static var sharedInstance:Null<Instance>;

	/** Indicates whether the instance is still loading. */
	public static var loading(default, null):Bool = false;

	/**
	 * Initializes the global instance of LibVLC if it isn't already.
	 * 
	 * @param options The additional options you can add to the instance.
	 * 
	 * @return `true` if the instance was created successfully or `false` if there was an error or the instance is still loading.
	 */
	public static function init(?options:Array<String>):Bool
	{
		if (!loading)
		{
			var result:Bool = true;

			loading = true;

			if (sharedInstance == null)
			{
				sharedInstance = new Instance(options);

				if (sharedInstance?.nativeInstance != null)
				{
					#if HXVLC_LOGGING
					sharedInstance.setLog(function(info:haxe.PosInfos, level:Int, msg:String):Void
					{
						var message:String = msg;

						#if HXVLC_SHOW_LOG_TYPE
						switch (level)
						{
							case 0: /** Debug message */
								message = '[DEBUG] $message';
							case 2: /** Important informational message */
								message = '[NOTICE] $message';
							case 3: /** Warning (potential error) message */
								message = '[WARNING] $message';
							case 4: /** Error message */
								message = '[ERROR] $message';
						}
						#end

						haxe.Log.trace(message, info);
					});
					#end
				}
				else
				{
					sharedInstance = null;

					final errmsg:String = LibVLC.errmsg();

					if (errmsg != null && errmsg.length > 0)
						throw 'Failed to initialize the global instance of LibVLC: $errmsg';
					else
						throw 'Failed to initialize the global instance of LibVLC';

					result = false;
				}
			}

			loading = false;

			return result;
		}

		return false;
	}

	/**
	 * Initializes the global instance of LibVLC asynchronously if it isn't already.
	 * 
	 * @param options The additional options you can add to the instance.
	 * @param finishCallback A callback that is called after it finishes loading.
	 */
	/**
	 * True while an async init thread has been requested but has not started yet.
	 * 
	 * Without this guard two concurrent `initAsync()` calls can both observe
	 * `loading == false` (the worker only sets it once it runs), queue two
	 * threads and end up creating two LibVLC instances.
	 */
	@:noCompletion
	private static var asyncStarting:Bool = false;

	@:noCompletion
	private static var initMutex:sys.thread.Mutex = new sys.thread.Mutex();

	/**
	 * Initializes the global instance of LibVLC asynchronously if it isn't already.
	 * 
	 * @param options The additional options you can add to the instance.
	 * @param finishCallback A callback that is called after it finishes loading.
	 */
	public static function initAsync(?options:Array<String>, ?finishCallback:Bool->Void):Void
	{
		initMutex.acquire();

		if (loading || asyncStarting)
		{
			initMutex.release();
			return;
		}

		asyncStarting = true;
		initMutex.release();

		try
		{
			MainLoop.addThread(function():Void
			{
				final success:Bool = init(options);

				initMutex.acquire();
				asyncStarting = false;
				initMutex.release();

				if (finishCallback != null)
					MainLoop.runInMainThread(finishCallback.bind(success));
			});
		}
		catch (e:Dynamic)
		{
			initMutex.acquire();
			asyncStarting = false;
			initMutex.release();

			throw e;
		}
	}

	/**
	 * Frees the global instance of LibVLC.
	 */
	public static function dispose():Void
	{
		if (sharedInstance == null)
			return;

		sharedInstance.destroy();
		sharedInstance = null;
	}
}
