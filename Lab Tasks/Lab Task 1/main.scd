//LAB TAST 1 (Parts I & II)

(

(Document.current.dir +/+ "synthDefs.scd").load;


~server = Server.default;
~server.options_(ServerOptions.new.numOutputBusChannels_(2));

~server.waitForBoot({

	~sounds = "../sounds/*".resolveRelative.pathMatch;

	~buffers = ~sounds.collect{ |pathName, increment|
		CtkBuffer(pathName).load
	};

	~audioBuss = CtkAudio.play(1, server: ~server);

	10.do{ |i|
		~buffer = ~buffers.choose;
		~start = 0.0.rrand(10.0);
		~myPlayBufPNotes[\dxarts46x_stereoPlayBuf].note(
			starttime: ~start,
			duration: ~buffer.duration
		)
		.dur_(~buffer.duration)
		.bufnum_(~buffer)
		.outBus_(~audioBuss)
		.play
	};

	~reverbNote = ~myPlayBufPNotes['reverb'].note(addAction: 'tail').in_(~audioBuss).play;

});

)
