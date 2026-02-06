import Phaser from 'phaser';
import { gameConfig } from '../gameConfig';
import { GameState } from '../core/GameState';
import { Button } from '../ui/Button';
import { textStyles } from '../ui/TextStyles';
import { UserService } from '../services/UserService';
import { LeaderboardService } from '../services/LeaderboardService';

export class MenuScene extends Phaser.Scene {
  private gameState!: GameState;
  private userService!: UserService;
  private leaderboardService!: LeaderboardService;
  private particles!: Phaser.GameObjects.Particles.ParticleEmitter;

  constructor() {
    super('MenuScene');
  }

  create(): void {
    this.gameState = GameState.getInstance();
    this.userService = new UserService();
    this.leaderboardService = new LeaderboardService();

    // Initialize user
    this.initializeUser();

    // Create background effects
    this.createBackground();

    // Create UI
    this.createTitle();
    this.createButtons();
    this.createStats();
  }

  private async initializeUser(): Promise<void> {
    try {
      await this.userService.initializeUser();
    } catch (error) {
      console.error('Failed to initialize user:', error);
    }
  }

  private createBackground(): void {
    // Animated grid lines
    const graphics = this.add.graphics();
    graphics.lineStyle(1, gameConfig.colors.primary, 0.2);

    for (let i = 0; i < 10; i++) {
      const y = i * 140;
      graphics.lineBetween(0, y, this.cameras.main.width, y);
    }

    this.tweens.add({
      targets: graphics,
      y: 140,
      duration: 2000,
      repeat: -1,
      ease: 'Linear'
    });

    // Particle effects
    const particles = this.add.particles(0, 0, 'particle', {
      x: { min: 0, max: this.cameras.main.width },
      y: -10,
      lifespan: 4000,
      speedY: { min: 50, max: 150 },
      scale: { start: 0.5, end: 0 },
      alpha: { start: 0.6, end: 0 },
      tint: [gameConfig.colors.primary, gameConfig.colors.secondary, gameConfig.colors.accent],
      frequency: 200
    });
  }

  private createTitle(): void {
    const centerX = this.cameras.main.centerX;
    
    // Title
    const title = this.add.text(centerX, 200, 'NEON BEAT', textStyles.title);
    title.setOrigin(0.5);

    const subtitle = this.add.text(centerX, 280, 'DASH', textStyles.title);
    subtitle.setOrigin(0.5);

    // Glow effect
    title.setStroke('#00ffff', 8);
    subtitle.setStroke('#ff00ff', 8);
    title.setShadow(0, 0, '#00ffff', 20, true, true);
    subtitle.setShadow(0, 0, '#ff00ff', 20, true, true);

    // Pulse animation
    this.tweens.add({
      targets: [title, subtitle],
      scale: 1.05,
      duration: 1000,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut'
    });
  }

  private createButtons(): void {
    const centerX = this.cameras.main.centerX;
    const startY = 450;
    const spacing = 120;

    // Play button
    const playBtn = new Button(this, centerX, startY, 'PLAY', () => {
      this.startGame('normal');
    });
    this.add.existing(playBtn);

    // Daily challenge button
    const dailyBtn = new Button(this, centerX, startY + spacing, 'DAILY CHALLENGE', () => {
      this.startGame('daily');
    });
    this.add.existing(dailyBtn);

    // Leaderboard button
    const leaderboardBtn = new Button(this, centerX, startY + spacing * 2, 'LEADERBOARD', () => {
      this.showLeaderboard();
    });
    this.add.existing(leaderboardBtn);

    // Settings button
    const settingsBtn = new Button(this, centerX, startY + spacing * 3, 'SETTINGS', () => {
      this.showSettings();
    });
    this.add.existing(settingsBtn);
  }

  private createStats(): void {
    const centerX = this.cameras.main.centerX;
    
    // Best score
    const bestScore = this.gameState.getBestScore();
    const scoreText = this.add.text(
      centerX,
      1100,
      `Best Score: ${bestScore.toLocaleString()}`,
      textStyles.score
    );
    scoreText.setOrigin(0.5);
  }

  private startGame(mode: 'normal' | 'daily'): void {
    // Fade out
    this.cameras.main.fadeOut(300, 0, 0, 0);
    
    this.cameras.main.once('camerafadeoutcomplete', () => {
      this.gameState.setGameMode(mode);
      this.scene.start('GameScene');
      this.scene.launch('UIScene');
    });
  }

  private async showLeaderboard(): Promise<void> {
    try {
      const scores = await this.leaderboardService.getTopScores(10);
      
      // Create overlay
      const overlay = this.add.rectangle(
        this.cameras.main.centerX,
        this.cameras.main.centerY,
        this.cameras.main.width,
        this.cameras.main.height,
        0x000000,
        0.9
      );
      overlay.setInteractive();

      // Title
      const title = this.add.text(
        this.cameras.main.centerX,
        150,
        'LEADERBOARD',
        textStyles.title
      );
      title.setOrigin(0.5);
      title.setFontSize(36);

      // Scores list
      let yPos = 250;
      scores.forEach((score, index) => {
        const rankText = this.add.text(
          150,
          yPos,
          `${index + 1}. ${score.display_name || 'Anonymous'}`,
          textStyles.normal
        );
        
        const scoreText = this.add.text(
          this.cameras.main.width - 150,
          yPos,
          score.score.toLocaleString(),
          textStyles.score
        );
        scoreText.setOrigin(1, 0);

        yPos += 60;
      });

      // Close button
      const closeBtn = new Button(
        this,
        this.cameras.main.centerX,
        1100,
        'CLOSE',
        () => {
          overlay.destroy();
          title.destroy();
          closeBtn.destroy();
          this.children.list
            .filter(child => child.type === 'Text' && child.y > 200 && child.y < 900)
            .forEach(child => child.destroy());
        }
      );
      this.add.existing(closeBtn);

    } catch (error) {
      console.error('Failed to load leaderboard:', error);
      
      const errorText = this.add.text(
        this.cameras.main.centerX,
        this.cameras.main.centerY,
        'Failed to load leaderboard\nCheck your connection',
        textStyles.normal
      );
      errorText.setOrigin(0.5);
      errorText.setAlign('center');

      this.time.delayedCall(2000, () => {
        errorText.destroy();
      });
    }
  }

  private showSettings(): void {
    // Create overlay
    const overlay = this.add.rectangle(
      this.cameras.main.centerX,
      this.cameras.main.centerY,
      this.cameras.main.width,
      this.cameras.main.height,
      0x000000,
      0.9
    );
    overlay.setInteractive();

    // Title
    const title = this.add.text(
      this.cameras.main.centerX,
      200,
      'SETTINGS',
      textStyles.title
    );
    title.setOrigin(0.5);
    title.setFontSize(36);

    // Audio toggle
    const audioText = this.add.text(
      this.cameras.main.centerX,
      400,
      `Audio: ${this.gameState.isMuted() ? 'OFF' : 'ON'}`,
      textStyles.normal
    );
    audioText.setOrigin(0.5);
    audioText.setInteractive();
    audioText.on('pointerdown', () => {
      this.gameState.toggleMute();
      audioText.setText(`Audio: ${this.gameState.isMuted() ? 'OFF' : 'ON'}`);
    });

    // Close button
    const closeBtn = new Button(
      this,
      this.cameras.main.centerX,
      1000,
      'CLOSE',
      () => {
        overlay.destroy();
        title.destroy();
        audioText.destroy();
        closeBtn.destroy();
      }
    );
    this.add.existing(closeBtn);
  }
}