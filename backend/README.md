# Backend Proxy — Flutter AI Tutor

Proxy giữ `GEMINI_API_KEY` an toàn ở phía server. Flutter app gọi endpoint này, không biết key.

## Yêu cầu
- Tài khoản Cloudflare (miễn phí)
- Gemini API key miễn phí từ `https://aistudio.google.com/app/apikey`

## Cài đặt

```bash
cd backend
npm install -g wrangler
wrangler login
```

## Thiết lập secret (key Gemini)

```bash
wrangler secret put GEMINI_API_KEY
# Nhập key của bạn khi được yêu cầu

wrangler secret put GEMINI_MODEL
# Nhập: gemini-2.0-flash (hoặc để trống, mặc định là gemini-2.0-flash)
```

## Deploy

```bash
wrangler deploy
```

Sau khi deploy, bạn sẽ nhận URL như `https://flutter-quiz-ai-proxy.<subdomain>.workers.dev`.

## Kết nối với Flutter app

Mở `lib/presentation/providers/chat_provider.dart`, thay `serverUrl` khi khởi tạo `ChatProvider`:

```dart
ChangeNotifierProvider(
  create: (_) => ChatProvider(serverUrl: 'https://<your-worker>.workers.dev'),
),
```

Nếu để trống `serverUrl`, app sẽ chạy ở **chế độ demo offline** (không cần key, không cần mạng).

## Endpoint

- `POST /api/chat` — nhận stream SSE từ Gemini
- `GET /health` — kiểm tra servidor sống

## Lưu ý miễn phí

- Gemini free tier: ~15 request/phút, 1500 request/ngày.
- Cloudflare Worker free: 100,000 request/ngày.
