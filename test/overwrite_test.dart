import "dart:html";
import "dart:async";
import "package:unittest/unittest.dart";
import "package:overwrite/overwrite.dart";

main() {
  // get the textarea
  TextAreaElement _ta = querySelector("textarea");

  // put overwrite on the text area
  setInputMode(_ta, OverwriteMode.OVERWRITE);

  test("Initial padding", () {
    _ta.focus();
    expect(_ta.value, matches(r"^abcdef +$"));
  });

  // TODO test other edit events
  // TODO do we have to use webdriver or is there something simpler?
}