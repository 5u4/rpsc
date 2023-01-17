package;

import VectorMath.vec2;
import arcade.Group;
import ceramic.Assets;
import ceramic.GeometryUtils;
import ceramic.Quad;
import ceramic.Scene;
import ceramic.Timer;

class MainScene extends Scene {
	static final INITIAL_PLAYER_COUNT = 10;
	static final INITIAL_POS_RANDOM_OFFSET = 40;

	override function preload() {
		assets.add(Images.PAPER);
		assets.add(Images.ROCK);
		assets.add(Images.SCISSORS);
	}

	override function create() {
		var playerBodies = new Group();
		app.arcade.groups.set('players', playerBodies);
		var players = new ceramic.Group<Player>();

		var initPlayerConfigs = [
			{playerType: PlayerType.Paper, x: width / 2, y: height / 2 - 120},
			{playerType: PlayerType.Rock, x: width / 2 - 120, y: height / 2},
			{playerType: PlayerType.Scissors, x: width / 2 + 120, y: height / 2},
		];

		for (config in initPlayerConfigs) {
			for (_ in 0...INITIAL_PLAYER_COUNT) {
				var player = new Player(config.playerType, assets, players);
				player.pos(config.x + Random.float(-INITIAL_POS_RANDOM_OFFSET, INITIAL_POS_RANDOM_OFFSET),
					config.y + Random.float(-INITIAL_POS_RANDOM_OFFSET, INITIAL_POS_RANDOM_OFFSET));
				playerBodies.add(player.body);
				players.add(player);
				add(player);
			}
		}

		app.arcade.onUpdate(this, updatePhysics);
	}

	function updatePhysics(delta:Float) {
		var world = app.arcade.world;
		var players = app.arcade.groups.get('players');

		world.collideGroupVsGroup(players, players);
	}
}

enum PlayerType {
	Paper;
	Rock;
	Scissors;
}

class Player extends Quad {
	var assets:Assets;
	var players:ceramic.Group<Player>;
	var playerType:PlayerType;
	var freezedSteps:Int = 0;

	static final MOVE_SPEED = 30;
	static final CHASE_WHEN_TARGET_LESS_THAN = 5;

	public function new(playerType:PlayerType, assets:Assets, players:ceramic.Group<Player>) {
		super();
		this.assets = assets;
		this.players = players;
		updatePlayerType(playerType);

		anchor(0.5, 0.5);
		size(14, 14);

		onCollide(this, (self, overlapper) -> {
			var self = cast(self, Player);
			var other = cast(overlapper, Player);
			var shouldTransformOverlapper = false;

			switch (self.playerType) {
				case PlayerType.Paper:
					shouldTransformOverlapper = other.playerType == PlayerType.Rock;
				case PlayerType.Rock:
					shouldTransformOverlapper = other.playerType == PlayerType.Scissors;
				case PlayerType.Scissors:
					shouldTransformOverlapper = other.playerType == PlayerType.Paper;
			}

			if (!shouldTransformOverlapper || freezedSteps > 0 || other.freezedSteps > 0)
				return;

			freezedSteps = 3;
			other.freezedSteps = 3;
			other.updatePlayerType(self.playerType);
		});

		Timer.interval(this, 0.1, onUpdate);
	}

	function walkRandomly() {
		var v = vec2(Random.float(-1, 1), Random.float(-1, 1)).normalize() * MOVE_SPEED;
		velocityX = v.x;
		velocityY = v.y;
	}

	function chaseNearestTarget(targets:Array<Player>) {
		var nearest = targets[0];
		var nearestDist = GeometryUtils.distance(x, y, nearest.x, nearest.y);

		for (p in targets) {
			var dist = GeometryUtils.distance(x, y, p.x, p.y);
			if (dist < nearestDist) {
				nearest = p;
				nearestDist = dist;
			}
		}

		chaseTarget(nearest);
	}

	function chaseTarget(target:Player) {
		var v = vec2(target.x - x, target.y - y).normalize() * MOVE_SPEED;
		velocityX = v.x;
		velocityY = v.y;
	}

	function walkAwayFromTarget(target:Player) {
		var v = vec2(x - target.x, x - target.y).normalize() * MOVE_SPEED / 4 * 3;
		velocityX = v.x;
		velocityY = v.y;
	}

	function onUpdate() {
		if (freezedSteps > 0) {
			freezedSteps -= 1;
			velocity(0, 0);
			return;
		}

		var targets:Null<Array<Player>> = null;
		var predators:Null<Array<Player>> = null;

		switch (playerType) {
			case PlayerType.Paper:
				targets = players.items.filter(p -> p.playerType == PlayerType.Rock);
				predators = players.items.filter(p -> p.playerType == PlayerType.Scissors);
			case PlayerType.Rock:
				targets = players.items.filter(p -> p.playerType == PlayerType.Scissors);
				predators = players.items.filter(p -> p.playerType == PlayerType.Paper);
			case PlayerType.Scissors:
				targets = players.items.filter(p -> p.playerType == PlayerType.Paper);
				predators = players.items.filter(p -> p.playerType == PlayerType.Rock);
		}

		if (targets.length == 0) {
			walkRandomly();
			return;
		}

		if (targets.length < CHASE_WHEN_TARGET_LESS_THAN) {
			chaseNearestTarget(targets);
			return;
		}

		var shouldChase = Random.float(0, 1) < 0.5;
		if (shouldChase) {
			var target = targets[Random.int(0, targets.length - 1)];
			chaseTarget(target);
			return;
		}

		var escape = Random.float(0, 1) < 0.3;
		if (predators.length > 0 && escape) {
			var predator = predators[Random.int(0, predators.length - 1)];
			walkAwayFromTarget(predator);
			return;
		}

		walkRandomly();
	}

	function updatePlayerType(playerType:PlayerType) {
		this.playerType = playerType;
		switch (playerType) {
			case PlayerType.Paper:
				this.texture = assets.texture(Images.PAPER);
			case PlayerType.Rock:
				this.texture = assets.texture(Images.ROCK);
			case PlayerType.Scissors:
				this.texture = assets.texture(Images.SCISSORS);
		}
	}
}
