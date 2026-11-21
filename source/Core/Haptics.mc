import Toybox.Attention;
import Toybox.Lang;

// Vibration patterns, given as flat [dutyCycle, durationMs, ...] lists.
module Haptics {
  // A single long pulse: a limit was reached.
  function pulse() as Void {
    play([100, 200]);
  }

  // Rising pattern: input too long, or GPS acquired.
  function ramp() as Void {
    play([75, 50, 50, 50, 25, 50, 100, 50]);
  }

  // Three short pulses: lap marked, or a value could not be stored.
  function triple() as Void {
    play([100, 50, 10, 50, 100, 50, 10, 50, 100, 50]);
  }

  // Soft bump: nothing to select or no further page.
  function bump() as Void {
    play([25, 66, 100, 66, 25, 66]);
  }

  // Long pattern for glucose alarms and automatic laps.
  function alarm() as Void {
    play([50, 100, 100, 500, 50, 50, 100, 1000, 50, 100, 100, 500, 50, 50, 100, 500]);
  }

  function cancel() as Void {
    play([0, 1]);
  }

  function play(pattern as Array<Number>) as Void {
    if (!(Attention has :vibrate)) {
      return;
    }
    var profiles = [] as Array<Attention.VibeProfile>;
    for (var i = 0; i + 1 < pattern.size(); i += 2) {
      profiles.add(new Attention.VibeProfile(pattern[i], pattern[i + 1]));
    }
    Attention.vibrate(profiles);
  }
}

// Glucose alarm raised by Juggluco. While active it vibrates on every tick
// until the user presses a button or taps the glucose screen, or Juggluco
// clears it.
module Alarm {
  var active as Boolean = false;

  function start() as Void {
    active = true;
    Haptics.alarm();
  }

  function tick() as Void {
    if (active) {
      Haptics.alarm();
    }
  }

  // Cleared by Juggluco or by a normal reading.
  function clear() as Void {
    active = false;
  }

  // Silenced on the watch: stop vibrating and tell Juggluco.
  function silence() as Void {
    if (active) {
      active = false;
      Haptics.cancel();
    }
    Comm.send([STOPALARM]);
  }
}
