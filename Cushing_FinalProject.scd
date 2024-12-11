s.boot;

/*
How are we gonna do this.

We wanna make a "Turntable ".

Use certain level meters to gauge the sync of the mix?

User loads a track and pre-sets the estimated tempo of the track.

There's pitch control, slider control, and somethin else?

*/
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
	var sig, buff = \buff.ir(0);

	var play = \play.kr(0.0);
	var pitch = \pitch.kr(0.0);

	var reverse = \reverse.kr(0.0);
	var nudge_fwd = \nudge_fwd.kr(0.0);
	var nudge_back = \nudge_back.kr(0.0);
	var snap = \snap.kr(1.0);
	var nudgeAmount = \nudgeAmount.kr(0.01);

	var rate;

	// PLaybackRate calculations
	rate = BufRateScale.ir(buff);

	pitch = Lag2.kr(pitch, snap);

	rate = rate * (1.0 + pitch) * play;

	rate = rate * (1.0 + ((nudge_fwd - nudge_back) * nudgeAmount));

	reverse = Lag2.kr(reverse, 1.0);

	rate = rate * (1.0 - (2.0 * reverse)); // reversing should take longer
	// rate = Lag2.kr(rate, snap);

	// Tempo / beat tracking?
	sig = PlayBuf.ar(
		numChannels: 2,
		bufnum: buff,
		rate: rate,
		doneAction: 2
	);

	Out.ar(0, sig);
}).add;
)

x = Synth(\turntable, [\buff, ~dauwd.bufnum]);
y = Synth(\turntable, [\buff, ~isola.bufnum]);
Synth(\turntable, [\buff, ~yaeji.bufnum]);


x.set(\play, 1.0);

x.set(\pitch, 0.02);
x.set(\snap, 1.0);
x.set(\pitch, 0.0);

x.set(\reverse, 0.0);
x.set(\reverse, 1.0);



// Finalized interface below.
(
~turntable_layout = {
	arg turntable_synth;

	var mainLayout;
	// var cueButtons;
	var playBack;
	var tempoDisplay;

	var playPause = Button();
	var nudgeForward = Button().string_("nudge ⏩");
	var nudgeBackward = Button().string_("⏪ nudge");

	var pitchSlider = Slider().orientation_(\horizontal);

	var pitchBendSpec;

/*	var cueButton1 = Button().string_("Cue 1");
	var cueButton2 = Button().string_("Cue 2");
	var cueButton3 = Button().string_("Cue 3");
	var cueButton4 = Button().string_("Cue 4");*/


	// Define properties of the buttons
	playPause.states = [["Play ▶️", Color.new(0.25, 0.75, 0.33), Color.white], ["Pause ⏸️", Color.white, Color.grey]];

	// Define properties of the layouts

	w = Window.new("Turntable", Rect(Window.screenBounds.width / 4, Window.screenBounds.height / 4, 400.0, 160.0),
		resizable: true
	)
	.alwaysOnTop_(true)
	.front;

	// cueButtons = HLayout(cueButton1, cueButton2, cueButton3, cueButton4);

	tempoDisplay = View();
	tempoDisplay.background = \gray;

	playBack = GridLayout.rows(
		[[tempoDisplay, columns: 3], Button()],
		[[pitchSlider, columns: 3], Knob()],
		[nudgeBackward, Knob(), nudgeForward, playPause]
	);

	// ===== Define the Button + Slider Actions =======

	pitchSlider.value_(0.5);
	pitchBendSpec = ControlSpec.new(-0.08, 0.08);
	pitchSlider.action_({
		|v|
		pitchBendSpec.map(v.value).postln;
		turntable_synth.set(\pitch, pitchBendSpec.map(v.value));
	});

	playPause.action_({
		|v|
		v.value.postln;
		turntable_synth.set(\play, v.value);
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








