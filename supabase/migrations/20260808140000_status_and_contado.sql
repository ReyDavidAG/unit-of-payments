-- Three states where there was one boolean, and a one-payment installment.
--
-- `active` could say "running" or "gone" but never "paused, I'll resume it".
-- Three states in one boolean is where the bug farm starts, so the boolean is
-- replaced outright rather than paired with a second flag that can disagree.

create type public.subscription_status as enum ('active', 'paused', 'cancelled');

alter table public.subscriptions
  add column status public.subscription_status not null default 'active';

-- Every soft-deleted row predates pausing, so it can only have meant cancelled.
update public.subscriptions set status = 'cancelled' where not active;

-- Rebuilt at the bottom; each one reads s.active and would block the drop.
drop view if exists public.v_card_statement;
drop view if exists public.v_upcoming;
drop view if exists public.v_debtors;
drop view if exists public.v_card_totals;
drop view if exists public.v_subscriptions;

alter table public.subscriptions drop column active;

-- Contado: paid once, settled on the next statement. It is an installment plan
-- of length one — the same trigger sets ends_on to the charge date and the same
-- progress maths reads 1 de 1. No second code path anywhere.
alter table public.subscriptions
  drop constraint subs_installments,
  add constraint subs_installments check (
    (kind = 'installment' and installments_total between 1 and 60 and cycle = 'monthly')
    or (kind = 'subscription' and installments_total is null)
  );

-- Carries paused rows now: the list has to show one to offer resuming it.
-- Only cancelled disappears, and only settled plans age out.
create view public.v_subscriptions with (security_invoker = true) as
select
  s.*,
  c.alias as card_alias,
  c.brand as card_brand,
  c.color as card_color,
  -- The card is already hidden from every picker; the charge that still points
  -- at it is the thing that needs to say so.
  coalesce(c.archived, false) as card_archived,
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
where s.status <> 'cancelled'
  and (s.ends_on is null or s.ends_on >= current_date);

-- Everything downstream is about money that will actually move, so all four
-- filter to 'active'. A paused charge costs nothing this month.
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
  -- In the join, not the where: a card whose charges are all paused still
  -- belongs on the dashboard, reading zero.
  left join public.v_subscriptions v
    on v.card_id = c.id and v.status = 'active'
where not c.archived
group by c.id, c.user_id, c.alias, c.brand, c.color;

create view public.v_upcoming with (security_invoker = true) as
select *
from public.v_subscriptions
where status = 'active'
  and next_charge_date <= current_date + 30
order by next_charge_date;

create view public.v_debtors with (security_invoker = true) as
select
  v.user_id,
  v.owed_by,
  count(*) as plan_count,
  coalesce(sum(v.monthly_amount), 0) as monthly_amount,
  coalesce(sum(v.outstanding), 0) as outstanding,
  min(v.next_charge_date) as next_charge_date
from public.v_subscriptions v
where v.owed_by is not null and v.status = 'active'
group by v.user_id, v.owed_by;

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
    where s.card_id = w.card_id and s.status = 'active'
    group by s.id, s.amount, s.owed_by
  ) l on true
group by
  w.card_id, w.user_id, w.alias, w.color,
  w.cutoff_day, w.payment_due_day, w.opens_after, w.closes_on;
