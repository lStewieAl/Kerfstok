using Toybox.Attention;
using Toybox.Lang;

function vibrate(profile as Lang.Array<Attention.VibeProfile>) as Void {
  if (Attention has :vibrate) {
    Attention.vibrate(profile);
  }
}

const VIBE_PROFILE_200MS_FULL_POWER = [new Attention.VibeProfile(100, 200)];
const VIBE_PROFILE_BEEP2 = [
  new Attention.VibeProfile(75, 50),
  new Attention.VibeProfile(50, 50),
  new Attention.VibeProfile(25, 50),
  new Attention.VibeProfile(100, 50),
];
const VIBE_PROFILE_BEEP3 = [
  new Attention.VibeProfile(100, 50),
  new Attention.VibeProfile(10, 50),
  new Attention.VibeProfile(100, 50),
  new Attention.VibeProfile(10, 50),
  new Attention.VibeProfile(100, 50),
];
const VIBE_PROFILE_BEEP4 = [
  new Attention.VibeProfile(25, 66),
  new Attention.VibeProfile(100, 66),
  new Attention.VibeProfile(25, 66),
];

var CLEAR_VIBRATION as Lang.Array<Attention.VibeProfile> = [
  new Attention.VibeProfile(50, 100),
  new Attention.VibeProfile(100, 500),
  new Attention.VibeProfile(50, 50),
  new Attention.VibeProfile(100, 1000),
  new Attention.VibeProfile(50, 100),
  new Attention.VibeProfile(100, 500),
  new Attention.VibeProfile(50, 50),
  new Attention.VibeProfile(100, 500),
];

public function beep1() as Void { vibrate(VIBE_PROFILE_200MS_FULL_POWER); }
public function beep2() as Void { vibrate(VIBE_PROFILE_BEEP2); }
public function beep3() as Void { vibrate(VIBE_PROFILE_BEEP3); }
public function beep4() as Void { vibrate(VIBE_PROFILE_BEEP4); }
public function clearBeepPattern() as Void { vibrate(CLEAR_VIBRATION); }

function generatealarm() as Void {
  for (var i = 0; i < 6; ++i) {
    clearBeepPattern();
    if (!AppSettings.isAlarmActive) {
      return;
    }
  }
}

function startGeneratedAlarm() as Void {
  AppSettings.isAlarmActive = true;
  generatealarm();
}

function stopGeneratedAlarm() as Void {
  if (AppSettings.isAlarmActive) {
    AppSettings.isAlarmActive = false;
    if (Attention has :vibrate) {
      Attention.vibrate([new Attention.VibeProfile(0, 1)]); // 0 power for 1ms to clear vibration
    }
  }
}
