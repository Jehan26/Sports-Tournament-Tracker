-- Sports Tournament Tracker Database Schema
-- Create Database
CREATE DATABASE sports_tournament;
USE sports_tournament;

-- 1. Teams Table
CREATE TABLE teams (
    team_id INT PRIMARY KEY AUTO_INCREMENT,
    team_name VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    coach_name VARCHAR(100),
    established_year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Players Table
CREATE TABLE players (
    player_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    team_id INT,
    position VARCHAR(50),
    jersey_number INT,
    birth_date DATE,
    height_cm INT,
    weight_kg DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE SET NULL,
    UNIQUE KEY unique_team_jersey (team_id, jersey_number)
);

-- 3. Matches Table
CREATE TABLE matches (
    match_id INT PRIMARY KEY AUTO_INCREMENT,
    home_team_id INT NOT NULL,
    away_team_id INT NOT NULL,
    match_date DATETIME NOT NULL,
    venue VARCHAR(100),
    home_score INT DEFAULT 0,
    away_score INT DEFAULT 0,
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled') DEFAULT 'scheduled',
    tournament_round VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (home_team_id) REFERENCES teams(team_id),
    FOREIGN KEY (away_team_id) REFERENCES teams(team_id),
    CHECK (home_team_id != away_team_id)
);

-- 4. Player Statistics Table
CREATE TABLE player_stats (
    stat_id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    match_id INT NOT NULL,
    goals_scored INT DEFAULT 0,
    assists INT DEFAULT 0,
    yellow_cards INT DEFAULT 0,
    red_cards INT DEFAULT 0,
    minutes_played INT DEFAULT 0,
    passes_completed INT DEFAULT 0,
    passes_attempted INT DEFAULT 0,
    shots_on_target INT DEFAULT 0,
    shots_total INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE CASCADE,
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    UNIQUE KEY unique_player_match (player_id, match_id)
);

-- 5. Team Statistics Table (aggregated from matches)
CREATE TABLE team_stats (
    team_stat_id INT PRIMARY KEY AUTO_INCREMENT,
    team_id INT NOT NULL,
    matches_played INT DEFAULT 0,
    wins INT DEFAULT 0,
    draws INT DEFAULT 0,
    losses INT DEFAULT 0,
    goals_for INT DEFAULT 0,
    goals_against INT DEFAULT 0,
    points INT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE
);

-- Insert Sample Data
-- Teams
INSERT INTO teams (team_name, city, coach_name, established_year) VALUES
('Thunder Bolts', 'New York', 'John Smith', 2015),
('Fire Dragons', 'Los Angeles', 'Maria Garcia', 2018),
('Ice Hawks', 'Chicago', 'David Johnson', 2016),
('Storm Eagles', 'Miami', 'Sarah Wilson', 2019),
('Lightning Wolves', 'Seattle', 'Mike Brown', 2017),
('Flame Tigers', 'Phoenix', 'Lisa Davis', 2020);

-- Players
INSERT INTO players (first_name, last_name, team_id, position, jersey_number, birth_date, height_cm, weight_kg) VALUES
-- Thunder Bolts (team_id: 1)
('Alex', 'Rodriguez', 1, 'Forward', 10, '1995-03-15', 180, 75.5),
('James', 'Wilson', 1, 'Midfielder', 8, '1993-07-22', 175, 72.0),
('Michael', 'Taylor', 1, 'Defender', 5, '1994-11-08', 185, 80.0),
('Chris', 'Anderson', 1, 'Goalkeeper', 1, '1992-05-14', 190, 85.0),
-- Fire Dragons (team_id: 2)
('Carlos', 'Martinez', 2, 'Forward', 9, '1996-01-20', 178, 73.5),
('Roberto', 'Silva', 2, 'Midfielder', 7, '1994-09-12', 172, 70.0),
('Diego', 'Lopez', 2, 'Defender', 4, '1995-12-03', 183, 78.0),
('Luis', 'Gonzalez', 2, 'Goalkeeper', 1, '1993-04-25', 188, 82.0),
-- Ice Hawks (team_id: 3)
('Tommy', 'Johnson', 3, 'Forward', 11, '1995-08-17', 176, 74.0),
('Kevin', 'Brown', 3, 'Midfielder', 6, '1994-02-28', 180, 76.0),
('Steve', 'Davis', 3, 'Defender', 3, '1993-10-15', 182, 79.0),
('Mark', 'Wilson', 3, 'Goalkeeper', 1, '1992-12-07', 192, 88.0);

-- Matches
INSERT INTO matches (home_team_id, away_team_id, match_date, venue, home_score, away_score, status, tournament_round) VALUES
(1, 2, '2024-07-01 15:00:00', 'Stadium A', 2, 1, 'completed', 'Group Stage'),
(3, 4, '2024-07-01 17:00:00', 'Stadium B', 1, 1, 'completed', 'Group Stage'),
(5, 6, '2024-07-02 15:00:00', 'Stadium C', 3, 0, 'completed', 'Group Stage'),
(2, 3, '2024-07-03 15:00:00', 'Stadium A', 0, 2, 'completed', 'Group Stage'),
(4, 5, '2024-07-03 17:00:00', 'Stadium B', 2, 2, 'completed', 'Group Stage'),
(6, 1, '2024-07-04 15:00:00', 'Stadium C', 1, 3, 'completed', 'Group Stage'),
(1, 3, '2024-07-15 15:00:00', 'Stadium A', 0, 0, 'scheduled', 'Semi-Final'),
(2, 5, '2024-07-16 15:00:00', 'Stadium B', 0, 0, 'scheduled', 'Semi-Final');

-- Player Statistics
INSERT INTO player_stats (player_id, match_id, goals_scored, assists, minutes_played, shots_on_target, shots_total) VALUES
-- Match 1: Thunder Bolts vs Fire Dragons (2-1)
(1, 1, 2, 0, 90, 3, 5), -- Alex Rodriguez
(2, 1, 0, 1, 90, 1, 2), -- James Wilson
(3, 1, 0, 1, 90, 0, 1), -- Michael Taylor
(4, 1, 0, 0, 90, 0, 0), -- Chris Anderson
(5, 1, 1, 0, 90, 2, 4), -- Carlos Martinez
(6, 1, 0, 0, 90, 1, 3), -- Roberto Silva
(7, 1, 0, 0, 90, 0, 0), -- Diego Lopez
(8, 1, 0, 0, 90, 0, 0), -- Luis Gonzalez
-- Match 2: Ice Hawks vs Storm Eagles (1-1)
(9, 2, 1, 0, 90, 1, 3), -- Tommy Johnson
(10, 2, 0, 1, 90, 0, 2), -- Kevin Brown
(11, 2, 0, 0, 90, 0, 0), -- Steve Davis
(12, 2, 0, 0, 90, 0, 0); -- Mark Wilson

-- Initialize Team Statistics
INSERT INTO team_stats (team_id, matches_played, wins, draws, losses, goals_for, goals_against, points) VALUES
(1, 2, 2, 0, 0, 5, 2, 6),
(2, 2, 0, 0, 2, 1, 4, 0),
(3, 2, 1, 1, 0, 3, 1, 4),
(4, 2, 0, 1, 1, 3, 4, 1),
(5, 2, 1, 1, 0, 5, 2, 4),
(6, 2, 0, 0, 2, 1, 5, 0);

-- Create Indexes for Performance
CREATE INDEX idx_matches_date ON matches(match_date);
CREATE INDEX idx_matches_teams ON matches(home_team_id, away_team_id);
CREATE INDEX idx_player_stats_player ON player_stats(player_id);
CREATE INDEX idx_player_stats_match ON player_stats(match_id);
CREATE INDEX idx_players_team ON players(team_id);