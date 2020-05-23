'use strict';

MediaPlayer = window.MediaPlayer || {
	init: function (player) {
		this.player = player;
		this.ready = true;
	},

	play: function () {
		if (!this.ready) { return; }
		this.player.playVideo();
	},

	pause: function () {
		if (!this.ready) { return; }
		if (this.player.isPaused()) { return; }
		this.player.pauseVideo();
	},
};

Twitch.player.ready(MediaPlayer.init.bind(MediaPlayer));
