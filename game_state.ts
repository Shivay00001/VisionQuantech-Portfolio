import { GameMode } from '../gameConfig';
import { StorageService } from '../services/StorageService';

export interface GameStats {
  score: number;
  duration: number;
  distance: number;
  perfectBeats: number;
  maxSpeed: number;
}

export class GameState {
  private static instance: GameState;
  private storage: StorageService;
  
  private userId: string = '';
  private displayName: string = '';
  private bestScore: number = 0;
  private lastScore: number = 0;
  private lastGameStats: GameStats = {
    score: 0,
    duration: 0,
    distance: 0,
    perfectBeats: 0,
    maxSpeed: 0
  };
  
  private gameMode: GameMode = 'normal';
  private currentSeed: string = '';
  private isMutedFlag: boolean = false;

  private constructor() {
    this.storage = new StorageService();
    this.loadFromStorage();
  }

  public static getInstance(): GameState {
    if (!GameState.instance) {
      GameState.instance = new GameState();
    }
    return GameState.instance;
  }

  private loadFromStorage(): void {
    this.userId = this.storage.get('userId', '');
    this.displayName = this.storage.get('displayName', 'Anonymous');
    this.bestScore = this.storage.get('bestScore', 0);
    this.isMutedFlag = this.storage.get('isMuted', false);
  }

  private saveToStorage(): void {
    this.storage.set('userId', this.userId);
    this.storage.set('displayName', this.displayName);
    this.storage.set('bestScore', this.bestScore);
    this.storage.set('isMuted', this.isMutedFlag);
  }

  // User management
  public setUserId(id: string): void {
    this.userId = id;
    this.saveToStorage();
  }

  public getUserId(): string {
    return this.userId;
  }

  public setDisplayName(name: string): void {
    this.displayName = name;
    this.saveToStorage();
  }

  public getDisplayName(): string {
    return this.displayName;
  }

  // Score management
  public setBestScore(score: number): void {
    if (score > this.bestScore) {
      this.bestScore = score;
      this.saveToStorage();
    }
  }

  public getBestScore(): number {
    return this.bestScore;
  }

  public setLastScore(score: number): void {
    this.lastScore = score;
  }

  public getLastScore(): number {
    return this.lastScore;
  }

  public setLastGameStats(stats: GameStats): void {
    this.lastGameStats = stats;
  }

  public getLastGameStats(): GameStats {
    return this.lastGameStats;
  }

  // Game mode
  public setGameMode(mode: GameMode): void {
    this.gameMode = mode;
  }

  public getGameMode(): GameMode {
    return this.gameMode;
  }

  public setCurrentSeed(seed: string): void {
    this.currentSeed = seed;
  }

  public getCurrentSeed(): string {
    return this.currentSeed;
  }

  // Settings
  public toggleMute(): void {
    this.isMutedFlag = !this.isMutedFlag;
    this.saveToStorage();
  }

  public isMuted(): boolean {
    return this.isMutedFlag;
  }

  public setMuted(muted: boolean): void {
    this.isMutedFlag = muted;
    this.saveToStorage();
  }

  // Reset
  public reset(): void {
    this.lastScore = 0;
    this.lastGameStats = {
      score: 0,
      duration: 0,
      distance: 0,
      perfectBeats: 0,
      maxSpeed: 0
    };
  }
}