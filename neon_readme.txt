# Neon Beat Dash - Production Game

A hyper-casual, hyper-addictive mobile and web rhythm runner game built with TypeScript, Phaser 3, and Capacitor.

## 🎮 Game Features

- **3-lane endless runner** with rhythm-reactive gameplay
- **Perfect Beat system** - time your moves to the music for bonuses
- **Daily challenges** - compete globally with the same pattern
- **Online leaderboards** via Supabase
- **Offline PWA support** with local high scores
- **Android APK** ready via Capacitor
- **Smooth animations** and neon aesthetic

## 📋 Requirements

- Node.js 18+ LTS
- npm 9+
- Supabase account (free tier)
- Android Studio (for APK generation)
- Modern browser (Chrome/Firefox/Safari)

## 🚀 Quick Start

### 1. Clone and Install

```bash
# Extract all files to a folder called "neon-beat-dash"
cd neon-beat-dash/game
npm install
```

### 2. Setup Supabase Backend

1. Create account at https://supabase.com
2. Create new project
3. Go to Project Settings → API
4. Copy your `Project URL` and `anon public` key
5. Create `.env` file in `/game` folder:

```env
VITE_SUPABASE_URL=your_project_url_here
VITE_SUPABASE_ANON_KEY=your_anon_key_here
```

### 3. Setup Database

In Supabase SQL Editor, run the schema from `supabase-schema.sql`:

```sql
-- See supabase-schema.sql for complete schema
-- Copy and paste into Supabase SQL Editor
```

### 4. Run Locally

```bash
cd game
npm run dev
```

Open http://localhost:5173

## 🌐 Web Deployment (Netlify)

### Option 1: Netlify CLI

```bash
cd game
npm install -g netlify-cli
npm run build
netlify deploy --prod --dir=dist
```

### Option 2: Netlify UI

1. Connect GitHub repo to Netlify
2. Build settings:
   - Base directory: `game`
   - Build command: `npm run build`
   - Publish directory: `game/dist`
3. Environment variables:
   - Add `VITE_SUPABASE_URL`
   - Add `VITE_SUPABASE_ANON_KEY`

### Option 3: Vercel

```bash
cd game
npm install -g vercel
npm run build
vercel --prod
```

## 📱 Android APK Generation

### 1. Setup Capacitor

```bash
cd mobile
npm install
npm run build:mobile
npx cap sync android
```

### 2. Configure App

Edit `mobile/capacitor.config.ts`:

```typescript
appId: 'com.yourcompany.neonbeatdash'
appName: 'Neon Beat Dash'
```

Edit `mobile/android/app/src/main/res/values/strings.xml`:

```xml
<string name="app_name">Neon Beat Dash</string>
```

### 3. Generate APK

```bash
npx cap open android
```

In Android Studio:
1. Build → Generate Signed Bundle / APK
2. Choose APK
3. Create new keystore or use existing
4. Build Release APK
5. Find APK in `android/app/build/outputs/apk/release/`

### 4. Install Icons and Splash

Place your icons in `mobile/android/app/src/main/res/`:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

## 🎨 Asset Customization

Replace placeholder assets in `/game/src/assets/`:
- Add custom sound effects (MP3/OGG)
- Add custom sprites/textures
- Update neon colors in `src/gameConfig.ts`

## 🔧 Development

```bash
# Run dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Type check
npm run type-check

# Lint code
npm run lint
```

## 📊 Monitoring

### Leaderboard Admin

Query Supabase directly for moderation:

```sql
-- Top scores
SELECT u.display_name, s.score, s.created_at 
FROM scores s 
JOIN users u ON s.user_id = u.id 
ORDER BY s.score DESC 
LIMIT 100;

-- Suspicious scores (too high)
SELECT * FROM scores 
WHERE score > 100000 
OR (score / duration_ms) > 100;

-- Delete cheated scores
DELETE FROM scores WHERE id = 'suspicious_id';
```

## 🐛 Troubleshooting

### Build fails
- Check Node version: `node -v` (should be 18+)
- Clear cache: `rm -rf node_modules package-lock.json && npm install`

### Supabase connection fails
- Verify `.env` file exists in `/game`
- Check Supabase project is not paused
- Verify anon key is correct

### APK not installing
- Enable "Install from Unknown Sources" on Android
- Check minimum SDK version in `android/app/build.gradle` (API 22+)

### PWA not installing
- Must be served over HTTPS
- Check manifest.webmanifest is accessible
- Run Lighthouse audit in Chrome DevTools

## 📦 Project Structure

```
neon-beat-dash/
├── game/                 # Web game (Vite + Phaser)
│   ├── src/
│   │   ├── scenes/      # Game scenes
│   │   ├── core/        # Core game logic
│   │   ├── services/    # Backend services
│   │   ├── ui/          # UI components
│   │   └── assets/      # Game assets
│   ├── public/          # Static assets
│   └── dist/            # Build output
├── mobile/              # Capacitor wrapper
│   ├── android/         # Android project
│   └── ios/             # iOS project (future)
└── infra/               # Deploy configs
```

## 🎯 Game Mechanics

### Scoring
- Base: 10 points per second survived
- Distance: 1 point per meter
- Perfect Beat: 100 points + combo multiplier
- Good Beat: 50 points + combo multiplier
- Combo multiplier: up to 5x

### Daily Challenge
- Same obstacle pattern for all players
- 24-hour window
- Separate leaderboard

### Difficulty Scaling
- Speed increases every 10 seconds
- Obstacle spawn rate increases
- Beat ring timing windows tighten

## 🔒 Security & Anti-Cheat

- Server-side score validation
- Impossible score rejection
- Rate limiting on submissions
- Obfuscated score payloads
- Deterministic seed validation

## 📄 License

MIT License - Free for personal and commercial use

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open Pull Request

## 📞 Support

- Report bugs via GitHub Issues
- Feature requests welcome
- Check existing issues before posting

---

Built with ❤️ using Phaser 3, TypeScript, and Supabase