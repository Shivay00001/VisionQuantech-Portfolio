import Phaser from 'phaser';
import { gameConfig } from '../gameConfig';

export class Button extends Phaser.GameObjects.Container {
  private background: Phaser.GameObjects.Image;
  private text: Phaser.GameObjects.Text;
  private onClick: () => void;

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    text: string,
    onClick: () => void,
    width: number = 300,
    height: number = 80
  ) {
    super(scene, x, y);

    this.onClick = onClick;

    // Background
    this.background = scene.add.image(0, 0, 'button');
    this.background.setDisplaySize(width, height);
    
    // Text
    this.text = scene.add.text(0, 0, text, {
      fontSize: '24px',
      color: '#ffffff',
      fontStyle: 'bold'
    });
    this.text.setOrigin(0.5);

    // Add to container
    this.add(this.background);
    this.add(this.text);

    // Make interactive
    this.setSize(width, height);
    this.setInteractive();
    
    // Hover effects
    this.on('pointerover', () => {
      this.setScale(1.05);
      this.background.setTint(gameConfig.colors.accent);
    });

    this.on('pointerout', () => {
      this.setScale(1);
      this.background.clearTint();
    });

    this.on('pointerdown', () => {
      this.setScale(0.95);
    });

    this.on('pointerup', () => {
      this.setScale(1.05);
      this.onClick();
    });

    // Pulse animation
    scene.tweens.add({
      targets: this,
      scaleX: 1.02,
      scaleY: 1.02,
      duration: 1500,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut'
    });
  }

  public setText(text: string): void {
    this.text.setText(text);
  }

  public setEnabled(enabled: boolean): void {
    this.setInteractive(enabled);
    this.setAlpha(enabled ? 1 : 0.5);
  }
}