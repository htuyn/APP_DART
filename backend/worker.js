/**
 * Backend proxy cho Flutter AI Tutor.
 * Giữ GEMINI_API_KEY trong Cloudflare secret (không để trong source Flutter).
 * Endpoint: POST /api/chat  body: { messages: [{role, content, langCode}], langCode }
 * Trả về SSE text/event-stream.
 *
 * Luồng: Gemini (nếu có key và khu vực hỗ trợ) -> Cloudflare Workers AI (dự phòng).
 * Workers AI chạy trên hạ tầng Cloudflare nên không bị giới hạn khu vực và
 * không cần API key riêng.
 */

const DEFAULT_GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-1.5-flash'];
const DEFAULT_WORKERS_AI_MODEL = '@cf/meta/llama-3.1-8b-instruct';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Accept',
};

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      ...CORS_HEADERS,
    },
  });
}

function systemPromptFor(langCode) {
  return langCode === 'vi'
    ? `Bạn là AI Tutor — trợ lý gia sư lập trình Flutter & Dart thông minh, thân thiện và tự nhiên (như ChatGPT).
Nguyên tắc giao tiếp:
- Trả lời TRỰC TIẾP, ĐÚNG TRỌNG TÂM câu hỏi. Không chào hỏi máy móc ở mỗi lượt chat, không lặp lại câu hỏi của học viên.
- Duy trì ngữ cảnh hội thoại: Nắm chắc chủ đề các tin nhắn trước để trả lời liền mạch các câu follow-up ("Tại sao?", "Thế còn...", "Cho ví dụ đi", "Nói ngắn gọn hơn").
- KHÔNG tự động chia câu trả lời thành các heading cứng nhắc như "Khối kiến thức / Đáp án đúng / Bản chất kỹ thuật".
- Khi minh họa code: Viết code Dart/Flutter chuẩn Clean Code trong khối \`\`\`dart có chú thích ngắn gọn, dễ hiểu.
- Định dạng Markdown đẹp mắt, thoáng mắt.`
    : `You are AI Tutor — an intelligent, friendly, and natural Flutter & Dart programming companion (like ChatGPT).
Communication Guidelines:
- Answer DIRECTLY and concisely to the point. Avoid robotic boilerplate greetings in each turn, and do not repeat user prompts.
- Maintain conversation context: Track previous dialogue turns and seamlessly answer follow-up questions ("Why?", "What about...", "Show an example").
- DO NOT use rigid textbook headings unless specifically asked to analyze or grade a quiz item.
- Provide clean, idiomatic Dart/Flutter code inside \`\`\`dart blocks with clear comments.
- Format responses with clean Markdown for easy reading.`;
}

/** Lọc bỏ tin nhắn rỗng/system và gộp các role liền nhau cho hợp lệ với Gemini. */
function buildContents(messages) {
  const contents = [];

  for (const message of messages) {
    if (!message || message.role === 'system') continue;
    const text = typeof message.content === 'string' ? message.content.trim() : '';
    if (!text) continue;

    const role = message.role === 'assistant' ? 'model' : 'user';
    const last = contents[contents.length - 1];

    if (last && last.role === role) {
      last.parts[0].text += `\n\n${text}`;
    } else {
      contents.push({ role, parts: [{ text }] });
    }
  }

  return contents;
}

/** Lịch sử chat dạng OpenAI/Workers AI: system + user/assistant. */
function buildChatMessages(messages, systemPrompt) {
  const result = [{ role: 'system', content: systemPrompt }];

  for (const message of messages) {
    if (!message || message.role === 'system') continue;
    const content =
      typeof message.content === 'string' ? message.content.trim() : '';
    if (!content) continue;
    result.push({
      role: message.role === 'assistant' ? 'assistant' : 'user',
      content,
    });
  }

  return result;
}

function createEventStream(pump) {
  const stream = new TransformStream();
  const writer = stream.writable.getWriter();
  const encoder = new TextEncoder();

  const writeEvent = (payload) =>
    writer.write(encoder.encode(`data: ${JSON.stringify(payload)}\n\n`));

  pump({ writeEvent })
    .catch(async (error) => {
      try {
        await writeEvent({ error: `Stream lỗi: ${String(error)}` });
      } catch (_) {
        // Client đã ngắt kết nối
      }
    })
    .finally(async () => {
      try {
        await writer.close();
      } catch (_) {
        // Stream đã đóng
      }
    });

  return new Response(stream.readable, {
    status: 200,
    headers: {
      'Content-Type': 'text/event-stream; charset=utf-8',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      ...CORS_HEADERS,
    },
  });
}

async function pumpGemini(body, { writeEvent }) {
  const reader = body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let sentAny = false;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';

    for (const rawLine of lines) {
      const line = rawLine.trimEnd();
      if (!line || line.startsWith(':') || !line.startsWith('data:')) continue;

      const data = line.slice(5).trim();
      if (!data || data === '[DONE]') continue;

      try {
        const parsed = JSON.parse(data);
        for (const candidate of parsed.candidates || []) {
          for (const part of candidate.content?.parts || []) {
            // Bỏ qua phần "suy nghĩ" (thinking) của Gemini 3.x
            if (part.thought === true) continue;
            if (typeof part.text === 'string' && part.text.length > 0) {
              await writeEvent({ chunk: part.text });
              sentAny = true;
            }
          }
        }
      } catch (_) {
        // Bỏ qua dòng SSE không phân tích được
      }
    }
  }

  if (!sentAny) {
    await writeEvent({ error: 'AI không trả về nội dung. Vui lòng thử lại.' });
  }
  await writeEvent({ done: true });
}

async function pumpWorkersAi(body, { writeEvent }) {
  const reader = body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let sentAny = false;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';

    for (const rawLine of lines) {
      const line = rawLine.trimEnd();
      if (!line || line.startsWith(':') || !line.startsWith('data:')) continue;

      const data = line.slice(5).trim();
      if (!data) continue;
      if (data === '[DONE]') continue;

      try {
        const parsed = JSON.parse(data);
        if (parsed.error) {
          throw new Error(String(parsed.error));
        }
        const chunk =
          (typeof parsed.response === 'string' && parsed.response) ||
          parsed.choices?.[0]?.delta?.content ||
          '';
        if (chunk.length > 0) {
          await writeEvent({ chunk });
          sentAny = true;
        }
      } catch (_) {
        // Bỏ qua dòng SSE không phân tích được
      }
    }
  }

  if (!sentAny) {
    await writeEvent({ error: 'AI không trả về nội dung. Vui lòng thử lại.' });
  }
  await writeEvent({ done: true });
}

async function tryGemini(env, systemPrompt, contents) {
  const apiKey = env.GEMINI_API_KEY;
  if (!apiKey) return { ok: false, error: 'Thiếu GEMINI_API_KEY' };

  const configuredModel = (env.GEMINI_MODEL || '').trim();
  const models = [
    ...new Set([configuredModel, ...DEFAULT_GEMINI_MODELS].filter(Boolean)),
  ];

  let lastError = '';

  for (const model of models) {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?alt=sse`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents,
        generationConfig: {
          temperature: 0.7,
          topP: 0.9,
          maxOutputTokens: 2048,
        },
      }),
    });

    if (response.ok) return { ok: true, response };

    lastError = await response.text();
    // Model bị khai tử/không tồn tại -> thử model kế tiếp.
    if (response.status !== 404) break;
  }

  return { ok: false, error: lastError.trim() };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    // Health check
    if (url.pathname === '/health' && request.method === 'GET') {
      return jsonResponse({
        ok: true,
        gemini: Boolean(env.GEMINI_API_KEY),
        workersAi: Boolean(env.AI),
      });
    }

    // Chỉ cho phép POST /api/chat
    if (url.pathname !== '/api/chat' || request.method !== 'POST') {
      return jsonResponse({ error: 'Not found' }, 404);
    }

    try {
      const body = await request.json();
      const { messages = [], langCode = 'vi' } = body;

      const systemPrompt = systemPromptFor(langCode);
      const contents = buildContents(messages);

      if (contents.length === 0 || contents[contents.length - 1].role !== 'user') {
        return jsonResponse(
          { error: 'Không có câu hỏi hợp lệ để gửi tới AI.' },
          400
        );
      }

      // 1) Ưu tiên Gemini nếu cấu hình được.
      const gemini = await tryGemini(env, systemPrompt, contents);
      if (gemini.ok) {
        return createEventStream((helpers) => pumpGemini(gemini.response.body, helpers));
      }

      // 2) Dự phòng Workers AI (không giới hạn khu vực, không cần API key).
      if (env.AI) {
        const chatMessages = buildChatMessages(messages, systemPrompt);
        const model = (env.WORKERS_AI_MODEL || DEFAULT_WORKERS_AI_MODEL).trim();
        const aiResponse = await env.AI.run(model, {
          messages: chatMessages,
          stream: true,
          max_tokens: 2048,
          temperature: 0.7,
        });
        return createEventStream((helpers) => pumpWorkersAi(aiResponse, helpers));
      }

      return jsonResponse(
        { error: `Gemini error: ${gemini.error || 'không khả dụng'}` },
        502
      );
    } catch (e) {
      return jsonResponse({ error: String(e) }, 500);
    }
  },
};
