using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;

const firstrows = 4;
class MainMenuView extends WatchUi.View {
  var hmid;
  function initialize() {
    View.initialize();
    clockFont =
      edge1040 || edgeexplore2 || edge830 ? Gfx.FONT_TINY : Gfx.FONT_XTINY;
  }

  function onLayout(dc) {
    height = dc.getHeight();
    width = dc.getWidth();
    System.println("width=" + width + " height=" + height);
    wmid = width / 2;

    hmid = height / (firstrows + 1);
    clockHeight =
      dc.getFontHeight(clockFont) /
      (edge1040 || edge840 ? 1.8 : edge830 ? 2.1 : 2.7);
    theight = dc.getFontHeight(Gfx.FONT_NUMBER_HOT);
  }

  function onUpdate(dc) {
    if (clockHeight != null) {
      dc.clearClip();
      dc.setColor(foreground, background);
      dc.clear();
      var myTime = System.getClockTime();
      dc.drawText(
        wmid,
        clockHeight,
        clockFont,
        myTime.hour.format("%02d") + ":" + myTime.min.format("%02d"),
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        wmid,
        hmid,
        Gfx.FONT_MEDIUM,
        "Input",
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
      if (storageid[0] > 0 || storageid[1] > 0) {
        dc.drawText(
          wmid,
          2 * hmid,
          Gfx.FONT_MEDIUM,
          "View",
          Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
        );
      }

      dc.drawText(
        wmid,
        3 * hmid,
        Gfx.FONT_MEDIUM,
        "Watch face",
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        wmid,
        4 * hmid,
        Gfx.FONT_MEDIUM,
        "Sport",
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }
}