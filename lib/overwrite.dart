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
 * user interaction with the element is returned to normal
 */
// TODO delete padded spaces when setting to INSERT?

/// Set the input mode on a [TextAreaElement]
void setInputMode(TextAreaElement element, OverwriteMode mode) {
  // TODO don't even bother creating the object if it doesn't exist yet and we're setting to INSERT?
  // create an overwrite object if it doesn't exist
  OverwriteElement._objects.putIfAbsent(element.hashCode, () => new OverwriteElement(element));
  // set the mode
  OverwriteElement._objects[element.hashCode].setInputMode(mode);
}

/// Enumeration of overwrite modes
class OverwriteMode {
  static const OVERWRITE = const OverwriteMode._(0);
  static const INSERT = const OverwriteMode._(1);
  
  static get values => [OVERWRITE, INSERT];
  
  final int _value;
  const OverwriteMode._(this._value);
}