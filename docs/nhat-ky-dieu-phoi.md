# Nhật ký điều phối

Một dòng cho một lần bàn giao hoặc một mốc đã qua. Người chấm đọc tệp này khi chấm
tiêu chí kế hoạch và điều phối, nên nó là bằng chứng chứ không phải thủ tục.

| Ngày | Ai | Làm gì | Mốc liên quan |
|---|---|---|---|
| 2/10 | Hà | Mối đe dọa, ranh giới, tác nhân đe dọa  | M1 |
| 5/10 | Hà | Dựng khung docker-compose.yml (3 service nginx/web/db, trỏ đúng cau-hinh/ và ma-nguon/), viết docs/architecture.md, review và merge PR của cả nhóm theo đúng thứ tự, cập nhật logbook | M2 |
| 5/10 | Trọng | Viết Dockerfile + cấu hình nginx (TLS bắt buộc, mTLS cho /admin), viết script scripts/generate-dev-certs.sh tự sinh chứng chỉ CA/server/client cho CI, viết script test scripts/test-nginx.sh, chạy testssl xác nhận TLS 1.2/1.3. | M2 |
| 5/10 | Chi | Viết Dockerfile + mã nguồn web app (Flask), kết nối PostgreSQL bằng vai trò app_user qua DATABASE_URL, review phần nginx của Trọng (phát hiện thiếu pin digest, ssl_protocols, cơ chế sinh key cho CI, lệch port test). | M2 |
| 5/10 | Hảo | Viết 01-schema.sql (schema + bảng departments/users/documents, dữ liệu test giả), viết 02-roles.sql tạo vai trò app_user theo đặc quyền tối thiểu kèm GRANT đúng phạm vi. | M2 |
| 5/10 | Trâm | Viết .github/workflows/ci.yml chạy docker compose up, kiểm tra 3 container đang chạy và endpoint /health phản hồi qua nginx, tích hợp bước sinh chứng chỉ trước khi build — CI chạy xanh. | M2 |
| 8/10 | Chi | Viết pytest web M3 cho /health và /db-check; tạo scripts/test-web.sh chạy test bằng Python 3.12 image ghim digest; kiểm thử thực tế 4 ca đều PASS | M3 |
| 8/10 | Chi | Tích hợp session context phòng ban cho /db-check bằng app.current_department; mở rộng 8 pytest web/session đều PASS; kiểm Compose thật xác nhận PostgreSQL nhận department=1, nhưng chưa lọc dữ liệu do RLS chưa có | M3 |
| 8/10 | Hảo | Bật RLS và FORCE trên app.documents theo app.current_department; cấu hình pgAudit ghi DDL/ALTER ROLE; chạy scripts/test-db.sh và scripts/test-audit.sh trên Docker, lưu bằng chứng vào bang-chung/db/ | M3 |
| 8/10 | Chi | Viết 8 integration pytest T1/T5 trên PostgreSQL thật, tạo scripts/test-m3-security.sh; chạy 8/8 PASS và lưu evidence bang-chung/db/test-m3-security-chi.txt | M3 |
| 9/10 | Hà | Chốt phương án T3: hostssl + ssl=on + scram-sha-256, web dùng PGSSLMODE=verify-full; bỏ clientcert và phần sửa web; cert client cho DB ghi vào mục giới hạn và hướng mở rộng của báo cáo | M4 |
| 9/10 | Hà | Lấy bằng chứng trạng thái trước khi làm cứng cho T1, T2, T3, T5 (T3 lấy trên main trước khi PR T3 merge; T1 tắt tạm RLS, T5 Postgres gốc không pgaudit, T2 nginx gốc không TLS), lưu vào bang-chung/ | M4 |
| 9/10 | Hà | Đối chiếu hiện trạng repo với bốn loại bằng chứng của đề, xác định còn thiếu bảng đối chiếu trước/sau, báo cáo, MANIFEST và quét gitleaks | M4 |
| 9/10 | Trọng | Xử lý góp ý review T3: bỏ PostgreSQL client-certificate mTLS khỏi kết nối web–DB; giữ PostgreSQL TLS, xác minh chứng chỉ máy chủ và SCRAM-SHA-256; khôi phục web chạy UID 10001; giữ Nginx mTLS cho /admin. Chạy lại T3, Nginx và web tests; ghi nhận riêng các lỗi T1/RLS, T5/pgAudit chưa xử lý trong thay đổi này. | M3/T3 |
| 9/10 | Hà | Viết scripts/make-manifest.sh (MANIFEST sha256) và scripts/scan-secrets.sh (gitleaks), thêm các target make preflight, attack, defend, export-evidence | M3 |
| 9/10 | Hà | Viết bản đầu docs/bao-cao.md, cập nhật tính ALE, sửa threat-model.json và mục 2 cho khớp cấu hình thật | M3 |
| 10/10 | Hà | Chạy thật attack.sh trên Docker: phát hiện bản đầu báo SUCCEEDED sai trên Windows do đọc %{redirect_url}; sửa sang đọc header bằng curl -I, kết quả 6 phép thử BLOCKED, lưu bang-chung/attack/attack.txt | M3 |
| 10/10 | Hà | Phát hiện MANIFEST.txt lệch sha256 ở 19/22 tệp vì băm khi file là CRLF (Windows) còn git lưu LF; xác định cách xử lý bằng .gitattributes (bang-chung/** -text) và sinh lại MANIFEST sau khi chuẩn hóa LF | M4 |
| 10/10 | Hà | Sửa lỗi curl thoát mã 23 trong script; xử lý 5 góp ý review của Chi trên PR #30; thống nhất email tác giả commit (PR #31); kiểm CI xanh ở commit fb09032 | M3 |
| 11/10 | Hà | Chỉnh docs/bao-cao.md cho khớp bản main (6 mục): đối chiếu cấu hình nginx, RLS, pg_hba, bảng ALE với scripts/tinh-ale.py, ghi rõ giới hạn (APP_DEPARTMENT_ID cố định, T4 chỉ nhận diện, testssl mới chạy cổng 8443), lập bảng pull request của cả nhóm | M3 |
| 11/10 | Hà | Chỉnh cột "Phần việc chính" trong NHOM.md theo nhật ký này; còn lại cho M4: PR bổ sung 4 tệp bằng chứng CI, .gitattributes, chạy lại testssl cổng 443, gắn thẻ nộp | M3/M4 |
| 19/10 | Trâm | PR bằng chứng CI: lấy artifact `bang-chung` (run [38157131256](https://github.com/UEH-CSS-26C/CSS-26C-N03-TH-True-Milk/actions/runs/38157131256), workflow "Cổng an toàn", xanh trên main, commit b38c8b23b459fd6e227203d168ecd8c54a241942, ngày 11/10) và chép nguyên vẹn 4 tệp vào bang-chung/: nginx/test-nginx.txt (3 PASS), web/test-web.txt (8 passed), db/test-m3-security.txt (8 passed), secrets/gitleaks.txt (no leaks found). Đây là bằng chứng của commit b38c8b2; các PR sau đó (#33, #34, #35) chưa có lần chạy Actions xanh nên chưa được tính. Chưa sinh lại MANIFEST (Trọng phụ trách) | M4 |
| 19/10 | Trâm | Kiểm SBOM và Cosign trên run main [38157131284](https://github.com/UEH-CSS-26C/CSS-26C-N03-TH-True-Milk/actions/runs/38157131284) (workflow "CI - dựng hệ thống M2", cùng commit b38c8b2): Syft 1.54.1 (ghim digest) sinh 3 SBOM CycloneDX 1.7 cho web (3375 thành phần), nginx (1305), db (7388); Cosign v2.4.3 ký keyless (`sign-blob`) và `verify-blob` với `--certificate-identity` và issuer token.actions.githubusercontent.com, log ghi `Verified OK` cho cả 3 tệp web.cdx.json, nginx.cdx.json, db.cdx.json; artifact `sbom-38157131284-1` gồm 3 SBOM và 3 bundle .sigstore.json. Lưu ý: SBOM trong bang-chung/sbom/ của main được commit từ lần chạy trước, không trùng hash với artifact này. Tên image trong SBOM là đường dẫn tar tạm (/src/.syft.*/web.tar...), nên nhận diện image qua digest sha256 chứ không qua tên. GitHub Actions đang báo lỗi billing nên chưa chạy lại được trên commit mới | M4 |
