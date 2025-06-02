using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian;

class MonthView extends WatchUi.View {
  const monthfont = venusq2 ? Gfx.FONT_SMALL : Gfx.FONT_MEDIUM;
  function initialize() {
    View.initialize();
  }

  function onLayout(dc) {}

  function onUpdate(dc) {
    dc.clearClip();
    dc.setColor(AppSettings.foregroundColor, AppSettings.backgroundColor);
    dc.clear();
    dc.setColor(AppSettings.foregroundColor, Graphics.COLOR_TRANSPARENT);
	
    var myTime = System.getClockTime();
    dc.drawText(
      wmid,
      clockHeight,
      clockFont,
      myTime.hour.format("%02d") + ":" + myTime.min.format("%02d"),
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
    );
    var fw = dc.getTextWidthInPixels(DateTimeUtil.monthNames[0], monthfont);
    var r = width / 2 - (fw * 4) / 5;
    var incr = Math.PI / 5;
    for (var i = 0, hoek = (Math.PI * 3) / 2; i < 10; hoek += incr, i++) {
      var x = Math.cos(hoek) * r + width / 2;
      var y = Math.sin(hoek) * r + (39 * height) / 80;
      dc.drawText(
        x,
        y,
        monthfont,
        DateTimeUtil.monthNames[i],
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
    }
    dc.drawText(
      wmid,
      (height * 2) / 5,
      monthfont,
      DateTimeUtil.monthNames[10],
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      wmid,
      (height * 3) / 5,
      monthfont,
      DateTimeUtil.monthNames[11],
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
    );
  }
}
