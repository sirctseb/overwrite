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
    _element.onKeyPress.listen((Event e) {
      if(_element.value.length == _length + 1) {
        int cursor = _element.selectionStart; 
        _element.value = _element.value.substring(0, _element.selectionStart) + _element.value.substring(_element.selectionStart + 1);
        _element.selectionEnd = _element.selectionStart = cursor;
      }
    });
  }
}