part of overwrite;

// A class to implement overwrite mode in a text area element
class OverwriteElement {
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

  // The current insert mode
  OverwriteMode _mode = OverwriteMode.OVERWRITE;

  // TODO types for this?
  // create a handler that generates an event based on the supplied function
  dynamic _changeEventFunction(dynamic fun, String type) {
    return (Event e) {
      // save current text
      var curText = _element.value;
      // call real handler
      if(fun(e)) {
        // add event to the stream if the text changed
        // TODO put type of change or event in event class?
        // delay check by 1 ms so that value member of element updates
        // TODO we could avoid having to use the timer if we forced fun to return
        // TODO the new string
        new Timer(const Duration(milliseconds:1), () {
          if(curText != _element.value) {
            _streamController.add(new OverwriteEvent(curText, _element.value, type));
          }
        });
      }
    };
  }

  // Create an overwrite object that implements overwrite mode on the input element
  OverwriteElement(TextAreaElement this._element) {
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
      // pad contents
      _updateWidth();
      return true;
    }, OverwriteEvent.PAD));

    // On paste, remove enough characters to make room for the text that will be pasted
    _pasteSub = _element.onPaste.listen(_changeEventFunction((Event e) {
      // remove enough characters to make room for pasted text
      _element.setRangeText("", start: _element.selectionStart, end: _element.selectionStart + e.clipboardData.getData("Text").length, selectionMode: "start");
      return true;
    }, OverwriteEvent.EDIT));

    // On cut, add in enough spaces to compensate for the text that will be removed
    _cutSub = _element.onCut.listen(_changeEventFunction((Event e) {
      // create a string of spaces the same length as the text that will be cut
      String fillString = new String.fromCharCodes(
          new List<int>.filled(_element.selectionEnd - _element.selectionStart, " ".codeUnitAt(0))
      );
      // add a string of spaces after the string that will be cut
      _element.setRangeText(fillString, start: _element.selectionEnd, end: _element.selectionEnd);
      return true;
    }, OverwriteEvent.EDIT));

    // On key down, add spaces for every character deleted on backspace and delete key
    _downSub = _element.onKeyDown.listen(_changeEventFunction((KeyboardEvent e) {
      // if start and end are equal, there is no selection
      if(_element.selectionStart == _element.selectionEnd) {
        if(e.which == 8) {
          // don't do anything if cursor is at the end
          if(_element.selectionStart != 0) {
            // insert a space after the character that will be removed by the backspace
            _element.setRangeText(" ");
            return true;
          }
        } else if(e.which == 46) {
          // don't do anything if cursor is at the end
          if(_element.selectionStart != _element.maxLength) {
            // insert a space after the character that will be deleted by the delete
            _element.setRangeText(" ", start: _element.selectionStart+1, end: _element.selectionStart+1);
            return true;
          }
        }
      } else {
        // if start and end are not equal, there is a selection
        if(e.which == 8 || e.which == 46) {
          // create a string of spaces the same length as the text that will be deleted
          String fillString = new String.fromCharCodes(
              new List<int>.filled(_element.selectionEnd - _element.selectionStart, " ".codeUnitAt(0))
              );
          // add a string of spaces after the string that will be deleted and with the same length
          _element.setRangeText(fillString, start: _element.selectionEnd, end: _element.selectionEnd);
          return true;
        }
      }
      return false;
    }, OverwriteEvent.EDIT));

    // On printable character, delete the character that will be overwritten
    _pressSub = _element.onKeyPress.listen(_changeEventFunction((Event e) {
      // if cursor is at end, move it back one
      if(_element.selectionStart == _element.maxLength) {
        _element.selectionEnd = _element.selectionStart = _element.maxLength - 1;
      }
      // delete the character the new one will replace and clobber selection if it exists
      _element.setRangeText("", start: _element.selectionStart, end: _element.selectionStart+1, selectionMode: "start");
      return true;
    }, OverwriteEvent.EDIT));
  }

  // Set the input mode
  void setInputMode(OverwriteMode mode) {
    // don't do anything if we're already at that mode
    if(mode == _mode) return;
    // update mode state
    _mode = mode;
    if(mode == OverwriteMode.OVERWRITE) {
      // resume event handlers
      _focusSub.resume();
      _pasteSub.resume();
      _cutSub.resume();
      _downSub.resume();
      _pressSub.resume();
    } else {
      // pause event handlers
      _focusSub.pause();
      _pasteSub.pause();
      _cutSub.pause();
      _downSub.pause();
      _pressSub.pause();
    }
  }

  // Pad the contents of the input element to make the contents as wide as the element
  void _updateWidth() {

    // copy font style from element
    _widthEl.style.font = _element.getComputedStyle().font;
    // put element value in hidden element
    _widthEl.text = _element.value;

    // increase length of text in width element until it is as wide as input box
    while(_widthEl.clientWidth < _element.clientWidth) {
      _widthEl.text = "${_widthEl.text} ";
    }
    // if new text is longer, update the input element value
    if(_widthEl.text.length > _element.value.length + 1) {
      // set the new value of input element
      _element.value = _widthEl.text.substring(0, _widthEl.text.length - 1);
      // set maxlength to length
      _element.maxLength = _element.value.length;
    }
  }
}