-- Tournament Management SQL Queries

-- 1. MATCH RESULTS QUERIES

-- Get all completed matches with team names and scores
SELECT 
    m.match_id,
    m.match_date,
    m.venue,
    ht.team_name as home_team,
    at.team_name as away_team,
    m.home_score,
    m.away_score,
    m.tournament_round,
    CASE 
        WHEN m.home_score > m.away_score THEN ht.team_name
        WHEN m.away_score > m.home_score THEN at.team_name
        ELSE 'Draw'
    END as winner
FROM matches m
JOIN teams ht ON m.home_team_id = ht.team_id
JOIN teams at ON m.away_team_id = at.team_id
WHERE m.status = 'completed'
ORDER BY m.match_date DESC;

-- Get upcoming matches
SELECT 
    m.match_id,
    m.match_date,
    m.venue,
    ht.team_name as home_team,
    at.team_name as away_team,
    m.tournament_round
FROM matches m
JOIN teams ht ON m.home_team_id = ht.team_id
JOIN teams at ON m.away_team_id = at.team_id
WHERE m.status = 'scheduled' AND m.match_date > NOW()
ORDER BY m.match_date ASC;

-- 2. PLAYER STATISTICS QUERIES

-- Top scorers in the tournament
SELECT 
    p.first_name,
    p.last_name,
    t.team_name,
    SUM(ps.goals_scored) as total_goals,
    SUM(ps.assists) as total_assists,
    COUNT(ps.match_id) as matches_played,
    ROUND(SUM(ps.goals_scored) / COUNT(ps.match_id), 2) as goals_per_match
FROM players p
JOIN teams t ON p.team_id = t.team_id
JOIN player_stats ps ON p.player_id = ps.player_id
JOIN matches m ON ps.match_id = m.match_id
WHERE m.status = 'completed'
GROUP BY p.player_id, p.first_name, p.last_name, t.team_name
ORDER BY total_goals DESC, total_assists DESC
LIMIT 10;

-- Player performance with shooting accuracy
SELECT 
    p.first_name,
    p.last_name,
    t.team_name,
    SUM(ps.goals_scored) as goals,
    SUM(ps.shots_on_target) as shots_on_target,
    SUM(ps.shots_total) as total_shots,
    CASE 
        WHEN SUM(ps.shots_total) > 0 
        THEN ROUND((SUM(ps.shots_on_target) / SUM(ps.shots_total)) * 100, 2)
        ELSE 0
    END as shooting_accuracy_percent
FROM players p
JOIN teams t ON p.team_id = t.team_id
JOIN player_stats ps ON p.player_id = ps.player_id
JOIN matches m ON ps.match_id = m.match_id
WHERE m.status = 'completed'
GROUP BY p.player_id, p.first_name, p.last_name, t.team_name
HAVING SUM(ps.shots_total) > 0
ORDER BY shooting_accuracy_percent DESC;

-- 3. VIEWS FOR LEADERBOARDS AND POINTS TABLES

-- Team Leaderboard View
CREATE VIEW team_leaderboard AS
SELECT 
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
        THEN ROUND((ts.wins / ts.matches_played) * 100, 2)
        ELSE 0
    END as win_percentage
FROM teams t
JOIN team_stats ts ON t.team_id = ts.team_id
ORDER BY ts.points DESC, goal_difference DESC, ts.goals_for DESC;

-- Player Statistics Summary View
CREATE VIEW player_statistics_summary AS
SELECT 
    p.player_id,
    CONCAT(p.first_name, ' ', p.last_name) as player_name,
    t.team_name,
    p.position,
    p.jersey_number,
    COUNT(ps.match_id) as matches_played,
    SUM(ps.goals_scored) as total_goals,
    SUM(ps.assists) as total_assists,
    SUM(ps.yellow_cards) as yellow_cards,
    SUM(ps.red_cards) as red_cards,
    SUM(ps.minutes_played) as total_minutes,
    ROUND(AVG(ps.minutes_played), 2) as avg_minutes_per_match,
    SUM(ps.shots_on_target) as shots_on_target,
    SUM(ps.shots_total) as total_shots,
    CASE 
        WHEN SUM(ps.shots_total) > 0 
        THEN ROUND((SUM(ps.shots_on_target) / SUM(ps.shots_total)) * 100, 2)
        ELSE 0
    END as shooting_accuracy
FROM players p
JOIN teams t ON p.team_id = t.team_id
LEFT JOIN player_stats ps ON p.player_id = ps.player_id
LEFT JOIN matches m ON ps.match_id = m.match_id AND m.status = 'completed'
GROUP BY p.player_id, p.first_name, p.last_name, t.team_name, p.position, p.jersey_number
ORDER BY total_goals DESC, total_assists DESC;

-- Match Results with Details View
CREATE VIEW match_results_detailed AS
SELECT 
    m.match_id,
    m.match_date,
    m.venue,
    ht.team_name as home_team,
    at.team_name as away_team,
    m.home_score,
    m.away_score,
    m.tournament_round,
    m.status,
    CASE 
        WHEN m.home_score > m.away_score THEN ht.team_name
        WHEN m.away_score > m.home_score THEN at.team_name
        ELSE 'Draw'
    END as result,
    ABS(m.home_score - m.away_score) as goal_margin
FROM matches m
JOIN teams ht ON m.home_team_id = ht.team_id
JOIN teams at ON m.away_team_id = at.team_id
ORDER BY m.match_date DESC;

-- 4. CTE FOR AVERAGE PLAYER PERFORMANCE

-- Average player performance across all matches
WITH player_averages AS (
    SELECT 
        p.player_id,
        CONCAT(p.first_name, ' ', p.last_name) as player_name,
        t.team_name,
        p.position,
        COUNT(ps.match_id) as matches_played,
        AVG(ps.goals_scored) as avg_goals_per_match,
        AVG(ps.assists) as avg_assists_per_match,
        AVG(ps.minutes_played) as avg_minutes_per_match,
        AVG(ps.shots_on_target) as avg_shots_on_target,
        AVG(ps.shots_total) as avg_total_shots
    FROM players p
    JOIN teams t ON p.team_id = t.team_id
    JOIN player_stats ps ON p.player_id = ps.player_id
    JOIN matches m ON ps.match_id = m.match_id
    WHERE m.status = 'completed'
    GROUP BY p.player_id, p.first_name, p.last_name, t.team_name, p.position
    HAVING COUNT(ps.match_id) >= 2  -- Only players with at least 2 matches
)
SELECT 
    player_name,
    team_name,
    position,
    matches_played,
    ROUND(avg_goals_per_match, 2) as avg_goals,
    ROUND(avg_assists_per_match, 2) as avg_assists,
    ROUND(avg_minutes_per_match, 2) as avg_minutes,
    ROUND(avg_shots_on_target, 2) as avg_shots_on_target,
    ROUND(avg_total_shots, 2) as avg_total_shots,
    CASE 
        WHEN avg_total_shots > 0 
        THEN ROUND((avg_shots_on_target / avg_total_shots) * 100, 2)
        ELSE 0
    END as avg_shooting_accuracy
FROM player_averages
ORDER BY avg_goals DESC, avg_assists DESC;

-- Team performance comparison with league averages
WITH league_averages AS (
    SELECT 
        AVG(goals_for) as avg_goals_for,
        AVG(goals_against) as avg_goals_against,
        AVG(points) as avg_points,
        AVG(wins) as avg_wins,
        AVG(matches_played) as avg_matches
    FROM team_stats
)
SELECT 
    t.team_name,
    ts.points,
    ts.goals_for,
    ts.goals_against,
    ts.wins,
    ts.matches_played,
    ROUND(ts.points - la.avg_points, 2) as points_vs_average,
    ROUND(ts.goals_for - la.avg_goals_for, 2) as goals_for_vs_average,
    ROUND(ts.goals_against - la.avg_goals_against, 2) as goals_against_vs_average
FROM teams t
JOIN team_stats ts ON t.team_id = ts.team_id
CROSS JOIN league_averages la
ORDER BY points_vs_average DESC;

-- 5. STORED PROCEDURES

-- Procedure to update team statistics after a match
DELIMITER //
CREATE PROCEDURE UpdateTeamStats(IN match_id INT)
BEGIN
    DECLARE home_team INT;
    DECLARE away_team INT;
    DECLARE home_score INT;
    DECLARE away_score INT;
    
    -- Get match details
    SELECT home_team_id, away_team_id, home_score, away_score 
    INTO home_team, away_team, home_score, away_score
    FROM matches 
    WHERE matches.match_id = match_id AND status = 'completed';
    
    -- Update home team stats
    UPDATE team_stats 
    SET matches_played = matches_played + 1,
        goals_for = goals_for + home_score,
        goals_against = goals_against + away_score,
        wins = wins + CASE WHEN home_score > away_score THEN 1 ELSE 0 END,
        draws = draws + CASE WHEN home_score = away_score THEN 1 ELSE 0 END,
        losses = losses + CASE WHEN home_score < away_score THEN 1 ELSE 0 END,
        points = points + CASE 
            WHEN home_score > away_score THEN 3 
            WHEN home_score = away_score THEN 1 
            ELSE 0 
        END
    WHERE team_id = home_team;
    
    -- Update away team stats
    UPDATE team_stats 
    SET matches_played = matches_played + 1,
        goals_for = goals_for + away_score,
        goals_against = goals_against + home_score,
        wins = wins + CASE WHEN away_score > home_score THEN 1 ELSE 0 END,
        draws = draws + CASE WHEN away_score = home_score THEN 1 ELSE 0 END,
        losses = losses + CASE WHEN away_score < home_score THEN 1 ELSE 0 END,
        points = points + CASE 
            WHEN away_score > home_score THEN 3 
            WHEN away_score = home_score THEN 1 
            ELSE 0 
        END
    WHERE team_id = away_team;
END //
DELIMITER ;

-- 6. TRIGGERS

-- Trigger to automatically update team stats when match is completed
DELIMITER //
CREATE TRIGGER update_team_stats_on_match_completion
AFTER UPDATE ON matches
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        CALL UpdateTeamStats(NEW.match_id);
    END IF;
END //
DELIMITER ;