# Thông Tin Deploy — Checkpoint 5

> Điền file này sau khi deploy xong. `pytest tests/test_cp5.py` đọc file này
> để tìm địa chỉ service của bạn và gọi thử.
>
> **Chỉ ghi TÊN biến môi trường, tuyệt đối không dán giá trị token vào đây.**
> Repo này công khai — dán token vào là mất token.

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | Đào Chí Hiển |
| Mã học viên | 2A202601066 |
| Repo | https://github.com/doclautc-1808/K4-Day12-2A202601066-DaoChiHien |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL |  https://chat-production-4f91.up.railway.app     |
| Platform | Railway |
| Ngày deploy | 10/08/2026 |

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và **nguồn giá trị**, không ghi giá trị:

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | ✅ | 8000 |
| `API_TOKEN` | ✅ | đặt trong dashboard, không nằm trong repo |
| `REDIS_URL` | ✅ | redis://localhost:6379/0 |
| `BUCKET_CAPACITY` | ✅ | 10 |
| `REFILL_PER_MINUTE` | ✅ | 10 |
| `DAILY_BUDGET_USD` | ✅ | 1.0 |
| `LOG_LEVEL` | ✅ | INFO |

## Lệnh Kiểm Tra

Thay `<URL>` bằng Public URL ở trên:

```bash
# 1. Liveness — mong đợi 200 {"status":"ok"}
curl -i  https://chat-production-4f91.up.railway.app/healthz

# 2. Readiness — mong đợi 200 {"status":"ready"} (đã nối được Redis)
curl -i  https://chat-production-4f91.up.railway.app/readyz

# 3. Không có token — mong đợi 401 kèm header WWW-Authenticate
curl -i -X POST  https://chat-production-4f91.up.railway.app/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello"}'

# 4. Có token — mong đợi 200 kèm câu trả lời
curl -i -X POST  https://chat-production-4f91.up.railway.app/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "X-Client-Id: sv-test" \
  -d '{"message":"Deploy là gì?"}'

# 5. Rate limit — gọi 15 lần, những lần cuối phải trả 429
for i in $(seq 1 15); do
  curl -s -o /dev/null -w "%{http_code} " -X POST  https://chat-production-4f91.up.railway.app/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "X-Client-Id: sv-test" \
    -d '{"message":"test"}'
done; echo
```

## Kết Quả Chạy Thật

Dán output của các lệnh trên vào đây:

```
HTTP/2 200
content-type: application/json
date: Mon, 10 Aug 2026 13:20:28 GMT
server: railway-hikari
x-railway-request-id: jxj0hGfQSIiQbifLjq4OvQ
content-length: 64
x-hikari-trace: sin1.98a6
x-railway-edge: sin1

{"status":"ok","service":"day12-chat-service","version":"1.0.0"}HTTP/2 200
content-type: application/json
date: Mon, 10 Aug 2026 13:20:28 GMT
server: railway-hikari
x-railway-request-id: BhRf9YOKR9i1VSCl9fVATg
content-length: 31
x-hikari-trace: sin1.98a6
x-railway-edge: sin1

{"status":"ready","redis":true}HTTP/2 401
content-type: application/json
date: Mon, 10 Aug 2026 13:20:29 GMT
server: railway-hikari
www-authenticate: Bearer
x-railway-request-id: mTFLtWINT5aCmck19I3ezw
content-length: 44
x-hikari-trace: sin1.tr00
x-railway-edge: sin1

{"detail":"invalid or missing bearer token"}HTTP/2 200
content-type: application/json
date: Mon, 10 Aug 2026 13:20:29 GMT
server: railway-hikari
x-railway-request-id: OtjCuAB3SyOltXx8LPU1MQ
content-length: 288
x-hikari-trace: sin1.d1nj
x-railway-edge: sin1
vary: accept-encoding

{"reply":"Câu hỏi hay. Deploy là gì thường được giải quyết bằng cách chuẩn hóa môi trường chạy: cùng một image chạy giống nhau ở laptop và trên cloud.","client_id":"sv-test","turns_before":0,"usd_cost":2.145e-05,"usage":{"prompt":3,"completion":35}}200 200 200 200 200 200 200 200 200 429 429 200 429 429 429
```

## Ảnh Chụp Màn Hình

Đặt ảnh trong thư mục `screenshots/`:

- `screenshots/dashboard.png` — trang quản lý service trên platform
- `screenshots/healthz.png` — kết quả gọi `/healthz` từ trình duyệt hoặc curl

---

## Nếu Dùng Phương Án Dự Phòng

Không đăng ký được tài khoản cloud? Vẫn nộp được bài, nhưng CP5 tối đa 60% điểm:

1. Đặt `LOCAL_FALLBACK=true` trong `.env`
2. Chạy `docker compose up -d` rồi kiểm tra `docker compose ps`
3. Chụp màn hình vào `screenshots/`
4. Chạy `pytest tests/test_cp5.py -v` — bộ test sẽ tự chuyển sang kiểm tra
   `http://localhost:8000`
5. Ghi rõ lý do không deploy được vào phần dưới đây:

```
Đã đăng ký được
```
