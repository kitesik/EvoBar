-- EvoBar community comparison (opt-in). Run once in the Supabase SQL editor.
--
-- The app never reads the table directly. It calls report_usage(), which
-- upserts one row per install per UTC day and returns today's percentile
-- among all installs that reported today. The anon key can execute only
-- that function; it has no table privileges.

create table if not exists public.usage_reports (
    install_id       uuid        not null,
    day              date        not null,
    tokens           bigint      not null check (tokens >= 0),
    five_hour_tokens bigint      not null check (five_hour_tokens >= 0),
    app_version      text        not null default '',
    updated_at       timestamptz not null default now(),
    primary key (install_id, day)
);

alter table public.usage_reports enable row level security;
-- No policies on purpose: anon and authenticated roles cannot touch rows directly.
revoke all on public.usage_reports from anon, authenticated;

create or replace function public.report_usage(
    p_install uuid,
    p_tokens bigint,
    p_five_hour bigint,
    p_version text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_day date := (now() at time zone 'utc')::date;
    -- Clamp so one bogus client cannot distort the distribution.
    v_tokens bigint := least(greatest(p_tokens, 0), 500000000);
    v_five bigint := least(greatest(p_five_hour, 0), 100000000);
    v_total int;
    v_day_rank int;
    v_five_rank int;
begin
    insert into public.usage_reports (install_id, day, tokens, five_hour_tokens, app_version)
    values (p_install, v_day, v_tokens, v_five, left(coalesce(p_version, ''), 32))
    on conflict (install_id, day) do update
        set tokens = excluded.tokens,
            five_hour_tokens = excluded.five_hour_tokens,
            app_version = excluded.app_version,
            updated_at = now();

    select count(*),
           1 + count(*) filter (where tokens > v_tokens),
           1 + count(*) filter (where five_hour_tokens > v_five)
      into v_total, v_day_rank, v_five_rank
      from public.usage_reports
     where day = v_day;

    return jsonb_build_object(
        'sample', v_total,
        'dayRank', v_day_rank,
        'fiveHourRank', v_five_rank
    );
end;
$$;

revoke all on function public.report_usage(uuid, bigint, bigint, text) from public;
grant execute on function public.report_usage(uuid, bigint, bigint, text) to anon;

-- Retention: keep seven days. Requires the pg_cron extension (Database > Extensions).
create extension if not exists pg_cron;
select cron.schedule(
    'evobar-usage-retention',
    '15 3 * * *',
    $$delete from public.usage_reports where day < (now() at time zone 'utc')::date - 7$$
);
