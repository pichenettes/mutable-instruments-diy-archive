Overview
--------

Mutable Instruments' CVpal is a DIY USB MIDI to CV interface - enabling you to control an analog synthesizer or modular system from a computer or smartphone/tablet equipped with a USB port. The CVpal is class-compliant and as such, does not require any driver. It features various conversion/voice allocation modes, covering monophonic, duophonic and drums/triggers applications.

### Quirks ahoy!

Before moving forward, it is important to state some limitations of the CVpal - most of them due to its ridiculously simple design:

-   The CVpal is a **USB device** not a **USB host**! It can be connected to 'active' devices such as smartphones, tablets, laptop or desktop computers, but not to USB MIDI controllers.
-   The CV output is in the 0 .. 4V range - so a tessitura of 4 octaves is covered. The CVpal **does not** support V/Hz conversion; only V/Oct.
-   The Gate output uses V-trig, has a 5V high level, and a direct polarity (note on = 5V, note off = 0V). Most Eurorack modules use a trigger level below 2.5V and can thus be triggered by the CVpal. If a module or synth requires a higher level, a level conversion circuit such as the CD4504 can be used. Polarity inversion can be implement with a CD4049 or with a software hack. S-trig conversion can be implement with a few parts.
-   The CVpal works optimally with iOS, OS X &gt;= 10.6.3 or Linux kernel &gt;= 2.6. On other operating systems, the messages might be delayed by up to 8ms, causing a very jittery timing!

Installation
------------

The CVpal can either be mounted in a Eurorack system, or used as a standalone box. In both cases, it does not need any external power source as it is powered by the USB bus.

About conversion modes
----------------------

The CVpal interprets MIDI messages differently depending on the MIDI channel on which they are received. For example, when receiving messages on MIDI channel 1, it behaves like a monophonic synthesizer and outputs a CV/Gate pair. When receiving messages on MIDI channel 10, it behaves instead like a drum trigger converter and outputs a trigger for 4 drum instruments.

### Channel 1: Monophonic mode

This mode is enabled when any MIDI message is received on channel 1. The CVpal behaves like a classic monophonic CV-Gate converter implementing most recent note priority.

-   OUT 1: Note CV
-   OUT 2: Velocity CV
-   GATE 1: Gate
-   GATE 2: Gate

### Channel 2: Turbocharged monophonic mode

This mode is enabled when any MIDI message is received on channel 2. The CVpal behaves like a monophonic CV-Gate converter implementing most recent note priority, but the primary Gate output is now a digital square oscillator!

-   OUT 1: Note CV
-   OUT 2: Velocity CV
-   GATE 1: Square oscillator playing the received MIDI note
-   GATE 2: Gate

Bonus digital square oscillator! Hell Yeah!

### Channel 3 / Channel 4: Dual monophonic mode

This mode is enabled when a MIDI message is received on channel 3 or on channel 4. The CVpal behaves like two independent monophonic CV-Gate converters with most recent note priority. One of them listens to notes received on channel 3, the other on channel 4.

-   OUT 1: Note CV for channel 3
-   OUT 2: Note CV for channel 4
-   GATE 1: Gate for channel 3
-   GATE 2: Gate for channel 4

### Channel 5: Duophonic mode

This mode is enabled when a MIDI message is received on channel 5. The CVpal behaves like a duophonic CV-Gate converter with voice stealing.

-   OUT 1: Note CV output 1
-   OUT 2: Note CV output 2
-   GATE 1: Gate
-   GATE 2: Gate

### Channel 6: Controller conversion

This mode is enabled when a MIDI message is received on channel 6. The CVpal converts continuous controllers (CC) 01 (modulation wheel) and 02 (breath controller) to control voltages.

-   OUT 1: Modulation wheel CC (01)
-   OUT 2: Breath controller CC (02)
-   GATE 1: Binarized value of CC 3
-   GATE 2: Binarized value of CC 4

### Channel 7/8: Note conversion + CC

These modes are enabled when a MIDI message is received on channel 7 or 8. The CVpal behaves like a monophonic CV-Gate converter, with an additional CC value produced on the secondary output.

-   OUT 1: Note CV
-   OUT 2: Modulation wheel or breath controller CC (01 or 02)
-   GATE 1: Gate
-   GATE 2: Gate

### Channel 10: Drums

This mode is enabled when a MIDI message is received on channel 10. CV Outputs 1 and 2 are respectively triggered by the MIDI notes 36 (kick drum on the GM drum map) and 38 (snare drum on the GM drum map). Gate outputs 1 and 2 are triggered by the MIDI note 40 (snare drum 2) and 46 (closed high-hat).

-   OUT 1: BD (note 36) trigger
-   OUT 2: SD (note 38) trigger
-   GATE 1: SD2 (note 40) trigger
-   GATE 2: CHH (note 46) trigger

### Channel 11: Drums gates

Same as Channel 10, but with gates instead of triggers.

### Channel 12, 13, 14: Monophonic mode with clock/reset output

In these modes, the CVpal behaves like a classic monophonic CV-Gate converter implementing most recent note priority, but also outputs triggers for synchronizing modular sequencers. A clock (with variable resolution) is sent to GATE 1; and a reset (corresponding to the MIDI 'start' message) is sent to GATE 2.

-   OUT 1: Note CV
-   OUT 2: Note Gate
-   GATE 1: Clock trigger
-   GATE 2: Reset trigger

The resolution of the clock trigger depends on the MIDI channel used: 24 ppqn for channel 12; 8 ppqn for channel 13; 4 ppqn for channel 14.

Calibration
-----------

Note: Yamaha and Roland have defined different schemes for numbering octaves – and since then nobody ever agreed on this! If, in the following procedures, everything appears to be off by one octave (the manual says something will happen with C4 but it happens with C3) or if measurements are off by +/-1V, don't panic – it is simply that your controller/DAW uses a different scheme for numbering octaves.

To ensure accurate note conversion, the CVpal needs to be manually calibrated. A digital multimeter with a precision of at least 3 digits is recommended for this task; but the calibration can also be done with an already calibrated synth or VCO module.

OUT 1 is calibrated by sending note messages to channel 15. OUT 2 is calibrated by sending note messages to channel 16.

Play a F\#2 note (MIDI note 42). Check that the output voltage is 0.500V (or that the pitch of the emitted note on the synth/VCO is correct). If this is not the case, use F1 and G1 to make adjustments.

Play a C3 note (MIDI note 48). The target voltage is 1.000V. Use B1 or C\#2 to make adjustments.

Play a F\#3 note (MIDI note 54). The target voltage is 1.500V. Use F2 or G2 to make adjustments.

Play a C4 note (MIDI note 60). The target voltage is 2.000V. Use B3 or C\#3 to make adjustments.

Play a F\#4 note (MIDI note 66). The target voltage is 2.500V. Use F3 or G3 to make adjustments.

Play a C5 note (MIDI note 72). The target voltage is 3.000V. Use B3 or C\#4 to make adjustments.

Play a F\#5 note (MIDI note 78). The target voltage is 3.500V. Use F4 or G4 to make adjustments.

Play a C6 note (MIDI note 84). The target voltage is 4.000V. Use B4 or C\#5 to make adjustments. The following chart summarizes this:

[![](../static/images/cvpal_calibration-540x200.png "cvpal_calibration")](../static/images/cvpal_calibration.png)

Technical note: to get maximum accuracy, it is recommended to temporarily connect a 100k resistor between the output being calibrated and ground. By doing so, the output protection resistor is taken into account. Not doing so might cause tuning errors of up to 10 cts at either ends of the scale.
