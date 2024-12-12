s.boot;

(
~dauwd = Buffer.read(s, (PathName("songs/".resolveRelative) +/+ PathName("dauwd.mp3")).fullPath, bufnum: 0);
~yaeji = Buffer.read(s, (PathName("songs/".resolveRelative) +/+ PathName("yaeji.mp3")).fullPath, bufnum: 2);
~isola = Buffer.read(s, (PathName("songs/".resolveRelative) +/+ PathName("isola.mp3")).fullPath, bufnum: 4);
)

~dauwd.numChannels; // Need to wait a second

~dauwd.play; // tempo: 120 bpm
~isola.play; // tempo: 125 bpm
~yaeji.play; // tempo: 120 bpm

(
SynthDef(\turntable, {
	var sig, sig_mono, buff = \buff.ir(0);

	var amp = \amp.kr(1.0);

	var low_sig, mid_sig, high_sig;

	var play = \play.kr(0.0);
	var pitch = \pitch.kr(0.0);

	var reverse = \reverse.kr(0.0);
	var nudge_fwd = \nudge_fwd.kr(0.0);
	var nudge_back = \nudge_back.kr(0.0);
	var snap = \snap.kr(1.0);
	var nudgeAmount = \nudgeAmount.kr(0.01);
	var rate;

	var low_mid_freq = 70;
	var mid_high_freq = 13000;
	var high_db = \eq_high.kr(0.0);
	var mid_db = \eq_mid.kr(0.0);
	var low_db = \eq_low.kr(0.0);

	var fft;
	var trackb, trackh, trackq, tempo = 0;
	var beep;

	// ====== PlaybackRate Calculations ======

	rate = BufRateScale.ir(buff);
	pitch = Lag2.kr(pitch, snap);
	rate = rate * (1.0 + pitch) * play;
	rate = rate * (1.0 + ((nudge_fwd - nudge_back) * nudgeAmount));
	reverse = Lag2.kr(reverse, 1.0);
	rate = rate * (1.0 - (2.0 * reverse)); // reversing should take longer

	sig = PlayBuf.ar(
		numChannels: 2,
		bufnum: buff,
		rate: rate,
		doneAction: 0
	);

	// ======= Tempo / Beat Tracking =======

	sig_mono = (sig[0] + sig[1]) / 2;
	fft = FFT(LocalBuf(1024), sig_mono);
	#trackb, trackh, trackq, tempo = BeatTrack.kr(fft, 0.0);
	tempo = tempo * 60;
	beep = SinOsc.ar(1000, 0.0, Decay.kr(trackb, 0.1)) * play * (60 < tempo.value * tempo.value < 180);
	/*
	(60 < tempo.value * tempo.value < 180).poll;
	(tempo).poll;*/
	// sig = sig + beep;

	// ======= Equalizing + Volume =======

	high_sig = BHiPass4.ar(sig, mid_high_freq) * high_db.dbamp;

	mid_sig = BHiPass4.ar(BLowPass4.ar(sig, mid_high_freq), low_mid_freq) * mid_db.dbamp;

	low_sig = BLowPass4.ar(sig, low_mid_freq) * low_db.dbamp;

	sig = high_sig + mid_sig + low_sig;

	sig = sig * amp;

	// sig = BHiShelf.ar(sig, db: high_db);
/*	sig = BPeakEQ.ar(sig, db: mid_db);
	sig = BLowShelf.ar(sig, db: low_db);*/

	// Avoid DC offset + clicking on pause/play
	sig = sig * Lag.kr(play, 0.001);
	Out.ar(0, sig);
}).add;
)

x = Synth(\turntable, [\buff, ~dauwd.bufnum]);
y = Synth(\turntable, [\buff, ~isola.bufnum]);
Synth(\turntable, [\buff, ~yaeji.bufnum]);


x.set(\play, 1.0);
x.set(\play, 0.0);

x.set(\pitch, 0.02);
x.set(\snap, 1.0);
x.set(\pitch, 0.0);

x.set(\reverse, 0.0);
x.set(\reverse, 1.0);


y.set(\play, 1.0);


// Finalized interface below.
(
~turntable_layout = {
	arg turntable_synth;

	var mainLayout;
	var nudgeLayout;
	var snapLayout;
	var eqLayout;
	var playBackLayout;
	var tempoDisplay;

	var amplitude = Knob();

	var snapKnob = Knob();
	var snapText = StaticText();
	var nudgeAmountKnob = Knob();
	var nudgeAmountText = StaticText();

	var playPause = Button();
	var nudgeForward = Button().string_("nudge ⏩");
	var nudgeBackward = Button().string_("⏪ nudge");
	var reverse = Button();

	var pitchReset = Button().string_("0").maxWidth_(30);
	var pitchSlider = Slider().orientation_(\horizontal), init_slider_val;
	var pitchSliderMarkings;

	var eqHigh = Knob();
	var eqMid = Knob();
	var eqLow = Knob();

	var pitchBendSpec, snapKnobSpec, nudgeAmountSpec, eqSpec;

	// Define properties of the buttons
	playPause.states = [["Play ▶️", Color.new(0.25, 0.75, 0.33), Color.white], ["Pause ⏸️", Color.white, Color.grey]];

	reverse.states = [["◀︎ reverse", Color.black, Color.white], ["reverse ▶️", Color.white, Color.grey]];

	// Define properties of the layouts

	w = Window.new("Turntable", Rect(Window.screenBounds.width / 4, Window.screenBounds.height / 4, 440.0, 190.0),
		resizable: true
	)
	.alwaysOnTop_(true)
	.front;

	pitchSliderMarkings = HLayout(
		StaticText().string_("-8%"), View(),
		pitchReset, View(),
		StaticText().string_("+8%"));
	pitchSliderMarkings.setStretch(1, 1);
	pitchSliderMarkings.setStretch(3, 1);

	tempoDisplay = View();
	tempoDisplay.background = \gray;

	nudgeLayout = HLayout(nudgeAmountKnob, VLayout(StaticText().string_("amount: "), nudgeAmountText)).setAlignment(1, \center);
	nudgeAmountText.font_(Font("Monaco"));

	snapLayout = HLayout(snapKnob, VLayout(StaticText().string_("snap"), snapText)).setAlignment(1, \center);
	snapText.font_(Font("Monaco"));

	playBackLayout = GridLayout.rows(
		[[tempoDisplay, columns: 3], amplitude],
		[[pitchSliderMarkings, columns: 3], reverse],
		[[pitchSlider, columns: 3], snapLayout],
		[nudgeBackward, nudgeLayout, nudgeForward, playPause]
	);

	eqLayout = VLayout(StaticText().string_("EQ").align_(\center), eqHigh, eqMid, eqLow);

	// ===== Define the Button + Slider Actions =======

	pitchBendSpec = ControlSpec.new(-0.08, 0.08);
	snapKnobSpec = ControlSpec.new(0.1, 5.0, \exp);
	nudgeAmountSpec = ControlSpec.new(0.005, 0.08, \exp);
	eqSpec = ControlSpec.specs[\db];

	amplitude.value_(1.0);
	amplitude.action_({ arg v;
		turntable_synth.set(\amp, v.value);
	});

	pitchSlider.value_(0.5);
	pitchSlider.action_({ arg v; var pitch;
		pitchBendSpec.map(v.value).postln;
		turntable_synth.set(\pitch, pitchBendSpec.map(v.value));
	});

	pitchReset.action_({
		turntable_synth.set(\pitch, 0.0);
		pitchSlider.value_(0.5);
	});

	// TODO: unmap the value to set initial position.
	turntable_synth.get(\snap, { arg val; var snapTime;
		{
			snapTime = snapKnobSpec.unmap(val);
			snapKnob.value_(snapTime);
			snapText.string_(snapTime.trunc(0.1) + "s");
		}.defer;
	});

	snapKnob.action_({
		|v|
		var snapTime = snapKnobSpec.map(v.value);
		snapTime.postln;
		turntable_synth.set(\snap, snapKnobSpec.map(v.value));
		snapText.string_(snapTime.trunc(0.1) + "s");
	});

	// TODO: unmap the value to set initial position.\ctrl1, { | val | ~x = val }
	turntable_synth.get(\nudgeAmount, { arg val; var nudgeAmount;
		{
			nudgeAmount = nudgeAmountSpec.unmap(val);
			nudgeAmountKnob.value_(nudgeAmount);
			nudgeAmountText.string_((val * 100).trunc(0.01) + "%");
		}.defer;
	});

	nudgeAmountKnob.action_({
		|v|
		var nudgeAmount = nudgeAmountSpec.map(v.value);
		nudgeAmount.postln;
		turntable_synth.set(\nudgeAmount, nudgeAmountSpec.map(v.value));
		nudgeAmountText.string_(((nudgeAmount * 100).trunc(0.01).asString().padRight(4, "0")) + "%");
	});

	eqHigh.value_(1.0);
	eqHigh.action_({
		|v|
		var eqDb = eqSpec.map(v.value);
		eqDb.postln;
		turntable_synth.set(\eq_high, eqDb);
	});

	eqMid.value_(1.0);
	eqMid.action_({
		|v|
		var eqDb = eqSpec.map(v.value);
		eqDb.postln;
		turntable_synth.set(\eq_mid, eqDb);
	});

	eqLow.value_(1.0);
	eqLow.action_({
		|v|
		var eqDb = eqSpec.map(v.value);
		eqDb.postln;
		turntable_synth.set(\eq_low, eqDb);
	});

	reverse.action_({
		|v| turntable_synth.set(\reverse, v.value);
	});

	playPause.action_({
		|v| turntable_synth.set(\play, v.value);
	});

	nudgeForward.mouseDownAction_({
		turntable_synth.set(\nudge_fwd, 1.0);
	});

	nudgeForward.mouseUpAction_({
		turntable_synth.set(\nudge_fwd, 0.0);
	});

	nudgeBackward.mouseDownAction_({
		turntable_synth.set(\nudge_back, 1.0);
	});

	nudgeBackward.mouseUpAction_({
		turntable_synth.set(\nudge_back, 0.0);
	});

	// Close the window if the synth dies
	turntable_synth.onFree({
		w.close;
	});

	// Finish the layout
	mainLayout = HLayout(eqLayout, playBackLayout);
	mainLayout.setStretch(1, 1);
	w.layout_(mainLayout);
}
);

(
x = Synth(\turntable, [\buff, ~dauwd.bufnum]);
~turntable_layout.value(x);
)

(
y = Synth(\turntable, [\buff, ~isola.bufnum]);
~turntable_layout.value(y);
)

(
z = Synth(\turntable, [\buff, ~yaeji.bufnum]);
~turntable_layout.value(z);
)






