# Calda Backend Developer Challenge

E-commerce backend application built with Supabase.

## Prerequisites

- Supabase CLI
- Docker Desktop

## Setup

Clone and start:
```bash
git clone https://github.com/Ch1spy/calda-backend-challenge.git
cd calda-backend-challenge
supabase start
```

Access Studio at http://localhost:54323

## Test Users

The seed creates 3 test users for local testing (see seed.sql).

## Database

Tables: profiles, items, item_history, orders, order_items, weekly_order_rollups

Features:
- Row Level Security policies
- Automatic audit trail on items table
- Order details view with JSON aggregation
- Automated updated_at timestamps

## Edge Function

Endpoint: `POST /functions/v1/create-order`


### 1) Login (get access token)

```bash
curl -s 'http://127.0.0.1:54321/auth/v1/token?grant_type=password' \
  -H 'apikey: <LOCAL_PUBLISHABLE_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{"email":"<EMAIL_FROM_SEED>","password":"<PASSWORD_FROM_SEED>"}'
```

Copy `access_token` from the response.

### 2) Create order

```bash
curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/create-order' \
  --header 'apikey: <LOCAL_PUBLISHABLE_KEY>' \
  --header 'Authorization: Bearer <ACCESS_TOKEN>' \
  --header 'Content-Type: application/json' \
  --data '{
    "recipient_name": "Test User",
    "shipping_address": "Test Address 123, Ljubljana",
    "items": [
      { "item_id": "<VALID_ITEM_ID>", "quantity": 2 }
    ]
  }'
```

If you need an item id:

```sql
select id, name
from items
limit 5;
```

Accepts order with items, inserts into database, returns total of all other orders.

## CRON Job

Runs weekly: deletes orders older than 1 week, stores aggregated totals.

## Deployment
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase functions deploy create-order
```

## Author

Dmitri Brglez