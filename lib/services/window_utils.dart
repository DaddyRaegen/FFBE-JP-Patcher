import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _SetWindowTextNative = Int32 Function(IntPtr hWnd, Pointer<Utf16> lpString);
typedef _SetWindowTextDart = int Function(int hWnd, Pointer<Utf16> lpString);

typedef _FindWindowNative = IntPtr Function(Pointer<Utf16> className, Pointer<Utf16> windowName);
typedef _FindWindowDart = int Function(Pointer<Utf16> className, Pointer<Utf16> windowName);

typedef _SetWindowPosNative = Int32 Function(IntPtr hWnd, IntPtr hWndInsertAfter, Int32 x, Int32 y, Int32 cx, Int32 cy, Uint32 flags);
typedef _SetWindowPosDart = int Function(int hWnd, int hWndInsertAfter, int x, int y, int cx, int cy, int flags);

typedef _GetWindowLongPtrNative = Int32 Function(IntPtr hWnd, Int32 nIndex);
typedef _GetWindowLongPtrDart = int Function(int hWnd, int nIndex);

typedef _SetWindowLongPtrNative = Int32 Function(IntPtr hWnd, Int32 nIndex, Int32 dwNewLong);
typedef _SetWindowLongPtrDart = int Function(int hWnd, int nIndex, int dwNewLong);

class WindowUtils {
  static final DynamicLibrary user32 = DynamicLibrary.open('user32.dll');

  static final _FindWindowDart _findWindow = user32
      .lookupFunction<_FindWindowNative, _FindWindowDart>('FindWindowW');

  static final _SetWindowTextDart _setWindowText = user32
      .lookupFunction<_SetWindowTextNative, _SetWindowTextDart>('SetWindowTextW');

  static final _SetWindowPosDart _setWindowPos = user32
      .lookupFunction<_SetWindowPosNative, _SetWindowPosDart>('SetWindowPos');

  static final _GetWindowLongPtrDart _getWindowLong = user32
      .lookupFunction<_GetWindowLongPtrNative, _GetWindowLongPtrDart>('GetWindowLongPtrW');

  static final _SetWindowLongPtrDart _setWindowLong = user32
      .lookupFunction<_SetWindowLongPtrNative, _SetWindowLongPtrDart>('SetWindowLongPtrW');

  static void disableResizeAndMaximize(int hWnd) {
    const int gwlStyle = -16;
    const int wsThickframe = 0x00040000;
    const int wsMaximizebox = 0x00010000;

    int currentStyles = _getWindowLong(hWnd, gwlStyle);
    int newStyles = currentStyles & ~(wsThickframe | wsMaximizebox);
    _setWindowLong(hWnd, gwlStyle, newStyles);
  }

  static void setWindowSizeAndTitle(int width, int height, String title) {
    final hWnd = _findWindow('FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16(), nullptr); // Pointers can rot in hell
    if (hWnd != 0) {
      _setWindowText(hWnd, title.toNativeUtf16());
      _setWindowPos(hWnd, 0, 0, 0, width, height, 0x0040);  // SWP_NOMOVE | SWP_NOZORDER
      disableResizeAndMaximize(hWnd);
    }
  }
}
