(

(Document.current.dir +/+ "synthDefs.scd").load;


~server = Server.default;
~server.options_(ServerOptions.new.numOutputBusChannels_(2));

~server.waitForBoot({

	~soundPath = PathName("../../sounds/Vibraphone.bow.Ab3.stereo.aif".resolveRelative);
	~soundPath2 = PathName("../../sounds/Marimba.roll.ff.Ab3.stereo.aif".resolveRelative);

	~buffers = CtkBuffer(~soundPath.fullPath).load;
	~buffers2 = CtkBuffer(~soundPath2.fullPath).load;

	~rateSpec = ControlSpec(0.25, 4.0, 'exp');
	~panSpec = ControlSpec(-45, 45, 'lin');

	~audioBuss = CtkAudio.play(1, server: ~server);

	~buffer = ~buffers;
	~buffer2 = ~buffers2;
	//I've set the start time to be a random value from a small range in the interest of not having to wait more than one second
	~start = 0.0.rrand(1.0);
	~note = ~myPlayBufPNotes[\dxarts46x_stereoPlayBuf].note(
		starttime: ~start,
	)
	.dur_(~buffer.duration)
	.bufnum_(~buffer)
	.outBus_(~audioBuss)
	//this makes it so that the soundfile is played continuously
	.loop_(1)
	.play;

	~note2 = ~myPlayBufPNotes[\dxarts46x_stereoPlayBuf].note(
		starttime: ~start,
	)
	.dur_(~buffer2.duration)
	.bufnum_(~buffer2)
	.outBus_(~audioBuss)
	//this makes it so that the soundfile is played continuously
	.loop_(1)
	.play;

	//iterating

	//this is the reverb - it's the FreeVerb2 for stereo sound in the SynthDefs file
	~reverbNote = ~myPlayBufPNotes['reverb'].note(addAction: 'tail').in_(~audioBuss).play;

	//the first argument in NetAddr is the Local IP Address in TochOSC
	//Note that TouchOSC's Host also needs to be set to the IP Address to this machine's wifi connection
	~iPhone = NetAddr("10.0.0.8", 9000);

    //this maps the playback speed to the OSC knob
    ~rate = OSCFunc({ |msg, time, addr, recPort|
        ~note.rate_(~rateSpec.map(msg[1]))
    }, '/1/fader1', ~iPhone);

    //this maps the pan angle to the OSC knob
    ~pan = OSCFunc({ |msg, time, addr, recPort|
        ~note.panAngle_(~panSpec.map(msg[1]))
    }, '/1/rotary1', ~iPhone);

    ~rate = OSCFunc({ |msg, time, addr, recPort|
        ~note2.rate_(~rateSpec.map(msg[1]))
    }, '/1/fader2', ~iPhone);

    ~pan = OSCFunc({ |msg, time, addr, recPort|
        ~note2.panAngle_(~panSpec.map(msg[1]))
    }, '/1/rotary4', ~iPhone);

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

OSCFunc.trace;

	~hdr.stop;