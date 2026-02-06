import Phaser from 'phaser';
import { gameConfig } from '../gameConfig';
import { GameState } from '../core/GameState';
import { Button } from '../ui/Button';
import { textStyles } from '../ui/TextStyles';
import { LeaderboardService } from '../services/LeaderboardService';

export class GameOverScene extends Phaser.Scene {
  private gameState!: GameState;
  private leaderboardService!: LeaderboardService;

  constructor() {
    super('GameOverScene');
  }

  async create(): Promise<void> {
    this.gameState = GameState.getInstance();
    this.leaderboardService = new LeaderboardService();

    // Fade in
    this.cameras.main.fadeIn(300, 0, 0, 0);

    // Create UI
    this.createBackground();
    this.createScoreDisplay();
    this.createButtons();

    // Submit score
    await this.submitScore();
  }

  private createBackground(): void {
    // Dark overlay
    this.add.rectangle(
      this.cameras.main.centerX,
      this.cameras.main.centerY,
      this.cameras.main.width,
      this.cameras.main.height,
      0x000000,
      0.9
    );

    // Particle burst
    const particles = this.add.particles(
      this.cameras.main.centerX,
      this.cameras.main.centerY - 200,
      'particle',
      {
        speed: { min: 100, max: 300 },
        angle: { min: 0, max: 360 },
        scale: { start: 1, end: 0 },
        lifespan: 2000,
        tint: [gameConfig.colors.primary, gameConfig.colors.secondary, gameConfig.colors.accent],
        quantity: 50
      }
    );

    this.time.delayedCall(100, () => {
      particles.stop();
    });
  }

  private createScoreDisplay(): void {
    const centerX = this.cameras.main.centerX;
    const stats = this.gameState.getLastGameStats();
    const bestScore = this.gameState.getBestScore();
    const isNewBest = stats.score > bestScore;

    // Game Over title
    const title = this.add.text(
      centerX,
      200,
      'GAME OVER',
      textStyles.title
    );
    title.setOrigin(0.5);
    title.setFontSize(48);

    // Score
    const scoreLabel = this.add.text(
      centerX,
      320,
      'SCORE',
      textStyles.normal
    );
    scoreLabel.setOrigin(0.5);
    scoreLabel.setFontSize(24);

    const scoreValue = this.add.text(
      centerX,
      380,
      stats.score.toLocaleString(),
      textStyles.score
    );
    scoreValue.setOrigin(0.5);
    scoreValue.setFontSize(64);

    // New best indicator
    if (isNewBest) {
      const newBestText = this.add.text(
        centerX,
        460,
        '🏆 NEW BEST! 🏆',
        textStyles.accent
      );
      newBestText.setOrigin(0.5);
      newBestText.setFontSize(28);

      this.tweens.add({
        targets: newBestText,
        scale: 1.1,
        duration: 500,
        yoyo: true,
        repeat: -1
      });

      this.gameState.setBestScore(stats.score);
    } else {
      const bestText = this.add.text(
        centerX,
        460,
        `Best: ${bestScore.toLocaleString()}`,
        textStyles.normal
      );
      bestText.setOrigin(0.5);
      bestText.setFontSize(24);
    }

    // Stats
    const statsY = 560;
    const statsSpacing = 50;

    this.createStatLine(centerX - 150, statsY, 'Time', this.formatTime(stats.duration));
    this.createStatLine(centerX + 150, statsY, 'Distance', `${Math.floor(stats.distance)}m`);
    this.createStatLine(centerX - 150, statsY + statsSpacing, 'Perfect Beats', stats.perfectBeats.toString());
    this.createStatLine(centerX + 150, statsY + statsSpacing, 'Max Speed', stats.maxSpeed.toFixed(1));
  }

  private createStatLine(x: number, y: number, label: string, value: string): void {
    const labelText = this.add.text(x, y, label, {
      fontSize: '18px',
      color: '#888888'
    });
    labelText.setOrigin(0.5);

    const valueText = this.add.text(x, y + 30, value, {
      fontSize: '24px',
      color: '#ffffff',
      fontStyle: 'bold'
    });
    valueText.setOrigin(0.5);
  }

  private createButtons(): void {
    const centerX = this.cameras.main.centerX;

    // Play Again
    const playAgainBtn = new Button(
      this,
      centerX,
      800,
      'PLAY AGAIN',
      () => {
        this.scene.start('GameScene');
        this.scene.launch('UIScene');
      }
    );
    this.add.existing(playAgainBtn);

    // Share
    const shareBtn = new Button(
      this,
      centerX,
      920,
      'SHARE SCORE',
      () => {
        this.shareScore();
      }
    );
    this.add.existing(shareBtn);

    // Menu
    const menuBtn = new Button(
      this,
      centerX,
      1040,
      'MENU',
      () => {
        this.scene.start('MenuScene');
      }
    );
    this.add.existing(menuBtn);
  }

  private async submitScore(): Promise<void> {
    try {
      const stats = this.gameState.getLastGameStats();
      const mode = this.gameState.getGameMode();
      const seed = this.gameState.getCurrentSeed();

      await this.leaderboardService.submitScore({
        score: stats.score,
        duration_ms: stats.duration,
        perfect_beats: stats.perfectBeats,
        max_speed: stats.maxSpeed,
        seed: seed,
        mode: mode
      });

      // Show top scores
      this.showTopScores();
    } catch (error) {
      console.error('Failed to submit score:', error);
    }
  }

  private async showTopScores(): Promise<void> {
    try {
      const scores = await this.leaderboardService.getTopScores(5);
      
      const centerX = this.cameras.main.centerX;
      const startY = 700;

      const title = this.add.text(
        centerX - 250,
        startY - 50,
        'Top Players',
        textStyles.normal
      );
      title.setFontSize(20);

      scores.forEach((score, index) => {
        const y = startY + index * 30;
        
        const rankText = this.add.text(
          centerX - 250,
          y,
          `${index + 1}. ${score.display_name || 'Anonymous'}`,
          {
            fontSize: '16px',
            color: index === 0 ? '#ffff00' : '#ffffff'
          }
        );

        const scoreText = this.add.text(
          centerX + 200,
          y,
          score.score.toLocaleString(),
          {
            fontSize: '16px',
            color: index === 0 ? '#ffff00' : '#ffffff'
          }
        );
        scoreText.setOrigin(1, 0);
      });
    } catch (error) {
      // Silent fail - not critical
    }
  }

  private shareScore(): void {
    const stats = this.gameState.getLastGameStats();
    const text = `I scored ${stats.score.toLocaleString()} points in Neon Beat Dash! 🎮✨`;
    const url = window.location.href;

    if (navigator.share) {
      navigator.share({
        title: 'Neon Beat Dash',
        text: text,
        url: url
      }).catch(() => {
        this.copyToClipboard(text + '\n' + url);
      });
    } else {
      this.copyToClipboard(text + '\n' + url);
    }
  }

  private copyToClipboard(text: string): void {
    navigator.clipboard.writeText(text).then(() => {
      const toast = this.add.text(
        this.cameras.main.centerX,
        this.cameras.main.centerY,
        'Copied to clipboard!',
        textStyles.normal
      );
      toast.setOrigin(0.5);
      toast.setBackgroundColor('#000000');
      toast.setPadding(20);

      this.tweens.add({
        targets: toast,
        alpha: 0,
        duration: 2000,
        delay: 1000,
        onComplete: () => toast.destroy()
      });
    });
  }

  private formatTime(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  }
}