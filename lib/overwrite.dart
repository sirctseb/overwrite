/** overwrite.dart implements overwrite mode in a text input element */
library overwrite;

import "dart:html";
import "dart:async";

part "src/overwriteelement.dart";

/** Set the input mode of a [TextAreaElement] to overwrite or insert.
 * Setting the mode to [OverwriteMode.OVERWRITE] pads the contents of the element
 * with spaces so that it fits the width of the element and handles editing events
 * to implement overwrite mode.
 * Setting the mode to [OverwriteMode.INSERT] leaves the contents as they are and
 * user interaction with the element is returned to normal.
 */
// TODO delete padded spaces when setting to INSERT?

/// Set the input mode on a [TextAreaElement]
/// returns a [Stream<OverwriteEvent>] that fires when changes are made to the text
Stream<OverwriteEvent> setInputMode(TextAreaElement element, OverwriteMode mode) {
  // TODO don't even bother creating the object if it doesn't exist yet and we're setting to INSERT?
  // create an overwrite object if it doesn't exist
  OverwriteElement._objects.putIfAbsent(element.hashCode, () => new OverwriteElement(element));
  // set the mode
  OverwriteElement._objects[element.hashCode].setInputMode(mode);
  return OverwriteElement._objects[element.hashCode]._streamController.stream;
}

/// Get the [Stream<OverwriteEvent>] for a given element
/// returns null if element has never been set to overwrite mode
Stream<OverwriteEvent> getOverwriteStream(TextAreaElement element) {
  return OverwriteElement._objects.containsKey(element.hashCode) ?
        OverwriteElement._objects[element.hashCode]._streamController.stream :
        null;
}

/// Event class for text change event stream
class OverwriteEvent {
  // fired when whitespace is added to fille the width of the element
  static final String PAD = 'pad';
  // fired when the user edits the contents
  static final String EDIT = 'edit';

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