// Cloudflare Worker. Store FEEDBACK_WEBHOOK as a secret; bind REPORT_LIMITS to KV.
// The client never receives the Discord credential.
export default {
  async fetch(request, env) {
    const reply = (message, status) => new Response(message, {status});
    if (request.method !== 'POST') return reply('Method not allowed', 405);
    if (!env.FEEDBACK_WEBHOOK || !env.REPORT_LIMITS) return reply('Reporting unavailable', 503);
    if (Number(request.headers.get('content-length') || 0) > 8192) return reply('Report too large', 413);
    const reader = request.body?.getReader();
    if (!reader) return reply('Missing report', 400);
    let bytes = 0; const chunks = [];
    while (true) {
      const {done, value} = await reader.read();
      if (done) break;
      bytes += value.length;
      if (bytes > 8192) { await reader.cancel(); return reply('Report too large', 413); }
      chunks.push(value);
    }
    const raw = new Uint8Array(bytes); let offset = 0;
    for (const chunk of chunks) { raw.set(chunk, offset); offset += chunk.length; }
    let report;
    try { report = JSON.parse(new TextDecoder().decode(raw)); } catch { return reply('Invalid report', 400); }
    const input = report?.embeds?.[0];
    const kinds = ['Bug Report', 'Feedback', 'New Feature', 'New Game Request'];
    const kind = kinds.find(value => input?.title === 'Serenity · ' + value);
    if (!kind || typeof input?.description !== 'string' || input.description.trim().length < 10 || input.description.length > 1800) return reply('Invalid report', 400);
    const ip = request.headers.get('CF-Connecting-IP');
    if (!ip) return reply('Missing client address', 400);
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(ip));
    const key = 'report:' + Array.from(new Uint8Array(digest), n => n.toString(16).padStart(2, '0')).join('');
    if (await env.REPORT_LIMITS.get(key)) return reply('Please wait before sending another report', 429);
    await env.REPORT_LIMITS.put(key, '1', {expirationTtl: 60});
    const fields = ['Game', 'Place ID', 'Job ID', 'UI build'].map(name => ({name, value: String(input.fields?.find(field => field.name === name)?.value || 'Unavailable').slice(0, 256)}));
    try {
      const result = await fetch(env.FEEDBACK_WEBHOOK, {
        method: 'POST', headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({allowed_mentions: {parse: []}, embeds: [{title: 'Serenity · ' + kind, description: input.description.trim(), fields}]}),
        signal: AbortSignal.timeout(10000),
      });
      return result.ok ? new Response(null, {status: 204}) : reply('Delivery failed', result.status === 429 ? 429 : 502);
    } catch { return reply('Delivery unavailable', 502); }
  },
};
