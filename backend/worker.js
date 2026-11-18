/**
 * Backend proxy cho Flutter AI Tutor.
 * Giữ GEMINI_API_KEY trong Cloudflare secret (không để trong source Flutter).
 * Endpoint: POST /api/chat  body: { messages: [{role, content, langCode}], langCode }
 * Trả về SSE text/event-stream.
 */

const DEFAULT_MODEL = 'gemini-2.0-flash';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const GEMINI_API_KEY = env.GEMINI_API_KEY;
    const MODEL = env.GEMINI_MODEL || DEFAULT_MODEL;

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      });
    }

    // Health check
    if (url.pathname === '/health' && request.method === 'GET') {
      return new Response(JSON.stringify({ ok: true }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Chỉ cho phép POST /api/chat
    if (url.pathname !== '/api/chat' || request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (!GEMINI_API_KEY) {
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY not configured on server' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    try {
      const body = await request.json();
      const { messages = [], langCode = 'vi' } = body;

      // Prompt hệ thống song ngữ
      const systemPrompt = langCode === 'vi'
        ? `Bạn là Gia sư AI Flutter, trả lời câu hỏi về Flutter/Dart và lập trình.
Ngôn ngữ: Tiếng Việt.
Quy tắc:
- Trả lời ngắn gọn, rõ ràng, dễ hiểu.
- Nếu câu hỏi liên quan mã, hãy đưa ví dụ mã Dart/Flutter.
- Không bịa thông tin nếu không chắc chắn.`
        : `You are an AI Flutter Tutor. Answer questions about Flutter/Dart and programming.
Language: English.
Rules:
- Answer concisely, clearly, and easy to understand.
- If the question involves code, provide Dart/Flutter code examples.
- Do not hallucinate information if you are not sure.`

      // Xây dựng nội dung cho Gemini: system prompt + lịch sử hội thoại
      const contents = [];
      contents.push({ role: 'user', parts: [{ text: systemPrompt }] });
      contents.push({ role: 'model', parts: [{ text: 'Tôi sẵn sàng hỗ trợ bạn.' }] });

      for (const m of messages) {
        if (m.role === 'system') continue;
        contents.push({
          role: m.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: m.content }],
        });
      }

      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:streamGenerateContent?key=${GEMINI_API_KEY}`;

      const geminiRes = await fetch(geminiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents,
          generationConfig: {
            temperature: 0.7,
            topP: 0.9,
            maxOutputTokens: 2048,
          },
        }),
      });

      if (!geminiRes.ok) {
        const errText = await geminiRes.text();
        return new Response(JSON.stringify({ error: `Gemini error: ${geminiRes.status} ${errText}` }), {
          status: 502,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      // Trả về stream SSE cho Flutter
      const stream = new TransformStream();
      const writer = stream.writable.getWriter();
      const encoder = new TextEncoder();

      (async () => {
        const reader = geminiRes.body.getReader();
        const decoder = new TextDecoder();
        let buffer = '';

        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split('\n');
            buffer = lines.pop() || '';

            for (const line of lines) {
              if (!line.startsWith('data: ')) continue;
              const data = line.slice(6).trim();
              if (data === '[DONE]') {
                await writer.write(encoder.encode('data: {"done": true}\n\n'));
                continue;
              }
              try {
                const parsed = JSON.parse(data);
                const candidates = parsed.candidates || [];
                for (const cand of candidates) {
                  const parts = cand.content?.parts || [];
                  for (const part of parts) {
                    if (part.text) {
                      await writer.write(encoder.encode(`data: {"chunk": ${JSON.stringify(part.text)}}\n\n`));
                    }
                  }
                }
              } catch (_) {
                // Bỏ qua dòng không parse được
              }
            }
          }
        } finally {
          await writer.close();
        }
      })();

      return new Response(stream.readable, {
        status: 200,
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
          'Access-Control-Allow-Origin': '*',
        },
      });
    } catch (e) {
      return new Response(JSON.stringify({ error: String(e) }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }
  },
};
