# Backend Proxy — Flutter AI Tutor

Proxy giữ `GEMINI_API_KEY` an toàn ở phía server. Flutter app gọi endpoint này, không biết key.

Luồng xử lý:

1. **Gemini** (nếu có `GEMINI_API_KEY` và khu vực được hỗ trợ) — model mặc định `gemini-3.8-flash`.
2. **Cloudflare Workers AI** (dự phòng) — chạy trên hạ tầng Cloudflare nên không bị giới hạn khu vực, không cần API key riêng. Model mặc định `@cf/qwen/qwen3.8-27b`.

Nếu cả hai lỗi, app Flutter tự chuyển sang trả lời bằng dữ liệu offline (`assets/data/questions.json`).

## Yêu cầu

- Tài khoản Cloudflare (miễn phí)
- (Tùy chọn) Gemini API key miễn phí từ `https://aistudio.google.com/app/apikey`

## Cài đặt

```bash
cd backend
npm install -g wrangler
wrangler login
```

## Thiết lập secret (key Gemini, tùy chọn)

```bash
wrangler secret put GEMINI_API_KEY
# Nhập key của bạn khi được yêu cầu
```

Nếu bỏ qua bước này, Worker vẫn hoạt động bằng Workers AI.

## Deploy

```bash
wrangler deploy
```

Sau khi deploy, bạn sẽ nhận URL như `https://flutter-quiz-ai-proxy.<subdomain>.workers.dev`.

## Cấu hình model

Sửa trong `wrangler.toml`:

```toml
[vars]
GEMINI_MODEL = "gemini-3.8-flash"
WORKERS_AI_MODEL = "@cf/qwen/qwen3.8-27b"
```

Có thể xem danh sách model Workers AI bằng `wrangler ai models list`.

## Kết nối với Flutter app

URL proxy được cấu hình trong `lib/main.dart` qua `AI_PROXY_URL`:

```bash
flutter run --dart-define=AI_PROXY_URL=https://<your-worker>.workers.dev
```

Nếu không truyền, app dùng URL mặc định trong source. Nếu để trống `serverUrl`, app chạy **demo offline** (không cần key, không cần mạng).

## Endpoint

- `POST /api/chat` — nhận stream SSE (`data: {"chunk": "..."}`, kết thúc bằng `data: {"done": true}`)
- `GET /health` — kiểm tra server sống và trạng thái cấu hình Gemini / Workers AI

## Ghi chú

- Gemini có thể báo `User location is not supported` khi Worker egress từ một số khu vực (ví dụ Hồng Kông). Khi đó Worker tự chuyển sang Workers AI.
- Gemini free tier: ~15 request/phút, 1500 request/ngày. Workers AI free tier: ~10.000 Neurons/ngày.
