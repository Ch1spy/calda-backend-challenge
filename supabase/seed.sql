
-- CREATE EXAMPLE USERS
DO $$
DECLARE
  dmitri_id uuid := gen_random_uuid();
  anze_id uuid := gen_random_uuid();
  jost_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password, --bcrypt
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES
  (
    '00000000-0000-0000-0000-000000000000',
    dmitri_id,
    'authenticated',
    'authenticated',
    'dmitri.brglez+1@gmail.com',
    crypt('aoisd@i3nf!F', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Dmitri Brglez"}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    anze_id,
    'authenticated',
    'authenticated',
    'dmitri.brglez+2@gmail.com',
    crypt('aoisd@i3nf!F', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Anze Andlovec"}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    jost_id,
    'authenticated',
    'authenticated',
    'dmitri.brglez+3@gmail.com',
    crypt('aoisd@i3nf!F', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Jost Podobnik"}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  );

  -- Insert into identities table (required for auth to work properly)
  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES
  (
    gen_random_uuid(),
    dmitri_id,
    dmitri_id::text,
    format('{"sub":"%s","email":"dmitri.brglez+1@gmail.com"}', dmitri_id)::jsonb,
    'email',
    NOW(),
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    anze_id,
    anze_id::text,
    format('{"sub":"%s","email":"dmitri.brglez+2@gmail.com"}', anze_id)::jsonb,
    'email',
    NOW(),
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    jost_id,
    jost_id::text,
    format('{"sub":"%s","email":"dmitri.brglez+3@gmail.com"}', jost_id)::jsonb,
    'email',
    NOW(),
    NOW(),
    NOW()
  );

  -- EXAMPLE ITEMS

  INSERT INTO public.items (name, price_cents, currency, stock) VALUES
  ('Plezalni pas', 8990, 'EUR', 15),
  ('Plezalna čelada', 6499, 'EUR', 22),
  ('Cepin', 2999, 'EUR', 30),
  ('Dereze', 12900, 'EUR', 12),
  ('Varovalna vrv 40m', 15999, 'EUR', 8);

  -- EXAMPLE ORDERS
  
  INSERT INTO public.orders (
    user_id, 
    recipient_name, 
    shipping_address, 
    status,
    subtotal_cents,
    shipping_cents,
    total_cents
  ) VALUES (
    dmitri_id,
    'Dmitri Brglez',
    'Grabloviceva ulica 40, 1000 Ljubljana',
    'completed',
    15489,
    500,
    15989
  );

  INSERT INTO public.orders (
    user_id,
    recipient_name,
    shipping_address,
    status,
    subtotal_cents,
    shipping_cents,
    total_cents
  ) VALUES (
    anze_id,
    'Anze Andlovec',
    'Neki neki 10, 1215 Zbilje',
    'processing',
    31798,
    500,
    32298
  );

  INSERT INTO public.orders (
    user_id,
    recipient_name,
    shipping_address,
    status,
    subtotal_cents,
    shipping_cents,
    total_cents
  ) VALUES (
    jost_id,
    'Jost Podobnik',
    'Trubarjeva cesta 33, 1000 Ljubljana',
    'created',
    20979,
    500,
    21479
  );

  --INSERTING ORDER ITEMS

  
  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT 
    o.id,
    i.id,
    i.price_cents,
    1,
    i.price_cents * 1
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = dmitri_id
    AND i.name = 'Plezalna čelada';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT 
    o.id,
    i.id,
    i.price_cents,
    1,
    i.price_cents * 1
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = dmitri_id
    AND i.name = 'Plezalni pas';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT 
    o.id,
    i.id,
    i.price_cents,
    2,
    i.price_cents * 2
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = anze_id
    AND i.name = 'Dereze';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT 
    o.id,
    i.id,
    i.price_cents,
    2,
    i.price_cents * 2
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = anze_id
    AND i.name = 'Cepin';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT 
    o.id,
    i.id,
    i.price_cents,
    2,
    i.price_cents * 2
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = jost_id
    AND i.name = 'Plezalni pas';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT 
    o.id,
    i.id,
    i.price_cents,
    1,
    i.price_cents * 1
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = jost_id
    AND i.name = 'Cepin';

END $$;