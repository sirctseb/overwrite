/** overwrite.dart implements overwrite mode in a text input element */
part of Tabasci;

class Overwrite {
  // the element to implement overwrite mode in
  TextAreaElement _element;
  // flag to indicate the width has been set initially
  bool _initWidth = false;
  // an element used to calculate text width
  DivElement widthDiv;
  
  /// Create an overwrite object that implements overwrite mode on the input element 
  Overwrite(TextAreaElement this._element) {

    // create div for determining text width
    widthDiv = new DivElement()
      ..classes.add("text-width-div")
      ..text = new String.fromCharCodes(new List<int>.filled(_element.value.length, "x".codeUnitAt(0)));
    // add div to body
    document.body.children.add(widthDiv);
    _element.onFocus.listen((e) {
      // pad contents
      _updateWidth();
    });
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
      // if cursor is at end, move it back one
      if(_element.selectionStart == _element.maxLength) {
        _element.selectionEnd = _element.selectionStart = _element.maxLength - 1;
      }
      // delete the character the new one will replace and clobber selection if it exists
      _element.setRangeText("", _element.selectionStart, _element.selectionStart+1, "start");
    });
  }
  
  /// Pad the contents of the input element to make the contents as wide as the element
  _updateWidth() {
    // increase length of text in widthdiv until it is as wide as input box
    bool madeLonger = false;
    while(widthDiv.offsetWidth < _element.clientWidth) {
      widthDiv.text = "${widthDiv.text}x";
      madeLonger = true;
    }
    // pad input value to make correct length
    if(madeLonger) {
      _element.value = StringExtension.padString(_element.value, " ", widthDiv.text.length);
      // set maxlength to length
      _element.maxLength = _element.value.length;
    }
  }
}