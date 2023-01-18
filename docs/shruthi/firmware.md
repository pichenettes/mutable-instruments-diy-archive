Where?
------

The firmware code is hosted on [github](http://github.com/pichenettes/shruthi-1).

[Latest version (v1.02)](../static/firmware/shruthi1_1.02.syx).

What?
-----

To build the firmware you need:

-   A GCC toolchain for the AVR platform, the AVR includes/libraries, and the AVRDude utility. All those guys are bundled with the Arduino development environment, which you can get [here](http://arduino.cc/en/Main/Software) ; or with [CrossPack](http://www.obdev.at/products/crosspack/index.html). If you use Windows, you can find them in [WinAVR](http://winavr.sourceforge.net/). Make sure your avr-gcc is as close as possible to 4.3.3 since the most recent versions of gcc are performing optimizations differently and can cause the firmware to grow out of the size constraints.
-   Python (2.5 or above) and [numpy](http://numpy.scipy.org/). I love numpy!

To flash it, you need either:

-   An AVR ISP programmer, with a 2x3 connector. The one used for the Shruthi development is [this one](http://uk.farnell.com/atmel/atavrisp2/programmer-avr-mcu-isp/dp/1135517?Ntt=1135517).
-   OR you can also use the firmware update by MIDI procedure described at the end of the user manual. It will take longer to load your program using this method (1 min vs 5s) - thus it is recommended only if you are really scared of wires and circuits!

The Shruthi build environment is command-line / makefile based. **OS X** is the system on which Mutable instruments develops ; but getting it to work on Linux is straightforward. On Windows machines you might have to fiddle a bit with system paths to get things to work.

How?
----

### Building the firmware

1.  Get the source from [github](http://github.com/pichenettes/shruthi-1) (or run `git clone ...`).
2.  Move to the directory created by git (or the directory created when decompressing the .zip).
3.  Run `git submodule init` and `git submodule update` to pull the dependencies.
4.  Edit the `avrlib/makefile.mk` file (extended by all makefiles) to change the path `(AVR_TOOLS_PATH / AVR_ETC_PATH)` to the directory containing the AVR toolchain. This path depends on your system.
5.  In the same file, change `PROGRAMMER` to the reference of your ISP programmer (don't care about this if you want to upload your modified firmware by MIDI).
6.  Build the resources: `make resources`. Pre-compiled resource files (`resources.cc`, `resources.h`) are already bundled with the source code, so if you don't modify the Python resources file, you don't need this step.
7.  Build the firmware: `make`.
8.  Make sure that the firmware size is below 64512 bytes: `make size` (If you don't have figlet and cowsay installed, you're going to miss some awesome Moose action, but you can still type: cat shruthi1.size and add the first 2 numbers). Note that trying to upload with the standard MIDI update procedure a firmware size too large can "brick" your unit.
9.  If you want to upload the firmware by MIDI (or realease a mod to the community): `make midi` (you need python installed on your computer for this step). The resulting file is in `build/shruthi1/shruthi1.mid`.

### Bootloader development

The "firmware update by MIDI" feature is made possible by a 1k bootloader programmed into the chips distributed with the kits. The source code of this [bootloader](http://github.com/pichenettes/shruthi-1/tree/master/bootloader/) can be compiled with `make -f bootloader/makefile` ; and uploaded with `make -f bootloader/makefile upload`

### Starting from a blank chip

The single command: **make bake\_all** first sets up the fuses at a slow speed ; and then flashes the firmware, bootloader and internal eeprom at high speed.

Installing the factory presets
------------------------------

This is not properly speaking firmware development, but hey, here we go. The factory data for the eeprom is [in this file](../static/firmware/shruthi1_factory_data.syx). Play the .syx file into the Shruthi (with its firmware installed of course).

Some notes about the code
-------------------------

### AVR development library (avrlib)

Most of the code directly dealing with the hardware is in the `avrlib` directory, which is an import for the [avril project](http://github.com/pichenettes/avril). You'll find there various template classes allowing hardware resources (serial ports, switches, LCD display...) to be manipulated with a friendly, high-level syntax... without the cost associated with abstraction since everything is flattened/evaluated/inlined at compile time. A good example (I think) of what C** can bring to embedded development.

### Resources

All the data residing in program flash ROM (strings, lookup tables, waveforms) is contained in the `shruthi/resources.h` and `shruthi/resources.cc` files, which are automatically generated from some python code (this is where the wavetable generation happens). If you want to add a string to your program, add the string to the list `shruthi/resources/strings.py`, build the resources, and use the `ResourcesManager::LoadStringResource(STR_RES_MY_STRING, buffer, size);` idiom to copy it to RAM whenever you want to access it.

### Code tour

#### Core data structures

**Patch** (`patch.h`) is the data structure holding the synthesis parameters. **SequencerSettings** (`sequencer_settings.h`) is the data structure holding the sequencer configuration (tempo, quantize, arpeggiator pattern) and the sequence itself. **SystemSettings** (`system_settings.h`) is holding the global configuration data (MIDI options, transpose, tuning).

**Storage** (`storage.h`) contains the routines for loading patch or sequence data from the internal or external eeprom ; and for parsing incoming SysEx MIDI messages (since all of them are related to reception/transmission of user data).

#### Synthesis

**Envelope** (`envelope.h`) has two instances for the two envelope generators. Just like **Lfo** in `lfo.h`.

**Oscillator** (`oscillator.h`) contains the main oscillator code. To add an oscillator algorithm:

1.  Add the oscillator name in the oscillator names list in `strings.py`
2.  Add an entry in the **OscillatorAlgorithm** enum in `patch.h`
3.  In `oscillator.cc`, locate the table of function pointers at the end of the file. Add an entry: `&Osc::RenderMyAlgo`. Note that you have to make sure that the string, enum entry, and function pointer entry are in the same order! For example, if you've added the string at the end of the list, you'll have to add the enum entry and function pointer entries at the end of their respective lists too.
4.  Add a `void RenderMyAlgo(uint8_t* buffer)` forward declaration in `oscillator.h` ; and implement `void Oscillator::RenderMyAlgo(uint8_t* buffer)` in `oscillator.cc`. Your function must fill `kAudioBlockSize` samples of audio into the buffer passed as an argument. The macros `BEGIN_SAMPLE_LOOP`, `END_SAMPLE_LOOP` and `UPDATE_PHASE` can be used to take care of phase incrementation and sync. `RenderDirtyPwm` is probably the simplest example to study!

**TransientGenerator** (`transient_generator.h`) is the sound generator responsible for adding clicks/attacks at the beginning of the note.

**NoteStack** (`note_stack.h`) is a stack (implemented as a linked list with "pointers in a pool array" instead of pointers) used for storing the depressed keys and doing voice allocation.

**SynthesisEngine** (`synthesis_engine.h`) contains the bulk of the synthesis code, and integrates all the synthesis-related objects described above. The synthesis engine can handle several voices (at the moment only one) and start/stop a sound on each voice. However, it is not responsible for doing all the voice stealing / arpeggiation stuff. The classes responsible for turning sequencer data and incoming MIDI messages into actual notes routed to the synthesis voice are **VoiceController** (`voice_controller.h`) and **VoiceAllocator** (`voice_allocator.h`). **VoiceAllocator** is used in polychaining mode, and implements a LRU voice-stealing algorithm. **VoiceController** is used otherwise, and handles the note priority (through a `NoteStack`) and all the additional events generated by the sequencer or arpeggiator.

#### Interaction with the rest of the world ®

**Editor** (`editor.h`) is responsible for all the UI, pages navigation, etc. There are 3 modes for the editor, corresponding to the 5th key: patch ; sequence ; and performance. Each mode contains grouped pages. Each page has a UI Type (sequencer, traditional 4 parameters view). For each UI type, callback functions for drawing the screen, handling pots or encoder events are implemented.

**ParameterDefinitions** (`parameter_definitions.h`) is the central repository of everything the Shruthi needs to know about each synthesis parameter: its name, unit, descriptive string, and range. It is used by the editor, the random patch generator, to validate incoming NRPN data, and to scale incoming CC data.

**MidiDispatcher** (`midi_dispatcher.h`) is the class that will handle the reception of MIDI messages. All the handlers (NoteOn, ControlChange) will be inlined into the MIDI parsing state machine. Those handlers are responsible for updating the LCD display (status character), the Editor (step by step recording), the MIDI out and obviously the synthesis engine.

#### Beast

The main code is in `shruthi.cc`. It consists of short chunks of code, aka "tasks" called in turns. The most important task, called inbetween all the other ones, is **AudioRenderingTask** which fills as much as possible of the audio buffer. Very few things happens in timer ISR-land (clocked at 39kHz):

1.  Pop a sample from an audio buffer and write it to the PWM output
2.  Every 16th call, pop a nibble from the display buffer and write it to the LCD
3.  Every 16th call, pop a byte from the MIDI out buffer and write it to the UART (This means the Shruthi can only achieve 78% of the maximum MIDI bandwidth).
4.  Every 16th call, debounce the switches
5.  Every 32th call, do the math to keep track of the number of ms elapsed since boot

Releases
--------

### v1.02

This version improves the scanning rate of knobs for the "classic" (4-knob) Shruthi, and contains several minor bug fixes.

### v1.01

Major code rewrite!

#### Synthesis

-   Single-cycle LFO mode.
-   Individual ADSR parameters are modulation destinations.

#### Sequencing

-   The **warp** modes for the sequencer/arpeggiator have been deprecated.
-   The **impro** and **rec** modes for the sequencer have been deprecated.
-   The internals of the sequencer/arpeggiator are now that of a reasonable 24 ppqn MIDI sequencer. External MIDI sync is tighter, and the Shruthi can output a MIDI clock to control other devices.
-   Tempo-synchronized LFOs do not have the occasional reset/glitching they sometimes had in the previous version.
-   The **Warp** setting has been replaced by an adjustable MIDI clock divider, which allows the arpeggiator or sequencer to run at other divisions than sixteenth notes, from 1/96 notes to whole notes. This new feature explains the disappearance of "turbo" tempi and dividers in the external clock mode.

#### Performance and system

-   Duophonic mode behaves in a more predictable way, especially when coupled with the arpeggiator.
-   Arpeggiator, portamento/legato and sequencer settings are now saved with the patch. When an arp or sequence is already running, loading a new patch will only load the synth settings (to keep your sequence running...)
-   Pressing the encoder for 1 second will latch whatever the synth is playing (arpeggio, sequence, or single note), and will put the unit in latched mode unless the encoder is pressed again for 1s.
-   Using the latch function when no note is playing puts the synth in "jam" mode - you can scroll through preset scales using the knobs. It works with the sequencer and arpeggiator too, so it effectively replaces the "test note".
-   It is no longer possible to individually save/load sequences. Sequences are now part of a patch.

#### MIDI

-   The MIDI **split** mode has been deprecated.
-   The code handling CC/NRPN has been rewritten. Major benefit: knob moves are transmitted as CC rather than as NRPN - whenever possible of course.

#### UI

-   Support for the XT digital control board.
-   The UI is much more responsive.
-   The **Performance page** has been deprecated.
-   The **Triggers** feature has been deprecated.
-   What used to be the "split point" setting is now an option to choose the behaviour at boot: splash screen on/off and boot on the presets page on/off.
-   Screensaver (for OLED displays).

#### Filter board handling

-   Support for an upcoming filter board by TubeOhm.

### v0.98

Minor bug fixes, and extended SysEx support for [third party editors](http://www.vauxlab.com/downloads/shreditor/).

### v0.97

#### Synthesis

-   The envelopes have a different behaviour - the attack does not reset 0 at the beginning of each note, but rather starts from the current level of the envelope.
-   The way velocity is managed in the context of note priority handling has been changed. When you play and hold a note, play a new note and release it, the held note is retriggered with its original velocity.
-   Phase increments are computed using a new interpolation technique, saving 1.3kb of code size.

#### Filter board handling

-   Support for the "LP2+Delay" filter board.

#### UI

-   When using the programmer, the screen shows the value of the edited parameter.

### v0.96

#### Synthesis

-   The LFSR used for the noise oscillator can now be reset by oscillator sync. This allows the creation of pitched sounds with a very rich timbre.
-   Constant values have been introduced in the mod matrix. They can be combined with operators to attenuate, translate, or quantize a modulation source by a known value.
-   A Quantize operation has been added to the operators. It reduces the bit-depth of a modulation source to create a Sample & Hold like effect on any modulation.
-   A Lag processor operation has been added to the operators. It smoothes the slope of a modulation source to create more progressive modulations.
-   Two MIDI channel/note combo can be defined as "triggers". When such a MIDI message is received, a note is not played. Instead, a modulation source ("trigger 1" and "trigger 2" in the mod matrix) changes. This can be used to trigger effects (such as a pitch change or LFO speed boost) from a keyboard or an external MIDI sequencer.
-   2 new modulation destinations, "env 1" and "env 2" allow the envelopes to be triggered whenever a modulation source crosses a threshold.
-   A new mixing mode, "duo", allows the synth to be used in a pseudo-duophonic mode. The least recently played note is played on osc 2, and the most recently played note is played on osc 1.
-   3 new mixing modes, "2 steps", "4 steps" and "8 steps" allow the oscillators (or oscillators, sub-oscillator and noise source) to be triggered rythmically at each note.
-   A new mixing mode, "seqmix" allows the oscillators/sub/noise sources to be rythmically disabled according to the pattern input in the step sequencer. This allows very crude rythmic patterns to be programmed (using noise as a snare drum and the sub-oscillator as a kick).
-   The attack time modulation destination now accepts both positive (faster attack) and negative (slower attack) modulations.

#### Filter board handling

-   The cutoff range of the Polivoks filter board has been shifted up by one octave.

#### Code

-   256 bytes have been saved by using the same table for the lowest octaves of the triangle oscillator.
-   129 bytes have been saved by simplifying the "vibes" wavetable.
-   A bug that caused random corruption of an unused memory area during program startup has been fixed.
-   2.5 kbytes have been saved by de-specialization the Oscillators code.

### v0.95

#### Synthesis

-   A page has been added to configure the routing of the Polivoks filter board.
-   The page showing the hpf settings for the SSM2044 filter board simultaneously displays the cutoff/resonance of the lpf - allowing both filters to be tweaked at the same time.
-   Added a cutoff-coupling mode for the dual SVF filter board.
-   MIDI notes in the 120-128 range are no longer wrapped to 108-116.
-   Fixed a bug causing a faint VCA bleed with some specific combinations of modulation sources routed to the VCA.
-   Added a new mixing mode, "fold", which equally mixes oscillator 1 and 2 and send the output to a fold-back distortion, the amount of which is controlled by "mix"
-   Added a new mixing mode, "bits", which equally mixes oscillator 1 and 2 and send the output to a bit-reduction distortion, the amount of which is controlled by "mix".

#### Code

-   512 bytes have been saved by using the same table for the lowest octaves of the triangle oscillator.

#### UI

-   Fixed a bug occurring when scrolling backwards from the second filter page.
-   Fixed a bug preventing the tempo and LFO rate parameters to be edited with the pot, when the unit is configured in "snap" mode.

### v0.94

#### Synthesis

-   Fixed a bug that caused a loudness drop of the vowel oscillator
-   Fixed a bug that caused the filtered noise "oscillator" to output incorrect values when the parameter was set to a high value.
-   The envelopes now have a smoother curve, and slower attack / decay / release times can be achieved.
-   Fixed a timing bug that caused the main oscillators pitch to be off by 8cents.

#### Code

-   The z-family oscillators now share common code, saving \~700 bytes of code.
-   Resource table de-duplication saved \~200 bytes of code.
-   The vowel oscillator code has been simplified by \~100 bytes.
-   MIDI input is polled from the 39kHz audio interrupt rather than interrupt-driven. This saves \~80 CPU cycles per byte of MIDI data received,since there is no extra ISR intro/outtro when a MIDI byte is received.

#### MIDI implementation

-   The Shruthi now uses an officially registered manufacturer ID for SysEx communication. As a result, patch dumps/backups made with previous versions willstill be readable with v0.94 and onwards, but patch dumps made with v0.94 won't be readable with earlier versions.
-   CC90 and CC87 can be used to control the cutoff frequency and resonance of the second filter on the dual SVF filter board.

### v0.93

#### Synthesis

-   A menu has been added to control the routing of the dual SVF filter board.
-   A menu has been added to control the effects of the digital FX board.
-   The wavetable synthesis code has been rewritten to allow interpolation between waveforms which are not contiguous in memory. This allows the definition of wavetables which are a subset, or a permutation, or a mix of the existing wavetables. 10 such wavetables have been added to oscillator 1, approximating classic Waldorf Microwave wavetables.

#### MIDI

-   Upon reception of a program change, the active patch number is updated (in v0.92, the patch was loaded but the patch number was not changed).

#### Code

-   Removed some cruft left after the oscillators rendering rewrite of v0.92. Saved 110 bytes of code.
-   The classes and functions in the 'hal' directory are now an independent project called AVRil.
-   I/O pins are now referenced by port/bit rather than by an Arduino-style pin number.


### v0.92

#### UI

-   Patches can be tweaked from the load/save page. In this case, the 4 knobs have the functions assigned to them in the performance page for this patch.
-   The Shruthi can be configured to boot directly on the presets page (aka "presets mode").
-   Non-blocking ADC scanning increases UI responsiveness.
-   The "mix" and "osc 1" pages have been modified. The sub-oscillator settings are now on the same page as the oscillator 1 settings.
-   Holding the load/save switch (S6) pressed down while rotating the encoder allows the values to be incremented/decremented by steps of 10. Useful for browsing patches!

#### System

-   Different options are available for using the 4 CV: 4 CV ins (assignable in mod matrix -- default setting), 32-knobs programmer, or simple mapping to cutoff, param1/param2 for pedals and joystick.
-   External eeproms larger than 64kb are supported, up to 512kb. Note that when a 512kb eeprom is used, the last 64kb block is not used (this is due to the fact that 16-bit arithmetic is used to compute addresses, and that the address space includes the 16kb of the internal eeprom).
-   Patches / sequences loading and saving can now be linked together (loading patch 15 simultaneously loads sequence 15...). Since it is not clear how this feature will be exposed in the UI, it is for now dormant.

#### MIDI

-   SysEx Patch request command (0x11 0x00). Upon reception of this command, the Shruthi dumps the currently edited patch. Might be useful for an editor!
-   SysEx Patch write command (0x21 0x00 0xnn 0xnn). Upon reception of this command, the Shruthi writes the current patch to a target memory.
-   Support for NRPN increment/decrement.
-   The SysEx backup protocol has been extended to support backing up / restoring more than 16kb of patch data.
-   A bank and program change message is sent whenever a preset is loaded.
-   Bank change messages are handled, to allow patches above 128 to be loaded.
-   Volume change messages (CC 7) are handled.
-   A new MIDI out mode has been added in which only user-initiated knobs changes are sent to the MIDI out. This mode is ideal for using the Shruthi with both its IN/OUT ports connected to the same device. The other modes are not suitable for operation in this configuration since they can cause unwanted MIDI loops.

#### Synthesis

-   The shape of the envelope (approximation of an exponential) has been refined.
-   The "2 bits" modulation destination is gone, since there are now better ways (extra TX pin, shift register out) to communicate with a filter board.
-   A new modulation destination (replacing "2 bits") allows the attack of both envelopes to be sped up. This settings is particularly useful when velocity is used as a modulation source.
-   The "digital silencing" of oscillators when envelopes have reached zero has been improved. The oscillators are now digitally silenced whenever the VCA destination in the modulation matrix has reached a value of zero.
-   The noise source in the mixer is now refreshed at 40kHz instead of 10kHz, giving it a richer timbre.
-   The phase counters are now 24 bits instead of 16 bits. This allows more subtle detuning effects between the oscillators, especially in the lowest notes.
-   The audio engine has been rewritten from a "breadth first" to a "depth first" perspective, and as a result, is faster.
-   As a result of the audio engine rewrite, the vowel oscillator can now be used with the noise and sub generators.
-   The crossfading between wavetable zones is more subtle on the pulse oscillator (square with a parameter &gt; 0).
-   To make more room for upcoming features, the waves wavetable has been downsampled to 128 samples/waveform instead of 256.
-   New mixing modes (&gt;&gt;4, &gt;&gt;8) allow the oscillators signal to be bitcrushed (sample rate reduction with a S&H) before being sent to the filter.
-   A new feature ("operators") allows 2 pairs of modulation sources to be combined through a variety of mathematical operations (addition, multiplication, comparison) to yield two new complex modulation sources.

#### Code

-   Various code size optimizations saved 1kb.
-   The modulation matrix processing code has been simplified.
-   Changed compilation flags to achieve smaller code size.
-   A menu in the UI and code infrastructure is ready to provide filter-board specific menus and parameters in future firmware revisions.

### v0.91

-   Improved encoder debouncing/decoding algorithm.
-   Changed "load" label to "browse" in patch load/save page.

### v0.90

-   Original release.
