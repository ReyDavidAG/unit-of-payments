-- The scheduler upserts with on_conflict=subscription_id,charge_date, and
-- ON CONFLICT can only infer a NON-partial unique index. The partial ones
-- introduced with the card notices made every sync fail with 42P10, which took
-- the whole Avisos screen down with it.
--
-- Dropping the predicates keeps the same guarantee: nulls are distinct in a
-- unique index, so a card notice (subscription_id null) never collides on the
-- subscription key, and a subscription notice (card_id null) never collides on
-- the card key.

drop index if exists public.notif_once_sub;
drop index if exists public.notif_once_card;

create unique index notif_once_sub
  on public.notification_log (subscription_id, charge_date);

create unique index notif_once_card
  on public.notification_log (card_id, charge_date, kind);
