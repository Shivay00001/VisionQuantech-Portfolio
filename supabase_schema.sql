-- Neon Beat Dash Database Schema
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  display_name TEXT,
  country TEXT
);

-- Scores table
CREATE TABLE IF NOT EXISTS scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  score BIGINT NOT NULL,
  duration_ms INTEGER NOT NULL,
  perfect_beats INTEGER NOT NULL DEFAULT 0,
  max_speed NUMERIC(5,2) NOT NULL DEFAULT 0,
  seed TEXT NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('normal', 'daily')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily challenges table
CREATE TABLE IF NOT EXISTS daily_challenges (
  day DATE PRIMARY KEY,
  seed TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_scores_user_id ON scores(user_id);
CREATE INDEX IF NOT EXISTS idx_scores_score_desc ON scores(score DESC);
CREATE INDEX IF NOT EXISTS idx_scores_mode ON scores(mode);
CREATE INDEX IF NOT EXISTS idx_scores_created_at ON scores(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_daily_challenges_day ON daily_challenges(day);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_challenges ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can read all users"
  ON users FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own data"
  ON users FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update their own data"
  ON users FOR UPDATE
  USING (true);

-- RLS Policies for scores table
CREATE POLICY "Anyone can read scores"
  ON scores FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own scores"
  ON scores FOR INSERT
  WITH CHECK (true);

-- RLS Policies for daily_challenges table
CREATE POLICY "Anyone can read daily challenges"
  ON daily_challenges FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert daily challenges"
  ON daily_challenges FOR INSERT
  WITH CHECK (true);

-- Function to get top scores (with deobfuscation)
CREATE OR REPLACE FUNCTION get_top_scores(
  score_mode TEXT DEFAULT 'normal',
  score_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  score BIGINT,
  display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.user_id,
    -- Deobfuscate score (reverse the rotation)
    ((s.score >> 3) | (s.score << 29))::BIGINT AS score,
    u.display_name,
    s.created_at
  FROM scores s
  JOIN users u ON s.user_id = u.id
  WHERE s.mode = score_mode
  ORDER BY score DESC
  LIMIT score_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate and insert score
CREATE OR REPLACE FUNCTION submit_score(
  p_user_id UUID,
  p_score BIGINT,
  p_duration_ms INTEGER,
  p_perfect_beats INTEGER,
  p_max_speed NUMERIC,
  p_seed TEXT,
  p_mode TEXT
)
RETURNS UUID AS $$
DECLARE
  v_score_id UUID;
  v_max_possible_score BIGINT;
  v_max_possible_beats INTEGER;
BEGIN
  -- Basic validation
  IF p_score < 0 OR p_duration_ms < 0 OR p_perfect_beats < 0 THEN
    RAISE EXCEPTION 'Invalid score data';
  END IF;

  -- Calculate maximum possible score (generous estimate)
  v_max_possible_score := (p_duration_ms / 1000) * 1000;
  
  -- Calculate maximum possible perfect beats
  v_max_possible_beats := p_duration_ms / 1000;

  -- Validate score is reasonable
  IF p_score > v_max_possible_score THEN
    RAISE EXCEPTION 'Score too high for duration';
  END IF;

  -- Validate perfect beats
  IF p_perfect_beats > v_max_possible_beats THEN
    RAISE EXCEPTION 'Perfect beats count invalid';
  END IF;

  -- Insert score
  INSERT INTO scores (
    user_id,
    score,
    duration_ms,
    perfect_beats,
    max_speed,
    seed,
    mode
  ) VALUES (
    p_user_id,
    p_score,
    p_duration_ms,
    p_perfect_beats,
    p_max_speed,
    p_seed,
    p_mode
  ) RETURNING id INTO v_score_id;

  RETURN v_score_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on functions
GRANT EXECUTE ON FUNCTION get_top_scores TO anon, authenticated;
GRANT EXECUTE ON FUNCTION submit_score TO anon, authenticated;

-- Create view for daily leaderboard
CREATE OR REPLACE VIEW daily_leaderboard AS
SELECT 
  s.id,
  s.user_id,
  ((s.score >> 3) | (s.score << 29))::BIGINT AS score,
  u.display_name,
  s.created_at,
  s.perfect_beats,
  s.duration_ms
FROM scores s
JOIN users u ON s.user_id = u.id
WHERE s.mode = 'daily'
  AND s.created_at >= CURRENT_DATE
ORDER BY score DESC;

GRANT SELECT ON daily_leaderboard TO anon, authenticated;