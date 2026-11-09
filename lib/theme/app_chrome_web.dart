// Web-only: compiled in through the `dart.library.js_interop` conditional
// import in app_chrome.dart. Uses dart:js_interop (not the deprecated
// dart:html / dart:js), so the seed analyzes clean.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

String _hex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

void _setMeta(String name, String content) {
  final document = globalContext.getProperty<JSObject?>('document'.toJS);
  if (document == null) return;
  final head = document.getProperty<JSObject?>('head'.toJS);
  if (head == null) return;
  var el = document.callMethod<JSObject?>(
    'querySelector'.toJS,
    'meta[name="$name"]'.toJS,
  );
  if (el == null) {
    el = document.callMethod<JSObject>('createElement'.toJS, 'meta'.toJS);
    el.callMethod<JSAny?>('setAttribute'.toJS, 'name'.toJS, name.toJS);
    head.callMethod<JSAny?>('appendChild'.toJS, el);
  }
  el.callMethod<JSAny?>('setAttribute'.toJS, 'content'.toJS, content.toJS);
}

/// Push this screen's chrome into FlutterGo preview letterboxing + theme-color.
void syncPreviewChrome(Color top, Color bottom) {
  final topHex = _hex(top);
  final bottomHex = _hex(bottom);
  _setMeta('theme-color', topHex);
  _setMeta('od-chrome-top', topHex);
  _setMeta('od-chrome-bottom', bottomHex);
  try {
    if (globalContext.has('FgSetChrome')) {
      globalContext.callMethod<JSAny?>(
        'FgSetChrome'.toJS,
        topHex.toJS,
        bottomHex.toJS,
      );
    }
  } catch (_) {}
}
