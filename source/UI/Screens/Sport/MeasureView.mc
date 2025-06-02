using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Activity;

class MeasureView extends WatchUi.View {
  var hmid;
  var start = -1,
    iter = -1;
  function initialize() {
    View.initialize();
    hmid = height / (2 * rows + 1);
  }

  function onShow() {}
  function onLayout(dc) {}

  function onUpdate(dc) {
    dc.clearClip();
    dc.setColor(foreground, background);
    dc.clear();

    var myTime = System.getClockTime();
    dc.drawText(
      wmid,
      clockHeight,
      clockFont,
      myTime.hour.format("%02d") +
        ":" +
        myTime.min.format("%02d") +
        ":" +
        myTime.sec.format("%02d"),
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
    );

    dc.setColor(foreground, Gfx.COLOR_TRANSPARENT);
    iter = start;
    var tot = infostr.size();
    var end = 2 * rows + 1;
    if (activityInfo == null) {
      return;
    }

    for (var i = 1; i < end; i++) {
      var res;
      do {
        ++iter;
        if (iter == tot) {
          return;
        }
        res = infofunc(activityInfo, iter);
      } while (res == null);
      var lab = infostr[iter];
      dc.drawText(wmid, hmid * i, Gfx.FONT_XTINY, lab, Gfx.TEXT_JUSTIFY_CENTER);
      i++;
      dc.drawText(
        wmid,
        hmid * (i + 0.4),
        Gfx.FONT_NUMBER_MEDIUM,
        "" + res,
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }
}
