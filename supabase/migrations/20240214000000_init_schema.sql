create extension if not exists "pg_cron";
-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to automatically update updated_at timestamp
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Function to get current authenticated user ID
create or replace function public.current_user_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

-- ============================================
-- TABLES
-- ============================================

-- Profiles table (extends auth.users)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Items table
create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price_cents int not null check (price_cents >= 0),
  currency text not null default 'EUR',
  stock int not null default 0 check (stock >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Item history
create table if not exists public.item_history (
  id bigint generated always as identity primary key,
  item_id uuid not null,
  action text not null check (action in ('INSERT','UPDATE','DELETE')),
  changed_by uuid,
  changed_at timestamptz not null default now(),
  old_row jsonb,
  new_row jsonb,
  constraint fk_item_history_item
    foreign key (item_id) references public.items(id) on delete cascade
);

-- Orders table
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  recipient_name text not null,
  shipping_address text not null,
  status text not null default 'created',
  subtotal_cents int not null default 0 check (subtotal_cents >= 0),
  shipping_cents int not null default 0 check (shipping_cents >= 0),
  total_cents int not null default 0 check (total_cents >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Order items table
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  item_id uuid not null references public.items(id),
  unit_price_cents int not null check (unit_price_cents >= 0),
  quantity int not null check (quantity > 0),
  line_total_cents int not null check (line_total_cents >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(order_id, item_id)
);

-- Weekly order rollups cron job
create table if not exists public.weekly_order_rollups (
  id bigint generated always as identity primary key,
  window_start timestamptz not null,
  window_end timestamptz not null,
  rolled_up_total_cents bigint not null,
  rolled_up_at timestamptz not null default now()
);

-- ============================================
-- TRIGGERS: Auto-update updated_at
-- ============================================

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger trg_items_updated_at
  before update on public.items
  for each row execute function public.set_updated_at();

create trigger trg_orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

create trigger trg_order_items_updated_at
  before update on public.order_items
  for each row execute function public.set_updated_at();

-- ============================================
-- TRIGGER: Track all changes to items
-- ============================================

create or replace function public.audit_items_changes()
returns trigger
language plpgsql
as $$
declare
  v_user uuid;
begin
  v_user := auth.uid();

  if (tg_op = 'INSERT') then
    insert into public.item_history(item_id, action, changed_by, old_row, new_row)
    values (new.id, 'INSERT', v_user, null, to_jsonb(new));
    return new;
  elsif (tg_op = 'UPDATE') then
    insert into public.item_history(item_id, action, changed_by, old_row, new_row)
    values (new.id, 'UPDATE', v_user, to_jsonb(old), to_jsonb(new));
    return new;
  elsif (tg_op = 'DELETE') then
    insert into public.item_history(item_id, action, changed_by, old_row, new_row)
    values (old.id, 'DELETE', v_user, to_jsonb(old), null);
    return old;
  end if;

  return null;
end;
$$;

create trigger trg_items_audit
  after insert or update or delete on public.items
  for each row execute function public.audit_items_changes();

-- ============================================
-- AUTO-CREATE PROFILE FOR NEW USERS
-- ============================================

create or replace function public.handle_new_user() 
returns trigger 
language plpgsql 
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================
-- RLS POLICIES
-- ============================================

-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.item_history enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.weekly_order_rollups enable row level security;

-- Profiles: users can only see/edit their own profile
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (user_id = auth.uid());

create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Items: any authenticated user has full CRUD access
create policy "items_crud_authenticated"
  on public.items for all
  to authenticated
  using (true)
  with check (true);

-- Item history: authenticated users can read
create policy "item_history_read_authenticated"
  on public.item_history for select
  to authenticated
  using (true);

-- Orders: users can only see their own orders
create policy "orders_select_own"
  on public.orders for select
  to authenticated
  using (user_id = auth.uid());

create policy "orders_insert_own"
  on public.orders for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "orders_update_own"
  on public.orders for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "orders_delete_own"
  on public.orders for delete
  to authenticated
  using (user_id = auth.uid());

-- Order items: must belong to orders owned by the user
create policy "order_items_select_own_orders"
  on public.order_items for select
  to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.user_id = auth.uid()
    )
  );

create policy "order_items_insert_own_orders"
  on public.order_items for insert
  to authenticated
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.user_id = auth.uid()
    )
  );

create policy "order_items_update_own_orders"
  on public.order_items for update
  to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.user_id = auth.uid()
    )
  );

create policy "order_items_delete_own_orders"
  on public.order_items for delete
  to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.user_id = auth.uid()
    )
  );

-- Weekly rollups: authenticated users can read
create policy "weekly_rollups_read_authenticated"
  on public.weekly_order_rollups for select
  to authenticated
  using (true);

-- ============================================
-- VIEW: Order details with items
-- ============================================

create or replace view public.v_order_details
with (security_invoker = on)
as
select
  o.id,
  o.user_id,
  o.recipient_name,
  o.shipping_address,
  o.status,
  o.subtotal_cents,
  o.shipping_cents,
  o.total_cents,
  o.created_at,
  o.updated_at,
  coalesce(
    jsonb_agg(
      jsonb_build_object(
        'order_item_id', oi.id,
        'item_id', oi.item_id,
        'quantity', oi.quantity,
        'unit_price_cents', oi.unit_price_cents,
        'line_total_cents', oi.line_total_cents
      )
      order by oi.created_at
    ) filter (where oi.id is not null),
    '[]'::jsonb
  ) as order_items
from public.orders o
left join public.order_items oi on oi.order_id = o.id
group by o.id;

-- ============================================
-- CRON FUNCTION: Rollup old orders
-- ============================================

create or replace function public.rollup_and_delete_old_orders()
returns void
language plpgsql
as $$
declare
  v_window_end timestamptz := now();
  v_window_start timestamptz := now() - interval '1 week';
  v_sum bigint;
begin
  -- Sum totals of orders older than 1 week
  select coalesce(sum(total_cents), 0)
  into v_sum
  from public.orders
  where created_at < v_window_start;

  -- Store the rollup
  insert into public.weekly_order_rollups(window_start, window_end, rolled_up_total_cents)
  values (v_window_start, v_window_end, v_sum);

  -- Delete old orders
  delete from public.orders
  where created_at < v_window_start;
end;
$$;

-- Schedule cron job (runs every Monday at 8:00 AM UTC)
select cron.schedule(
  'weekly-order-cleanup',
  '0 7 * * 1',
  $$ select public.rollup_and_delete_old_orders(); $$
);