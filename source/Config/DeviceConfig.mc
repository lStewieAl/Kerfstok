import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;

module DeviceConfig {
  // Device identification flags
  public var isVenusq as Lang.Boolean = false;
  public var isVenu as Lang.Boolean = false;
  public var isVenusq2 as Lang.Boolean = false;
  public var isFenix7 as Lang.Boolean = false;
  public var isFenix8 as Lang.Boolean = false; // Fenix "Pro" models, or next gen
  public var isFenixE as Lang.Boolean = false; // Epix / Fenix X etc.
  public var isMarq2 as Lang.Boolean = false;
  public var isEdgeExplore2 as Lang.Boolean = false;
  public var isEdge1040 as Lang.Boolean = false;
  public var isEdge830 as Lang.Boolean = false;
  public var isEdge840 as Lang.Boolean = false;
  public var isFr965 as Lang.Boolean = false;
  public var isFr165 as Lang.Boolean = false;
  public var isMk3 as Lang.Boolean = false;
  public var isRectangleScreen as Lang.Boolean = false;

  // Screen dimensions (initialized in onLayout of first view, then stored here)
  public var screenWidth as Lang.Number = 0;
  public var screenHeight as Lang.Number = 0;
  public var screenWidthMid as Lang.Number = 0;
  public var screenShape as System.ScreenShape = System.SCREEN_SHAPE_ROUND;

  // Layout configurations
  public var histViewRows as Lang.Number = 4;

  public function initialize() as Void {
    _determineWatchVersion();
    var deviceSettings = System.getDeviceSettings();
    screenShape = deviceSettings.screenShape;
    isRectangleScreen = screenShape == System.SCREEN_SHAPE_RECTANGLE;

    if (isEdge1040 || isEdgeExplore2 || isEdge830) {
      clockFont = Graphics.FONT_TINY;
    } else {
      clockFont = Graphics.FONT_XTINY;
    }

    if (isEdgeExplore2) {
      histViewRows = 7;
    } else if (isEdge830 || isEdge840) {
      histViewRows = 5;
    } else if (isEdge1040) {
      histViewRows = 8;
    } else {
      histViewRows = 4;
    }

    // TODO add ... (many more device-specific initializations for fonts, row counts, etc.)
    // Example for screenDensityFactor from GlucoseView
    // screenDensityFactor = (2.0 * screenWidth) / 396.0;
  }

  function _determineWatchVersion() as Void {
    if (WatchUi.loadResource(Rez.Strings.venusq).equals("y")) { isVenusq = true; return; }
    if (WatchUi.loadResource(Rez.Strings.venusq2).equals("y")) { isVenusq2 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.venu).equals("y")) { isVenu = true; return; }
    if (WatchUi.loadResource(Rez.Strings.fenix7).equals("y")) { isFenix7 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.marq2).equals("y")) { isMarq2 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.edgeexplore2).equals("y")) { isEdgeExplore2 = true; return;}
    if (WatchUi.loadResource(Rez.Strings.edge830).equals("y")) { isEdge830 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.fr965).equals("y")) { isFr965 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.mk3).equals("y")) { isMk3 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.fenix8).equals("y")) { isFenix8 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.fenixe).equals("y")) { isFenixE = true; return; }
    if (WatchUi.loadResource(Rez.Strings.edge1040).equals("y")) { isEdge1040 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.edge840).equals("y")) { isEdge840 = true; isEdge830 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.fr165).equals("y")) { isFr165 = true; isFr965 = true; return; }
  }
}
