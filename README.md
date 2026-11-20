# ParqFpV

A first-person quad simulator for monochrome RadioMaster transmitters, by soorya. Fly five abandoned sites, race four three-lap circuits, or see how far you can get on an endless course. The flight model, maps and 128×64 wireframe renderer fit in one Lua tool.

## Install and play

1. Save the [current ParqFpV.lua](https://raw.githubusercontent.com/Soorya-John/ParqFpV/main/SCRIPTS/TOOLS/ParqFpV.lua) as `SCRIPTS/TOOLS/ParqFpV.lua` on the radio's SD card. When upgrading, replace the script and delete its old `ParqFpV.luac` cache if present. Keep the `Parq*.dat` score files.
2. Safely eject the SD card or USB storage, then return the radio to normal operation.
3. Use a simulator model with both RF modules off. Open **Radio Settings → Tools → ParqFpV**.
4. Open **Bando freestyle**, turn the roller or use the next/previous keys to preview a site, lower the throttle, and press **ENT** to fly. **Gate race**, **Endless Run** and **Gate practice** have their own main-menu entries.

Use the roller or the radio's next/previous keys to navigate. **ENT** confirms and **RTN** pauses in flight or goes back in menus. Impacts stop motion into the surface and let you keep flying from where you hit. To reset manually, press **RTN** and select **Restart**. **Stick setup** shows all four live axes and allows pitch and throttle reversal for the session.

## Radio compatibility

| RadioMaster family | Companion target exercised | Default controls |
| --- | --- | --- |
| Pocket, Boxer, Zorro | EdgeTX 2.12, each target | Radio stick mode |
| TX12 Mark II, GX12 | EdgeTX 2.12, each target | Radio stick mode |
| Original TX12, T8 Pro with its clip-on display | EdgeTX 2.11.8, TX12 and T8 targets | Radio stick mode |
| MT12 surface radio running EdgeTX | EdgeTX 2.12, MT12 target | CH1–4 and Angle mode |

Use the firmware target for your exact transmitter. Editions sharing one of these targets, such as the Pocket Crush, use the same script. EdgeTX 2.11 is the final firmware series for the original TX12 and T8 Pro. The discontinued TX8 uses DeviationTX. The T8 Lite and T8L also lack the EdgeTX Tools runtime required for on-radio play. [EdgeTX target list](https://edgetx.org/supportedradios/) · [Display specifications](https://edgetx.org/edgetx/latest/hardware/stm32-platforms/) · [RadioMaster TX8](https://radiomasterrc.com/products/tx8-radio-controller-1) · [T8 Lite](https://radiomasterrc.com/collections/t8/products/tx8-lite-radio-controller) · [T8L](https://radiomasterrc.com/products/t8l-radio-controller)

**MT12 setup.** In a dedicated simulator model, mix four controls to **CH1 roll, CH2 pitch, CH3 throttle, CH4 yaw**. One layout uses the wheel for yaw, the trigger for pitch, and two knobs for throttle and roll. Centre the roll knob for level flight. Set the throttle knob's low end to −100% and high end to +100%. Check each axis in **Stick setup** before launching. Any supported transmitter can switch between logical sticks and this channel layout.

## Freestyle

| Site | A line to try |
| --- | --- |
| Ironworks | Thread both warehouse loading bays, then cut under the broken concrete floor. |
| Spillway | Enter either sluice mouth and weave right, left, right through the low baffles. |
| Parkade | Climb by the lift tower, cross the skybridge and dive through the lightwell in both decks. |
| Dry Dock | Skim the channel between the quays, pass under the suspended loads and return over the cranes. |
| Kiln Yard | Shoot a furnace bore, climb above its roof and reverse through the gap between the chimney stacks. |

**Rewind a trick.** Press **RTN → Rewind** after an attempt. Move back or forward through the last six seconds in 0.2-second steps. **ENT** gives you the sticks at that instant, including your bank angle, rotation, momentum and motor response. **RTN** returns to the original pause point. Rewind is a freestyle feature.

Gimbal radios start in **Acro**, which commands rotation rates for flips and rolls. The MT12 starts in **Angle** for self-levelling flight. Select **Flight** in the main menu to switch modes. With the **65mm Whoop**, raise the throttle toward 45% for level hover, then use small stick movements.

| Quad | Flight feel |
| --- | --- |
| 65mm Whoop | Low camera tilt and quick drag for close gaps |
| 3in Cine | Softer rotation rates and more carry |
| 5in Freestyle | Faster rolls with stronger thrust |
| 5in Racer | Highest camera tilt, rates and thrust |

## Gate racing

Fly three laps through the numbered gates in order and in the marked direction. The active gate has thick solid posts, a double top bar and an inverted number. The next gate is dotted. On the three open courses, dotted ground markings show where the circuit turns.

| Course | Gates | What changes |
| --- | --- | --- |
| 1 · Club Loop | 6 | Broad turns and 7.2 m wide openings give you room to carry speed. |
| 2 · Switchback | 8 | A staggered slalom and hairpin reward setting up early. Gates narrow to 5.8 m. |
| 3 · Highline | 10 | Climb to 12.5 m, descend through a chicane and line up 4.5 m wide gates. |
| Classic · Ironworks | 8 | Race through the warehouse, around the upper floor and back past the containers. |

Each circuit keeps its own three-lap best on the SD card. Ironworks continues to use the original `ParqPB.dat` record. Results also show your fastest lap.

An arrow at the edge of the view points toward the active gate. A bar behind a sideways arrow means the gate is behind you. On the first lap, each crossing flashes the time since lap start. On later laps it shows the difference against the same gate on your fastest completed lap of this race. A negative split means you're ahead.

**Gate practice** lets you choose any of the 32 fixed gates. Start in a level hover seven metres out, match the displayed throttle, press **ENT**, and pitch forward. After crossing, **ENT** repeats the approach and **RTN** opens gate selection. Each gate, quad and flight mode has its own session best.

## Endless Run

Lower the throttle and press **ENT**. The quad flies forward automatically. Use roll or yaw to steer sideways, pull pitch to climb and push to dive. Steer through the solid frame and look for the dotted gate beyond it.

Every five clears raise the level. Speed builds from 6 m/s, openings narrow, and new gates can move farther sideways or vertically. A miss ends the run. **ENT** generates a fresh route. Your best gate count is saved in `ParqRun.dat` when a run ends or you leave it through the pause menu.

## Verification

Run `lua tests/flight.lua` from the repository root using Lua 5.2. The tests fly every practice approach on all eight input profiles, check all four circuits' scoring and record files, test openings and collisions in the five bandos, and replay a manoeuvre after rewinding to verify the flight state. A stick-driven test pilot clears 100 procedural gates in one run. Companion checks cover the monochrome display. Frame rate and stick feel still need playtesting on physical radios.

- [EdgeTX one-time tool scripts](https://luadoc.edgetx.org/latest/api-overview/script-types/one-time-scripts/)
