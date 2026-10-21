#!/bin/sh
# test-audit-password.sh - Kiem pgaudit co ghi mat khau cua CREATE/ALTER ROLE ... PASSWORD vao log hay khong.
#   sh scripts/test-audit-password.sh      (can "make up" truoc)
# Dung mat khau canary tu sinh, KHONG phai bi mat that. Script chi KET LUAN, khong lam CI do:
# thoat 0 ca khi mat khau lo (day la ket qua can ghi vao bao cao, khong phai loi cua script).
# Dong ket luan cuoi: "AUDIT-PASSWORD RESULT: ..."
set -eu

echo "      PGAUDIT VA MAT KHAU TRONG LOG (T5)"
echo

ROLE="audit_pw_probe_$$"
CANARY="canary_pw_$$_$(date -u +%s)"

docker compose exec -T db psql -U postgres -d appdb \
    -c "CREATE ROLE ${ROLE} LOGIN PASSWORD '${CANARY}';" \
    -c "ALTER ROLE ${ROLE} PASSWORD '${CANARY}_2';" \
    -c "DROP ROLE ${ROLE};"

LOG_FILE=$(mktemp)
trap 'rm -f "$LOG_FILE"' EXIT HUP INT TERM
docker compose logs --no-color db > "$LOG_FILE"

if ! grep -Fq "${ROLE}" "$LOG_FILE"; then
    echo "FAIL: pgaudit khong ghi thao tac CREATE ROLE ${ROLE}"
    exit 1
fi
echo "PASS: pgaudit ghi CREATE ROLE / ALTER ROLE / DROP ROLE cua vai tro thu"

if grep -Fq "${CANARY}" "$LOG_FILE"; then
    echo "AUDIT-PASSWORD RESULT: LO - pgaudit ghi nguyen van mat khau trong CREATE/ALTER ROLE ... PASSWORD; can loc log hoac dat mat khau bang cach khac (vd. truyen ma bam SCRAM)"
else
    echo "AUDIT-PASSWORD RESULT: KHONG LO - mat khau khong xuat hien trong log pgaudit"
fi
