using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class AskView extends WatchUi.View {
  var comments;
  var question;
  
  function initialize(comments, questions) {
    View.initialize();
    self.comments = comments;
    self.question = questions;
  }

  function onLayout(dc) {}

  function onUpdate(dc) {
    dc.clearClip();
    dc.setColor(foreground, background);
    dc.clear();

    var unixnu = Time.now().value();
    var myTime = Gregorian.info(new Time.Moment(unixnu), Time.FORMAT_MEDIUM);
    dc.drawText(
      wmid,
      clockHeight,
      clockFont,
      myTime.hour.format("%02d") + ":" + myTime.min.format("%02d"),
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
    );

    dc.setColor(foreground, Gfx.COLOR_TRANSPARENT);
    var vers = unixnu - glucosetime;
    if (vers < maxver) {
      dc.drawText(
        width * 0.95,
        height * 0.35,
        Gfx.FONT_XTINY,
        glucosestr + (glucoserate == -20 ? ">" : glucoserate == 20 ? "<" : ""),
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_RIGHT
      );
    }
    dc.drawText(
      wmid,
      height * 0.2,
      Gfx.FONT_LARGE,
      self.comments,
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      wmid,
      height * 0.5,
      Gfx.FONT_LARGE,
      self.question,
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      width * 0.4,
      height * 0.8,
      Gfx.FONT_LARGE,
      "No",
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_RIGHT
    );
    dc.drawText(
      width * 0.6,
      height * 0.8,
      Gfx.FONT_LARGE,
      "Yes",
      Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_LEFT
    );
  }
}
