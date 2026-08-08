-- End-to-end check for installments, third-party debt and the statement view.
-- Writes real rows, asserts against them, then raises to roll the whole thing
-- back. Success looks like: ERROR: SMOKE OK -- all assertions passed.
--
-- Every expectation is relative to current_date. Pinning literal dates here
-- would make the file pass today and fail on its own in a fortnight.

do $$
declare
  v_user   uuid;
  v_card   uuid;
  v_sub    uuid;
  v_end    date;
  v_paid   int;
  v_left   int;
  v_out    numeric;
  v_total  numeric;
  v_owed   numeric;
  v_yours  numeric;
  v_opens  date;
  v_closes date;
  v_due    date;
  v_bad    boolean;
  v_count  int;
  v_cash   uuid;
  v_arch   boolean;
begin
  select id into v_user from auth.users limit 1;
  if v_user is null then
    raise exception 'SMOKE: no auth users to test against';
  end if;

  insert into public.cards (user_id, alias, brand, cutoff_day, payment_due_day, color)
  values (v_user, '__smoke__', 'visa', 20, 10, '#494ECF')
  returning id into v_card;

  -- Something bought on 12 months, first charge today, repaid by someone else.
  insert into public.subscriptions
    (user_id, card_id, name, amount, cycle, first_charge_date, kind, installments_total, owed_by)
  values (v_user, v_card, '__smoke_msi__', 1000, 'monthly', current_date, 'installment', 12, '__smoke_juan__')
  returning id into v_sub;

  -- The trigger derives the end from the count, so they cannot disagree.
  select ends_on into v_end from public.subscriptions where id = v_sub;
  assert v_end = (current_date + interval '11 months')::date,
    format('ends_on = %s, want %s', v_end, (current_date + interval '11 months')::date);

  -- Progress is derived from dates: the first charge lands today.
  select installments_paid, installments_left, outstanding
    into v_paid, v_left, v_out
    from public.v_subscriptions where id = v_sub;
  assert v_paid = 1,     format('installments_paid = %s, want 1', v_paid);
  assert v_left = 11,    format('installments_left = %s, want 11', v_left);
  assert v_out = 11000,  format('outstanding = %s, want 11000', v_out);

  select opens_after, closes_on, due_on, total_due, owed_by_others, yours
    into v_opens, v_closes, v_due, v_total, v_owed, v_yours
    from public.v_card_statement where card_id = v_card;

  -- Today always sits inside the open statement, whatever the cutoff day is.
  assert v_opens < current_date,   format('opens_after %s is not before today', v_opens);
  assert v_closes >= current_date, format('closes_on %s is before today', v_closes);
  assert v_due > v_closes,         format('due_on %s must fall after the close %s', v_due, v_closes);
  assert v_due <= v_closes + 62,   format('due_on %s is more than two months past the close', v_due);

  -- So today's charge is in it, and all of it is someone else's to repay.
  assert v_total = 1000, format('total_due = %s, want 1000', v_total);
  assert v_owed  = 1000, format('owed_by_others = %s, want 1000', v_owed);
  assert v_yours = 0,    format('yours = %s, want 0', v_yours);

  select outstanding into v_out from public.v_debtors where owed_by = '__smoke_juan__';
  assert v_out = 11000, format('v_debtors outstanding = %s, want 11000', v_out);

  -- A cutoff notice hangs off the card and carries no subscription.
  insert into public.notification_log
    (user_id, card_id, kind, charge_date, scheduled_for, amount, title)
  values (v_user, v_card, 'payment_due', v_due, now(), v_total, '__smoke_notice__')
  on conflict (card_id, charge_date, kind) do nothing;

  -- The exact conflict target the client infers on every scheduler run. A
  -- partial unique index cannot be inferred and raises 42P10 here, which is
  -- what took the whole notices screen down once already.
  for v_count in 1 .. 2 loop
    insert into public.notification_log
      (user_id, subscription_id, kind, charge_date, scheduled_for, amount, title)
    values (v_user, v_sub, 'charge', current_date, now(), 1000, '__smoke_charge__')
    on conflict (subscription_id, charge_date) do nothing;
  end loop;

  select count(*) into v_count
    from public.notification_log
   where subscription_id = v_sub and charge_date = current_date;
  assert v_count = 1, format('the upsert wrote %s rows, want 1', v_count);

  -- And the XOR refuses a row that claims both targets.
  begin
    insert into public.notification_log
      (user_id, card_id, subscription_id, kind, charge_date, scheduled_for, amount, title)
    values (v_user, v_card, v_sub, 'charge', current_date, now(), 1000, '__smoke_bad__');
    v_bad := true;
  exception when check_violation then
    v_bad := false;
  end;
  assert not v_bad, 'notif_target_xor accepted a notice with both a card and a subscription';

  -- Contado is a one-payment plan, so it settles on the day it is charged and
  -- the trigger has nothing left to add.
  insert into public.subscriptions
    (user_id, card_id, name, amount, cycle, first_charge_date, kind, installments_total)
  values (v_user, v_card, '__smoke_cash__', 500, 'monthly', current_date, 'installment', 1)
  returning id into v_cash;

  select ends_on into v_end from public.subscriptions where id = v_cash;
  assert v_end = current_date, format('contado ends_on = %s, want today', v_end);

  select installments_paid, installments_left, outstanding
    into v_paid, v_left, v_out
    from public.v_subscriptions where id = v_cash;
  assert v_paid = 1,   format('contado paid = %s, want 1', v_paid);
  assert v_left = 0,   format('contado left = %s, want 0', v_left);
  assert v_out  = 0,   format('contado outstanding = %s, want 0', v_out);

  -- Pausing keeps the row on the list but takes it out of every total, which
  -- is the whole difference between pausing and cancelling.
  update public.subscriptions set status = 'paused' where id = v_sub;

  select count(*) into v_count from public.v_subscriptions where id = v_sub;
  assert v_count = 1, 'a paused charge must stay visible so it can be resumed';

  select count(*) into v_count from public.v_upcoming where id = v_sub;
  assert v_count = 0, 'a paused charge must not be scheduled';

  select count(*) into v_count from public.v_debtors where owed_by = '__smoke_juan__';
  assert v_count = 0, 'a paused charge must not count as debt someone owes';

  select total_due into v_total from public.v_card_statement where card_id = v_card;
  assert v_total = 500, format('paused charge still on the statement: total_due = %s, want 500', v_total);

  update public.subscriptions set status = 'cancelled' where id = v_sub;
  select count(*) into v_count from public.v_subscriptions where id = v_sub;
  assert v_count = 0, 'a cancelled charge must leave the list';

  -- Archiving the card leaves the charge pointing at it, and the view has to
  -- say so — that flag is the only warning the list can draw.
  update public.cards set archived = true where id = v_card;
  select card_archived into v_arch from public.v_subscriptions where id = v_cash;
  assert v_arch, 'card_archived must be true once the card is archived';

  raise exception 'SMOKE OK -- all assertions passed, rolling back';
end $$;
