using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;

const firstrows = 4;
class MainMenuView extends WatchUi.View {
  hidden var rowHeight;

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

    rowHeight = height / (firstrows + 1);
    clockHeight =
      dc.getFontHeight(clockFont) /
      (edge1040 || edge840 ? 1.8 : edge830 ? 2.1 : 2.7);
    theight = dc.getFontHeight(Gfx.FONT_NUMBER_HOT);

    AppSettings.hasInitializedHeight = true;
  }

  function onUpdate(dc) {
    if (AppSettings.hasInitializedHeight) {
      dc.clearClip();
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
      dc.drawText(
        wmid,
        rowHeight,
        Gfx.FONT_MEDIUM,
        "Input",
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
      if (storageid[0] > 0 || storageid[1] > 0) {
        dc.drawText(
          wmid,
          2 * rowHeight,
          Gfx.FONT_MEDIUM,
          "View",
          Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
        );
      }

      dc.drawText(
        wmid,
        3 * rowHeight,
        Gfx.FONT_MEDIUM,
        "Watch face",
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        wmid,
        4 * rowHeight,
        Gfx.FONT_MEDIUM,
        "Sport",
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }
}