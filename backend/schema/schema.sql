-- Create "users" table
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `name` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `default_tz` varchar(64) NOT NULL DEFAULT "Asia/Tokyo",
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `email` (`email`)
) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
-- Create "sources" table
CREATE TABLE `sources` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `kind` enum('chrome') NOT NULL DEFAULT "chrome",
  `install_id` char(36) NOT NULL,
  `device_label` varchar(100) NOT NULL,
  `profile_name` varchar(100) NOT NULL,
  `browser_version` varchar(50) NULL,
  `active` bool NOT NULL DEFAULT 1,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uniq_user_install` (`user_id`, `install_id`),
  CONSTRAINT `fk_sources_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
-- Create "detection_runs" table
CREATE TABLE `detection_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `source_id` bigint unsigned NULL,
  `window_start_at` datetime(6) NOT NULL,
  `window_end_at` datetime(6) NOT NULL,
  `algorithm_version` varchar(40) NOT NULL,
  `params_json` json NULL,
  `computed_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  INDEX `fk_runs_source` (`source_id`),
  INDEX `idx_run_user_time` (`user_id`, `window_start_at`),
  CONSTRAINT `fk_runs_source` FOREIGN KEY (`source_id`) REFERENCES `sources` (`id`) ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT `fk_runs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT `chk_run_window` CHECK (`window_start_at` < `window_end_at`)
) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
-- Create "history_gaps" table
CREATE TABLE `history_gaps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `source_id` bigint unsigned NULL,
  `gap_start_at` datetime(6) NOT NULL,
  `gap_end_at` datetime(6) NOT NULL,
  `last_host_before` varchar(255) NULL,
  `next_host_after` varchar(255) NULL,
  `last_title_before` varchar(255) NULL,
  `next_title_after` varchar(255) NULL,
  `created_by` enum('extension','backend') NOT NULL DEFAULT "extension",
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  INDEX `fk_gaps_source` (`source_id`),
  INDEX `idx_gap_user_time` (`user_id`, `gap_start_at`),
  CONSTRAINT `fk_gaps_source` FOREIGN KEY (`source_id`) REFERENCES `sources` (`id`) ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT `fk_gaps_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT `chk_gap_order` CHECK (`gap_start_at` < `gap_end_at`)
) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
-- Create "sleep_periods" table
CREATE TABLE `sleep_periods` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `source_id` bigint unsigned NULL,
  `run_id` bigint unsigned NULL,
  `method` enum('auto','manual') NOT NULL DEFAULT "auto",
  `status` enum('proposed','confirmed','edited','rejected') NOT NULL DEFAULT "proposed",
  `start_at` datetime(6) NOT NULL,
  `end_at` datetime(6) NOT NULL,
  `duration_minutes` int AS (timestampdiff(MINUTE,`start_at`,`end_at`)) STORED NULL,
  `confidence` tinyint unsigned NULL,
  `note` text NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  INDEX `fk_sleep_run` (`run_id`),
  INDEX `fk_sleep_source` (`source_id`),
  INDEX `idx_sleep_user_end` (`user_id`, `end_at`),
  INDEX `idx_sleep_user_start` (`user_id`, `start_at`),
  CONSTRAINT `fk_sleep_run` FOREIGN KEY (`run_id`) REFERENCES `detection_runs` (`id`) ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT `fk_sleep_source` FOREIGN KEY (`source_id`) REFERENCES `sources` (`id`) ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT `fk_sleep_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT `chk_sleep_order` CHECK (`start_at` < `end_at`)
) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
-- Create "sleep_feedbacks" table
CREATE TABLE `sleep_feedbacks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `sleep_period_id` bigint unsigned NOT NULL,
  `action` enum('confirm','reject','edit') NOT NULL,
  `old_start_at` datetime(6) NULL,
  `old_end_at` datetime(6) NULL,
  `new_start_at` datetime(6) NULL,
  `new_end_at` datetime(6) NULL,
  `reason` varchar(255) NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  INDEX `fk_fb_sleep` (`sleep_period_id`),
  INDEX `idx_feedback_user_time` (`user_id`, `created_at`),
  CONSTRAINT `fk_fb_sleep` FOREIGN KEY (`sleep_period_id`) REFERENCES `sleep_periods` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT `fk_fb_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
-- Create "user_settings" table
CREATE TABLE `user_settings` (
  `user_id` bigint unsigned NOT NULL,
  `min_gap_minutes_for_sleep` int NOT NULL DEFAULT 180,
  `usual_bedtime_start` time NULL,
  `usual_bedtime_end` time NULL,
  `dnd_start` time NULL,
  `dnd_end` time NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_settings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
) CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
