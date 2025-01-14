DO LANGUAGE plpgsql $$
DECLARE
	ver integer;
	partners integer;
	res text := 0;
BEGIN
	SELECT current_setting('server_version_num') INTO ver;
	SELECT count(*) FROM pg_stat_replication INTO partners;

	IF (partners != 0) THEN
		IF (ver >= 100000) THEN
			SELECT * INTO res from (
				SELECT
					CASE WHEN pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn()
						THEN 0
						ELSE COALESCE(EXTRACT(EPOCH FROM now() - pg_last_xact_replay_timestamp())::integer, 0)
					END
				) T;

		ELSE
			SELECT * INTO res from (
				SELECT
					CASE WHEN pg_last_xlog_receive_location() = pg_last_xlog_replay_location()
						THEN 0
						ELSE COALESCE(EXTRACT(EPOCH FROM now() - pg_last_xact_replay_timestamp())::integer, 0)
					END
				) T;
		END IF;
	END IF;

	perform set_config('zbx_tmp.repl_lag_res', res, false);
END $$;

select current_setting('zbx_tmp.repl_lag_res');
