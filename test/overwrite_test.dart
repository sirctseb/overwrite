import "dart:html";
import "dart:async";
import "package:unittest/unittest.dart";
import "package:overwrite/overwrite.dart";

main() {
  // get the textarea
  TextAreaElement _ta = query("textarea");
  
  // put overwrite on the text area
  new Overwrite(_ta);

  test("Initial padding", () {
    _ta.focus();
    expect(_ta.value, matches(r"^abcdef +$"));
  });
  
  // TODO test other edit events
  // TODO do we have to use webdriver or is there something simpler?
}