/** overwrite.dart implements overwrite mode in a text area element */
library overwrite;

import "dart:html";
import "dart:async";
import 'package:logging/logging.dart';

/**
 * A wrapper class for a [TextAreaElement] to support overwrite editing. Upon
 * construction, the element will be put in to overwrite mode, in which typing,
 * cut, copy, and paste events are captured ot overwrite the current contents
 * of the element. Call setMode with OverwriteMode.INSERT to set the element
 * back to normal editing, and OverwriteMode.OVERWRITE to set overwrite mode.
 *
 * [onOverwriteEvent] provides a stream of events describing changes that are
 * made to the value of the element by typing ([OverwriteEvent.EDIT]), by
 * padding the element with spaces to fill the width of the element
 * ([OverwriteEvent.PAD]), or by explicitly setting the value
 * ([OverwriteEvent.VALUE]).
 *
 * The value of the element can be set programmatically by assigning to
 * [OverwriteElement.value]. Setting the value of the underlying TextAreaElement
 * will circumvent the functionality of this class and should not be done.
 */
// TODO delete padded spaces when setting to INSERT?
class OverwriteElement {
  static var _logger = new Logger('overwrite');
  // a map from TextAreaElement hashes to OverwriteElements
  static Map<int, OverwriteElement> _objects = new Map<int, OverwriteElement>();
  // a stream controller for change events on the element
  StreamController _streamController;

  // The element to implement overwrite mode in
  TextAreaElement _element;
  // An element used to calculate text width
  PreElement _widthEl;

  StreamSubscription _focusSub;
  StreamSubscription _pasteSub;
  StreamSubscription _cutSub;
  StreamSubscription _downSub;
  StreamSubscription _pressSub;
  StreamSubscription _resizeSub;

  // The current insert mode
  OverwriteMode _mode = OverwriteMode.OVERWRITE;

  bool _suppressBackspace(KeyboardEvent event) {
    return (event.which == 46 || // delete
            event.which == 8) && // or backspace
        ((_mac && (event.metaKey || event.altKey)) || // mac macro delete
            (!_mac && (event.ctrlKey || event.altKey))); // win macro delete
  }

  bool get _mac => window.navigator.platform.contains('Mac');

  /// A stream of events that describes changes to the value of the element
  Stream<OverwriteEvent> get onOverwriteEvent => _streamController.stream;

  // TODO types for this?
  // create a handler that generates an event based on the supplied function
  dynamic _changeEventFunction(dynamic fun, String type) {
    _logger.fine('_changeEventFunction of type: $type');
    return (Event e) {
      // save current text
      var curText = _element.value;
      _logger.finer('current text is $curText');
      // call real handler
      if (fun(e)) {
        _logger.finer('handler returned true, so a change event will be sent');
        // add event to the stream if the text changed
        // TODO put type of change or event in event class?
        // delay check by 1 ms so that value member of element updates
        // TODO we could avoid having to use the timer if we forced fun to return
        // TODO the new string
        new Timer(const Duration(milliseconds: 1), () {
          _logger.finest('comparing |$curText| to |${_element.value}|');
          if (curText != _element.value) {
            _logger.finer('new value is different, sending an event');
            _streamController
                .add(new OverwriteEvent(curText, _element.value, type));
          }
        });
      }
    };
  }

  /// Create an overwrite object that implements overwrite mode on the input
  /// element
  factory OverwriteElement(TextAreaElement element) {
    // create an overwrite object if it doesn't exist
    OverwriteElement._objects.putIfAbsent(
        element.hashCode, () => new OverwriteElement._private(element));
    // set the mode
    OverwriteElement._objects[element.hashCode]
        .setInputMode(OverwriteMode.OVERWRITE);
    return OverwriteElement._objects[element.hashCode];
  }

  OverwriteElement._private(this._element) {
    _logger.fine('creating an overwrite object for ${_element}');
    // create a stream controller for the element
    _streamController = new StreamController<OverwriteEvent>();

    // create element for determining text width
    _widthEl = new PreElement()
      // set style elements to make invisible
      ..style.position = "absolute"
      ..style.opacity = "0";
    // add element to body
    document.body.children.add(_widthEl);

    // On focus, update the width of the element to fill available space
    _focusSub = _element.onFocus.listen(_changeEventFunction((e) {
      _logger.fine('onFocus handler, updating width');
      // pad contents
      _updateWidth();
      return true;
    }, OverwriteEvent.PAD));

    // On paste, remove enough characters to make room for the text that will be pasted
    _pasteSub =
        _element.onPaste.listen(_changeEventFunction((ClipboardEvent e) {
      _logger.fine('onPaste handler');
      _logger.fine('setting ${_element.selectionStart} to' +
          ' ${_element.selectionStart + e.clipboardData.getData("Text").length}' +
          ' with empty string to clear room for pasted text');
      // remove enough characters to make room for pasted text
      _element.setRangeText("",
          start: _element.selectionStart,
          end: _element.selectionStart + e.clipboardData.getData("Text").length,
          selectionMode: "start");
      return true;
    }, OverwriteEvent.EDIT));

    // On cut, add in enough spaces to compensate for the text that will be removed
    _cutSub = _element.onCut.listen(_changeEventFunction((Event e) {
      _logger.fine('onCut handler');
      _logger.fine('making a string of spaces of length ' +
          '${_element.selectionEnd - _element.selectionStart}');
      // create a string of spaces the same length as the text that will be cut
      String fillString = new String.fromCharCodes(new List<int>.filled(
          _element.selectionEnd - _element.selectionStart, " ".codeUnitAt(0)));
      _logger.finer('setting spaces at ${_element.selectionEnd}');
      // add a string of spaces after the string that will be cut
      _element.setRangeText(fillString,
          start: _element.selectionEnd,
          end: _element.selectionEnd,
          selectionMode: 'preserve');
      return true;
    }, OverwriteEvent.EDIT));

    // On key down, add spaces for every character deleted on backspace and delete key
    _downSub =
        _element.onKeyDown.listen(_changeEventFunction((KeyboardEvent e) {
      _logger.fine('keyDown handler which: ${e.which}');
      // if start and end are equal, there is no selection
      if (_element.selectionStart == _element.selectionEnd) {
        _logger.fine('no selection');
        if (e.which == 8) {
          if (_suppressBackspace(e)) {
            e.preventDefault();
            return false;
          } else {
            _logger.fine('keydown is a backspace');
            // don't do anything if cursor is at the end
            if (_element.selectionStart != 0) {
              _logger.fine('cursor not at the beginning of the line');
              _logger
                  .fine('adding space to replace whatever we\'re backspacing');
              // insert a space after the character that will be removed by the backspace
              _element.setRangeText(" ",
                  start: _element.selectionStart,
                  end: _element.selectionStart,
                  selectionMode: "preserve");
              return true;
            }
          }
        } else if (e.which == 46) {
          if (_suppressBackspace(e)) {
            e.preventDefault();
            return false;
          } else {
            _logger.fine('keydown is delete');
            // don't do anything if cursor is at the end
            if (_element.selectionStart != _element.maxLength) {
              _logger.fine('cursor is not at the end');
              _logger.fine('inserting a space to replace what we\'re deleting');
              // insert a space after the character that will be deleted by the delete
              _element.setRangeText(" ",
                  start: _element.selectionStart + 1,
                  end: _element.selectionStart + 1,
                  selectionMode: "preserve");
              return true;
            }
          }
        }
      } else {
        _logger.fine('there is a selection');
        // if start and end are not equal, there is a selection
        if (e.which == 8 || e.which == 46) {
          _logger.fine('keydown is a backspace (${e.which == 8})' +
              ' or delete (${e.which == 46}))');
          _logger.fine('creating string of spaces to replace deleted text');
          // create a string of spaces the same length as the text that will be deleted
          String fillString = new String.fromCharCodes(new List<int>.filled(
              _element.selectionEnd - _element.selectionStart,
              " ".codeUnitAt(0)));
          // add a string of spaces after the string that will be deleted and with the same length
          _element.setRangeText(fillString,
              start: _element.selectionEnd,
              end: _element.selectionEnd,
              selectionMode: "preserve");
          return true;
        }
      }
      return false;
    }, OverwriteEvent.EDIT));

    // On printable character, delete the character that will be overwritten
    _pressSub =
        _element.onKeyPress.listen(_changeEventFunction((KeyboardEvent e) {
      _logger.finer('keypress which: ${e.which}, keyCode: ${e.keyCode}');
      // ignore arrow keys that fire this on firefox
      if ((e.keyCode == 37 && e.which == 0) ||
          (e.keyCode == 38 && e.which == 0) ||
          (e.keyCode == 39 && e.which == 0) ||
          (e.keyCode == 40 && e.which == 0) ||
          (e.keyCode == 46 && e.which == 0) ||
          e.keyCode == 8) {
        return false;
      }
      // ignore when meta|ctrl that we get on firefox
      if (_mac ? e.metaKey : e.ctrlKey) {
        return false;
      }
      if (e.which == 13) {
        _logger.fine('keypress was enter, preventing default');
        e.preventDefault();
        return false;
      }
      // if cursor is at end, move it back one
      if (_element.selectionStart == _element.maxLength) {
        _logger.fine('cursor at end, moving back by one');
        _element.selectionEnd =
            _element.selectionStart = _element.maxLength - 1;
      }
      _logger.fine('setting range of next char to empty string');
      // delete the character the new one will replace and clobber selection if it exists
      _element.setRangeText("",
          start: _element.selectionStart,
          end: _element.selectionStart + 1,
          selectionMode: "start");
      return true;
    }, OverwriteEvent.EDIT));

    // fix whitespace on browser resize
    _resizeSub = window.onResize.listen(_changeEventFunction((e) {
      _logger.fine('resize handler, updating width');
      // pad contents
      _updateWidth();
      return true;
    }, OverwriteEvent.PAD));
  }

  /// The contents of the element
  String get value => _element.value;

  /// Set the contents of the element
  set value(String v) {
    // if this has focus, maintain cursor position across value change
    var selectionStart, selectionEnd;
    if (document.activeElement == _element) {
      selectionStart = _element.selectionStart;
      selectionEnd = _element.selectionEnd;
    }

    var oldValue = _element.value;
    _element.value = v;
    _updateWidth();

    if (selectionStart != null) {
      _element.selectionStart = selectionStart;
      _element.selectionEnd = selectionEnd;
    }

    _streamController
        .add(new OverwriteEvent(oldValue, v, OverwriteEvent.VALUE));
  }

  /// Set the input mode. Pass [OverwriteMode.OVERWRITE] to set overwrite mode,
  /// or [OverwriteModel.INSERT] to return the element to input mode
  void setInputMode(OverwriteMode mode) {
    // don't do anything if we're already at that mode
    if (mode == _mode) return;
    // update mode state
    _mode = mode;
    if (mode == OverwriteMode.OVERWRITE) {
      // resume event handlers
      _focusSub.resume();
      _pasteSub.resume();
      _cutSub.resume();
      _downSub.resume();
      _pressSub.resume();
      _resizeSub.resume();
    } else {
      // pause event handlers
      _focusSub.pause();
      _pasteSub.pause();
      _cutSub.pause();
      _downSub.pause();
      _pressSub.pause();
      _resizeSub.pause();
    }
  }

  // Pad the contents of the input element to make the contents as wide as the element
  void _updateWidth() {
    // copy font style from element
    _widthEl.style.font = _element.getComputedStyle().font;
    // put element value in hidden element
    _widthEl.text = _element.value.trimRight();

    _logger.fine('widening to ${_element.clientWidth}');
    // increase length of text in width element until it is as wide as input box
    while (_widthEl.clientWidth < _element.clientWidth) {
      _widthEl.text = "${_widthEl.text} ";
    }
    _logger.fine('calculated text is |${_widthEl.text}|');
    // if new text is longer, update the input element value
    if (_widthEl.text.length > _element.value.trimRight().length) {
      _logger.fine('setting value of actual text area');
      // set the new value of input element
      _element.value = _widthEl.text.substring(0, _widthEl.text.length - 1);
      _logger.fine('new textarea value: |${_element.value}|');
    }
    // set maxlength to length
    _element.maxLength = _element.value.length;
  }
}

/// A representation of a change to the contents of the element. The type will
/// be [OverwriteEvent.PAD] if the only change was whitespace being added to
/// fill the width of the element, [OverwriteEvent.EDIT] if the user modified
/// the contents by typing, cutting, copying, or pasting, and
/// [OverwriteEvent.VALUE] if the contents were set using the value accessor.
///
/// The contents of the element before the change are in [oldText], and the
/// value after the change are in [newText].
class OverwriteEvent {
  // fired when whitespace is added to fille the width of the element
  static final String PAD = 'pad';
  // fired when the user edits the contents
  static final String EDIT = 'edit';
  // fired when value changed via the value setter
  static final String VALUE = 'value';

  final String type;
  final String oldText;
  final String newText;
  OverwriteEvent(String this.oldText, String this.newText, String this.type);
}

/// Enumeration of overwrite modes
class OverwriteMode {
  static const OVERWRITE = const OverwriteMode._(0);
  static const INSERT = const OverwriteMode._(1);

  static get values => [OVERWRITE, INSERT];

  final int _value;
  const OverwriteMode._(this._value);
}
