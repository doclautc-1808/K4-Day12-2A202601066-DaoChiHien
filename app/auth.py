"""CP3 — Xác thực bằng Bearer token.

Public URL = ai cũng gọi được. Không có lớp này, hóa đơn LLM của bạn do
người lạ quyết định.

Chuẩn dùng ở đây là **RFC 6750** — token đi trong header ``Authorization``:

    Authorization: Bearer <token>

Đây là cách mọi API lớn (GitHub, Stripe, OpenAI) nhận token, nên client viết
bằng ngôn ngữ nào cũng có sẵn thư viện hiểu nó.
"""

from __future__ import annotations

import secrets

from fastapi import Header, HTTPException, status

from .config import get_settings

ANONYMOUS_CLIENT = "anonymous"
SCHEME = "Bearer"


def _unauthorized() -> HTTPException:
    """Một thông báo lỗi duy nhất cho mọi trường hợp 401 — không tặng
    thông tin (sai scheme? sai token? thiếu header?) cho người đang dò."""
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="invalid or missing bearer token",
        headers={"WWW-Authenticate": "Bearer"},
    )


def verify_bearer_token(
    authorization: str | None = Header(default=None),
    x_client_id: str | None = Header(default=None),
) -> str:
    """Kiểm tra header ``Authorization``; trả về client_id nếu hợp lệ."""
    if not authorization:
        raise _unauthorized()

    scheme, _, token = authorization.partition(" ")

    if scheme.lower() != SCHEME.lower() or not token:
        raise _unauthorized()

    expected_token = get_settings().api_token
    if not secrets.compare_digest(token, expected_token):
        raise _unauthorized()

    return x_client_id if x_client_id else ANONYMOUS_CLIENT