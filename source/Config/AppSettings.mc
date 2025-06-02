import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.WatchUi;

module AppSettings {
  // Theme colors
  public var foregroundColor as Graphics.ColorType = Graphics.COLOR_WHITE;
  public var backgroundColor as Graphics.ColorType = Graphics.COLOR_BLACK;

  function updateThemeColors(num as Lang.Number) as Void {
    if (num == 1) {
      foregroundColor = Graphics.COLOR_WHITE;
      backgroundColor = Graphics.COLOR_BLACK;
    } else {
      foregroundColor = Graphics.COLOR_BLACK;
      backgroundColor = Graphics.COLOR_WHITE;
    }
    WatchUi.requestUpdate();
  }

  // Application states
  public var isAlarmActive as Lang.Boolean = false;
  public var isGlucoCommsActive as Lang.Boolean = false; // was AppSettings.isGlucoCommsActive
}
