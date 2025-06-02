using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;

class RetrieveView extends WatchUi.View {
  var geg;
  function initialize(g) {
    geg = g;
    View.initialize();
  }

  function onLayout(dc) {}

  function onUpdate(dc) {
    dc.clearClip();
    var wmid = width / 2;
    var hmid = height / (geg.onscr + 1);
    dc.setColor(AppSettings.foregroundColor, AppSettings.backgroundColor);
    dc.clear();

    var myTime = System.getClockTime();
    dc.drawText(
      wmid,
      clockHeight,
      clockFont,
      myTime.hour.format("%02d") + ":" + myTime.min.format("%02d"),
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
    );

    for (var i = 0; i < geg.onscr; i++) {
      var val = geg.from + i;
      if (val >= numset.size()) {
        return;
      }
      dc.drawText(
        wmid,
        hmid * (i + 1),
        Gfx.FONT_MEDIUM,
        memlab[numset[val]],
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }
}
