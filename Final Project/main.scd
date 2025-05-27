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

	//the first argument in NetAddr is the Local IP Address in TochOSC
	//Note that TouchOSC's Host also needs to be set to the IP Address to this machine's wifi connection
	~iPhone = NetAddr("10.18.254.169", 9000);

    //this maps the playback speed to the OSC knob
    ~rate = OSCFunc({ |msg, time, addr, recPort|
        ~note.rate_(~rateSpec.map(msg[1]))
    }, '/1/fader1', ~iPhone);

    //this maps the pan angle speed to the OSC knob
    ~pan = OSCFunc({ |msg, time, addr, recPort|
        ~note.panAngle_(~panSpec.map(msg[1]))
    }, '/1/fader2', ~iPhone);

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

OSCFunc.trace();
OSCFunc.trace(false);
