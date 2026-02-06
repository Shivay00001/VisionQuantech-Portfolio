import Phaser from 'phaser';
import { textStyles } from '../ui/TextStyles';
import { Button } from '../ui/Button';

export class UIScene extends Phaser.Scene {
  private scoreText!: Phaser.GameObjects.Text;
  private comboText!: Phaser.GameObjects.Text;
  private pauseOverlay!: Phaser.GameObjects.Container;

  constructor() {
    super('UIScene');
  }

  create(): void {
    this.createUI();
    this.setupEventListeners();
  }

  private createUI(): void {
    // Score display
    this.scoreText = this.add.text(
      this.cameras.main.centerX,
      80,
      '0',
      textStyles.score
    );
    this.scoreText.setOrigin(0.5);
    this.scoreText.setFontSize(48);

    // Combo display
    this.comboText = this.add.text(
      this.cameras.main.centerX,
      150,
      '',
      textStyles.combo
    );
    this.comboText.setOrigin(0.5);
    this.comboText.setAlpha(0);

    // Pause button
    const pauseBtn = this.add.text(
      this.cameras.main.width - 60,
      60,
      '||',
      textStyles.button
    );
    pauseBtn.setOrigin(0.5);
    pauseBtn.setInteractive();
    pauseBtn.on('pointerdown', () => {
      this.scene.get('GameScene').events.emit('pauseRequested');
    });
  }

  private setupEventListeners(): void {
    const gameScene = this.scene.get('GameScene');

    gameScene.events.on('scoreUpdate', (score: number) => {
      this.scoreText.setText(score.toLocaleString());
    });

    gameScene.events.on('comboUpdate', (combo: number) => {
      if (combo > 1) {
        this.comboText.setText(`Combo x${combo}`);
        this.comboText.setAlpha(1);
        
        this.tweens.add({
          targets: this.comboText,
          scale: 1.2,
          duration: 100,
          yoyo: true,
          ease: 'Power2'
        });
      } else {
        this.comboText.setAlpha(0);
      }
    });

    gameScene.events.on('gamePaused', () => {
      this.showPauseMenu();
    });

    gameScene.events.on('gameResumed', () => {
      this.hidePauseMenu();
    });

    gameScene.events.on('pauseRequested', () => {
      (gameScene as any).pauseGame();
    });
  }

  private showPauseMenu(): void {
    // Overlay
    const overlay = this.add.rectangle(
      this.cameras.main.centerX,
      this.cameras.main.centerY,
      this.cameras.main.width,
      this.cameras.main.height,
      0x000000,
      0.8
    );

    // Title
    const title = this.add.text(
      this.cameras.main.centerX,
      this.cameras.main.centerY - 200,
      'PAUSED',
      textStyles.title
    );
    title.setOrigin(0.5);

    // Resume button
    const resumeBtn = new Button(
      this,
      this.cameras.main.centerX,
      this.cameras.main.centerY,
      'RESUME',
      () => {
        this.scene.get('GameScene').events.emit('pauseRequested');
      }
    );

    // Quit button
    const quitBtn = new Button(
      this,
      this.cameras.main.centerX,
      this.cameras.main.centerY + 120,
      'QUIT TO MENU',
      () => {
        this.scene.stop('GameScene');
        this.scene.stop('UIScene');
        this.scene.start('MenuScene');
      }
    );

    this.pauseOverlay = this.add.container(0, 0, [overlay, title, resumeBtn, quitBtn]);
  }

  private hidePauseMenu(): void {
    if (this.pauseOverlay) {
      this.pauseOverlay.destroy();
    }
  }
}