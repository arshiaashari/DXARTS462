//FINAL PROJECT

(

MIDIIn.connectAll;

~server = Server.default;

~server.options_(ServerOptions.new.numOutputBusChannels_(2));

~server.waitForBoot({

	~soundPath = PathName("../sounds/Marimba.cord.ff.Ab3.stereo.aif".resolveRelative);

	~buffers = CtkBuffer(~soundPath.fullPath).load;

	(Document.current.dir +/+ "synthDefs.scd").load;

	~rateSpec = ControlSpec(0.25, 4.0, 'exp');

	~panSpec = ControlSpec(-45, 45, 'lin');

	~audioBuss = CtkAudio.play(1, server: ~server);

	// ~buffer = ~buffers.choose;

	~start = 0.0;

	~rate = 1.0;
	~panAngle = 0;

	~proc = ProcModR.new(
		env: Env([0, 1, 0], [10, 10], 'sin', 1),
		amp: 2,
		numChannels: 2,
		procout: ~audioBuss,
		id: 'test',
		server: ~server,
		function: { |group, routebus, server, pmod|
			[pmod, group, routebus, server].postln;
			~task = Task({
				loop({
					~buffer = ~buffers;
					~note = ~myPlayBufPNotes[\dxarts46x_stereoPlayBuf].note(target: group)
					.dur_(~buffer.duration)
					.rate_(~rate)
					.bufnum_(~buffer)
					.outBus_(routebus)
					.panAngle_(~panAngle)
					.play;
					0.5.wait
				})
			})
		}
	);

	// list the events in a ProcEvents
	~events = ProcEvents.new([
		[~proc, nil], // play the first procmod and release nothing
		[nil, ~proc] // play nothing and release a procmod
	], 1, nil, nil, 'test'
	);


	//this is the reverb - it's the FreeVerb2 for stereo sound in the SynthDefs file
	~reverbNote = ~myPlayBufPNotes['reverb'].note(addAction: 'tail').in_(~audioBuss).play;

	//this maps the playback speed to the MIDI knob
	~midiRate = MIDIFunc.cc({ |val, num, chan, src|
        ~rate = ~rateSpec.map(val.linlin(0, 127, 0, 1))
    }, ccNum: 0);

	//this maps the pan angle speed to the MIDI knob
	~midiPan = MIDIFunc.cc({ |val, num, chan, src|
        ~panAngle = ~panSpec.map(val.linlin(0, 127, 0, 1))
    }, ccNum: 1);

	//a MIDI button starts & stops the scheduling — the if statement makes it so that only the first press–down runs the code, not the release of the button
	~midiStart = MIDIFunc.cc({ |val, num, chan, src|
		(val == 127).if({ ~events.next; })
	}, 64);

	//THE FOLLOWING IS NOT NEEDED WHEN USING THE ProcMod Event ABOVE BECAUSE THE ProcMod DOES THE STARTING AND STOPPING
	/*
	//a MIDI button stops the sound — the if statement makes it so that only the first press–down runs the code, not the release
	~midiStop = MIDIFunc.cc({ |val, num, chan, src|
		(val == 127).if({ ~task.stop; })
	}, 65);
	*/

	~hdr = HDR(
		~server,
		[0, 1],
		1,
		0,
		"recordings/".resolveRelative,
		~soundPath.fileNameWithoutExtension,
		"WAV",
		"float"
	);

	~hdr.record;

});

)

MIDIFunc.trace();
MIDIFunc.trace(false);
