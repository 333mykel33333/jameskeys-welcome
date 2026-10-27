CREATE TABLE IF NOT EXISTS `jameskeys_welcome_claims` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(96) NOT NULL,
    `claimed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `chosen_vehicle` VARCHAR(64) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_jameskeys_welcome_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ox_inventory imports ESX items from this table when it starts.
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`)
VALUES ('house_robbery_tablet', 'House Robbery Tablet', 500, 0, 1)
ON DUPLICATE KEY UPDATE
    `label` = VALUES(`label`),
    `weight` = VALUES(`weight`),
    `can_remove` = VALUES(`can_remove`);
