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

	//

	//


	sig = PlayBuf.ar(
		numChannels: 2,
		bufnum: buff,
		rate: BufRateScale.ir(buff) * \rate.kr(1.0),
		doneAction: 2
	);
	Out.ar(0, sig);
}).add;
)

x = Synth(\turntable, [\buff, ~dauwd.bufnum]);
Synth(\turntable, [\buff, ~isola.bufnum]);
Synth(\turntable, [\buff, ~yaeji.bufnum]);

120 * 1.08;
120 * 0.92;





// Finalized interface below.
(
~turntable_layout = {
var mainLayout;
var cueButtons;
var playBack;

var tempoDisplay;

var slider;

w =  Window.new("Turntable", Rect(Window.screenBounds.width / 4, Window.screenBounds.height / 4, 480.0, 240.0),
	resizable: true
)
.alwaysOnTop_(true)
.front;

tempoDisplay = UserView();
tempoDisplay.background = \gray;

slider = UserView();
slider.layout_(VLayout( Slider() ));

cueButtons = HLayout(Button(), Button(), Button(), Button());

playBack = GridLayout.rows(
	[[tempoDisplay, columns: 3], Button()],
	[[Slider().orientation_(\horizontal), columns: 3], Knob()],
	[Button(), Knob(), Button(), Button()]
);

mainLayout = VLayout(cueButtons, playBack);
w.layout_(mainLayout);
}
);

~turntable_layout.value;









