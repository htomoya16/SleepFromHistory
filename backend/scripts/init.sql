-- データベース作成
CREATE DATABASE IF NOT EXISTS sleepfromhistory
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE sleepfromhistory;

-- ユーザー
CREATE TABLE IF NOT EXISTS users (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email         VARCHAR(255) NOT NULL UNIQUE,
  name          VARCHAR(100) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  default_tz    VARCHAR(64)  NOT NULL DEFAULT 'Asia/Tokyo',
  created_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- データ取得元（拡張のインストール/端末プロファイル単位）
CREATE TABLE IF NOT EXISTS sources (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id         BIGINT UNSIGNED NOT NULL,
  kind            ENUM('chrome') NOT NULL DEFAULT 'chrome',
  install_id      CHAR(36) NOT NULL,       -- 拡張側UUID
  device_label    VARCHAR(100) NOT NULL,   -- 任意表示名
  profile_name    VARCHAR(100) NOT NULL,   -- "Default" 等
  browser_version VARCHAR(50)  NULL,
  active          TINYINT(1) NOT NULL DEFAULT 1,
  created_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uniq_user_install (user_id, install_id),
  CONSTRAINT fk_sources_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 推定アルゴリズムの実行ログ（再現性用）
CREATE TABLE IF NOT EXISTS detection_runs (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id           BIGINT UNSIGNED NOT NULL,
  source_id         BIGINT UNSIGNED NULL,
  window_start_at   DATETIME(6) NOT NULL,
  window_end_at     DATETIME(6) NOT NULL,
  algorithm_version VARCHAR(40) NOT NULL,   -- 例: "v1.0.0" or git短SHA
  params_json       JSON NULL,
  computed_at       DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  created_at        DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_run_user_time (user_id, window_start_at),
  CONSTRAINT chk_run_window CHECK (window_start_at < window_end_at),
  CONSTRAINT fk_runs_user   FOREIGN KEY (user_id)  REFERENCES users(id)   ON DELETE CASCADE,
  CONSTRAINT fk_runs_source FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 履歴の“空白”要約（プライバシー配慮でドメイン/タイトルのみ）
CREATE TABLE IF NOT EXISTS history_gaps (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id           BIGINT UNSIGNED NOT NULL,
  source_id         BIGINT UNSIGNED NULL,
  gap_start_at      DATETIME(6) NOT NULL,  -- 最終閲覧時刻（空白始端）
  gap_end_at        DATETIME(6) NOT NULL,  -- 次の閲覧時刻（空白終端）
  last_host_before  VARCHAR(255) NULL,
  next_host_after   VARCHAR(255) NULL,
  last_title_before VARCHAR(255) NULL,
  next_title_after  VARCHAR(255) NULL,
  created_by        ENUM('extension','backend') NOT NULL DEFAULT 'extension',
  created_at        DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_gap_user_time (user_id, gap_start_at),
  CONSTRAINT chk_gap_order CHECK (gap_start_at < gap_end_at),
  CONSTRAINT fk_gaps_user   FOREIGN KEY (user_id)  REFERENCES users(id)   ON DELETE CASCADE,
  CONSTRAINT fk_gaps_source FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 睡眠区間（自動/手動、ユーザー確定可能）
CREATE TABLE IF NOT EXISTS sleep_periods (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id          BIGINT UNSIGNED NOT NULL,
  source_id        BIGINT UNSIGNED NULL,
  run_id           BIGINT UNSIGNED NULL,   -- detection_runs.id（手動ならNULL）
  method           ENUM('auto','manual') NOT NULL DEFAULT 'auto',
  status           ENUM('proposed','confirmed','edited','rejected') NOT NULL DEFAULT 'proposed',
  start_at         DATETIME(6) NOT NULL,
  end_at           DATETIME(6) NOT NULL,
  duration_minutes INT GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_at, end_at)) STORED,
  confidence       TINYINT UNSIGNED NULL,  -- 0-100（auto時）
  note             TEXT NULL,
  created_at       DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at       DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_sleep_user_start (user_id, start_at),
  KEY idx_sleep_user_end   (user_id, end_at),
  CONSTRAINT chk_sleep_order CHECK (start_at < end_at),
  CONSTRAINT fk_sleep_user   FOREIGN KEY (user_id)   REFERENCES users(id)           ON DELETE CASCADE,
  CONSTRAINT fk_sleep_source FOREIGN KEY (source_id) REFERENCES sources(id)         ON DELETE SET NULL,
  CONSTRAINT fk_sleep_run    FOREIGN KEY (run_id)    REFERENCES detection_runs(id)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ユーザーのフィードバック履歴（確定/却下/編集の差分）
CREATE TABLE IF NOT EXISTS sleep_feedbacks (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id          BIGINT UNSIGNED NOT NULL,
  sleep_period_id  BIGINT UNSIGNED NOT NULL,
  action           ENUM('confirm','reject','edit') NOT NULL,
  old_start_at     DATETIME(6) NULL,
  old_end_at       DATETIME(6) NULL,
  new_start_at     DATETIME(6) NULL,
  new_end_at       DATETIME(6) NULL,
  reason           VARCHAR(255) NULL,
  created_at       DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_feedback_user_time (user_id, created_at),
  CONSTRAINT fk_fb_user  FOREIGN KEY (user_id)         REFERENCES users(id)         ON DELETE CASCADE,
  CONSTRAINT fk_fb_sleep FOREIGN KEY (sleep_period_id)  REFERENCES sleep_periods(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ユーザー設定（検出閾値など）
CREATE TABLE IF NOT EXISTS user_settings (
  user_id                    BIGINT UNSIGNED NOT NULL,
  min_gap_minutes_for_sleep  INT NOT NULL DEFAULT 180,  -- 何分以上の空白で睡眠候補にするか
  usual_bedtime_start        TIME NULL,                 -- 例: '22:00:00'
  usual_bedtime_end          TIME NULL,                 -- 例: '03:00:00'
  dnd_start                  TIME NULL,                 -- 通知抑制
  dnd_end                    TIME NULL,
  created_at                 DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at                 DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (user_id),
  CONSTRAINT fk_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;