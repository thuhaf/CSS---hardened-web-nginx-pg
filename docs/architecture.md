# Kiến trúc hệ thống — Chủ đề A

## Tổng quan

Hệ thống gồm ba thành phần nối tiếp nhau: **nginx** làm cổng vào, một **ứng dụng web** nhỏ, và **PostgreSQL** lưu dữ liệu các phòng ban.

```
Người dùng --> [nginx :443] --> [web app] --> [PostgreSQL]
                   |
                   +-- /admin --> yêu cầu mTLS (xác thực chứng chỉ khách)
```

## Vai trò từng thành phần

- **nginx**: cổng vào duy nhất từ bên ngoài, bắt buộc TLS cho toàn bộ traffic. Đường `/admin` yêu cầu thêm xác thực chứng chỉ khách (mTLS) trước khi được chuyển tiếp vào ứng dụng.
- **web app**: không expose trực tiếp ra ngoài, chỉ nhận request đã qua nginx. Kết nối tới PostgreSQL bằng một vai trò riêng (`app_user`), không dùng vai trò chủ sở hữu; RLS giới hạn tài liệu theo session context phòng ban.
- **PostgreSQL**: lưu dữ liệu các phòng ban. Bảng `app.documents` bật và FORCE Row Level Security theo `app.current_department`; pgAudit ghi nhận các thao tác DDL và thay đổi role.

## Ranh giới tin cậy (trust boundary)

1. Mạng ngoài — nginx: người dùng chưa xác thực chỉ chạm được cổng 443.
2. Người dùng thường — đường `/admin`: cùng qua nginx nhưng đường quản trị đòi hỏi xác thực chứng chỉ khách riêng.
3. nginx — web app: ứng dụng không được expose trực tiếp ra ngoài.
4. web app — PostgreSQL: ứng dụng kết nối bằng vai trò riêng, không phải vai trò chủ sở hữu.

## Cách chạy

```
docker compose up --build
```

CI (`.github/workflows/ci.yml`) sẽ chạy đúng lệnh này để xác nhận cả 3 service khởi động thành công trước khi cho phép merge vào `main`.
## Sơ đồ kiến trúc

![Sơ đồ kiến trúc hệ thống](architecture.png)