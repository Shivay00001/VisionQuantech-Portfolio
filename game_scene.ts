import Phaser from 'phaser';
import { gameConfig } from '../gameConfig';
import { GameState } from '../core/GameState';
import { InputManager } from '../core/InputManager';
import { DifficultyManager } from '../core/DifficultyManager';
import { AudioManager } from '../core/AudioManager';
import { DailyChallenge } from '../core/DailyChallenge';

export class GameScene extends Phaser.Scene {
  private gameState!: GameState;
  private inputManager!: InputManager;
  private difficultyManager!: DifficultyManager;
  private audioManager!: AudioManager;
  private dailyChallenge!: DailyChallenge;

  private player!: Phaser.GameObjects.Image;
  private currentLane: number = 1;
  private targetLane: number = 1;
  
  private obstacles!: Phaser.Physics.Arcade.Group;
  private beatRings!: Phaser.Physics.Arcade.Group;
  
  private gameTime: number = 0;
  private distance: number = 0;
  private score: number = 0;
  private combo: number = 0;
  private perfectBeats: number = 0;
  
  private obstacleSpawnTimer: number = 0;
  private beatSpawnTimer: number = 0;
  
  private isPaused: boolean = false;
  private isGameOver: boolean = false;
  
  private currentSpeed: number = gameConfig.obstacle.baseSpeed;
  private rng!: Phaser.Math.RandomDataGenerator;

  constructor() {
    super('GameScene');
  }

  create(): void {
    this.gameState = GameState.getInstance();
    this.inputManager = new InputManager(this);
    this.difficultyManager = new DifficultyManager();
    this.audioManager = AudioManager.getInstance(this);
    this.dailyChallenge = new DailyChallenge();

    // Initialize RNG with seed
    this.initializeRNG();

    // Setup game
    this.createBackground();
    this.createPlayer();
    this.createGroups();
    this.setupInput();
    this.setupCollisions();

    // Reset stats
    this.resetStats();

    // Fade in
    this.cameras.main.fadeIn(300, 0, 0, 0);

    // Start game loop
    this.audioManager.playBGM();
  }

  private async initializeRNG(): Promise<void> {
    let seed: string;
    
    if (this.gameState.getGameMode() === 'daily') {
      seed = await this.dailyChallenge.getDailySeed();
    } else {
      seed = Date.now().toString();
    }
    
    this.gameState.setCurrentSeed(seed);
    this.rng = new Phaser.Math.RandomDataGenerator([seed]);
  }

  private createBackground(): void {
    // Moving grid lines for speed effect
    const graphics = this.add.graphics();
    graphics.lineStyle(2, gameConfig.colors.primary, 0.3);

    for (let i = 0; i < 20; i++) {
      const y = i * 80;
      graphics.lineBetween(0, y, this.cameras.main.width, y);
    }

    this.tweens.add({
      targets: graphics,
      y: 80,
      duration: 1000,
      repeat: -1,
      ease: 'Linear'
    });

    // Lane markers
    gameConfig.lanes.positions.forEach(x => {
      const line = this.add.graphics();
      line.lineStyle(1, 0xffffff, 0.1);
      line.lineBetween(x, 0, x, this.cameras.main.height);
    });
  }

  private createPlayer(): void {
    this.player = this.add.image(
      gameConfig.lanes.positions[1],
      gameConfig.player.startY,
      'player'
    );
    this.player.setScale(1);

    // Glow effect
    this.tweens.add({
      targets: this.player,
      scale: 1.1,
      duration: 500,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut'
    });

    // Trail effect
    const particles = this.add.particles(this.player.x, this.player.y, 'particle', {
      follow: this.player,
      lifespan: 500,
      scale: { start: 0.6, end: 0 },
      alpha: { start: 0.8, end: 0 },
      tint: gameConfig.colors.primary,
      frequency: 30
    });
  }

  private createGroups(): void {
    this.obstacles = this.physics.add.group();
    this.beatRings = this.physics.add.group();
  }

  private setupInput(): void {
    // Swipe and tap controls
    this.inputManager.onSwipeLeft(() => this.moveLane(-1));
    this.inputManager.onSwipeRight(() => this.moveLane(1));
    this.inputManager.onTapLeft(() => this.moveLane(-1));
    this.inputManager.onTapRight(() => this.moveLane(1));

    // Keyboard controls
    this.input.keyboard?.on('keydown-LEFT', () => this.moveLane(-1));
    this.input.keyboard?.on('keydown-RIGHT', () => this.moveLane(1));
    this.input.keyboard?.on('keydown-A', () => this.moveLane(-1));
    this.input.keyboard?.on('keydown-D', () => this.moveLane(1));
    this.input.keyboard?.on('keydown-ESC', () => this.pauseGame());
    this.input.keyboard?.on('keydown-P', () => this.pauseGame());
  }

  private setupCollisions(): void {
    this.physics.add.overlap(
      this.player,
      this.obstacles,
      this.handleObstacleCollision,
      undefined,
      this
    );

    this.physics.add.overlap(
      this.player,
      this.beatRings,
      this.handleBeatRingCollision,
      undefined,
      this
    );
  }

  private moveLane(direction: number): void {
    if (this.isPaused || this.isGameOver) return;

    this.targetLane = Phaser.Math.Clamp(
      this.targetLane + direction,
      0,
      gameConfig.lanes.count - 1
    );

    if (this.targetLane !== this.currentLane) {
      this.audioManager.playSFX('move');
    }
  }

  update(time: number, delta: number): void {
    if (this.isPaused || this.isGameOver) return;

    // Update game time
    this.gameTime += delta;

    // Update difficulty
    this.difficultyManager.update(this.gameTime);
    this.currentSpeed = this.difficultyManager.getCurrentSpeed();

    // Update player position (smooth lane switching)
    if (this.currentLane !== this.targetLane) {
      const targetX = gameConfig.lanes.positions[this.targetLane];
      const diff = targetX - this.player.x;
      
      if (Math.abs(diff) < 5) {
        this.player.x = targetX;
        this.currentLane = this.targetLane;
      } else {
        this.player.x += diff * 0.2;
      }
    }

    // Spawn obstacles
    this.obstacleSpawnTimer += delta;
    if (this.obstacleSpawnTimer >= this.difficultyManager.getSpawnInterval()) {
      this.spawnObstacle();
      this.obstacleSpawnTimer = 0;
    }

    // Spawn beat rings
    this.beatSpawnTimer += delta;
    if (this.beatSpawnTimer >= gameConfig.beatRing.spawnInterval) {
      this.spawnBeatRing();
      this.beatSpawnTimer = 0;
    }

    // Move and cleanup obstacles
    this.obstacles.children.entries.forEach((obstacle: Phaser.GameObjects.GameObject) => {
      const sprite = obstacle as Phaser.Physics.Arcade.Image;
      sprite.y += this.currentSpeed;

      if (sprite.y > this.cameras.main.height + 100) {
        sprite.destroy();
        this.distance += 1;
      }
    });

    // Move and cleanup beat rings
    this.beatRings.children.entries.forEach((ring: Phaser.GameObjects.GameObject) => {
      const sprite = ring as Phaser.Physics.Arcade.Image;
      sprite.y += this.currentSpeed;

      if (sprite.y > this.cameras.main.height + 100) {
        sprite.destroy();
        this.combo = 0; // Miss resets combo
      }
    });

    // Update score
    this.score += Math.floor(gameConfig.scoring.basePerSecond * (delta / 1000));
    this.score += Math.floor(this.distance * gameConfig.scoring.distanceMultiplier);

    // Send updates to UI
    this.events.emit('scoreUpdate', this.score);
    this.events.emit('comboUpdate', this.combo);
  }

  private spawnObstacle(): void {
    const lane = this.rng.between(0, gameConfig.lanes.count - 1);
    const x = gameConfig.lanes.positions[lane];
    const colorIndex = this.rng.between(0, gameConfig.obstacle.colors.length - 1);

    const obstacle = this.physics.add.image(x, -50, `obstacle${colorIndex}`);
    obstacle.setData('lane', lane);
    this.obstacles.add(obstacle);
  }

  private spawnBeatRing(): void {
    const lane = this.rng.between(0, gameConfig.lanes.count - 1);
    const x = gameConfig.lanes.positions[lane];

    const ring = this.physics.add.image(x, -100, 'beatRing');
    ring.setData('lane', lane);
    ring.setData('spawnTime', this.gameTime);
    this.beatRings.add(ring);

    // Pulse animation
    this.tweens.add({
      targets: ring,
      scale: 1.2,
      alpha: 0.6,
      duration: 300,
      yoyo: true,
      repeat: -1
    });
  }

  private handleObstacleCollision(
    player: Phaser.GameObjects.GameObject,
    obstacle: Phaser.GameObjects.GameObject
  ): void {
    if (this.isGameOver) return;

    // Check if player is in same lane
    const obstacleLane = (obstacle as Phaser.Physics.Arcade.Image).getData('lane');
    if (this.currentLane === obstacleLane) {
      this.gameOver();
    }
  }

  private handleBeatRingCollision(
    player: Phaser.GameObjects.GameObject,
    ring: Phaser.GameObjects.GameObject
  ): void {
    const ringSprite = ring as Phaser.Physics.Arcade.Image;
    const ringLane = ringSprite.getData('lane');
    
    if (this.currentLane !== ringLane) return;

    const spawnTime = ringSprite.getData('spawnTime');
    const timing = Math.abs(this.gameTime - spawnTime - 1000); // Target is 1 second travel

    let beatScore = 0;
    let beatType = '';

    if (timing < gameConfig.beatRing.perfectWindow) {
      beatScore = gameConfig.scoring.perfectBeat;
      beatType = 'PERFECT!';
      this.combo = Math.min(this.combo + 1, gameConfig.scoring.maxCombo);
      this.perfectBeats++;
      this.audioManager.playSFX('perfect');
    } else if (timing < gameConfig.beatRing.goodWindow) {
      beatScore = gameConfig.scoring.goodBeat;
      beatType = 'GOOD!';
      this.combo = Math.min(this.combo + 1, gameConfig.scoring.maxCombo);
      this.audioManager.playSFX('good');
    } else {
      this.combo = 0;
    }

    if (beatScore > 0) {
      const multiplier = gameConfig.scoring.comboMultipliers[Math.min(this.combo - 1, 4)];
      this.score += Math.floor(beatScore * multiplier);

      // Show feedback
      this.showBeatFeedback(ringSprite.x, ringSprite.y, beatType, multiplier);
    }

    ringSprite.destroy();
  }

  private showBeatFeedback(x: number, y: number, text: string, multiplier: number): void {
    const feedback = this.add.text(x, y, `${text}\nx${multiplier.toFixed(1)}`, {
      fontSize: '32px',
      color: '#ffff00',
      fontStyle: 'bold',
      align: 'center'
    });
    feedback.setOrigin(0.5);

    this.tweens.add({
      targets: feedback,
      y: y - 100,
      alpha: 0,
      duration: 1000,
      ease: 'Power2',
      onComplete: () => feedback.destroy()
    });
  }

  private pauseGame(): void {
    if (this.isGameOver) return;

    this.isPaused = !this.isPaused;
    
    if (this.isPaused) {
      this.physics.pause();
      this.audioManager.pause();
      this.events.emit('gamePaused');
    } else {
      this.physics.resume();
      this.audioManager.resume();
      this.events.emit('gameResumed');
    }
  }

  private gameOver(): void {
    if (this.isGameOver) return;
    
    this.isGameOver = true;
    this.physics.pause();
    this.audioManager.stop();
    this.audioManager.playSFX('collision');

    // Save stats
    this.gameState.setLastScore(this.score);
    this.gameState.setLastGameStats({
      score: this.score,
      duration: this.gameTime,
      distance: this.distance,
      perfectBeats: this.perfectBeats,
      maxSpeed: this.currentSpeed
    });

    // Flash effect
    this.cameras.main.flash(300, 255, 0, 0);

    // Transition to game over
    this.time.delayedCall(1000, () => {
      this.scene.stop('UIScene');
      this.scene.start('GameOverScene');
    });
  }

  private resetStats(): void {
    this.gameTime = 0;
    this.distance = 0;
    this.score = 0;
    this.combo = 0;
    this.perfectBeats = 0;
    this.obstacleSpawnTimer = 0;
    this.beatSpawnTimer = 0;
    this.isPaused = false;
    this.isGameOver = false;
    this.currentLane = 1;
    this.targetLane = 1;
  }
}