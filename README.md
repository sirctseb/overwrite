overwrite
=========

Overwrite mode for textarea elements in Dart

To put a textarea element into overwrite mode:

```dart
    var overwrite = new OverwriteElement(element);
```

To set the element back to normal editing:

```dart
  overwrite.setInputMode(OverwriteMode.INSERT);
```

To subscribe to change made to the element value by typing, cutting, pasting,
setting the value programmatically, or by whitespace being added:

```dart
  overwrite.onOverwriteEvent.listen((event) {
    // set text in model
  });
```

New text typed into the textarea will overwrite the existing content instead of inserting it.

Overwrite also handles deleting and backspacing single characters and selections, cut, and paste.

When the textarea receives focus, overwrite pads the value with spaces to fill the client width of the element.
