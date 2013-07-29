overwrite
=========

Overwrite mode for textarea elements in Dart

To put a textarea element into overwrite mode:

```dart
    setInputMode(element, OverwriteMode.OVERWRITE);
```

New text typed into the textarea will overwrite the existing content instead of inserting it.

Overwrite also handles deleting and backspacing single characters and selections, cut, and paste.

When the textarea receives focus, overwrite pads the value with spaces to fill the client width of the element.
