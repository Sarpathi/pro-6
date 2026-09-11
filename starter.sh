#!/bin/bash

# ============================================================
# Linux Security Assignment
# Secure Departmental Directory
# ============================================================

set -e

# -----------------------------
# Configuration
# -----------------------------

GROUP_NAME="students"

USER1="student1"
USER2="student2"
UNAUTHORIZED="unauthorized"

BASE_DIR="/opt/department"
STUDENT_DIR="/opt/department/students"
TEST_FILE="/opt/department/students/student_info.txt"

# SELinux type used for content that an HTTP service can read.
SELINUX_TYPE="httpd_sys_content_t"

# Allows httpd to read user content.
SELINUX_BOOLEAN="httpd_read_user_content"

echo "======================================"
echo " Linux Security Assignment"
echo "======================================"

# ------------------------------------------------------------
# TODO 1: Check that the script is running as root
# ------------------------------------------------------------

echo "[1] Checking root privileges..."

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root."
    exit 1
fi

# ------------------------------------------------------------
# TODO 2: Check SELinux status
# ------------------------------------------------------------

echo "[2] Checking SELinux..."

if ! command -v getenforce >/dev/null 2>&1; then
    echo "ERROR: SELinux tools are not installed."
    exit 1
fi

SELINUX_STATUS="$(getenforce)"

if [ "${SELINUX_STATUS}" != "Enforcing" ]; then
    echo "ERROR: SELinux must be enabled and enforcing."
    echo "Current status: ${SELINUX_STATUS}"
    exit 1
fi

echo "SELinux status: ${SELINUX_STATUS}"

# ------------------------------------------------------------
# TODO 3: Create the students group
# ------------------------------------------------------------

echo "[3] Creating group: ${GROUP_NAME}"

if ! getent group "${GROUP_NAME}" >/dev/null 2>&1; then
    groupadd "${GROUP_NAME}"
    echo "Group created."
else
    echo "Group already exists."
fi

# ------------------------------------------------------------
# TODO 4: Create users
# ------------------------------------------------------------

echo "[4] Creating users..."

if ! id "${USER1}" >/dev/null 2>&1; then
    useradd "${USER1}"
    echo "Created ${USER1}."
else
    echo "${USER1} already exists."
fi

if ! id "${USER2}" >/dev/null 2>&1; then
    useradd "${USER2}"
    echo "Created ${USER2}."
else
    echo "${USER2} already exists."
fi

if ! id "${UNAUTHORIZED}" >/dev/null 2>&1; then
    useradd "${UNAUTHORIZED}"
    echo "Created ${UNAUTHORIZED}."
else
    echo "${UNAUTHORIZED} already exists."
fi

# Add students to the students group.
usermod -aG "${GROUP_NAME}" "${USER1}"
usermod -aG "${GROUP_NAME}" "${USER2}"

# Make sure unauthorized is NOT a member of students.
if id -nG "${UNAUTHORIZED}" | tr ' ' '\n' | grep -qx "${GROUP_NAME}"; then
    gpasswd -d "${UNAUTHORIZED}" "${GROUP_NAME}" >/dev/null
fi

# ------------------------------------------------------------
# TODO 5: Create departmental directory
# ------------------------------------------------------------

echo "[5] Creating directory..."

mkdir -p "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 6: Configure ownership and permissions
# ------------------------------------------------------------

echo "[6] Configuring ownership and permissions..."

# Root owns the directory; students is the controlling group.
chown root:"${GROUP_NAME}" "${BASE_DIR}"
chown root:"${GROUP_NAME}" "${STUDENT_DIR}"

# Department directory: accessible to root and students.
chmod 2770 "${STUDENT_DIR}"

# Prevent unauthorized access through the parent directory.
chmod 0750 "${BASE_DIR}"

# ------------------------------------------------------------
# TODO 7: Create test file
# ------------------------------------------------------------

echo "[7] Creating test file..."

cat > "${TEST_FILE}" <<EOF
This is the departmental student information file.
Members of the students group may access this file.
EOF

chown root:"${GROUP_NAME}" "${TEST_FILE}"
chmod 0660 "${TEST_FILE}"

# ------------------------------------------------------------
# TODO 8: Configure persistent SELinux file context
# ------------------------------------------------------------

echo "[8] Configuring SELinux file context..."

# Install semanage if it is not available.
if ! command -v semanage >/dev/null 2>&1; then
    echo "semanage not found."

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y policycoreutils-python-utils
    elif command -v yum >/dev/null 2>&1; then
        yum install -y policycoreutils-python-utils
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y policycoreutils
    else
        echo "ERROR: Could not determine package manager."
        exit 1
    fi
fi

# Remove an existing rule for this exact path if present.
semanage fcontext -d -m "${STUDENT_DIR}(/.*)?" 2>/dev/null || true

# Add a persistent SELinux file-context rule.
semanage fcontext -a -t "${SELINUX_TYPE}" "${STUDENT_DIR}(/.*)?"

# Apply the persistent context.
restorecon -Rv "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 9: Configure SELinux boolean
# ------------------------------------------------------------

echo "[9] Configuring SELinux boolean..."

if getsebool "${SELINUX_BOOLEAN}" >/dev/null 2>&1; then
    setsebool -P "${SELINUX_BOOLEAN}" on
    echo "${SELINUX_BOOLEAN} enabled persistently."
else
    echo "ERROR: SELinux boolean '${SELINUX_BOOLEAN}' is not available."
    exit 1
fi

# ------------------------------------------------------------
# TODO 10: Verification
# ------------------------------------------------------------

echo "[10] Verification"

echo
echo "Users:"
id "${USER1}" || true
id "${USER2}" || true
id "${UNAUTHORIZED}" || true

echo
echo "Directory:"
ls -ld "${STUDENT_DIR}" || true

echo
echo "Test file:"
ls -l "${TEST_FILE}" || true

echo
echo "SELinux context:"
ls -Zd "${STUDENT_DIR}" || true
ls -Z "${TEST_FILE}" || true

echo
echo "SELinux status:"
getenforce || true

echo
echo "Selected SELinux boolean:"
getsebool "${SELINUX_BOOLEAN}" || true

echo
echo "======================================"
echo " Script completed"
echo "======================================"
