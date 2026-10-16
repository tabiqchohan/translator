import { NextRequest } from 'next/server';
import { setUserPlan } from '@/lib/auth-db';

/**
 * RevenueCat webhook — keeps `users.plan` in sync with the store.
 *
 * Configure this URL in RevenueCat > Project settings > Integrations > Webhooks
 * and set the same value in the Authorization header field and in the
 * REVENUECAT_WEBHOOK_AUTH env var (optional but strongly recommended).
 *
 * The RevenueCat `app_user_id` must equal our internal user id. The mobile app
 * calls Purchases.logIn(user.id) after sign-in so the two always match.
 */

// Events that grant (or extend) Pro access.
const PRO_ACTIVE = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'PRODUCT_CHANGE',
  'UNCANCELLATION',
  'NON_RENEWING_PURCHASE',
  'SUBSCRIPTION_EXTENDED',
  'TEMPORARY_ENTITLEMENT_GRANT',
  'TRANSFER',
]);

// Events that revoke Pro access.
const PRO_EXPIRED = new Set(['EXPIRATION']);

export async function POST(req: NextRequest) {
  const secret = process.env.REVENUECAT_WEBHOOK_AUTH;
  if (secret) {
    const header = req.headers.get('authorization') || '';
    if (header !== secret && header !== `Bearer ${secret}`) {
      return Response.json({ error: 'Unauthorized' }, { status: 401 });
    }
  }

  try {
    const body = await req.json();
    const event = body?.event;
    const type: string | undefined = event?.type;
    if (!type) {
      return Response.json({ error: 'Invalid payload' }, { status: 400 });
    }

    const userId: string | undefined = event?.app_user_id;
    // Ignore anonymous RevenueCat ids (no linked account yet).
    if (!userId || userId.startsWith('$RCAnonymousID')) {
      return Response.json({ ok: true, ignored: true });
    }

    const expiresAt = event?.expiration_at_ms
      ? new Date(Number(event.expiration_at_ms))
      : null;

    if (PRO_ACTIVE.has(type)) {
      await setUserPlan(userId, 'pro', expiresAt);
    } else if (PRO_EXPIRED.has(type)) {
      await setUserPlan(userId, 'free', null);
    }
    // CANCELLATION keeps access until expiration -> no immediate change.

    return Response.json({ ok: true });
  } catch {
    return Response.json({ error: 'Webhook failed' }, { status: 500 });
  }
}
