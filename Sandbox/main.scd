//SANDBOX

(

~server = Server.default;
~server.options_(ServerOptions.new.numOutputBusChannels_(2));

~server.waitForBoot({
	~synth = CtkSynthDef('simple', { |out = 0, gain = 0, pan = 0|
		var sinosc;
		sinosc = SinOsc.ar('freq'.kr(440, 0.1), 0, gain.dbamp);
		Out.ar(out, Pan2.ar(sinosc, pan));
		SynthDef('reverb', { |in, out = 0|
			var src;
			src = In.ar(in, 2); // stereo buss
			Out.ar(out, FreeVerb2.ar(src[0], src[1], 2, 2, 2))
		});
	});


	~note = ~synth.note.play;

	~iPhone = NetAddr("192.168.0.94", 9000);

	~freq = OSCFunc({ |msg, time, addr, recPort|
		~note.freq_(msg[1].linexp(0, 1, 110, 1760))
	}, '/1/fader1', ~iPhone);

    ~pan = OSCFunc({ |msg, time, addr, recPort|
        ~note.pan_(msg[1].linlin(0, 1, -1, 1))
    }, '/1/fader2', ~iPhone);


})

)

OSCFunc.trace();
OSCFunc.trace(false);
