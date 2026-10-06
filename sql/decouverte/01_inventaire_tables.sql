-- 01 — Inventaire des tables de l'export GA4
-- Question : quelles tables quotidiennes existent, quand sont-elles arrivées,
-- quelle taille font-elles, et quand expirent-elles (bac à sable : 60 jours) ?
-- Lecture seule. Aucune donnée utilisateur.

SELECT
  t.table_id                                AS table_name,
  TIMESTAMP_MILLIS(t.creation_time)         AS creee_le_utc,
  TIMESTAMP_MILLIS(t.last_modified_time)    AS modifiee_le_utc,
  t.row_count                               AS lignes,
  ROUND(t.size_bytes / POW(10, 6), 1)       AS taille_mo,
  o.option_value                            AS expire_le
FROM `ga4-chemin-form.analytics_383563328.__TABLES__` AS t
LEFT JOIN `ga4-chemin-form.analytics_383563328.INFORMATION_SCHEMA.TABLE_OPTIONS` AS o
  ON o.table_name = t.table_id
 AND o.option_name = 'expiration_timestamp'
ORDER BY t.table_id;
