(

(Document.current.dir +/+ "synthDefs.scd").load;


~server = Server.default;
~server.options_(ServerOptions.new.numOutputBusChannels_(2));

~server.waitForBoot({

	~audioBuss = CtkAudio.play(1, server: ~server);
	~reverbNote = ~myPlayBufPNotes['reverb'].note(addAction: 'tail').in_(~audioBuss).play;
	~lotsOfReverbBus = Bus.audio(~server, 2);
	~lessReverbBus = Bus.audio(~server, 2);

	MIDIIn.connectAll;
	MIDIFunc.trace(true);
	~midiOne = MIDIClient.sources[1229632811];
	~midiTwo = MIDIClient.sources[478418422];

	~conditionalKr = {
		arg condition, falseVal, trueVal;
		Select.kr(condition, [falseVal, trueVal]);
	};

	~iPhone = NetAddr("10.0.0.241", 9000);
	OSCFunc.trace(false);
	~start = 0.0.rrand(1.0);
	~rateSpec = ControlSpec(0.1, 30.0, \lin);
	~freqSpec = ControlSpec(100, 1000, \lin);
	~freqShiftSpec = ControlSpec(0, 800, \lin);
	~lpfSpec = ControlSpec(100, 10000, \exp);
	~audioRateSpec = ControlSpec(0.25, 4.0, 'exp');
	~volumeSpec = ControlSpec(0.0, 2.0, \lin);
	~volumeSpec2 = ControlSpec(0.0, 2.0, \lin);
	~panSpec = ControlSpec(45, -45, 'lin');
	~synths = IdentityDictionary.new;

	~playFunc = {
		arg key, synthName, args;
		var existingSynth = ~synths[key];
		existingSynth.tryPerform(\free);
		~synths[key] = Synth(synthName, args);
	};

	SynthDef(\lotsOfReverb, {
		var source = In.ar(~lotsOfReverbBus, 2);
		Out.ar(0, FreeVerb2.ar(source[0], source[1], 0.9, 0.8, 0.5));
	}).add;

	SynthDef(\lessReverb, {
		var source = In.ar(~lessReverbBus, 2);
		Out.ar(0, FreeVerb2.ar(source[0], source[1], 0.2, 0.3, 0.5));
	}).add;

	s.sync;
	~lotsOfReverb = Synth(\lotsOfReverb);
	~lessReverb = Synth(\lessReverb);

	SynthDef.new(\polyrhythm, {
		arg noiseRate, noiseRate2, freq1, freq2, freqShift = 0, gate = 1, lpfFreq = 10000, amp = 0.4;
		var f1, f2, sig1, sig2, env, envSig, sig;
		f1 = ~conditionalKr.(freq1 <= 0, freq1, LFNoise0.kr(noiseRate).range(30 + freqShift, 300 + freqShift));
		f2 = ~conditionalKr.(freq2 <= 0, freq2, LFNoise0.kr(noiseRate2).range(20 + freqShift, 350 + freqShift));
		env = Env.asr(0.01, 1, 0.1);
		envSig = EnvGen.kr(env, gate);
		sig1 = Saw.ar(f1 + SinOsc.ar(f1 * 0.5, 0, 30)) * amp * envSig;
		sig2 = Saw.ar(f2 + SinOsc.ar(f2 * 0.5, 0, 30)) * amp * envSig;
		sig = [sig1, sig2];
		sig = LPF.ar(sig, lpfFreq);
		Out.ar(~lotsOfReverbBus, sig);
	}).add;

	~polyrhythmMidiToggle = MIDIFunc.cc({ |val, num, chan, src|
		if (val == 127) {
			var key = \polyrhythmRegisteryKey;
			var synth = ~synths[key];
			if (synth.notNil) {
				synth.free;
				~synths[key] = nil;
				"Polyrhythm synth stopped.".postln;
			} {
				~synths[key] = Synth(\polyrhythm, [
					\noiseRate, 1,
					\noiseRate2, 1,
					\freq1, 0,
					\freq2, 0,
					\freqShift, 0,
					\lpfFreq, 100,
					\amp, 0
				]);
				"Polyrhythm synth started.".postln;
			};
		}
	}, 64, nil, 478418422);

	~polyrhythmMidiNoiseRate = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\polyrhythmRegisteryKey];
		synth.notNil.if {
			synth.set(\noiseRate, ~rateSpec.map(val.linlin(0, 127, 0.01, 1)));
		};
	}, 0, nil, 478418422);

	~polyrhythmMidiNoiseRate2 = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\polyrhythmRegisteryKey];
		synth.notNil.if {
			synth.set(\noiseRate2, ~rateSpec.map(val.linlin(0, 127, 0.01, 1)));
		};
	}, 1, nil, 478418422);

	~polyrhythmMidiFreqShift = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\polyrhythmRegisteryKey];
		synth.notNil.if {
			synth.set(\freqShift, ~freqSpec.map(val.linlin(0, 127, 0.01, 1)));
		};
	}, 16, nil, 478418422);

	~polyrhythmMidiLPF = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\polyrhythmRegisteryKey];
		synth.notNil.if {
			var cutoff = ~lpfSpec.map(val.linlin(0, 127, 0.0, 1.0));
			synth.set(\lpfFreq, cutoff);
		};
	}, 17, nil, 478418422);

	~polyrhythmVolumeControl = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\polyrhythmRegisteryKey];
		synth.notNil.if {
			var volume = ~volumeSpec.map(val.linlin(0, 127, 0.0, 1.0));
			synth.set(\amp, volume);
		};
	}, 0, nil, 1229632811);

	SynthDef.new(\drum, {
		arg freq, amp, rate;
		var trig, env, sig;
		trig = Impulse.kr(rate);
		env = Decay2.kr(trig, 0.001, 0.5);
		sig = SinOsc.ar(freq) * env * amp;
		Out.ar(~lessReverbBus, sig!2);
	}).add;

	~drumMidiToggle = MIDIFunc.cc({ |val, num, chan, src|
		if (val == 127) {
			var key = \drumRegisteryKey;
			var synth = ~synths[key];
			if (synth.notNil) {
				synth.free;
				~synths[key] = nil;
				"Drum synth stopped.".postln;
			} {
				~synths[key] = Synth(\drum, [\freq, 100, \rate, 0.1, \amp, 0]);
				"Drum synth started.".postln;
			};
		}
	}, 66, nil, 478418422);

	~drumMidiRate = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\drumRegisteryKey];
		synth.notNil.if {
			synth.set(\rate, ~rateSpec.map(val.linlin(0, 127, 0.01, 1)));
		};
	}, 2, nil, 478418422);

	~drumMidiFreq = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\drumRegisteryKey];
		synth.notNil.if {
			synth.set(\freq, ~freqSpec.map(val.linlin(0, 127, 0.01, 1)));
		};
	}, 18, nil, 478418422);

	~drumVolumeControl = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\drumRegisteryKey];
		synth.notNil.if {
			var volume = ~volumeSpec.map(val.linlin(0, 127, 0.0, 1.0));
			synth.set(\amp, volume);
		};
	}, 2, nil, 1229632811);


	// Sustained Sounds

	~soundPath1 = PathName("../sounds/sustained.wav".resolveRelative);
	~buffer1 = CtkBuffer(~soundPath1.fullPath).load;

	~note1MidiToggle = MIDIFunc.cc({ |val, num, chan, src|
		if (val == 127) {
			~note1 = ~myPlayBufPNotes[\dxarts46x_stereoPlayBuf].note(
				starttime: ~start,
			)
			.dur_(~buffer1.duration)
			.bufnum_(~buffer1)
			.outBus_(~audioBuss)
			.loop_(1)
			.lpfFreq_(100)
			.lpfRes_(0.5)
			.volume_(0)
			.play;
			"Sustained Sounds are playing now".postln;
		}
	}, 67, nil, 478418422);

	~note1FilterControl = MIDIFunc.cc({ |val, num, chan, src|
		~note1.lpfFreq_(~lpfSpec.map(val.linlin(0, 127, 0.001, 1)));
	}, 19, nil, 478418422);

	~note1RateControl = MIDIFunc.cc({ |val, num, chan, src|
		~note1.rate_(~audioRateSpec.map(val.linlin(0, 127, 0.001, 1)));
	}, 3, nil, 478418422);

	~note1VolumeControl = MIDIFunc.cc({ |val, num, chan, src|
		~note1.volume_(~volumeSpec2.map(val.linlin(0, 127, 0.001, 1)));
	}, 3, nil, 1229632811);

	~note1PanControl = MIDIFunc.cc({ |val, num, chan, src|
		~note1.panAngle_(~panSpec.map(val.linlin(0, 127, 0.001, 1)));
	}, 19, nil, 1229632811);


	// Noisy Sounds

	~soundPath2 = PathName("../sounds/noisy.wav".resolveRelative);
	~buffer2 = CtkBuffer(~soundPath2.fullPath).load;

	~note2MidiToggle = MIDIFunc.cc({ |val, num, chan, src|
		if (val == 127) {
			~note2 = ~myPlayBufPNotes[\dxarts46x_stereoPlayBuf].note(
				starttime: ~start,
			)
			.dur_(~buffer2.duration)
			.bufnum_(~buffer2)
			.outBus_(~audioBuss)
			.loop_(1)
			.lpfFreq_(100)
			.lpfRes_(0.5)
			.volume_(0)
			.play;
			"Noisy Sounds are playing now".postln;
		}
	}, 68, nil, 478418422);

	~note2FilterControl = MIDIFunc.cc({ |val, num, chan, src|
		~note2.lpfFreq_(~lpfSpec.map(val.linlin(0, 127, 0.001, 1)));
	}, 20, nil, 478418422);

	~note2RateControl = MIDIFunc.cc({ |val, num, chan, src|
		~note2.rate_(~audioRateSpec.map(val.linlin(0, 127, 0.001, 1)));
	}, 4, nil, 478418422);

    ~note2VolumeControl = MIDIFunc.cc({ |val, num, chan, src|
		~note2.volume_(~volumeSpec2.map(val.linlin(0, 127, 0.001, 1)));
	}, 4, nil, 1229632811);

	~note2PanControl = MIDIFunc.cc({ |val, num, chan, src|
		~note2.panAngle_(~panSpec.map(val.linlin(0, 127, 0.001, 1)));
	}, 20, nil, 1229632811);


	// Clicky Sounds

	~soundPath3 = PathName("../sounds/clicky.wav".resolveRelative);
	~buffer3 = CtkBuffer(~soundPath3.fullPath).load;

	~note3MidiToggle = MIDIFunc.cc({ |val, num, chan, src|
		if (val == 127) {
			~note3 = ~myPlayBufPNotes[\dxarts46x_stereoPlayBuf].note(
				starttime: ~start,
			)
			.dur_(~buffer3.duration)
			.bufnum_(~buffer3)
			.outBus_(~audioBuss)
			.loop_(1)
			.lpfFreq_(100)
			.lpfRes_(0.5)
			.volume_(0)
			.play;
			"Clicky Sounds are playing now".postln;
		}
	}, 69, nil, 478418422);

	~note3FilterControl = MIDIFunc.cc({ |val, num, chan, src|
		~note3.lpfFreq_(~lpfSpec.map(val.linlin(0, 127, 0.001, 1)));
	}, 21, nil, 478418422);

	~note3RateControl = MIDIFunc.cc({ |val, num, chan, src|
		~note3.rate_(~audioRateSpec.map(val.linlin(0, 127, 0.001, 1)));
	}, 5, nil, 478418422);

    ~note3VolumeControl = MIDIFunc.cc({ |val, num, chan, src|
		~note3.volume_(~volumeSpec2.map(val.linlin(0, 127, 0.001, 1)));
	}, 5, nil, 1229632811);

	~note3PanControl = MIDIFunc.cc({ |val, num, chan, src|
		~note3.panAngle_(~panSpec.map(val.linlin(0, 127, 0.001, 1)));
	}, 21, nil, 1229632811);


	SynthDef.new(\homorhythm, {
		arg noiseRate, noiseRate2, freq1, freq2, freqShift = 0, gate = 1, lpfFreq = 10000, glideTime = 3, amp = 0.4;
		var f1, f2, sig1, sig2, env, envSig, sig;
		var freqs = [130.81, 146.83, 155.56, 174.61, 196.00, 207.65, 233.08,	261.63, 293.66, 311.13, 349.23, 392.00, 415.30, 466.16] + freqShift;
		var index1 = LFNoise0.kr(noiseRate).range(0, freqs.size - 1).round(1).clip(0, freqs.size - 1);
		var index2 = LFNoise0.kr(noiseRate2).range(0, freqs.size - 1).round(1).clip(0, freqs.size - 1);
		var selected1 = Select.kr(index1, freqs);
		var selected2 = Select.kr(index2, freqs);
		var smoothF1 = Lag.kr(selected1, glideTime);
		var smoothF2 = Lag.kr(selected2, glideTime);
		f1 = ~conditionalKr.(freq1 <= 0, freq1, smoothF1);
		f2 = ~conditionalKr.(freq2 <= 0, freq2, smoothF2);
		env = Env.asr(0.01, 1, 0.1);
		envSig = EnvGen.kr(env, gate);
		sig1 = SinOsc.ar(f1 + SinOsc.ar(f1 * 0.5, 0, 30)) * amp * envSig;
		sig2 = SinOsc.ar(f2 + SinOsc.ar(f2 * 0.5, 0, 30)) * amp * envSig;
		sig = [sig1, sig2];
		sig = LPF.ar(sig, lpfFreq);
		Out.ar(~lessReverbBus, sig);
	}).add;

	~homorhythmMidiToggle = MIDIFunc.cc({ |val, num, chan, src|
		if (val == 127) {
			var key = \homorhythmRegisteryKey;
			var synth = ~synths[key];
			if (synth.notNil) {
				synth.free;
				~synths[key] = nil;
				"Homorhythm synth stopped.".postln;
			} {
				~synths[key] = Synth(\homorhythm, [
					\noiseRate, 0.4,
					\noiseRate2, 0.4,
					\freq1, 0,
					\freq2, 0,
					\freqShift, 0,
					\lpfFreq, 1000,
					\amp, 0
				]);
				"Homorhythm synth started.".postln;
			};
		}
	}, 70, nil, 478418422);

	~homorhythmMidiNoiseRate = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\homorhythmRegisteryKey];
		synth.notNil.if {
			synth.set(\noiseRate, ~rateSpec.map(val.linlin(0, 127, 0.01, 1)));
		};
	}, 6, nil, 478418422);

	~homorhythmMidiNoiseRate2 = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\homorhythmRegisteryKey];
		synth.notNil.if {
			synth.set(\noiseRate2, ~rateSpec.map(val.linlin(0, 127, 0.01, 1)));
		};
	}, 7, nil, 478418422);

	~homorhythmMidiFreqShift = MIDIFunc.cc({ |val, num, chan, src|
		var shift = ~freqShiftSpec.map(val.linlin(0, 127, 0.001, 1));
		~synths[\homorhythmRegisteryKey].set(\freqShift, shift);
	}, 22, nil, 478418422);

	~homorhythmMidiLPF = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\homorhythmRegisteryKey];
		synth.notNil.if {
			var cutoff = ~lpfSpec.map(val.linlin(0, 127, 0.0, 1.0));
			synth.set(\lpfFreq, cutoff);
		};
	}, 23, nil, 478418422);

	~homorhythmVolumeControl = MIDIFunc.cc({ |val, num, chan, src|
		var synth = ~synths[\homorhythmRegisteryKey];
		synth.notNil.if {
			var volume = ~volumeSpec.map(val.linlin(0, 127, 0.0, 1.0));
			synth.set(\amp, volume);
		};
	}, 6, nil, 1229632811);

	~hdr = HDR(
		~server,
		[0, 1],
		1,
		0,
		"recordings/".resolveRelative,
		"Final Project Performance",
		"WAV",
		"float"
	);
});

)

MIDIFunc.trace(true);
OSCFunc.trace(hideStatusMsg: true);
~hdr.record;
~hdr.stop;