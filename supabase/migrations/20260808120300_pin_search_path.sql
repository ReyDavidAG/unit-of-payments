-- Same fix 20260807130000 applied to the original functions, now for the ones
-- added with installments. A mutable search_path lets a caller shadow an
-- unqualified name with their own schema and change what the function runs.
--
-- All six only call pg_catalog built-ins or already schema-qualified functions,
-- so pinning the path changes nothing about what they resolve to.

alter function public.cutoff_on(int, date) set search_path = '';
alter function public.statement_close(int, date) set search_path = '';
alter function public.payment_due_after(int, date) set search_path = '';
alter function public.installments_paid(date, int, date) set search_path = '';
alter function public.set_installment_end() set search_path = '';
alter function public.charge_dates_between(date, public.billing_cycle, int, date, date)
  set search_path = '';
