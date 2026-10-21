-- 02-roles.sql: tạo vai trò ứng dụng theo nguyên tắc đặc quyền tối thiểu.

-- app_user: tài khoản duy nhất web app dùng để kết nối (khớp DATABASE_URL trong compose).
-- Chủ động tắt mọi quyền nguy hiểm; NOBYPASSRLS đảm bảo RLS ở M3 luôn áp lên role này.
-- LƯU Ý: mật khẩu dưới đây chỉ dùng cho dev/CI, không phải bí mật thật.
CREATE ROLE app_user
    LOGIN
    PASSWORD 'changeme_app_pw'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    NOBYPASSRLS;

-- Mặc định mọi role đều được CONNECT vào DB; thu hồi rồi chỉ cấp cho app_user.
-- Dùng DO + format vì SQL thuần không nhận tên DB làm tham số.
DO $$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO app_user', current_database());
END
$$;

-- Thu hồi quyền mặc định của PUBLIC trên schema public.
REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- Chỉ cấp đúng quyền app cần.
GRANT USAGE ON SCHEMA app TO app_user;

GRANT SELECT ON app.departments TO app_user;   -- danh mục, app chỉ đọc
GRANT SELECT (id, username, department_id, is_admin) ON app.users TO app_user;   -- app chỉ đọc để xác thực, không sửa tài khoản
GRANT SELECT, INSERT, UPDATE, DELETE ON app.documents TO app_user;

-- Cố ý KHÔNG cấp CREATE/DROP/ALTER/TRUNCATE: app bị khai thác cũng không đổi được cấu trúc dữ liệu.
