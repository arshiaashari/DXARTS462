(

(Document.current.dir +/+ "synthDefs.scd").load;


~server = Server.default;
~server.options_(ServerOptions.new.numOutputBusChannels_(2));

~server.waitForBoot({

	~buffers = PathName(Document.current.dir +/+ "Sounds/").files.collect{ |pathName, increment|
		CtkBuffer(pathName.fullPath).load
	};

	~rateSpec = ControlSpec(0.25, 4.0, 'exp');
	~panSpec = ControlSpec(-45, 45, 'lin');

	~audioBuss = CtkAudio.play(1, server: ~server);

	~buffer = ~buffers.choose;
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

	//this is the reverb - it's the FreeVerb2 for stereo sound in the SynthDefs file
	~reverbNote = ~myPlayBufPNotes['reverb'].note(addAction: 'tail').in_(~audioBuss).play;

	~iPhone = NetAddr("10.19.196.215", 9000);

    //this maps the playback speed to the OSC knob
    ~rate = OSCFunc({ |msg, time, addr, recPort|
        ~note.rate_(~rateSpec.map(msg[1]))
    }, '/1/fader1', ~iPhone);

    //this maps the pan angle speed to the OSC knob
    ~pan = OSCFunc({ |msg, time, addr, recPort|
        ~note.panAngle_(~panSpec.map(msg[1]))
    }, '/1/fader2', ~iPhone);

});

)
