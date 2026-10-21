#!/bin/sh

set -eu

echo "      DATABASE ROW LEVEL SECURITY TESTS (T1)"
echo

POLICY=$(docker compose exec -T db psql -U postgres -d appdb -At -F '|' \
    -c "SELECT policyname, roles::text, cmd FROM pg_policies WHERE schemaname = 'app' AND tablename = 'documents';")

if [ "$POLICY" = "documents_by_department|{app_user}|ALL" ]; then
    echo "PASS: documents_by_department policy applies to app_user"
else
    echo "FAIL: unexpected documents RLS policy: ${POLICY:-<none>}"
    exit 1
fi

RLS_FLAGS=$(docker compose exec -T db psql -U postgres -d appdb -At \
    -c "SELECT CASE WHEN relrowsecurity AND relforcerowsecurity THEN 'enabled-and-forced' ELSE 'not-enabled-or-not-forced' END FROM pg_class WHERE oid = 'app.documents'::regclass;")

if [ "$RLS_FLAGS" = "enabled-and-forced" ]; then
    echo "PASS: row-level security is enabled and forced"
else
    echo "FAIL: row-level security is not both enabled and forced"
    exit 1
fi

NO_CONTEXT=$(docker compose exec -T db psql -U app_user -d appdb -At -F '|' \
    -c "SELECT department_id, count(*) FROM app.documents GROUP BY department_id ORDER BY department_id;")

if [ -z "$NO_CONTEXT" ]; then
    echo "PASS: app_user sees no documents without department context"
else
    echo "FAIL: app_user saw documents without context: $NO_CONTEXT"
    exit 1
fi

DEPARTMENT_ONE_OUTPUT=$(docker compose exec -T db psql -U app_user -d appdb -At -F '|' \
    -c "BEGIN; SELECT set_config('app.current_department', '1', true); SELECT department_id, count(*) FROM app.documents GROUP BY department_id ORDER BY department_id; COMMIT;")
DEPARTMENT_ONE=$(printf '%s\n' "$DEPARTMENT_ONE_OUTPUT" \
    | sed -n '/^[0-9][0-9]*|[0-9][0-9]*$/p')

if [ "$DEPARTMENT_ONE" = "1|2" ]; then
    echo "PASS: department 1 sees exactly its 2 documents"
else
    echo "FAIL: unexpected documents visible to department 1: ${DEPARTMENT_ONE:-<none>}"
    exit 1
fi

DEPARTMENT_NINETY_NINE_OUTPUT=$(docker compose exec -T db psql -U app_user -d appdb -At -F '|' \
    -c "BEGIN; SELECT set_config('app.current_department', '99', true); SELECT department_id, count(*) FROM app.documents GROUP BY department_id ORDER BY department_id; COMMIT;")
DEPARTMENT_NINETY_NINE=$(printf '%s\n' "$DEPARTMENT_NINETY_NINE_OUTPUT" \
    | sed -n '/^[0-9][0-9]*|[0-9][0-9]*$/p')

if [ -z "$DEPARTMENT_NINETY_NINE" ]; then
    echo "PASS: unknown department context sees no documents"
else
    echo "FAIL: unexpected documents visible to department 99: $DEPARTMENT_NINETY_NINE"
    exit 1
fi

if INSERT_OUTPUT=$(docker compose exec -T db psql -U app_user -d appdb \
    -c "BEGIN; SELECT set_config('app.current_department', '1', true); INSERT INTO app.documents (department_id, title, content) VALUES (2, 'RLS negative test', 'Should be rejected by policy'); COMMIT;" 2>&1); then
    echo "FAIL: app_user inserted a document into another department"
    exit 1
fi

if printf '%s\n' "$INSERT_OUTPUT" | grep -Fq 'violates row-level security policy'; then
    echo "PASS: RLS rejected insert into another department"
else
    echo "FAIL: insert failed for an unexpected reason:"
    printf '%s\n' "$INSERT_OUTPUT"
    exit 1
fi

# T1-07 (ca am): app_user doc cot password_hash cua app.users phai bi tu choi.
# Quyen SELECT tren app.users duoc cap theo cot (02-roles.sql), khong gom password_hash.
if HASH_OUTPUT=$(docker compose exec -T db psql -U app_user -d appdb \
    -c "SELECT password_hash FROM app.users;" 2>&1); then
    echo "FAIL: app_user read app.users.password_hash"
    exit 1
fi

if printf '%s\n' "$HASH_OUTPUT" | grep -Fq 'permission denied for table users'; then
    echo "PASS: app_user is denied SELECT on app.users.password_hash"
else
    echo "FAIL: password_hash read failed for an unexpected reason:"
    printf '%s\n' "$HASH_OUTPUT"
    exit 1
fi

# "SELECT *" cung phai bi tu choi vi * bao gom password_hash.
if STAR_OUTPUT=$(docker compose exec -T db psql -U app_user -d appdb \
    -c "SELECT * FROM app.users;" 2>&1); then
    echo "FAIL: app_user read app.users with SELECT *"
    exit 1
fi

if printf '%s\n' "$STAR_OUTPUT" | grep -Fq 'permission denied for table users'; then
    echo "PASS: app_user is denied SELECT * on app.users"
else
    echo "FAIL: SELECT * failed for an unexpected reason:"
    printf '%s\n' "$STAR_OUTPUT"
    exit 1
fi

# T1-08 (ca duong): cac cot duoc cap van doc duoc (4 tai khoan du lieu gia).
USER_COUNT=$(docker compose exec -T db psql -U app_user -d appdb -At \
    -c "SELECT count(*) FROM (SELECT id, username, department_id, is_admin FROM app.users) t;" | tr -d '\r')

if [ "$USER_COUNT" = "4" ]; then
    echo "PASS: app_user reads the granted columns of app.users (4 rows)"
else
    echo "FAIL: unexpected granted-column read of app.users: ${USER_COUNT:-<none>}"
    exit 1
fi

echo
echo "ALL T1 DATABASE RLS TESTS PASSED"
