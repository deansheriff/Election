-- VoteNG 2027 — Nigeria Mock Election Platform
-- MySQL Schema

CREATE DATABASE IF NOT EXISTS voteng2027;
USE voteng2027;

-- ─────────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────────
CREATE TABLE users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(150) UNIQUE,
  phone         VARCHAR(20) NOT NULL UNIQUE,
  state         VARCHAR(50) NOT NULL,
  lga           VARCHAR(100) NOT NULL,
  gender        ENUM('male','female','other') NOT NULL,
  age           TINYINT UNSIGNED NOT NULL,
  geopolitical_zone VARCHAR(30),
  password_hash VARCHAR(255) NOT NULL,
  otp_code      VARCHAR(10),
  otp_expires_at DATETIME,
  is_verified   TINYINT(1) DEFAULT 0,
  is_admin      TINYINT(1) DEFAULT 0,
  is_flagged    TINYINT(1) DEFAULT 0,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- PARTIES
-- ─────────────────────────────────────────────
CREATE TABLE parties (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  abbreviation  VARCHAR(10) NOT NULL UNIQUE,
  color_hex     VARCHAR(7) NOT NULL,
  logo_url      VARCHAR(255),
  manifesto     TEXT
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- STATES (with geopolitical zones)
-- ─────────────────────────────────────────────
CREATE TABLE states (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(60) NOT NULL UNIQUE,
  abbreviation  VARCHAR(5),
  geopolitical_zone VARCHAR(30) NOT NULL,
  capital       VARCHAR(60)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- LOCAL GOVERNMENT AREAS
-- ─────────────────────────────────────────────
CREATE TABLE lgas (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  state_id      INT UNSIGNED NOT NULL,
  name          VARCHAR(100) NOT NULL,
  FOREIGN KEY (state_id) REFERENCES states(id)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- SENATORIAL ZONES
-- ─────────────────────────────────────────────
CREATE TABLE senatorial_zones (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  state_id      INT UNSIGNED NOT NULL,
  name          VARCHAR(100) NOT NULL,
  FOREIGN KEY (state_id) REFERENCES states(id)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- HOUSE OF REPS CONSTITUENCIES
-- ─────────────────────────────────────────────
CREATE TABLE constituencies (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  state_id      INT UNSIGNED NOT NULL,
  name          VARCHAR(150) NOT NULL,
  FOREIGN KEY (state_id) REFERENCES states(id)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- CANDIDATES
-- ─────────────────────────────────────────────
CREATE TABLE candidates (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name         VARCHAR(150) NOT NULL,
  photo_url         VARCHAR(255),
  party_id          INT UNSIGNED NOT NULL,
  election_type     ENUM('presidential','senate','house','governorship','state_assembly') NOT NULL,
  state_id          INT UNSIGNED,
  senatorial_zone_id INT UNSIGNED,
  constituency_id   INT UNSIGNED,
  running_mate_name VARCHAR(150),
  running_mate_photo_url VARCHAR(255),
  bio               TEXT,
  age               TINYINT UNSIGNED,
  is_incumbent      TINYINT(1) DEFAULT 0,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (party_id) REFERENCES parties(id),
  FOREIGN KEY (state_id) REFERENCES states(id),
  FOREIGN KEY (senatorial_zone_id) REFERENCES senatorial_zones(id),
  FOREIGN KEY (constituency_id) REFERENCES constituencies(id)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- VOTES
-- ─────────────────────────────────────────────
CREATE TABLE votes (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id       INT UNSIGNED NOT NULL,
  candidate_id  INT UNSIGNED NOT NULL,
  election_type ENUM('presidential','senate','house','governorship','state_assembly') NOT NULL,
  user_state    VARCHAR(60),
  user_zone     VARCHAR(30),
  user_gender   ENUM('male','female','other'),
  user_age      TINYINT UNSIGNED,
  cast_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY no_double_vote (user_id, election_type),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (candidate_id) REFERENCES candidates(id)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- ELECTION CONFIGURATION
-- ─────────────────────────────────────────────
CREATE TABLE election_config (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  election_type ENUM('presidential','senate','house','governorship','state_assembly') NOT NULL UNIQUE,
  is_open       TINYINT(1) DEFAULT 0,
  open_date     DATETIME,
  close_date    DATETIME,
  label         VARCHAR(100),
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- ACTUAL (INEC) RESULTS — Filled post-election
-- ─────────────────────────────────────────────
CREATE TABLE actual_results (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  candidate_id    INT UNSIGNED NOT NULL UNIQUE,
  election_type   ENUM('presidential','senate','house','governorship','state_assembly') NOT NULL,
  real_vote_count BIGINT UNSIGNED DEFAULT 0,
  real_percentage DECIMAL(5,2) DEFAULT 0.00,
  entered_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (candidate_id) REFERENCES candidates(id)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- BROADCAST NOTIFICATIONS
-- ─────────────────────────────────────────────
CREATE TABLE notifications (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title       VARCHAR(200) NOT NULL,
  body        TEXT NOT NULL,
  sent_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  sent_by     INT UNSIGNED,
  FOREIGN KEY (sent_by) REFERENCES users(id)
) ENGINE=InnoDB;
