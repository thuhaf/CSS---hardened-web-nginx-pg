# Tái lập: chạy lại toàn bộ hệ thống và bằng chứng

Mục này cho người chấm (hoặc bất kỳ ai) nhân bản kho về máy mình và thấy đúng kết quả nhóm báo cáo.

## 1. Cần có

| Công cụ | Ghi chú |
|---|---|
| Docker + Compose v2 | `docker compose version` phải chạy được; Docker daemon đang bật. Cần kéo được image từ Docker Hub (các image ghim digest trong `Dockerfile`) |
| make | Windows: dùng Git Bash và cài `make` (ví dụ `scoop install make`) |
| openssl, curl, git | Sinh chứng chỉ dev và gọi thử nginx |
| python3 (có `venv`) | `make verify` chạy pytest tích hợp trong một venv tạm |
| Cổng 80 và 443 trống | nginx công bố hai cổng này; `make preflight` kiểm trước |

## 2. Các bước

```
git clone <url-kho-nhom> && cd <thu-muc-kho>
make preflight   # kiểm môi trường, ghi bang-chung/preflight.txt
make up          # sinh chứng chỉ dev, build và dựng nginx + web + db (--wait)
make verify      # chạy mọi ca kiểm, ghi vào bang-chung/, cuối cùng sinh và kiểm MANIFEST
make attack      # góc nhìn kẻ tấn công: in BLOCKED / SUCCEEDED
make defend      # góc nhìn phòng thủ: đọc cấu hình đang chạy so với giá trị mong đợi
make down        # dừng và xóa container + volume để lần sau sạch
```

Thứ tự bắt buộc: `make up` trước mọi lệnh khác, `make down` sau cùng. `make verify` đã gọi sẵn `attack.sh` và `defend.sh`; chạy riêng `make attack` / `make defend` chỉ để xem từng góc nhìn.

Kết quả đúng: mỗi script in dòng `ALL ... PASSED` (hoặc `ATTACK RESULT: moi tan cong bi chan`, `DEFEND RESULT: moi bien phap dang ap dung`) và `make` thoát mã 0. Script có ca FAIL thì thoát mã khác 0 và `make verify` dừng.

Muốn đóng gói bằng chứng để nộp: `make export-evidence` (tạo `bang-chung/MANIFEST.txt` và `dist/bang-chung-<ngày>.zip`).

## 3. Lưu ý riêng cho Windows / Git Bash

- Chạy mọi lệnh trong **Git Bash**, không dùng PowerShell hay CMD (script là `sh`/`bash`).
- Bật Docker Desktop (WSL2) trước khi `make preflight`.
- `.gitattributes` buộc script, SQL, cấu hình về LF và giữ nguyên xuống dòng của `bang-chung/`. Nếu vẫn thấy lỗi `\r: command not found`, clone lại kho vào thư mục mới để git áp `.gitattributes` từ đầu.
- `generate-dev-certs.sh` đã đặt `MSYS_NO_PATHCONV=1` để Git Bash không đổi `/C=VN/...` của OpenSSL thành đường dẫn Windows. Đừng bỏ dòng này.
- Nên clone vào đường dẫn không dấu cách, không dấu tiếng Việt (đường dẫn máy cá nhân còn lọt vào log của `docker compose`, xem mục 4.5 của báo cáo).

## 4. Chứng chỉ và bí mật

`make up` tự sinh CA, chứng chỉ máy chủ, chứng chỉ khách và chứng chỉ PostgreSQL vào `cau-hinh/nginx/certs/`. Các tệp `*.key` và `*.crt` này **không** nằm trong Git (xem `.gitignore`). Mật khẩu trong `docker-compose.yml` và `02-roles.sql` là giá trị giữ chỗ cho dev/CI, không phải bí mật thật.

## 5. Lỗi gặp khi chạy thử trên bản clone sạch

> TODO (Trọng): chạy các bước trên trên một bản clone mới và ghi lỗi gặp cùng cách xử lý vào đây. Xóa dòng này khi xong.

