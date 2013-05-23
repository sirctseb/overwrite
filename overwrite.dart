/** overwrite.dart implements overwrite mode in a text input element */
part of Tabasci;

/// A class to implement overwrite mode in a text area element
class Overwrite {
  // the element to implement overwrite mode in
  TextAreaElement _element;
  // an element used to calculate text width
  PreElement _widthEl;
  
  /// Create an overwrite object that implements overwrite mode on the input element 
  Overwrite(TextAreaElement this._element) {
    
    // create element for determining text width
    _widthEl = new PreElement()
      // set style elements to make invisible
      ..style.position = "absolute"
      ..style.opacity = "0";
    // add element to body
    document.body.children.add(_widthEl);
    
    // On focus, update the width of the element to fill available space
    _element.onFocus.listen((e) {
      // pad contents
      _updateWidth();
    });
    
    // On paste, remove enough characters to make room for the text that will be pasted
    _element.onPaste.listen((Event e) {
      // remove enough characters to make room for pasted text
      _element.setRangeText("", _element.selectionStart, _element.selectionStart + e.clipboardData.getData("Text").length, "start");
    });
    
    // On cut, add in enough spaces to compensate for the text that will be removed
    _element.onCut.listen((Event e) {
      // create a string of spaces the same length as the text that will be cut
      String fillString = new String.fromCharCodes(
          new List<int>.filled(_element.selectionEnd - _element.selectionStart, " ".codeUnitAt(0))
      );
      // add a string of spaces after the string that will be cut
      _element.setRangeText(fillString, _element.selectionEnd, _element.selectionEnd);
    });
    
    // On key down, add spaces for every character deleted on backspace and delete key
    _element.onKeyDown.listen((Event e) {
      // if start and end are equal, there is no selection
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
      // if start and end are not equal, there is a selection
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
    
    // On printable character, delete the character that will be overwritten
    _element.onKeyPress.listen((Event e) {
      // if cursor is at end, move it back one
      if(_element.selectionStart == _element.maxLength) {
        _element.selectionEnd = _element.selectionStart = _element.maxLength - 1;
      }
      // delete the character the new one will replace and clobber selection if it exists
      _element.setRangeText("", _element.selectionStart, _element.selectionStart+1, "start");
    });
  }
  
  // Pad the contents of the input element to make the contents as wide as the element
  _updateWidth() {
    
    // copy font style from element
    _widthEl.style.font = _element.getComputedStyle().font;
    // put element value in hidden element
    _widthEl.text = _element.value;

    // increase length of text in width element until it is as wide as input box
    bool madeLonger = false;
    while(_widthEl.clientWidth < _element.clientWidth) {
      _widthEl.text = "${_widthEl.text} ";
      madeLonger = true;
    }
    // pad input value to make correct length
    if(madeLonger) {
      _element.value = StringExtension.padString(_element.value, " ", _widthEl.text.length);
      // set maxlength to length
      _element.maxLength = _element.value.length;
    }
  }
}