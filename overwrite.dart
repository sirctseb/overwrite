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
      // create a string of spaces the same length as the text that will be cut
      String fillString = new String.fromCharCodes(
          new List<int>.filled(_element.selectionEnd - _element.selectionStart, " ".codeUnitAt(0))
      );
      // add a string of spaces after the string that will be cut
      _element.setRangeText(fillString, _element.selectionEnd, _element.selectionEnd);
    });
    _element.onKeyDown.listen((Event e) {
      Logger.root.info("overwrite got key down which: ${e.which}");
      Logger.root.info("_length: $_length, new length: ${_element.value.length}");
      if(_element.selectionStart == _element.selectionEnd) { 
        if(e.which == 8) {
          // don't do anything if cursor is at the end
          if(_element.selectionStart != 0) {
            // insert a space after the character that will be removed by the backspace
            _element.setRangeText(" ");
          }
        } else if(e.which == 46) {
          // don't do anything if cursor is at the end
          if(_element.selectionStart != _length) {
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