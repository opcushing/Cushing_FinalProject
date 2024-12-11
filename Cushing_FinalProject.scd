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
	var nudge_fwd, nudge_back;
	var snap = \snap.kr(1.0);
	var nudgeAmount = \nudgeAmount.kr(0.04);

	var rate;

	// PLaybackRate calculations
	rate = BufRateScale.ir(buff);

	pitch = Lag2.kr(pitch, snap);

	rate = rate * (play + pitch);

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

x.set(\pitch, 0.0);
x.set(\snap, 1.0);
x.set(\pitch, 0.0);

x.set(\reverse, 0.0);
x.set(\reverse, 1.0);



// Finalized interface below.
(
var mainLayout;
var cueButtons;
var playBack;
var tempoDisplay;
var pitchSlider = Slider().orientation_(\horizontal);

var cueButton1 = Button().string_("Cue 1");
var cueButton2 = Button().string_("Cue 2");
var cueButton3 = Button().string_("Cue 3");
var cueButton4 = Button().string_("Cue 4");

w = Window.new("Turntable", Rect(Window.screenBounds.width / 4, Window.screenBounds.height / 4, 480.0, 240.0),
	resizable: true
)
.alwaysOnTop_(true)
.front;

cueButtons = HLayout(cueButton1, cueButton2, cueButton3, cueButton4);

tempoDisplay = View();
tempoDisplay.background = \gray;

pitchSlider.value_(0.5);

playBack = GridLayout.rows(
	[[tempoDisplay, columns: 3], Button()],
	[[pitchSlider, columns: 3], Knob()],
	[Button(), Knob(), Button(), Button()]
);




// ===== Define the Button + Slider Actions =======

pitchSlider.action();

// Finish the layout

mainLayout = VLayout(cueButtons, playBack);
w.layout_(mainLayout);
);









