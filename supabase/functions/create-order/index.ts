import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) throw new Error("Unauthorized");

    const { recipient_name, shipping_address, items } = await req.json();

    // Get item prices
    const { data: itemsData, error: itemsError } = await supabaseClient
      .from("items")
      .select("id, price_cents")
      .in("id", items.map(i => i.item_id));

    if (itemsError) throw itemsError;

    // Calculate totals and prepare order items
    let subtotal_cents = 0;
    const orderItems = items.map(orderItem => {
      const item = itemsData.find(i => i.id === orderItem.item_id);
      if (!item) throw new Error(`Item ${orderItem.item_id} not found`);
      
      const line_total = item.price_cents * orderItem.quantity;
      subtotal_cents += line_total;

      return {
        item_id: orderItem.item_id,
        quantity: orderItem.quantity,
        unit_price_cents: item.price_cents,
        line_total_cents: line_total,
      };
    });

    const shipping_cents = 500;
    const total_cents = subtotal_cents + shipping_cents;

    // Insert order
    const { data: order, error: orderError } = await supabaseClient
      .from("orders")
      .insert({
        user_id: user.id,
        recipient_name,
        shipping_address,
        status: "created",
        subtotal_cents,
        shipping_cents,
        total_cents,
      })
      .select()
      .single();

    if (orderError) throw orderError;

    // Insert order items
    const { error: orderItemsError } = await supabaseClient
      .from("order_items")
      .insert(orderItems.map(item => ({ ...item, order_id: order.id })));

    if (orderItemsError) throw orderItemsError;

    // Calculate total of all other orders
    const { data: allOrders, error: allOrdersError } = await supabaseClient
      .from("orders")
      .select("total_cents")
      .neq("id", order.id);

    if (allOrdersError) throw allOrdersError;

    const other_orders_total = allOrders.reduce((sum, o) => sum + o.total_cents, 0);

    return new Response(
      JSON.stringify({
        success: true,
        order_id: order.id,
        order_total_cents: total_cents,
        other_orders_total_cents: other_orders_total,
        message: "Order created successfully",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
    );
  }
});