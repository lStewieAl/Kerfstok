using Toybox.WatchUi;
using Toybox.System;
using Toybox.StringUtil;
using Toybox.Graphics as Gfx;
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian;
import Toybox.Lang;

const maxline = 11;
class DialView extends WatchUi.View {
  const numsfont = venusq2
    ? Gfx.FONT_XTINY
    : edge1040 || edgeexplore2 || edge830
    ? Gfx.FONT_MEDIUM
    : Gfx.FONT_TINY;

  const dialnumberfont = venusq2 ? Gfx.FONT_NUMBER_MEDIUM : Gfx.FONT_NUMBER_HOT;
  var nums as EntryData;

  var variable;
  var timeoff = 0.0;
  function initialize(numin as EntryData, vari) {
    View.initialize();
    variable = vari;
    nums = numin;
    timeoff =
      System.SCREEN_SHAPE_RECTANGLE == screenShape
        ? edge1040 || edgeexplore2
          ? height * 0.15
          : edge830
          ? theight * 0.3
          : venusq
          ? theight * 0.2
          : theight * 0.1
        : width > 340
        ? theight * 0.05
        : 0.0;
  }

  var vary;
  var numwidth;
  function onLayout(dc) {
    numwidth = dc.getTextWidthInPixels("9", dialnumberfont);
    var dim = dc.getTextDimensions("9", numsfont);
    wnumfont = dim[0];
    hnumfont = (dim[1] * 3) / 4;
    xnumbers = wmid - (maxline * wnumfont) / 2;
    hmidnum = height / 2 - hnumfont;
    vary =
      hmidnum -
      (hnumfont * 7) / 4 -
      (edge1040 || edgeexplore2 || edge830 ? hnumfont : 0);
  }

  function onUpdate(dc) {
      dc.clearClip();
      dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_BLACK);

      dc.clear();
      dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      var r = width / 2 - (numwidth * 4) / 5;
      var incr = Math.PI / 5;
      dc.drawText(wmid, timeoff, dialnumberfont, "0", Gfx.TEXT_JUSTIFY_CENTER);
      for (
        var i = 1, hoek = incr + (Math.PI * 3) / 2;
        i < 10;
        hoek += incr, i++
      ) {
        var x = Math.cos(hoek) * r + width / 2;
        var y = Math.sin(hoek) * r + (39 * height) / 80;
        dc.drawText(
          x,
          y,
          dialnumberfont,
          i,
          Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
        );
      }
      dc.drawText(
        wmid,
        vary,
        Gfx.FONT_SMALL,
        variable,
        Gfx.TEXT_JUSTIFY_CENTER
      );
      var myTime = System.getClockTime();
      dc.drawText(
        wmid,
        clockHeight,
        clockFont,
        myTime.hour.format("%02d") + ":" + myTime.min.format("%02d"),
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.setClip(xnumbers, hmidnum, wnumfont * maxline, (hnumfont * 10) / 3);

    dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    var getstr = nums.toString();
    var en = (getstr.length() + maxline - 1) / maxline;
    for (var i = 0; i < en; i++) {
      var sub = getstr.substring(i * maxline, (i + 1) * maxline);
      dc.drawText(
        xnumbers,
        hmidnum + i * hnumfont,
        numsfont,
        sub,
        Gfx.TEXT_JUSTIFY_LEFT
      );
    }
  }
}
