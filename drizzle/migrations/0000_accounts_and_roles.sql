create type public.app_role as enum ('girl','servant','admin');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_.]{3,32}$'),
  full_name text not null check (char_length(full_name) between 2 and 80),
  schedule_completed boolean not null default false,
  created_at timestamptz not null default now()
);
grant select, update on public.profiles to authenticated;
grant all on public.profiles to service_role;
alter table public.profiles enable row level security;

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  role public.app_role not null,
  unique (user_id)
);
grant select on public.user_roles to authenticated;
grant all on public.user_roles to service_role;
alter table public.user_roles enable row level security;

create or replace function public.has_role(_user_id uuid, _role public.app_role)
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.user_roles where user_id = _user_id and role = _role) $$;

create policy "Own profile readable" on public.profiles for select to authenticated using (auth.uid() = id);
create policy "Admins read profiles" on public.profiles for select to authenticated using (public.has_role(auth.uid(),'admin'));
create policy "Own role readable" on public.user_roles for select to authenticated using (auth.uid() = user_id);
create policy "Admins read roles" on public.user_roles for select to authenticated using (public.has_role(auth.uid(),'admin'));

-- users may only flip their own schedule flag; identity columns are locked
revoke update on public.profiles from authenticated;
grant update (schedule_completed) on public.profiles to authenticated;
create policy "Own schedule flag" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);