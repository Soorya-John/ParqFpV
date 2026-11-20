# ParqFpV

A first-person quad simulator for monochrome RadioMaster transmitters. Fly a warehouse in Acro, drill a single gate from a repeatable hover, or race the full circuit. One Lua file contains the flight model, course and 128×64 wireframe renderer.

## Install and play

1. Save the [current ParqFpV.lua](https://raw.githubusercontent.com/Soorya-John/ParqFpV/main/SCRIPTS/TOOLS/ParqFpV.lua) as `SCRIPTS/TOOLS/ParqFpV.lua` on the radio's SD card. When upgrading, replace the existing script and delete its old `ParqFpV.luac` cache if present. Keep `ParqPB.dat` to carry over your race best.
2. Safely eject the SD card or USB storage, then return the radio to normal operation.
3. Use a simulator model with both RF modules off. Open **Radio Settings → Tools → ParqFpV**.
4. Select **Bando freestyle** or **Gate race**, lower the throttle, and press **ENT** to start. For **Gate practice**, select a gate and match the hover throttle shown on screen.

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

## Fly Ironworks

Fly through the warehouse loading bays, between containers and columns, under the raised concrete floor, or over the roof beams in **Bando freestyle**. The HUD shows altitude, speed and throttle. Gimbal radios start in **Acro**, which commands rotation rates for flips and rolls. The MT12 starts in **Angle** for self-levelling flight. Select **Flight** in the main menu to switch modes. With the **65mm Whoop**, raise the throttle toward 45% for level hover, then use small stick movements.

| Quad | Flight feel |
| --- | --- |
| 65mm Whoop | Low camera tilt and quick drag for close gaps |
| 3in Cine | Softer rotation rates and more carry |
| 5in Freestyle | Faster rolls with stronger thrust |
| 5in Racer | Highest camera tilt, rates and thrust |

**Gate race** runs three laps. Fly through eight gates in order and in the course direction. The active gate has a double top bar and a number, with the following gate drawn dotted. The course starts through the warehouse, climbs around the raised floor, then drops past the containers and loops back to the start. The results show total time and fastest lap. The overall personal best is stored in **SCRIPTS/TOOLS/ParqPB.dat** on a writable SD card.

An arrow at the edge of the view points toward the active gate. A bar behind a sideways arrow means the gate is behind you. On the first lap, each crossing flashes the time since lap start. On later laps it shows the difference against the same gate on your fastest completed lap of this race. A negative split means you're ahead.

**Gate practice** starts you level, seven metres from the selected gate, facing the scoring direction. Match the displayed throttle, press **ENT**, and pitch forward. After crossing, **ENT** repeats the approach and **RTN** opens gate selection. The session best is tracked separately for each gate, quad and flight mode.

## Verification

The script launched from Tools and rendered Ironworks on all eight Companion targets above. The Lua 5.2 regression run flies all eight practice gates through the public tool entry points with simulated inputs. Run it from the repository root with `lua tests/flight.lua`. Physical transmitter frame rate and stick feel still need hardware testing.

- [EdgeTX one-time tool scripts](https://luadoc.edgetx.org/latest/api-overview/script-types/one-time-scripts/)
