s.boot;

/*
How are we gonna do this.

We wanna make a "Turntable ".

Use certain level meters to gauge the sync of the mix?

User loads a track and pre-sets the estimated tempo of the track.

There's pitch control, slider control, and somethin else?

*/
(
~dauwd = Buffer.read(s, (PathName("songs/".resolveRelative) +/+ PathName("dauwd2.mp3")).fullPath, bufnum: 0);
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

	var play = \play.kr(0.0);
	var pitch = \pitch.kr(0.0);

	var reverse = \reverse.kr(0.0);
	var nudge_fwd = \nudge_fwd.kr(0.0);
	var nudge_back = \nudge_back.kr(0.0);
	var snap = \snap.kr(1.0);
	var nudgeAmount = \nudgeAmount.kr(0.01);

	var fft;
	var trackb, trackh, trackq, tempo = 0;
	var beep;

	var rate;

	// ====== PlaybackRate Calculations ======
	rate = BufRateScale.ir(buff);

	pitch = Lag2.kr(pitch, snap);

	rate = rate * (1.0 + pitch) * play;

	rate = rate * (1.0 + ((nudge_fwd - nudge_back) * nudgeAmount));

	reverse = Lag2.kr(reverse, 1.0);

	rate = rate * (1.0 - (2.0 * reverse)); // reversing should take longer
	// rate = Lag2.kr(rate, snap);

	sig = PlayBuf.ar(
		numChannels: 2,
		bufnum: buff,
		rate: rate,
		doneAction: 2
	);

	sig_mono = (sig[0] + sig[1]) / 2;

	// Tempo / beat tracking?
	fft = FFT(LocalBuf(1024), sig_mono);
	#trackb, trackh, trackq, tempo = BeatTrack.kr(fft, 0.0);
	tempo = tempo * 60;
	beep = SinOsc.ar(1000, 0.0, Decay.kr(trackb, 0.1)) * play * (60 < tempo.value * tempo.value < 180);
	/*
	(60 < tempo.value * tempo.value < 180).poll;
	(tempo).poll;*/
	// sig = sig + beep;

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
	// var cueButtons;
	var playBack;
	var tempoDisplay;

	var snapKnob = Knob();
	var nudgeAmountKnob = Knob();
	var nudgeAmountText = StaticText();

	var playPause = Button();
	var nudgeForward = Button().string_("nudge ⏩");
	var nudgeBackward = Button().string_("⏪ nudge");

	var pitchSlider = Slider().orientation_(\horizontal), init_slider_val;

	var pitchBendSpec, snapKnobSpec, nudgeAmountSpec;

	// Define properties of the buttons
	playPause.states = [["Play ▶️", Color.new(0.25, 0.75, 0.33), Color.white], ["Pause ⏸️", Color.white, Color.grey]];

	// Define properties of the layouts

	w = Window.new("Turntable", Rect(Window.screenBounds.width / 4, Window.screenBounds.height / 4, 400.0, 160.0),
		resizable: true
	)
	.alwaysOnTop_(true)
	.front;

	nudgeAmountText.font_(Font("Monaco"));

	tempoDisplay = View();
	tempoDisplay.background = \gray;

	nudgeLayout = HLayout(nudgeAmountKnob, VLayout(StaticText().string_("amount: "), nudgeAmountText)).setAlignment(1, \center);

	playBack = GridLayout.rows(
		[[tempoDisplay, columns: 3], Button()],
		[[pitchSlider, columns: 3], snapKnob],
		[nudgeBackward, nudgeLayout, nudgeForward, playPause]
	);

	// ===== Define the Button + Slider Actions =======

	pitchBendSpec = ControlSpec.new(-0.08, 0.08);
	snapKnobSpec = ControlSpec.new(0.1, 5.0, \exp);
	nudgeAmountSpec = ControlSpec.new(0.005, 0.08, \exp);

	pitchSlider.value_(0.5);
	pitchSlider.action_({ arg v; var pitch
		|v|
		pitchBendSpec.map(v.value).postln;
		turntable_synth.set(\pitch, pitchBendSpec.map(v.value));
	});

	// TODO: unmap the value to set initial position.
	turntable_synth.get(\snap, { arg val; {snapKnob.value_(snapKnobSpec.unmap(val))}.defer; });
	snapKnob.action_({
		|v|
		snapKnobSpec.map(v.value).postln;
		turntable_synth.set(\snap, snapKnobSpec.map(v.value));
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

	w.onClose({
		turntable_synth.free;
	});

	// Finish the layout
	mainLayout = VLayout(playBack);
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






