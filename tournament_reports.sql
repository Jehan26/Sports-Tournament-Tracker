-- Tournament Reports and Analytics

-- 1. TEAM PERFORMANCE REPORT
SELECT 
    'TEAM PERFORMANCE REPORT' as report_title,
    NOW() as generated_at;

SELECT 
    RANK() OVER (ORDER BY ts.points DESC, (ts.goals_for - ts.goals_against) DESC) as position,
    t.team_name,
    t.city,
    t.coach_name,
    ts.matches_played,
    ts.wins,
    ts.draws,
    ts.losses,
    ts.goals_for,
    ts.goals_against,
    (ts.goals_for - ts.goals_against) as goal_difference,
    ts.points,
    CASE 
        WHEN ts.matches_played > 0 
        THEN ROUND((ts.wins / ts.matches_played) * 100, 1)
        ELSE 0
    END as win_percentage,
    CASE 
        WHEN ts.matches_played > 0 
        THEN ROUND(ts.goals_for / ts.matches_played, 2)
        ELSE 0
    END as goals_per_match,
    CASE 
        WHEN ts.matches_played > 0 
        THEN ROUND(ts.goals_against / ts.matches_played, 2)
        ELSE 0
    END as goals_conceded_per_match
FROM teams t
JOIN team_stats ts ON t.team_id = ts.team_id
ORDER BY ts.points DESC, goal_difference DESC, ts.goals_for DESC;

-- 2. TOP PLAYERS REPORT
SELECT 
    'TOP PLAYERS REPORT' as report_title,
    NOW() as generated_at;

-- Top Goal Scorers
SELECT 
    'Top Goal Scorers' as category,
    RANK() OVER (ORDER BY SUM(ps.goals_scored) DESC) as rank_position,
    CONCAT(p.first_name, ' ', p.last_name) as player_name,
    t.team_name,
    p.position,
    SUM(ps.goals_scored) as goals,
    SUM(ps.assists) as assists,
    COUNT(ps.match_id) as matches_played,
    ROUND(SUM(ps.goals_scored) / COUNT(ps.match_id), 2) as goals_per_match
FROM players p
JOIN teams t ON p.team_id = t.team_id
JOIN player_stats ps ON p.player_id = ps.player_id
JOIN matches m ON ps.match_id = m.match_id
WHERE m.status = 'completed'
GROUP BY p.player_id, p.first_name, p.last_name, t.team_name, p.position
ORDER BY goals DESC
LIMIT 10;

-- Top Assist Providers
SELECT 
    'Top Assist Providers' as category,
    RANK() OVER (ORDER BY SUM(ps.assists) DESC) as rank_position,
    CONCAT(p.first_name, ' ', p.last_name) as player_name,
    t.team_name,
    p.position,
    SUM(ps.assists) as assists,
    SUM(ps.goals_scored) as goals,
    COUNT(ps.match_id) as matches_played,
    ROUND(SUM(ps.assists) / COUNT(ps.match_id), 2) as assists_per_match
FROM players p
JOIN teams t ON p.team_id = t.team_id
JOIN player_stats ps ON p.player_id = ps.player_id
JOIN matches m ON ps.match_id = m.match_id
WHERE m.status = 'completed'
GROUP BY p.player_id, p.first_name, p.last_name, t.team_name, p.position
HAVING SUM(ps.assists) > 0
ORDER BY assists DESC
LIMIT 10;

-- 3. MATCH STATISTICS REPORT
SELECT 
    'MATCH STATISTICS REPORT' as report_title,
    NOW() as generated_at;

-- Recent Match Results
SELECT 
    m.match_date,
    CONCAT(ht.team_name, ' vs ', at.team_name) as fixture,
    CONCAT(m.home_score, ' - ', m.away_score) as score,
    m.venue,
    m.tournament_round,
    CASE 
        WHEN m.home_score > m.away_score THEN ht.team_name
        WHEN m.away_score > m.home_score THEN at.team_name
        ELSE 'Draw'
    END as winner,
    -- Get top scorer for the match
    (SELECT CONCAT(p.first_name, ' ', p.last_name, ' (', SUM(ps.goals_scored), ' goals)')
     FROM player_stats ps 
     JOIN players p ON ps.player_id = p.player_id 
     WHERE ps.match_id = m.match_id AND ps.goals_scored > 0
     GROUP BY p.player_id, p.first_name, p.last_name
     ORDER BY SUM(ps.goals_scored) DESC 
     LIMIT 1) as top_scorer
FROM matches m
JOIN teams ht ON m.home_team_id = ht.team_id
JOIN teams at ON m.away_team_id = at.team_id
WHERE m.status = 'completed'
ORDER BY m.match_date DESC
LIMIT 10;

-- 4. TOURNAMENT STATISTICS SUMMARY
SELECT 
    'TOURNAMENT STATISTICS SUMMARY' as report_title,
    NOW() as generated_at;

SELECT 
    (SELECT COUNT(*) FROM teams) as total_teams,
    (SELECT COUNT(*) FROM players) as total_players,
    (SELECT COUNT(*) FROM matches WHERE status = 'completed') as matches_completed,
    (SELECT COUNT(*) FROM matches WHERE status = 'scheduled') as matches_scheduled,
    (SELECT SUM(home_score + away_score) FROM matches WHERE status = 'completed') as total_goals,
    (SELECT ROUND(AVG(home_score + away_score), 2) FROM matches WHERE status = 'completed') as avg_goals_per_match,
    (SELECT COUNT(*) FROM matches WHERE status = 'completed' AND home_score = away_score) as total_draws,
    (SELECT ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM matches WHERE status = 'completed'), 1) 
     FROM matches WHERE status = 'completed' AND home_score = away_score) as draw_percentage;

-- 5. PLAYER DISCIPLINE REPORT
SELECT 
    'PLAYER DISCIPLINE REPORT' as report_title,
    NOW() as generated_at;

SELECT 
    CONCAT(p.first_name, ' ', p.last_name) as player_name,
    t.team_name,
    p.position,
    SUM(ps.yellow_cards) as yellow_cards,
    SUM(ps.red_cards) as red_cards,
    (SUM(ps.yellow_cards) + SUM(ps.red_cards) * 2) as discipline_points,
    COUNT(ps.match_id) as matches_played
FROM players p
JOIN teams t ON p.team_id = t.team_id
JOIN player_stats ps ON p.player_id = ps.player_id
JOIN matches m ON ps.match_id = m.match_id
WHERE m.status = 'completed' AND (ps.yellow_cards > 0 OR ps.red_cards > 0)
GROUP BY p.player_id, p.first_name, p.last_name, t.team_name, p.position
ORDER BY discipline_points DESC, yellow_cards DESC;

-- 6. VENUE STATISTICS
SELECT 
    'VENUE STATISTICS' as report_title,
    NOW() as generated_at;

SELECT 
    m.venue,
    COUNT(*) as matches_played,
    SUM(m.home_score + m.away_score) as total_goals,
    ROUND(AVG(m.home_score + m.away_score), 2) as avg_goals_per_match,
    SUM(CASE WHEN m.home_score > m.away_score THEN 1 ELSE 0 END) as home_wins,
    SUM(CASE WHEN m.away_score > m.home_score THEN 1 ELSE 0 END) as away_wins,