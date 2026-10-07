#!/usr/bin/env bash
# Usage: ./test_cubex.sh                       (all tests, including network)
#        CUBEX_TEST_NETWORK=0 ./test_cubex.sh  (skip search/pull)
set -u

BINS=(cubex cx)
IMAGE=docker.io/library/busybox:musl
pass=0
fail=0

ok()  { pass=$((pass + 1)); echo "PASS: $*"; }
bad() { fail=$((fail + 1)); echo "FAIL: $*" >&2; }

# run "<command line>" and expect exit 0
t_ok() {
  local label=$1 cmd=$2 rc
  # shellcheck disable=SC2086
  $cmd >/dev/null 2>&1
  rc=$?
  [[ $rc -eq 0 ]] && ok "$label" || bad "$label (exit $rc)"
}

# run "<command line>", expect exit 0 and output matching regex
t_match() {
  local label=$1 re=$2 cmd=$3 out rc
  # shellcheck disable=SC2086
  out=$($cmd 2>&1)
  rc=$?
  if [[ $rc -ne 0 ]]; then
    bad "$label (exit $rc)"
  elif grep -Eq "$re" <<<"$out"; then
    ok "$label"
  else
    bad "$label (output does not match: $re)"
  fi
}

# run "<command line>" and expect non-zero exit
t_fail() {
  local label=$1 cmd=$2
  # shellcheck disable=SC2086
  $cmd >/dev/null 2>&1 && bad "$label (unexpected success)" || ok "$label"
}

# run two command lines, expect identical output and exit code
t_same() {
  local label=$1 a=$2 b=$3 out_a out_b rc_a rc_b
  # shellcheck disable=SC2086
  out_a=$($a 2>&1); rc_a=$?
  # shellcheck disable=SC2086
  out_b=$($b 2>&1); rc_b=$?
  if [[ $rc_a -eq $rc_b && $out_a == "$out_b" ]]; then
    ok "$label"
  else
    bad "$label ('$a' differs from '$b')"
  fi
}

# --- prerequisites ---
for b in "${BINS[@]}"; do
  command -v "$b" >/dev/null || { echo "FAIL: '$b' not found in PATH" >&2; exit 1; }
done

# --- cx is a symlink/alias of cubex ---
real_cubex=$(readlink -f "$(command -v cubex)")
real_cx=$(readlink -f "$(command -v cx)")
if [[ $real_cubex == "$real_cx" ]]; then
  ok "cx resolves to cubex"
else
  bad "cx -> $real_cx, cubex -> $real_cubex"
fi

# --- per-binary tests ---
for b in "${BINS[@]}"; do
  for f in -v --version; do t_match "$b $f prints version" '[0-9]+\.[0-9]+' "$b $f"; done
  for f in -h --help;    do t_match "$b $f prints usage"   'Usage'          "$b $f"; done

  for c in "l" "list" "l r" "list registry"; do
    t_ok "$b $c" "$b $c"
  done

  t_fail "$b unknown command fails" "$b no-such-command"
done

# --- abbreviation == full form, and cx == cubex ---
pairs=("-v|--version" "-h|--help" "l|list" "l r|list registry")
for p in "${pairs[@]}"; do
  short=${p%%|*}
  full=${p##*|}
  for b in "${BINS[@]}"; do
    t_same "$b '$short' == '$full'" "$b $short" "$b $full"
  done
  t_same "cx '$full' == cubex '$full'" "cx $full" "cubex $full"
done

# --- network tests (default on; CUBEX_TEST_NETWORK=0 to skip) ---
if [[ ${CUBEX_TEST_NETWORK:-1} == 1 ]]; then
  for b in "${BINS[@]}"; do
    t_ok "$b search $IMAGE" "$b search $IMAGE"
    t_ok "$b pull $IMAGE"   "$b pull $IMAGE"
  done
else
  echo "SKIP: search/pull (CUBEX_TEST_NETWORK=0)"
fi

# --- summary ---
echo "---"
echo "passed: $pass, failed: $fail"
[[ $fail -eq 0 ]]
