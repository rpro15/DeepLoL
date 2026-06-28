/**
 * DeepLoL Worker — API для генерации мемных подписей
 *
 * POST /generate
 * GET  /health
 *
 * Флаг отладки: ?no_cache=true — пропускает кэш и шлёт запрос в DeepSeek
 *
 * Переменные окружения:
 *   DEEPSEEK_API_KEY — ключ DeepSeek (wrangler secret put)
 *   MEME_CACHE       — KV namespace
 */

async function md5Hash(input) {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('MD5', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

function buildPrompt({ prompt_context, style = 'абсурд' }) {
  return (
    `Создай смешную мем-подпись в стиле ${style}. ` +
    `Контекст: ${prompt_context}. ` +
    `Ответь одним предложением не более 100 символов без кавычек и лишнего текста.`
  );
}

async function callDeepSeek(prompt, apiKey) {
  const response = await fetch('https://api.deepseek.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'deepseek-chat',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 150,
      temperature: 0.8,
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.error(`[DeepSeek] API error ${response.status}: ${errorBody}`);
    throw new Error(`DeepSeek API вернул ${response.status}`);
  }

  const data = await response.json();

  if (
    !data.choices ||
    !Array.isArray(data.choices) ||
    data.choices.length === 0 ||
    !data.choices[0].message ||
    !data.choices[0].message.content
  ) {
    console.error('[DeepSeek] Неожиданная структура ответа:', JSON.stringify(data));
    throw new Error('Неверная структура ответа от DeepSeek API');
  }

  return data.choices[0].message.content.trim();
}

function parseRequestBody(body) {
  if (!body || typeof body !== 'object') return null;

  const prompt_context = body.prompt_context;
  const style = body.style || 'абсурд';

  if (!prompt_context || typeof prompt_context !== 'string' || prompt_context.trim().length === 0) {
    return null;
  }

  const validStyles = ['абсурд', 'сарказм', 'жизненный'];
  if (!validStyles.includes(style)) return null;

  return { prompt_context: prompt_context.trim(), style };
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const { pathname } = url;

    // Разбираем флаг отладки: ?no_cache=true — пропустить кэш
    const noCache = url.searchParams.get('no_cache') === 'true';

    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    // Health check
    if (pathname === '/health' && request.method === 'GET') {
      return new Response(
        JSON.stringify({ status: 'ok', service: 'deeplol-worker', version: '1.0.0' }),
        { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      );
    }

    // Генерация мема
    if (pathname === '/generate' && request.method === 'POST') {
      console.log(`[generate] Запрос от ${request.headers.get('CF-Connecting-IP') || 'unknown'}`);
      console.log(`[generate] no_cache=${noCache}`);

      // Парсинг тела
      let body;
      try {
        body = await request.json();
      } catch (err) {
        console.error('[generate] Ошибка JSON:', err.message);
        return new Response(
          JSON.stringify({ error: 'Неверный формат JSON' }),
          { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
        );
      }

      // Валидация
      const params = parseRequestBody(body);
      if (!params) {
        console.error('[generate] Невалидные параметры:', JSON.stringify(body));
        return new Response(
          JSON.stringify({ error: 'Требуется prompt_context (строка). Опционально: style' }),
          { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
        );
      }

      // Проверка API-ключа
      if (!env.DEEPSEEK_API_KEY) {
        console.error('[generate] DEEPSEEK_API_KEY не установлен');
        return new Response(
          JSON.stringify({ error: 'API-ключ не настроен' }),
          { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
        );
      }

      // Ключ кэша
      const cacheKey = await md5Hash(`${params.prompt_context}:${params.style}`);
      console.log(`[generate] cacheKey=${cacheKey}`);

      // Проверка кэша (если не выставлен флаг no_cache)
      if (!noCache && env.MEME_CACHE) {
        try {
          const cached = await env.MEME_CACHE.get(cacheKey);
          if (cached) {
            console.log(`[generate] HIT кэш: "${cached}"`);
            return new Response(
              JSON.stringify({ text: cached }),
              {
                status: 200,
                headers: {
                  'Content-Type': 'application/json',
                  'X-Cache': 'HIT',
                  'X-No-Cache': noCache ? 'true' : 'false',
                  ...corsHeaders,
                },
              },
            );
          }
        } catch (err) {
          console.warn(`[generate] Ошибка KV: ${err.message}`);
        }
      }
      console.log(`[generate] MISS кэш, шлю запрос в DeepSeek`);

      // Генерация
      const prompt = buildPrompt(params);
      console.log(`[generate] prompt="${prompt}"`);

      let generatedText;
      try {
        generatedText = await callDeepSeek(prompt, env.DEEPSEEK_API_KEY);
      } catch (err) {
        console.error(`[generate] Ошибка DeepSeek: ${err.message}`);
        return new Response(
          JSON.stringify({ error: 'Сервис генерации временно недоступен', detail: err.message }),
          { status: 502, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
        );
      }

      console.log(`[generate] ответ="${generatedText}"`);

      // Сохраняем в кэш в фоне
      if (env.MEME_CACHE) {
        try {
          ctx.waitUntil(env.MEME_CACHE.put(cacheKey, generatedText, { expirationTtl: 86400 }));
          console.log(`[generate] сохранено в кэш на 24ч`);
        } catch (err) {
          console.warn(`[generate] ошибка сохранения KV: ${err.message}`);
        }
      }

      return new Response(
        JSON.stringify({ text: generatedText }),
        {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'X-Cache': 'MISS',
            'X-No-Cache': noCache ? 'true' : 'false',
            ...corsHeaders,
          },
        },
      );
    }

    // 404
    console.log(`[404] ${request.method} ${pathname}`);
    return new Response(
      JSON.stringify({ error: 'Not Found', path: pathname }),
      { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );
  },
};
