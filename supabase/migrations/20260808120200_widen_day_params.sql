-- The day functions took smallint, which made them uncallable with a plain
-- integer literal: Postgres will not implicitly narrow int to smallint when
-- resolving a function. The views passed smallint columns and worked, so only
-- hand-written queries hit it. A smallint parameter saves nothing anyway.
--
-- Argument types cannot be changed in place, and v_card_statement depends on
-- all three, so it comes down with them and goes straight back up.

drop view if exists public.v_card_statement;
drop function if exists public.payment_due_after(smallint, date);
drop function if exists public.statement_close(smallint, date);
drop function if exists public.cutoff_on(smallint, date);

create or replace function public.cutoff_on(p_day int, p_in_month date)
returns date
language sql
immutable
as $$
  select least(
    date_trunc('month', p_in_month)::date + (p_day - 1),
    (date_trunc('month', p_in_month) + interval '1 month' - interval '1 day')::date
  );
$$;

create or replace function public.statement_close(p_day int, p_from date default current_date)
returns date
language sql
immutable
as $$
  select case
    when public.cutoff_on(p_day, p_from) >= p_from then public.cutoff_on(p_day, p_from)
    else public.cutoff_on(p_day, (p_from + interval '1 month')::date)
  end;
$$;

create or replace function public.payment_due_after(p_due_day int, p_close date)
returns date
language sql
immutable
as $$
  select case
    when public.cutoff_on(p_due_day, p_close) > p_close then public.cutoff_on(p_due_day, p_close)
    else public.cutoff_on(p_due_day, (p_close + interval '1 month')::date)
  end;
$$;

create view public.v_card_statement with (security_invoker = true) as
with statement as (
  select
    c.id as card_id,
    c.user_id,
    c.alias,
    c.color,
    c.cutoff_day,
    c.payment_due_day,
    public.statement_close(c.cutoff_day) as closes_on,
    public.cutoff_on(
      c.cutoff_day,
      (public.statement_close(c.cutoff_day) - interval '1 month')::date
    ) as opens_after
  from public.cards c
  where not c.archived and c.cutoff_day is not null
)
select
  w.card_id,
  w.user_id,
  w.alias,
  w.color,
  w.cutoff_day,
  w.payment_due_day,
  w.opens_after,
  w.closes_on,
  case when w.payment_due_day is null then null
       else public.payment_due_after(w.payment_due_day, w.closes_on)
  end as due_on,
  coalesce(sum(l.line_total), 0) as total_due,
  coalesce(sum(l.owed_total), 0) as owed_by_others,
  coalesce(sum(l.line_total), 0) - coalesce(sum(l.owed_total), 0) as yours,
  count(l.subscription_id) as line_count
from statement w
  left join lateral (
    select
      s.id as subscription_id,
      s.amount * count(*) as line_total,
      case when s.owed_by is null then 0 else s.amount * count(*) end as owed_total
    from public.subscriptions s
      cross join public.charge_dates_between(
        s.first_charge_date, s.cycle, s.custom_days,
        (w.opens_after + 1),
        least(w.closes_on, coalesce(s.ends_on, w.closes_on))
      ) as d
    where s.card_id = w.card_id and s.active
    group by s.id, s.amount, s.owed_by
  ) l on true
group by
  w.card_id, w.user_id, w.alias, w.color,
  w.cutoff_day, w.payment_due_day, w.opens_after, w.closes_on;
