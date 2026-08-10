# Phiếu Phản Ánh — K4 Ngày 12

<!-- > **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác. -->
>
<!-- > Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu). -->
>
> Họ và tên: .......Đào Chí Hiển...................  Mã học viên: ........2A202601066..................

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `api_token` không có giá trị mặc định nên app chết ngay khi
khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà việc
"chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Tình huống cụ thể có thể là deploy lên Railway nhưng quên set API_TOKEN. Nếu có "changeme", service vẫn khởi động và tưởng rằng cấu hình hợp lệ; request có thể sử dụng token mặc định. Với fail-fast, app dừng ngay khi thiếu secret nên lỗi cấu hình được phát hiện trước khi service nhận traffic.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/chat` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> : Khi gọi /chat, tôi nhận được response thành công và trong log của service có các dòng JSON có cấu trúc. Ví dụ một dòng log tôi thu được là:{"event": "service_started", "severity": "INFO", "ts": "2026-08-10T12:39:52.656532+00:00", "service": "day12-chat-service", "version": "1.0.0"}. Từ dòng log JSON này, tôi có thể dùng máy để lọc hoặc truy vấn theo từng trường như event, severity, ts và service. Tôi cũng có thể đưa các log có cấu trúc vào hệ thống monitoring để thống kê, tìm lỗi hoặc theo dõi thời điểm service khởi động. Trong khi đó, print("đã trả lời xong") chỉ tạo ra một chuỗi text không có cấu trúc nên khó tự động phân tích và truy vấn.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t chat:single .
docker build -t chat:multi .
docker images | grep chat
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | 1800 MB |
| Multi-stage | 270 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

>: Phần dung lượng chênh lệch chủ yếu đến từ image Python đầy đủ và các thành phần không cần thiết cho môi trường chạy. Bản 1-stage dùng `python:3.11` và giữ toàn bộ môi trường cài đặt dependency trong cùng một image. Bản multi-stage dùng `python:3.11-slim` và chỉ copy các package đã cài từ stage `builder` sang stage `runtime`, nên không mang theo các thành phần build hoặc dữ liệu không cần thiết. Đây là nguyên nhân chính giúp image giảm từ khoảng 1.8 GB xuống 270 MB.


---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

>Dockerfile của tôi đặt:
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
trước khi copy source code:
COPY app ./app
COPY utils ./utils
Khi tôi sửa một ký tự trong app/main.py, layer COPY requirements.txt và layer RUN pip install vẫn được Docker sử dụng lại từ cache vì requirements.txt không thay đổi. Các layer copy source code như COPY app ./app phải chạy lại vì nội dung source đã thay đổi; các layer phía sau nó cũng có thể phải chạy lại.
Output build thực tế của tôi cũng cho thấy:
CACHED [builder 2/4] WORKDIR /app
CACHED [builder 3/4] COPY requirements.txt .
CACHED [builder 4/4] RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
CACHED [runtime 3/6] COPY --from=builder /install /usr/local
[runtime 4/6] COPY app ./app
[runtime 5/6] COPY utils ./utils
Nếu đặt COPY . . lên trước RUN pip install, chỉ cần thay đổi một file source bất kỳ thì layer COPY bị thay đổi. Vì RUN pip install nằm sau layer đó nên Docker có thể phải chạy lại việc cài dependencies dù requirements.txt không thay đổi. Do đó cách sắp xếp hiện tại giúp tận dụng Docker cache tốt hơn và giảm thời gian build.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Chuỗi cần hiểu là:Lỗ hổng trong code Python -> attacker khai thác được -> thực thi code bên trong container -> quyền của process trong container -> nếu process là root → quyền rất cao trong container -> nếu tiếp tục khai thác container/runtime -> tăng nguy cơ ảnh hưởng tới host. USER chuyển process của application sang user không có đặc quyền. Nó không làm mất lỗ hổng Python, nhưng giảm quyền mà attacker nhận được nếu khai thác thành công.

---

### Câu 6 — Bearer token (CP3)

Vì sao 401 phải kèm header `WWW-Authenticate: Bearer`? Và vì sao ta trả **cùng
một** thông báo lỗi cho cả ba trường hợp (thiếu header, sai scheme, sai token)
thay vì nói rõ sai ở đâu cho người dùng dễ sửa?

>  WWW-Authenticate: Bearer cho client biết resource yêu cầu cơ chế xác thực bằng Bearer token, đúng với HTTP authentication scheme đang sử dụng. Ba trường hợp:thiếu Authorization, scheme không phải Bearer, token sai nên trả cùng một thông báo lỗi để không tiết lộ thông tin giúp attacker phân biệt trạng thái xác thực. Đồng thời client hợp lệ vẫn biết rằng request cần Bearer token.

---

### Câu 7 — Token bucket (CP3)

Với `capacity=10`, `refill_per_minute=10`: một client im lặng 10 phút rồi gửi
liên tiếp. Nó gửi được bao nhiêu request trước khi bị 429? Nếu bỏ đoạn
`min(capacity, ...)` trong `available()` thì con số đó thành bao nhiêu, và tại sao?

> Với capacity=10, refill_per_minute=10 Client im lặng 10 phút thì bucket được refill nhưng không vượt quá capacity 10. Vì vậy khi bắt đầu gửi liên tiếp: -> gửi được 10 request, sau đó request tiếp theo bị 429 nếu không có thời gian refill giữa các request.Nếu bỏ đoạn min(capacity, ...) trong available() thì token có thể tích lũy vô hạn. Sau 10 phút: 10 token ban đầu + 10 token/phút × 10 phút = 110 token. Do đó client có thể gửi khoảng 110 request liên tiếp trước khi hết token, thay vì 10.Điểm quan trọng của min(capacity, ...) là chặn lượng token tối đa, tránh việc một client im lặng lâu rồi quay lại tạo ra một burst rất lớn.

---

### Câu 8 — Ngân sách theo ngày (CP3)

So sánh hạn mức $30/tháng với hạn mức $1/ngày cho cùng một client. Giả sử có sự
cố khiến một client gọi liên tục từ 2h sáng. Với mỗi cách, thiệt hại tối đa là
bao nhiêu và service tự hồi phục khi nào?

> Với hạn mức $30/tháng, nếu sự cố bắt đầu lúc 2h sáng và client gọi liên tục, về mặt giới hạn ngân sách thì thiệt hại có thể lên tới $30 trong kỳ tháng đó nếu toàn bộ hạn mức bị tiêu thụ. Service không tự hồi phục theo ngày; nó phải chờ sang kỳ ngân sách/tháng tiếp theo hoặc có cơ chế reset tương ứng. Với $1/ngày, thiệt hại tối đa trong một ngày là $1. Khi quota ngày đã hết, client bị chặn và service có thể tự hồi phục khi sang ngày mới, khi daily budget được reset. Điểm khác biệt quan trọng là $1/day giới hạn blast radius theo từng ngày, trong khi $30/month cho phép một sự cố tiêu thụ phần lớn hoặc toàn bộ ngân sách tháng trong thời gian ngắn.

---

### Câu 9 — /healthz khác /readyz (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Nếu gộp hai endpoint và endpoint đó kiểm tra Redis: Redis mất kết nối -> 3 container đều kiểm tra Redis -> cả 3 container trả trạng thái unhealthy/not ready -> platform/load balancer coi các container là không sẵn sàng -> traffic bị loại khỏi các container đó -> cụm có thể không còn instance nào nhận request -> Redis khôi phục sau 30 giây -> health check thành công trở lại -> container được đánh dấu ready -> traffic quay trở lại

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

>Một lỗi tôi gặp khi deploy lên Railway là Uvicorn không khởi động được. Log Railway hiển thị:
{
  "message": "Usage: uvicorn [OPTIONS] APP",
  "severity": "error"
}
Từ thông báo này, tôi xác định vấn đề nằm ở command khởi động Uvicorn vì Uvicorn được gọi nhưng không nhận application theo đúng cú pháp. Tôi kiểm tra lại cấu hình Railway và Dockerfile, đặc biệt là startCommand, tên application app.main:app và việc đọc biến môi trường PORT.
Sau khi điều chỉnh lại cấu hình khởi động để Uvicorn chạy app.main:app trên 0.0.0.0 và sử dụng ${PORT:-8000}, tôi deploy lại service. Kết quả kiểm tra thực tế trên Railway cho thấy /healthz trả HTTP 200 với:
{"status":"ok","service":"day12-chat-service","version":"1.0.0"}
Endpoint /readyz cũng trả HTTP 200 với:
{"status":"ready","redis":true}
Ngoài ra, /chat không có token trả 401 kèm WWW-Authenticate: Bearer, còn request có token trả 200. Điều đó cho thấy service sau khi sửa đã khởi động và hoạt động đúng trên Railway
