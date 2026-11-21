import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The typed text, wrapped in lines at the screen center. Shared by the dial
// and operator screens so the text stays in place when switching.
class EntryText {
  static const LINE_LENGTH = 11;

  private var _font as Graphics.FontType;
  private var _charWidth as Number;
  private var _left as Number;
  var top as Number;
  var lineHeight as Number;

  function initialize(dc as Graphics.Dc) {
    _font = Device.venuSq2 ? Graphics.FONT_XTINY : Device.isEdge() ? Graphics.FONT_MEDIUM : Graphics.FONT_TINY;
    var size = dc.getTextDimensions("9", _font);
    _charWidth = size[0];
    lineHeight = (size[1] * 3) / 4;
    _left = Ui.cx - (LINE_LENGTH * _charWidth) / 2;
    top = Ui.height / 2 - lineHeight;
  }

  function draw(dc as Graphics.Dc, text as String) as Void {
    dc.setClip(_left, top, _charWidth * LINE_LENGTH, (lineHeight * 10) / 3);
    dc.setColor(Ui.fg, Ui.bg);
    dc.clear();
    dc.setColor(Ui.fg, Graphics.COLOR_TRANSPARENT);
    for (var start = 0, line = 0; start < text.length(); start += LINE_LENGTH, line++) {
      var end = start + LINE_LENGTH < text.length() ? start + LINE_LENGTH : text.length();
      dc.drawText(_left, top + line * lineHeight, _font, text.substring(start, end) as String, Graphics.TEXT_JUSTIFY_LEFT);
    }
    dc.clearClip();
  }
}

// Digits 0-9 on a ring; tapping the center evaluates the text, and tapping it
// again when nothing changed stores the number.
class DialView extends WatchUi.View {
  private var _entry as Entry;
  private var _title as String;
  private var _text as EntryText?;
  private var _digitFont as Graphics.FontType = Graphics.FONT_NUMBER_HOT;
  private var _radius as Float = 0.0;
  private var _zeroY as Float = 0.0;
  private var _titleY as Number = 0;

  function initialize(entry as Entry, title as String) {
    View.initialize();
    _entry = entry;
    _title = title;
  }

  private function layout(dc as Graphics.Dc) as Void {
    var hot = Ui.hotHeight;
    _digitFont = Device.venuSq2 ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_HOT;
    _radius = Ui.width / 2.0 - (dc.getTextWidthInPixels("9", _digitFont) * 4) / 5.0;
    if (Ui.isRect) {
      _zeroY = Device.isLargeEdge()
        ? Ui.height * 0.15
        : Device.edge830
        ? hot * 0.3
        : Device.venuSq
        ? hot * 0.2
        : hot * 0.1;
    } else {
      _zeroY = Ui.width > 340 ? hot * 0.05 : 0.0;
    }
    var text = new EntryText(dc);
    _titleY = text.top - (text.lineHeight * 7) / 4 - (Device.isEdge() ? text.lineHeight : 0);
    _text = text;
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    if (_text == null) {
      layout(dc);
    }
    dc.drawText(Ui.cx, _zeroY, _digitFont, "0", Graphics.TEXT_JUSTIFY_CENTER);
    for (var i = 1; i < 10; i++) {
      var point = Ui.ringPoint(i, 10, _radius);
      dc.drawText(point[0], point[1], _digitFont, i.toString(), Ui.CENTER);
    }
    dc.drawText(Ui.cx, _titleY, Graphics.FONT_SMALL, _title, Graphics.TEXT_JUSTIFY_CENTER);
    Ui.drawClock(dc);
    (_text as EntryText).draw(dc, _entry.text);
  }
}

class DialDelegate extends BaseDelegate {
  private var _entry as Entry;
  private var _target as EntryTarget;

  function initialize(entry as Entry, target as EntryTarget) {
    BaseDelegate.initialize();
    _entry = entry;
    _target = target;
  }

  // Backspace; leaves the dial when the text is empty.
  function onBack() as Boolean {
    if (_entry.length() > 0) {
      _entry.backspace();
      WatchUi.requestUpdate();
    } else {
      Ui.pop();
    }
    return true;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var point = event.getCoordinates();
    var centerRadius = Ui.width * 0.15 > 50 ? Ui.width * 0.15 : 50;
    if (Ui.isNearCenter(point[0], point[1], centerRadius)) {
      evaluateOrCommit();
    } else if (!_entry.append(Ui.sectorAt(point[0], point[1], 10).toString())) {
      Haptics.pulse();
    }
    WatchUi.requestUpdate();
    return true;
  }

  // Any button adds a decimal point.
  function onButton(key as WatchUi.Key) as Boolean {
    if (_entry.length() > Entry.MAX_LENGTH - 2) {
      Haptics.ramp();
    } else {
      _entry.addPoint();
      WatchUi.requestUpdate();
    }
    return true;
  }

  function onNextPage() as Boolean {
    if (!_entry.operated) {
      _entry.remember();
    }
    Ui.push(new OperatorView(_entry), new OperatorDelegate(_entry));
    return true;
  }

  function onPreviousPage() as Boolean {
    var view = new EntryHistoryView(_entry.history);
    Ui.push(view, new EntryHistoryDelegate(view, _entry));
    return true;
  }

  function onSwipeLeft() as Boolean {
    var view = new ListView(Memory.shortcutNames(), Graphics.FONT_MEDIUM, 0);
    Ui.push(view, new ShortcutDelegate(view, _entry));
    return true;
  }

  // Hold on the right half to recall a memory slot, on the left half to
  // store the text in one.
  function onHold(event as WatchUi.ClickEvent) as Boolean {
    if (event.getCoordinates()[0] > Ui.cx) {
      var slots = Memory.filledSlots();
      var names = [] as Array<String>;
      for (var i = 0; i < slots.size(); i++) {
        names.add(Memory.slotName(slots[i]));
      }
      var view = new ListView(names, Graphics.FONT_MEDIUM, names.size() - 1);
      Ui.push(view, new RecallDelegate(view, _entry, slots));
    } else {
      var names = [] as Array<String>;
      for (var i = 0; i < Memory.SLOT_COUNT; i++) {
        names.add(Memory.slotName(i));
      }
      var view = new ListView(names, Graphics.FONT_MEDIUM, 0);
      Ui.push(view, new StoreDelegate(view, _entry));
    }
    return true;
  }

  private function evaluateOrCommit() as Void {
    var value = Calc.evaluate(_entry.text);
    if (value == null) {
      Haptics.bump();
      return;
    }
    var result = Calc.format(value);
    if (!result.equals(_entry.text)) {
      _entry.operated = false;
      _entry.setText(result);
    } else if (_target.commit(result)) {
      Ui.pop();
    } else {
      Haptics.triple();
    }
  }
}
