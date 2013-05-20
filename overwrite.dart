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
    _element.onKeyDown.listen((Event e) {
      Logger.root.info("overwrite got key down which: ${e.which}");
      Logger.root.info("_length: $_length, new length: ${_element.value.length}");
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
    });
    _element.onKeyPress.listen((Event e) {
      Logger.root.info("overwrite got key press");
      if(_element.value.length == _length + 1) {
        // save the cursor position
        int cursor = _element.selectionStart;
        // set value to prefix + new char + suffix
        _element.value = _element.value.substring(0, _element.selectionStart) + _element.value.substring(_element.selectionStart + 1);
        // restore cursor
        _element.selectionEnd = _element.selectionStart = cursor;
      }
    });
  }
}