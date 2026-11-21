
Kerfstok is watch app for certain Garmin with touchscreen. It can be downloaded from: https://apps.garmin.com/en-US/apps/b6348ccc-86d8-4780-8013-d9e19fed5260
It should be used with Juggluco, https://www.juggluco.nl/Juggluco/index.html

With it, you can enter numbers under a certain label on your watch. These numbers are sent to Juggluco.
If you have a Freestyle Libre 2 sensor in you arm, Kerfstok can also display your current glucose value on your watch. The FreeStyle Libre 2 sensor sends via Bluetooth every minute the glucose level to Juggluco running on Android and Juggluco sends this to Kerfstok on a Garmin watch also via Bluetooth.

I published the source of Kerfstok so people can modify it to fit their taste.

For more information about Juggluco visit:

https://www.juggluco.nl/Juggluco/index.html

For more information about Kerfstok, see:

https://www.juggluco.nl/Kerfstok/index.html

For information about how to build a Garmin watch app, see:
https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/#gettingstarted

Building
--------
The app builds with any type check level, including strict (-l 3):

  monkeyc -f monkey.jungle -d venu2 -o bin/Kerfstok.prg -y developer_key.der

manifest.xml is generated from manifest.xml.in with `make` (define DEBUG in
manifest.xml.in for the Kerfstok-d app id).

Unit tests (tests/Tests.mc) run in the simulator:

  monkeyc -f monkey.jungle -d venu2 -o bin/test.prg -y developer_key.der --unit-test
  monkeydo bin/test.prg venu2 /t

Source layout
-------------
source/App.mc     Application lifecycle, phone message listener, redraw timer.
source/Comm       Messages exchanged with Juggluco (consts.mc is generated
                  from Juggluco and must stay in sync with it).
source/Core       Device families, screen helpers, haptics and glucose alarm,
                  units, the dial calculator and date helpers.
source/Data       Persisted state: logged records, labels, memory slots and
                  shortcuts, the latest glucose reading, insulin on board.
source/Sport      Sports list, activity recording and measurements.
source/UI         One file per screen (view and its input delegate).

Device-specific layout tweaks are selected by the DeviceFamily string in
resources-<product>/strings.xml.

Jaap Korthals Altes
