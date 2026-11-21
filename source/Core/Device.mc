import Toybox.Lang;
import Toybox.WatchUi;

// Device families that need hand-tuned layouts. The family is set per product
// by the DeviceFamily string in resources-<product>/strings.xml.
module Device {
  var venu as Boolean = false;
  var venuSq as Boolean = false;
  var venuSq2 as Boolean = false;
  var fenix7 as Boolean = false;
  var fenix8 as Boolean = false;
  var fenixE as Boolean = false;
  var marq2 as Boolean = false;
  var mk3 as Boolean = false;
  var fr965 as Boolean = false; // Also set for the FR165 family.
  var fr165 as Boolean = false;
  var edge830 as Boolean = false; // Also set for the Edge 840 family.
  var edge840 as Boolean = false;
  var edge1040 as Boolean = false;
  var edgeExplore2 as Boolean = false;

  function init() as Void {
    var family = WatchUi.loadResource(Rez.Strings.DeviceFamily) as String;
    venu = family.equals("venu");
    venuSq = family.equals("venusq");
    venuSq2 = family.equals("venusq2");
    fenix7 = family.equals("fenix7");
    fenix8 = family.equals("fenix8");
    fenixE = family.equals("fenixe");
    marq2 = family.equals("marq2");
    mk3 = family.equals("mk3");
    fr165 = family.equals("fr165");
    fr965 = fr165 || family.equals("fr965");
    edge840 = family.equals("edge840");
    edge830 = edge840 || family.equals("edge830");
    edge1040 = family.equals("edge1040");
    edgeExplore2 = family.equals("edgeexplore2");
  }

  // Edge bike computers with a large rectangular screen.
  function isLargeEdge() as Boolean {
    return edge1040 || edgeExplore2;
  }

  function isEdge() as Boolean {
    return edge1040 || edgeExplore2 || edge830;
  }
}
