-- Functions, triggers and views for installments and card statements.

-- A cutoff day clamped to the month it lands in: day 31 in February is the 28th.
create or replace function public.cutoff_on(p_day smallint, p_in_month date)
returns date
language sql
immutable
as $$
  select least(
    date_trunc('month', p_in_month)::date + (p_day - 1),
    (date_trunc('month', p_in_month) + interval '1 month' - interval '1 day')::date
  );
$$;

-- The statement that closes on or after p_from.
create or replace function public.statement_close(p_day smallint, p_from date default current_date)
returns date
language sql
immutable
as $$
  select case
    when public.cutoff_on(p_day, p_from) >= p_from then public.cutoff_on(p_day, p_from)
    else public.cutoff_on(p_day, (p_from + interval '1 month')::date)
  end;
$$;

-- The first due day strictly after a close. Cutoff on the 20th with a due day
-- of the 10th means the 10th of the following month, not four days before.
create or replace function public.payment_due_after(p_due_day smallint, p_close date)
returns date
language sql
immutable
as $$
  select case
    when public.cutoff_on(p_due_day, p_close) > p_close then public.cutoff_on(p_due_day, p_close)
    else public.cutoff_on(p_due_day, (p_close + interval '1 month')::date)
  end;
$$;

-- Every actual charge date inside a window. monthly_amount() averages a cycle
-- into a comparable figure; a statement needs the real hits instead.
create or replace function public.charge_dates_between(
  p_first date,
  p_cycle public.billing_cycle,
  p_custom_days int,
  p_from date,
  p_to date
) returns setof date
language sql
immutable
as $$
  -- Always n*step from the original date, never step-from-previous: that is
  -- the month-end drift next_charge_date() exists to avoid.
  -- ponytail: 400 occurrences past the window start, far more than a statement
  -- can hold; widen it only if a cycle shorter than a day ever appears.
  select x.d
  from (
    select (p_first + (n * s.step))::date as d
    from (
      select
        case p_cycle
          when 'weekly'  then interval '7 days'
          when 'monthly' then interval '1 month'
          when 'yearly'  then interval '1 year'
          when 'custom'  then make_interval(days => p_custom_days)
        end as step,
        case p_cycle
          when 'weekly'  then greatest(0, (p_from - p_first) / 7 - 1)
          when 'monthly' then greatest(0, (extract(year from age(p_from, p_first)) * 12
                                         + extract(month from age(p_from, p_first)))::int - 1)
          when 'yearly'  then greatest(0, extract(year from age(p_from, p_first))::int - 1)
          when 'custom'  then greatest(0, (p_from - p_first) / nullif(p_custom_days, 0) - 1)
        end as n0
    ) s
    cross join lateral generate_series(s.n0, s.n0 + 400) as n
    where s.step > interval '0'
  ) x
  where x.d between p_from and p_to;
$$;

-- Charges already taken. Never stored: the card charges itself, so "paid" is
-- "the date passed", and a counter would only drift from the truth.
create or replace function public.installments_paid(
  p_first date,
  p_total int,
  p_on date default current_date
) returns int
language sql
immutable
as $$
  select case
    when p_total is null then null
    when p_first > p_on then 0
    else least(p_total, (extract(year from age(p_on, p_first)) * 12
                       + extract(month from age(p_on, p_first)))::int + 1)
  end;
$$;

-- installments_total is what the user thinks in; ends_on is what the views
-- filter on. Deriving one from the other means they cannot disagree, and an
-- installment plan switches itself off the moment it is settled.
create or replace function public.set_installment_end()
returns trigger
language plpgsql
as $$
begin
  if new.kind = 'installment' then
    new.ends_on := (new.first_charge_date
                    + make_interval(months => new.installments_total - 1))::date;
  end if;
  return new;
end;
$$;

create trigger subscriptions_set_installment_end
  before insert or update on public.subscriptions
  for each row execute function public.set_installment_end();

-- Rebuilt rather than replaced: the dependent views below were defined with
-- select *, so they keep the old column list unless they are recreated too.
drop view if exists public.v_upcoming;
drop view if exists public.v_card_totals;
drop view if exists public.v_subscriptions;

create view public.v_subscriptions with (security_invoker = true) as
select
  s.*,
  c.alias as card_alias,
  c.brand as card_brand,
  c.color as card_color,
  public.next_charge_date(s.first_charge_date, s.cycle, s.custom_days) as next_charge_date,
  public.monthly_amount(s.amount, s.cycle, s.custom_days) as monthly_amount,
  public.installments_paid(s.first_charge_date, s.installments_total) as installments_paid,
  case when s.installments_total is null then null
       else s.installments_total
            - public.installments_paid(s.first_charge_date, s.installments_total)
  end as installments_left,
  -- Zero for open-ended subscriptions, so a card's outstanding debt is a plain sum.
  case when s.installments_total is null then 0
       else s.amount * (s.installments_total
            - public.installments_paid(s.first_charge_date, s.installments_total))
  end as outstanding
from public.subscriptions s
  left join public.cards c on c.id = s.card_id
where s.active
  and (s.ends_on is null or s.ends_on >= current_date);

create view public.v_card_totals with (security_invoker = true) as
select
  c.id as card_id,
  c.user_id,
  c.alias,
  c.brand,
  c.color,
  count(v.id) as subscription_count,
  count(v.id) filter (where v.kind = 'installment') as installment_count,
  coalesce(sum(v.monthly_amount), 0) as monthly_total,
  coalesce(sum(v.monthly_amount) filter (where v.owed_by is not null), 0) as monthly_owed_by_others,
  coalesce(sum(v.outstanding), 0) as outstanding_total,
  min(v.next_charge_date) as next_charge_date
from public.cards c
  left join public.v_subscriptions v on v.card_id = c.id
where not c.archived
group by c.id, c.user_id, c.alias, c.brand, c.color;

create view public.v_upcoming with (security_invoker = true) as
select *
from public.v_subscriptions
where next_charge_date <= current_date + 30
order by next_charge_date;

-- Who owes the user money, and how much of it is still coming.
create view public.v_debtors with (security_invoker = true) as
select
  v.user_id,
  v.owed_by,
  count(*) as plan_count,
  coalesce(sum(v.monthly_amount), 0) as monthly_amount,
  coalesce(sum(v.outstanding), 0) as outstanding,
  min(v.next_charge_date) as next_charge_date
from public.v_subscriptions v
where v.owed_by is not null
group by v.user_id, v.owed_by;

-- The open statement per card: what closes, when it must be paid, and how much
-- of the total someone else is repaying.
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
