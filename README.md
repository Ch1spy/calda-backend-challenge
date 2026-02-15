# Calda Backend Developer Challenge

E-commerce backend application built with Supabase.

## Prerequisites

- Supabase CLI
- Docker Desktop

## Setup

Clone and start:
```bash
git clone https://github.com/YOUR_USERNAME/calda-backend-challenge.git
cd calda-backend-challenge
supabase start
```

Access Studio at http://localhost:54323

## Test Users

The seed data creates 3 test users. Credentials are in the seed.sql file.

## Database

Tables: profiles, items, item_history, orders, order_items, weekly_order_rollups

Features:
- Row Level Security policies
- Automatic audit trail on items table
- Order details view with JSON aggregation
- Automated updated_at timestamps

## Edge Function

Endpoint: `POST /functions/v1/create-order`

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
EOF