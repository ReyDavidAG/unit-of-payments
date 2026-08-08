-- Functions, triggers and views. This is where the business rules live.

-- Next charge on or after p_from. Computed, never stored: a stored column goes stale on its own.
create or replace function public.next_charge_date(
  p_first date,
  p_cycle public.billing_cycle,
  p_custom_days int,
  p_from date default current_date
) returns date
language plpgsql
immutable
as $$
declare
  step interval := case p_cycle
    when 'weekly'  then interval '7 days'
    when 'monthly' then interval '1 month'
    when 'yearly'  then interval '1 year'
    when 'custom'  then make_interval(days => p_custom_days)
  end;
  n int := 0;
begin
  if step is null or step <= interval '0' then
    return null;
  end if;

  -- Always n*step from the original date. Adding step to the previous result drifts on month ends:
  -- Jan 31 -> Feb 28 -> Mar 28, instead of returning to Mar 31.
  -- ponytail: one iteration per elapsed cycle; swap for a closed form if it ever shows in a query plan.
  while (p_first + (n * step))::date < p_from loop
    n := n + 1;
    exit when n > 100000;
  end loop;

  return (p_first + (n * step))::date;
end;
$$;

-- Normalizes any cycle to a monthly cost, the only way weekly and yearly become comparable.
create or replace function public.monthly_amount(
  p_amount numeric,
  p_cycle public.billing_cycle,
  p_custom_days int
) returns numeric
language sql
immutable
as $$
  select round(p_amount * case p_cycle
    when 'weekly'  then 52.0 / 12
    when 'monthly' then 1
    when 'yearly'  then 1.0 / 12
    when 'custom'  then 30.4375 / p_custom_days
  end, 2);
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger subscriptions_set_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

-- Empty search_path: without it, security definer is a privilege escalation vector.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data ->> 'display_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- security_invoker is mandatory: without it the view runs as its owner and bypasses RLS.
create view public.v_subscriptions with (security_invoker = true) as
select
  s.*,
  c.alias as card_alias,
  c.brand as card_brand,
  c.color as card_color,
  public.next_charge_date(s.first_charge_date, s.cycle, s.custom_days) as next_charge_date,
  public.monthly_amount(s.amount, s.cycle, s.custom_days) as monthly_amount
from public.subscriptions s
  left join public.cards c on c.id = s.card_id
where s.active
  and (s.ends_on is null or s.ends_on >= current_date);

-- How much is owed per card alias.
create view public.v_card_totals with (security_invoker = true) as
select
  c.id as card_id,
  c.user_id,
  c.alias,
  c.brand,
  c.color,
  count(v.id) as subscription_count,
  coalesce(sum(v.monthly_amount), 0) as monthly_total,
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
