package;

import ceramic.Color;
import ceramic.Entity;
import ceramic.InitSettings;

class Project extends Entity {
	function new(settings:InitSettings) {
		super();

		settings.antialiasing = 2;
		settings.background = new Color(0xe2e8f0);
		settings.targetWidth = 480;
		settings.targetHeight = 480;
		settings.scaling = FIT;
		settings.resizable = true;

		app.onceReady(this, ready);
	}

	function ready() {
		// Set MainScene as the current scene (see MainScene.hx)
		app.scenes.main = new MainScene();
	}
}
