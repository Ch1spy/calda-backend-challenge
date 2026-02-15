-- CREATE EXAMPLE USERS
DO $$
DECLARE
  user1_id uuid := gen_random_uuid();
  user2_id uuid := gen_random_uuid();
  user3_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password, -- bcrypt
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
    user1_id,
    'authenticated',
    'authenticated',
    'user1@example.com',
    crypt('password_123', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"User1"}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    user2_id,
    'authenticated',
    'authenticated',
    'user2@example.com',
    crypt('password_123', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"User2"}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    user3_id,
    'authenticated',
    'authenticated',
    'user3@example.com',
    crypt('password_123', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"User3"}',
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
    user1_id,
    user1_id::text,
    format('{"sub":"%s","email":"user1@example.com"}', user1_id)::jsonb,
    'email',
    NOW(),
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    user2_id,
    user2_id::text,
    format('{"sub":"%s","email":"user2@example.com"}', user2_id)::jsonb,
    'email',
    NOW(),
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    user3_id,
    user3_id::text,
    format('{"sub":"%s","email":"user3@example.com"}', user3_id)::jsonb,
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
    user1_id,
    'User1',
    'Test Address 1',
    'completed',
    15489,
    500,
    15989
  ),
  (
    user2_id,
    'User2',
    'Test Address 2',
    'processing',
    31798,
    500,
    32298
  ),
  (
    user3_id,
    'User3',
    'Test Address 3',
    'created',
    20979,
    500,
    21479
  );

  -- INSERTING ORDER ITEMS
  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT o.id, i.id, i.price_cents, 1, i.price_cents * 1
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = user1_id
    AND i.name = 'Plezalna čelada';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT o.id, i.id, i.price_cents, 1, i.price_cents * 1
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = user1_id
    AND i.name = 'Plezalni pas';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT o.id, i.id, i.price_cents, 2, i.price_cents * 2
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = user2_id
    AND i.name = 'Dereze';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT o.id, i.id, i.price_cents, 2, i.price_cents * 2
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = user2_id
    AND i.name = 'Cepin';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT o.id, i.id, i.price_cents, 2, i.price_cents * 2
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = user3_id
    AND i.name = 'Plezalni pas';

  INSERT INTO public.order_items (order_id, item_id, unit_price_cents, quantity, line_total_cents)
  SELECT o.id, i.id, i.price_cents, 1, i.price_cents * 1
  FROM public.orders o
  CROSS JOIN public.items i
  WHERE o.user_id = user3_id
    AND i.name = 'Cepin';

END $$;
