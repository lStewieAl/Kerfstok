using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.StringUtil;

function datestr(tim) {
  var today = Gregorian.info(tim, Time.FORMAT_MEDIUM);
  var dst = new [17];
  dst[0] = (48 + today.hour / 10).toChar();
  dst[1] = (48 + (today.hour % 10)).toChar();
  dst[2] = ':';

  dst[3] = (48 + today.min / 10).toChar();
  dst[4] = (48 + (today.min % 10)).toChar();
  dst[5] = ' ';
  dst[6] = (48 + today.day / 10).toChar();
  dst[7] = (48 + (today.day % 10)).toChar();
  dst[8] = '-';
  var ar = today.month.toCharArray();
  for (var i = 0; i < 3; i++) {
    dst[9 + i] = ar[i];
  }
  dst[12] = '-';
  for (var y = today.year, i = 16; i > 12; i--) {
    dst[i] = (48 + (y % 10)).toChar();
    y = y / 10;
  }
  return StringUtil.charArrayToString(dst);
}