alter table public.service_providers
  drop constraint if exists service_providers_role_check;

alter table public.service_providers
  add constraint service_providers_role_check
  check (role in (
    'Electrician',
    'Plumber',
    'AC Repair',
    'Cleaning',
    'Tutor',
    'Beautician',
    'General'
  ));

alter table public.service_providers
  add column if not exists availability_slots text[] not null
    default array['Today 4:00 PM', 'Tomorrow 10:00 AM'],
  add column if not exists jobs_completed integer not null
    default 120 check (jobs_completed >= 0);

alter table public.bookings
  add column if not exists slot_label text not null default 'Next available slot',
  add column if not exists confirmation_message text not null default '';

create table if not exists public.agent_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete cascade,
  sequence integer not null check (sequence > 0),
  agent_name text not null,
  step text not null,
  message text not null,
  tool_name text not null,
  status text not null default 'done'
    check (status in ('ready', 'done', 'scheduled', 'failed')),
  created_at timestamptz not null default now()
);

alter table public.agent_events enable row level security;

drop policy if exists "Users can read their own agent events" on public.agent_events;
create policy "Users can read their own agent events"
on public.agent_events for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own agent events" on public.agent_events;
create policy "Users can create their own agent events"
on public.agent_events for insert
to authenticated
with check ((select auth.uid()) = user_id);

grant select, insert on public.agent_events to authenticated;

insert into public.service_providers
  (id, name, role, reliability, distance_km, rating, price, avatar_url, verified, city, active, availability_slots, jobs_completed)
values
  ('00000000-0000-0000-0000-000000000007', 'Ayesha Tutors', 'Tutor', 0.940, 4, 4.9, 1200, 'https://i.pravatar.cc/100?img=17', true, 'Islamabad', true, array['Tomorrow 9:00 AM', 'Tomorrow 6:00 PM'], 128),
  ('00000000-0000-0000-0000-000000000008', 'Zara Beauty Studio', 'Beautician', 0.910, 7, 4.8, 1500, 'https://i.pravatar.cc/100?img=18', true, 'Islamabad', true, array['Today 7:00 PM', 'Tomorrow 1:00 PM'], 109)
on conflict (id) do update set
  role = excluded.role,
  reliability = excluded.reliability,
  distance_km = excluded.distance_km,
  rating = excluded.rating,
  price = excluded.price,
  avatar_url = excluded.avatar_url,
  verified = excluded.verified,
  city = excluded.city,
  active = excluded.active,
  availability_slots = excluded.availability_slots,
  jobs_completed = excluded.jobs_completed,
  updated_at = now();
