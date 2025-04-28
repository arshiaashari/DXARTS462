//LAB TASK 3 (Part I)




(

MIDIIn.connectAll;

(Document.current.dir +/+ "synthDefs.scd").load;


~server = Server.default;
~server.options_(ServerOptions.new.numOutputBusChannels_(2));

~server.waitForBoot({

	~sounds = "../../sounds/*".resolveRelative.pathMatch;

	~buffers = ~sounds.collect{ |pathName, increment|
		CtkBuffer(pathName).load
	};

	~rateSpec = ControlSpec(0.25, 4.0, 'exp');

	~panSpec = ControlSpec(-45, 45, 'lin');

	~audioBuss = CtkAudio.play(1, server: ~server);

	~buffer = ~buffers.choose;

	~start = 0.0;

	~rate = 1.0;
	~panAngle = 0;

	~task = Task({
		loop({
			~note = ~myPlayBufPNotes[\dxarts46x_stereoPlayBuf].note
			.dur_(~buffer.duration)
			.rate_(~rate)
			.bufnum_(~buffer)
			.outBus_(~audioBuss)
			.panAngle_(~panAngle)
			.play;
			0.5.wait
		})
	});

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

	~midiStart = MIDIFunc.cc({ |val, num, chan, src|
		(val == 127).if({ ~task.play; })
	}, 64);

	~midiStop = MIDIFunc.cc({ |val, num, chan, src|
		(val == 127).if({ ~task.stop; })
	}, 65);

});

)
