# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization (bản production-ready)
#
# Đích cần đạt: image dưới 400MB.
#
# Kiểm tra:  pytest tests/test_cp2.py -v
# Build thử: docker build -t day12-chat:prod .
#            docker images day12-chat:prod     # xem dung lượng
# ═══════════════════════════════════════════════════════════════════

# ── Stage 1: builder — được phép nặng, sẽ bị vứt đi ──────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Cài trước, copy source SAU: sửa 1 dòng code không phải cài lại thư viện
COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: runtime — chỉ mang theo kết quả cài đặt, không compiler ──
FROM python:3.11-slim AS runtime

WORKDIR /app

# Lấy package đã cài từ stage builder, không mang theo build tool
COPY --from=builder /install /usr/local

# Copy source code sau khi dependency đã sẵn sàng (tận dụng cache layer)
COPY app ./app
COPY utils ./utils

# Không chạy bằng root — hạn chế thiệt hại nếu app bị chiếm quyền
RUN useradd --create-home --uid 10001 appuser
USER appuser

# Cloud (Railway/Render/Cloud Run) tự gán PORT, không cố định 8000
ENV PORT=8000
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.environ.get('PORT', '8000') + '/healthz').read()" || exit 1

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]