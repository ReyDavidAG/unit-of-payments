-- Past charges, derived per subscription from its first_charge_date and
-- cycle. One row per (subscription, historical charge date). Today's
-- "charge" is excluded — the bank may or may not have processed it, and
-- showing it would be a guess.
--
-- Cancelled subscriptions are excluded: their rows have a status flag but
-- still live in the table, and dragging them into history would mix
-- "I stopped paying for this" with "I paid this".
create or replace view public.v_charge_history with (security_invoker = true) as
select
  s.id   as subscription_id,
  s.name as subscription_name,
  s.amount,
  c.alias  as card_alias,
  c.color  as card_color,
  d.d      as charge_date
from public.subscriptions s
left join public.cards c on c.id = s.card_id
cross join lateral public.charge_dates_between(
  s.first_charge_date,
  s.cycle,
  s.custom_days,
  s.first_charge_date,
  current_date - 1
) d
where s.status <> 'cancelled'
order by d.d desc;