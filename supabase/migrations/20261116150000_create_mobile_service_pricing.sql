-- Online service pricing for the Alishams mobile app.
create table public.mobile_service_pricing (
  service_key text primary key,
  service_name text not null,
  min_price bigint not null default 0 check (min_price >= 0),
  max_price bigint not null default 0 check (max_price >= min_price),
  unit text not null,
  is_quote boolean not null default false,
  options jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  sort_order integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.mobile_service_pricing enable row level security;

create policy "Public can read mobile service pricing"
  on public.mobile_service_pricing
  for select
  to anon, authenticated
  using (true);

grant select on public.mobile_service_pricing to anon, authenticated;
revoke insert, update, delete on public.mobile_service_pricing from anon, authenticated;
grant all on public.mobile_service_pricing to service_role;

insert into public.mobile_service_pricing
(service_key, service_name, min_price, max_price, unit, is_quote, options, sort_order)
values
('motion_graphics', 'موشن‌گرافیک', 1750000, 25000000, 'پروژه', false, '[]'::jsonb, 1),
('website_design', 'طراحی وبسایت و قالب وبلاگ', 13795000, 150000000, 'پروژه', false, '[]'::jsonb, 2),
('blog_template', 'طراحی قالب اختصاصی وبلاگ', 650000, 650000, 'قالب', false, '[]'::jsonb, 3),
('reels_video', 'ریلز و محتوای ویدئویی', 2000000, 18000000, 'ویدئو', false, '[]'::jsonb, 4),
('ad_trailer', 'تیزر تبلیغاتی', 695000, 7850000, 'تیزر', false, '[]'::jsonb, 5),
('social_security', 'امنیت شبکه‌های اجتماعی', 8000000, 8000000, 'ماه', false, '[]'::jsonb, 6),
('logo_design', 'طراحی لوگو اختصاصی', 1550000, 22000000, 'لوگو', false, '[]'::jsonb, 7),
('website_article', 'نگارش مقاله وب‌سایت', 1250000, 7000000, 'مقاله', false, '[]'::jsonb, 8),
('online_consulting', 'مشاوره کسب‌وکار آنلاین', 2750000, 2750000, 'جلسه', false,
 '[{"label":"جلسه‌ای","min":2750000,"max":2750000,"unit":"جلسه"},{"label":"پروژه‌ای","min":7000000,"max":7000000,"unit":"پروژه"}]'::jsonb, 9),
('seo', 'خدمات SEO', 36000000, 36000000, 'پروژه', false,
 '[{"label":"پروژه‌ای","min":36000000,"max":36000000,"unit":"پروژه"},{"label":"ماهانه","min":9000000,"max":9000000,"unit":"ماه"}]'::jsonb, 10),
('social_media_services', 'خدمات شبکه‌های اجتماعی', 0, 0, 'استعلام', true, '[]'::jsonb, 11),
('advertising_promotion', 'تبلیغات و معرفی', 0, 0, 'استعلام', true, '[]'::jsonb, 12)
on conflict (service_key) do update set
  service_name = excluded.service_name,
  min_price = excluded.min_price,
  max_price = excluded.max_price,
  unit = excluded.unit,
  is_quote = excluded.is_quote,
  options = excluded.options,
  sort_order = excluded.sort_order,
  updated_at = now();
