# ParqFpV

A first-person FPV quad simulator that runs directly on the RadioMaster Pocket's 128x64 monochrome display. It uses a 3D wireframe camera and six-degree-of-freedom flight with thrust, gravity, drag and collisions.

## Install and play

1. Copy [ParqFpV.lua](SCRIPTS/TOOLS/ParqFpV.lua) to **SCRIPTS/TOOLS** on the radio's SD card.
2. Safely eject the SD card or USB storage, then return the radio to normal operation.
3. Use a simulator model with both RF modules off. Press **SYS**, select **ParqFpV** in **Tools**, and press the scroll wheel to open it.
4. Select **Bando freestyle** or **Gate race**, lower the throttle, then press the wheel to start.

The scroll wheel selects menu items and its click confirms. **RTN** pauses in flight and goes back in menus. Impacts stop motion into the surface and let you keep flying from where you hit. To reset manually, press **RTN** and select **Restart**. The game reads the radio's logical roll, pitch, yaw and throttle, so the stick layout follows your radio's stick mode. The **Stick setup** page shows live values and can reverse pitch or throttle for the session.

## Fly Ironworks

Fly through the warehouse loading bays, between containers and columns, under the raised concrete floor, or over the roof beams in **Bando freestyle**. The HUD shows altitude, speed and throttle. **Acro** is the default and commands rotation rates for flips and rolls. Select **Flight: Acro** in the main menu to switch to **Angle**. With the **65mm Whoop**, raise the throttle toward 45% for level hover, then use small stick movements.

| Quad | Flight feel |
| --- | --- |
| 65mm Whoop | Low camera tilt and quick drag for close gaps |
| 3in Cine | Softer rotation rates and more carry |
| 5in Freestyle | Faster rolls with stronger thrust |
| 5in Racer | Highest camera tilt, rates and thrust |

**Gate race** runs three laps. Fly through eight gates in order and in the course direction. The active gate has a double top bar and a number, with the following gate drawn dotted. The course starts through the warehouse, climbs around the raised floor, then drops past the containers and loops back to the start. The results show total time and fastest lap. The overall personal best is stored in **SCRIPTS/TOOLS/ParqPB.dat** on a writable SD card.

The target is the Pocket running EdgeTX 2.10 or later. The tool was exercised in the EdgeTX Companion 2.12 Pocket simulator. Real-radio flight performance and stick feel require a play test on the transmitter.

- [EdgeTX RadioMaster Pocket reference](https://luadoc.edgetx.org/dev/radios/radiomaster/radiomaster-pocket/)
- [EdgeTX one-time tool scripts](https://luadoc.edgetx.org/latest/api-overview/script-types/one-time-scripts/)
