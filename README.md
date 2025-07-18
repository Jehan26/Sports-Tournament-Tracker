# 🏆 Sports Tournament Tracker

## 📌 Overview

A MySQL-based system to track sports tournaments, manage match results, and analyze player statistics. The project is designed to simulate a real-world tournament environment with teams, players, matches, and performance tracking.

---

## 🧱 Database Schema

The schema includes the following tables:

- **Teams**: Stores team names, coaches, and countries
- **Players**: Stores player info and links to their respective teams
- **Matches**: Records match details, team scores, and winners
- **Stats**: Stores player-specific match performance (goals, assists, cards)

---

## 🛠️ Tools Used

- MySQL 8+
- MySQL Workbench
- dbdiagram.io (for ERD)
- SQL (DDL, DML, Views, CTE)

---

## 📁 Project Structure

# Sports-Tournament-Tracker

---

## 📊 Key Features

- Insert and track real match results
- Query top scorers and MVPs
- View match-by-match stats
- Generate team leaderboards
- Use CTEs to calculate average goals and assists

---

## 🧪 Sample Queries

```sql
-- Top 5 players by goals
SELECT PlayerID, SUM(Goals) AS TotalGoals
FROM Stats
GROUP BY PlayerID
ORDER BY TotalGoals DESC
LIMIT 5;

-- Team leaderboard by match wins
SELECT t.Name, COUNT(*) AS Wins
FROM Matches m
JOIN Teams t ON m.WinnerTeamID = t.TeamID
GROUP BY t.Name
ORDER BY Wins DESC;
