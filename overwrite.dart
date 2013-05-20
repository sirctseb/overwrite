/** overwrite.dart implements overwrite mode in a text input element */
part of Tabasci;

class Overwrite {
  // the element to implement overwrite mode in
  TextAreaElement _element;
  
  /// Create an overwrite object that implements overwrite mode on the input element 
  Overwrite(TextAreaElement this._element) {
    // set max length of element text to current length
    // TODO this should be set more intelligently
    _element.maxLength = _element.value.length;
    _element.onPaste.listen((Event e) {
      // remove enough characters to make room for pasted text
      _element.setRangeText("", _element.selectionStart, _element.selectionStart + e.clipboardData.getData("Text").length, "start");
    });
    _element.onCut.listen((Event e) {
      // create a string of spaces the same length as the text that will be cut
      String fillString = new String.fromCharCodes(
          new List<int>.filled(_element.selectionEnd - _element.selectionStart, " ".codeUnitAt(0))
      );
      // add a string of spaces after the string that will be cut
      _element.setRangeText(fillString, _element.selectionEnd, _element.selectionEnd);
    });
    _element.onKeyDown.listen((Event e) {
      Logger.root.info("overwrite got key down which: ${e.which}");
      Logger.root.info("_length: ${_element.maxLength}, new length: ${_element.value.length}");
      if(_element.selectionStart == _element.selectionEnd) { 
        if(e.which == 8) {
          // don't do anything if cursor is at the end
          if(_element.selectionStart != 0) {
            // insert a space after the character that will be removed by the backspace
            _element.setRangeText(" ");
          }
        } else if(e.which == 46) {
          // don't do anything if cursor is at the end
          if(_element.selectionStart != _element.maxLength) {
            // insert a space after the character that will be deleted by the delete
            _element.setRangeText(" ", _element.selectionStart+1, _element.selectionStart+1);
          }
        }
      } else {
        if(e.which == 8 || e.which == 46) {
          // create a string of spaces the same length as the text that will be deleted
          String fillString = new String.fromCharCodes(
              new List<int>.filled(_element.selectionEnd - _element.selectionStart, " ".codeUnitAt(0))
              );
          // add a string of spaces after the string that will be deleted and with the same length
          _element.setRangeText(fillString, _element.selectionEnd, _element.selectionEnd);
        }
      }
    });
    _element.onKeyPress.listen((Event e) {
      Logger.root.info("overwrite got key press");
      // if cursor is at end, move it back one
      if(_element.selectionStart == _element.maxLength) {
        _element.selectionEnd = _element.selectionStart = _element.maxLength - 1;
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