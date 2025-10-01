import "dart:async";
import "dart:ffi";

import "package:ffi/ffi.dart";
import "package:sdl3/sdl3.dart" as sdl;

/// A manager class for the SDL library.
///
/// Be sure to call [init] before using any SDL functionality and to call
/// [dispose] when you're done.
class SdlLibrary {
  /// Whether the library has already been initialized.
  static bool isInitialized = false;

  static Timer? _eventLoop;

  static final _arena = Arena();
  static final Pointer<sdl.SdlEvent> _eventPointer = _arena<sdl.SdlEvent>();

  static void _update(dynamic _) {
    sdl.sdlPumpEvents();
    sdl.sdlUpdateGamepads();
    while (true) {
      if (!_eventPointer.poll()) break;
      switch (_eventPointer.type) {
        case sdl.SDL_EVENT_QUIT:
          return dispose();
      }
    }
  }

  /// Initializes the SDL library and starts the event loop.
  static bool init({
    Duration eventLoopInterval = const Duration(milliseconds: 100),
  }) {
    if (isInitialized) return true;
    // Without this hint, events will not process on Windows.
    // For more details, see: https://github.com/libsdl-org/SDL/issues/10576
    sdl.sdlSetHint(sdl.SDL_HINT_JOYSTICK_THREAD, "1");
    final result = sdl.sdlInit(sdl.SDL_INIT_GAMEPAD);
    if (!result) return false;
    _eventLoop = Timer.periodic(eventLoopInterval, _update);
    isInitialized = true;
    return true;
  }

  /// Closes the library and stops the event loop.
  static void dispose() {
    _eventLoop?.cancel();
    sdl.sdlPumpEvents();
    while (true) {
      if (!sdl.sdlPollEvent(_eventPointer)) break;
    }
    sdl.sdlQuit();
    _arena.releaseAll();
    isInitialized = false;
  }

  /// Gets the previous error since the last call to [clearError], if any.
  static String? getError() => sdl.sdlGetError();

  /// Clears the error from [getError].
  static void clearError() => sdl.sdlClearError();
}
