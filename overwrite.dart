/** overwrite.dart implements overwrite mode in a text input element */
part of Tabasci;

class Overwrite {
  // the element to implement overwrite mode in
  TextAreaElement _element;
  // the length of the text in the element
  int _length;
  
  /// Create an overwrite object that implements overwrite mode on the input element 
  Overwrite(TextAreaElement this._element) {
    _length = _element.value.length;
    _element.onPaste.listen((Event e) {
      // save the cursor location
      int cursor = _element.selectionStart;
      // get the string to be pasted
      String pasteString = e.clipboardData.getData("Text");
      // truncate clipboard data if it is too long
      if(pasteString.length > _length - _element.selectionStart) {
        pasteString = pasteString.substring(0, _length - _element.selectionStart);
      }
      // get prefix of existing value, everything up to cursor
      String prefix = _element.value.substring(0,_element.selectionStart);
      // get suffix of existing value, everything after the suffx and the length of the paste string
      String suffix = "";
      if(pasteString.length < _length - cursor) {
        suffix = _element.value.substring(_element.selectionStart + pasteString.length);
      }
      // set new contents value
      _element.value = "$prefix$pasteString$suffix";
      // stop paste action from going through
      // NOTE we only strictly need to do this if clipboard contents are too long for input,
      // NOTE but it is simpler to do it for both cases
      e.preventDefault();
      // restore cursor
      _element.selectionEnd = _element.selectionStart = cursor;
    });
    _element.onCut.listen((Event e) {
      // save the selection state
      int start = _element.selectionStart;
      int end = _element.selectionEnd;
      // create a string to fill in places
      String fillString = new String.fromCharCodes(
          new List<int>.filled(_element.selectionEnd - _element.selectionStart, " ".codeUnitAt(0))
      );
      // set the value to the existing value with spaces added in
      _element.value = "${_element.value.substring(0, _element.selectionEnd)}$fillString${_element.value.substring(_element.selectionEnd)}";
      // restore selection
      _element.selectionStart = start;
      _element.selectionEnd = end;
      // NOTE cut will go through to remove selected text
    });
    _element.onKeyDown.listen((Event e) {
      Logger.root.info("overwrite got key down which: ${e.which}");
      Logger.root.info("_length: $_length, new length: ${_element.value.length}");
      if(_element.selectionStart == _element.selectionEnd) { 
        if(e.which == 8) {
          Logger.root.info("which is backspace, adding a space back in");
          // save the cursor position
          int cursor = _element.selectionStart;
          if(cursor != 0) {
            // set the value to the existing value with a space in the place after selection start
            _element.value = "${_element.value.substring(0, _element.selectionStart)} ${_element.value.substring(_element.selectionStart)}";
            // restore cursor
            _element.selectionEnd = _element.selectionStart = cursor;
            // NOTE the backspace will still go through and delete the character before the selection start
            // NOTE an alternative is to take out this char ourselves and e.preventDefault() to stop the backspace
          }
        } else if(e.which == 46) {
          // save the cursor position
          int cursor = _element.selectionStart;
          // set the value to the existing value with a space in the place of the character to delete
          _element.value = "${_element.value.substring(0, _element.selectionStart)} ${_element.value.substring(_element.selectionStart+1)}";
          // restore cursor
          _element.selectionEnd = _element.selectionStart = cursor;
          // prevent the delete from going throught because we've already taken out the character
          e.preventDefault();
        }
      } else {
        if(e.which == 8 || e.which == 46) {
          // save the cursor position
          int cursor = _element.selectionStart;
          // create a string to fill in places
          String fillString = new String.fromCharCodes(
              new List<int>.filled(_element.selectionEnd - _element.selectionStart, " ".codeUnitAt(0))
              );
          // set the value to the existing value with spaces in the selected places
          _element.value = "${_element.value.substring(0, _element.selectionStart)}$fillString${_element.value.substring(_element.selectionEnd)}";
          // restore cursor
          _element.selectionEnd = _element.selectionStart = cursor;
          // stop backspace or delete from actually going
          e.preventDefault();
          // NOTE we could alternately just add the spaces and let the real backspace or delete remove the selected text
        }
      }
    });
    _element.onKeyPress.listen((Event e) {
      Logger.root.info("overwrite got key press");
      // if cursor is at end, move it back one
      if(_element.selectionStart == _length) {
        _element.selectionEnd = _element.selectionStart = _length - 1;
      }
      // save the cursor position
      int cursor = _element.selectionStart;
      // set value to prefix + new char + suffix
      _element.value = _element.value.substring(0, _element.selectionStart) + _element.value.substring(_element.selectionStart + 1);
      // restore cursor
      _element.selectionEnd = _element.selectionStart = cursor;
      // TODO if typing over the last character, cursor should not advance.
      // TODO this would require putting the char in ourselves and e.preventDefault()ing
      Logger.root.info("length after ${_element.value.length}");
    });
  }
}