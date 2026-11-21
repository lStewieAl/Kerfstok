import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Operators on a ring ("C" clears). The upper center rounds the number, the
// lower center evaluates the expression.
class OperatorView extends WatchUi.View {
  static const OPERATORS = ["C", "^", "*", "/", "+", "-", "(", ")", "."];

  private var _entry as Entry;
  private var _text as EntryText?;
  private var _radius as Float = 0.0;
  private var _clearY as Float = 0.0;

  function initialize(entry as Entry) {
    View.initialize();
    _entry = entry;
  }

  private function layout(dc as Graphics.Dc) as Void {
    _radius = Ui.width / 2.0 - dc.getTextWidthInPixels("C", Graphics.FONT_LARGE);
    _clearY = Device.edgeExplore2 ? Ui.height * 0.19 : Device.edge830 ? Ui.hotHeight * 0.4 : Ui.clockY;
    _text = new EntryText(dc);
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    if (_text == null) {
      layout(dc);
    }
    Ui.drawClock(dc);
    dc.drawText(Ui.cx, _clearY, Graphics.FONT_LARGE, OPERATORS[0], Graphics.TEXT_JUSTIFY_CENTER);
    for (var i = 1; i < OPERATORS.size(); i++) {
      var point = Ui.ringPoint(i, OPERATORS.size(), _radius);
      dc.drawText(point[0], point[1], Graphics.FONT_LARGE, OPERATORS[i], Ui.CENTER);
    }
    dc.drawText(Ui.cx, Ui.height / 3, Graphics.FONT_XTINY, "Round", Ui.CENTER);
    (_text as EntryText).draw(dc, _entry.text);
  }
}

class OperatorDelegate extends BaseDelegate {
  private var _entry as Entry;

  function initialize(entry as Entry) {
    BaseDelegate.initialize();
    _entry = entry;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var point = event.getCoordinates();
    if (Ui.isNearCenter(point[0], point[1], Ui.height / 4)) {
      var value = Calc.evaluate(_entry.text);
      if (value == null) {
        Haptics.bump();
      } else {
        _entry.operated = false;
        _entry.setText(Calc.format(point[1] < Ui.height / 2 ? Math.round(value).toDouble() : value));
      }
    } else {
      var index = Ui.sectorAt(point[0], point[1], OperatorView.OPERATORS.size());
      if (index == 0) {
        _entry.setText("");
      } else if (_entry.length() >= Entry.MAX_LENGTH) {
        Haptics.ramp();
      } else if (index == OperatorView.OPERATORS.size() - 1) {
        _entry.addPoint();
      } else {
        _entry.append(OperatorView.OPERATORS[index]);
        _entry.operated = true;
      }
    }
    Ui.pop();
    return true;
  }

  function onPreviousPage() as Boolean {
    Ui.pop();
    return true;
  }

  function onNextPage() as Boolean {
    return true;
  }
}
