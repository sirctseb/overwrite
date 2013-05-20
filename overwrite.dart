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
      // TODO handle case where clipboard data is too long for input element
      // save the cursor location
      int cursor = _element.selectionStart;
      // find the length of the string to be pasted
      int pasteLength = e.clipboardData.getData("Text").length;
      // replace value with existing string minus that many characters
      _element.value = "${_element.value.substring(0,_element.selectionStart)}${_element.value.substring(_element.selectionStart + pasteLength)}";
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
          // set the value to the existing value with a space in the place after selection start
          _element.value = "${_element.value.substring(0, _element.selectionStart)} ${_element.value.substring(_element.selectionStart)}";
          // restore cursor
          _element.selectionEnd = _element.selectionStart = cursor;
          // NOTE the backspace will still go through and delete the character before the selection start
          // NOTE an alternative is to take out this char ourselves and e.preventDefault() to stop the backspace
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
      // save the cursor position
      int cursor = _element.selectionStart;
      // set value to prefix + new char + suffix
      _element.value = _element.value.substring(0, _element.selectionStart) + _element.value.substring(_element.selectionStart + 1);
      // restore cursor
      _element.selectionEnd = _element.selectionStart = cursor;
      Logger.root.info("length after ${_element.value.length}");
    });
  }
}