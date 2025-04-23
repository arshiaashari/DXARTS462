(

// need to connect the MIDI device
MIDIIn.connectAll;

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
	~start = 0.0.rrand(10.0);
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

	//this maps the playback speed to the MIDI knob
	~midiRate = MIDIFunc.cc({ |val, num, chan, src|
        ~note.rate_(~rateSpec.map(val.linlin(0, 127, 0, 1)))
    }, ccNum: 0);

	//this maps the pan angle speed to the MIDI knob
	~midiPan = MIDIFunc.cc({ |val, num, chan, src|
        ~note.panAngle_(~panSpec.map(val.linlin(0, 127, 0, 1)))
    }, ccNum: 1);

});

)
