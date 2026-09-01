// ═══════════════════════════════════════════════════════
// Payment Reconciliation — Bellerox GPS
// Supabase Edge Function called by webhook
// Processes payment: extend subscription + unlock device + release slot
// ═══════════════════════════════════════════════════════

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const TRACCAR_API_URL = Deno.env.get('TRACCAR_API_URL') || 'https://gps.bellerox.com/api';
const TRACCAR_ADMIN_EMAIL = Deno.env.get('TRACCAR_ADMIN_EMAIL');
const TRACCAR_ADMIN_PASSWORD = Deno.env.get('TRACCAR_ADMIN_PASSWORD');

interface ReconcilePayload {
  device_id: number;
  invoice_id: string;
  amount: number;
  slot_number: number;
  bank_ref?: string;
  timestamp: string;
}

serve(async (req) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    const payload: ReconcilePayload = await req.json();

    console.log('[reconcile] Processing payment:', {
      device_id: payload.device_id,
      amount: payload.amount,
      slot: payload.slot_number,
    });

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Step 1: Get subscription info
    const { data: subscription, error: subError } = await supabase
      .from('billing_subscriptions')
      .select('*')
      .eq('device_id', payload.device_id)
      .single();

    if (subError || !subscription) {
      console.error('[reconcile] Subscription not found:', subError);
      return new Response(
        JSON.stringify({ error: 'Subscription not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Step 2: Extend subscription (+6 months)
    const currentEndDate = new Date(subscription.end_date);
    const newEndDate = new Date(currentEndDate);
    newEndDate.setMonth(newEndDate.getMonth() + 6);

    const { error: updateError } = await supabase
      .from('billing_subscriptions')
      .update({
        end_date: newEndDate.toISOString().split('T')[0],
        status: 'active',
      })
      .eq('device_id', payload.device_id);

    if (updateError) {
      console.error('[reconcile] Failed to extend subscription:', updateError);
      throw new Error('Failed to extend subscription');
    }

    console.log('[reconcile] Subscription extended to:', newEndDate.toISOString().split('T')[0]);

    // Step 3: Create payment event record
    const { error: paymentError } = await supabase
      .from('billing_payment_events')
      .insert({
        invoice_id: payload.invoice_id,
        method: 'qr30_webhook',
        amount_thb: payload.amount,
        verified_at: new Date().toISOString(),
        provider_ref: payload.bank_ref || `SLOT-${payload.slot_number}`,
        raw_response: {
          slot_number: payload.slot_number,
          timestamp: payload.timestamp,
          device_id: payload.device_id,
        },
      });

    if (paymentError) {
      console.error('[reconcile] Failed to record payment event:', paymentError);
      // Non-fatal - continue
    }

    // Step 4: Mark invoice as paid
    const { error: invoiceError } = await supabase
      .from('billing_invoices')
      .update({
        status: 'paid',
        paid_at: new Date().toISOString(),
      })
      .eq('invoice_ref', payload.invoice_id);

    if (invoiceError) {
      console.error('[reconcile] Failed to update invoice:', invoiceError);
      // Non-fatal - continue
    }

    // Step 5: Unlock device in Traccar
    if (TRACCAR_ADMIN_EMAIL && TRACCAR_ADMIN_PASSWORD) {
      try {
        // Login to Traccar
        const loginRes = await fetch(`${TRACCAR_API_URL}/session`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({
            email: TRACCAR_ADMIN_EMAIL,
            password: TRACCAR_ADMIN_PASSWORD,
          }),
        });

        if (loginRes.ok) {
          const sessionCookie = loginRes.headers.get('set-cookie');

          // Update device attributes (remove disabled flag)
          await fetch(`${TRACCAR_API_URL}/devices/${payload.device_id}`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              Cookie: sessionCookie || '',
            },
            body: JSON.stringify({
              id: payload.device_id,
              attributes: {
                disabled: false,
              },
            }),
          });

          console.log('[reconcile] Device unlocked in Traccar');
        } else {
          console.error('[reconcile] Traccar login failed');
        }
      } catch (traccarError) {
        console.error('[reconcile] Traccar unlock error:', traccarError);
        // Non-fatal - continue
      }
    }

    // Step 6: Release slot (after 5-min buffer)
    // Note: Cleanup cron will handle this automatically
    // But we can trigger it immediately for faster reuse
    setTimeout(async () => {
      await supabase.rpc('release_payment_slot', {
        p_slot_number: payload.slot_number,
      });
      console.log('[reconcile] Slot released:', payload.slot_number);
    }, 5 * 60 * 1000); // 5 minutes

    return new Response(
      JSON.stringify({
        ok: true,
        device_id: payload.device_id,
        new_end_date: newEndDate.toISOString().split('T')[0],
        slot_released: false, // Will be released after buffer
      }),
      {
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('[reconcile] Error:', error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Internal server error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
});
