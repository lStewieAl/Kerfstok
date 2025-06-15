using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;

class AssignView extends WatchUi.View {
  var _delegate;
  function initialize(g as AssignDelegate) {
    _delegate = g;
    View.initialize();
  }

  function onLayout(dc) {}

  function onUpdate(dc) {
    dc.clearClip();
    dc.setColor(AppSettings.foregroundColor, AppSettings.backgroundColor);
    dc.clear();

    var wmid = width / 2;
    var hmid = height / (_delegate.onscr + 1);
    var myTime = System.getClockTime();
    dc.drawText(
      wmid,
      clockHeight,
      clockFont,
      myTime.hour.format("%02d") + ":" + myTime.min.format("%02d"),
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
    );
    for (var i = 0; i < _delegate.onscr; i++) {
      var val = _delegate.from + i;
      if (val >= memlab.size()) {
        return;
      }
      dc.drawText(
        wmid,
        hmid * (_delegate.onscr - i),
        Gfx.FONT_MEDIUM,
        memlab[val],
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }
}
