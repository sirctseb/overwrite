import "dart:html";
import "package:overwrite/overwrite.dart";
import "package:logging/logging.dart";
import "package:test/test.dart";

main() {
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // get the textarea
  TextAreaElement _ta = querySelector("textarea");

  OverwriteElement overwrite = new OverwriteElement(_ta);

  // put overwrite on the text area
  overwrite.setInputMode(OverwriteMode.OVERWRITE);

  test("Initial padding", () {
    _ta.focus();
    expect(_ta.value, matches(r"^abcdef +$"));
  });

  // TODO test other edit events
  // TODO do we have to use webdriver or is there something simpler?
}
