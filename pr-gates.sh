#!/usr/bin/env bash
# pr-gates.sh: offline gates G3-G6 of pr-preflight.sh, for a CI container started with
# `--network none`. Same checks, no sudo/netns needed (the container has no network).
#   pr-gates.sh <branch-dir> <master-dir> <out-dir>
# Both dirs already have node_modules (npm ci ran in a networked container before).
set -uo pipefail
B=$1; M=$2; O=$3
mkdir -p "$O"; T=$(mktemp -d); fails=()
pass() { printf '  PASS %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; fails+=("$1"); }

if curl -sS -m5 https://registry.npmjs.org >/dev/null 2>&1; then echo "network reachable: refusing (must run with --network none)"; exit 3; fi
echo "glibc: $(ldd --version | head -1) / node $(node -v) / network: none (verified)"

warnings() { grep -i -E 'warn|error|IMPORT_IS_UNDEFINED|fetch failed' "$1" | sed -E 's/[0-9]+(\.[0-9]+)?m?s\b//g' | sort -u; }

# G3 offline build vs master
(cd "$B" && npm run build >"$O/branch.build.log" 2>&1); rb=$?
(cd "$M" && npm run build >"$O/master.build.log" 2>&1); rm_=$?
if [ $rb -ne 0 ]; then
	fail "G3 offline build failed (exit $rb)"; tail -20 "$O/branch.build.log"
else
	new=$(comm -23 <(warnings "$O/branch.build.log") <([ $rm_ -eq 0 ] && warnings "$O/master.build.log"))
	broken=$(grep -rl 'void 0)()' "$B/build" 2>/dev/null | head -3)
	if [ -n "$new" ] || [ -n "$broken" ]; then fail "G3 new warnings vs master or broken output"; printf '    %s\n' "$new" $broken
	else pass "G3 offline build, no warnings beyond master's"; fi
fi

# G4 check + full suite
(cd "$B" && npm run check >"$O/check.log" 2>&1) && pass "G4 npm run check" || { fail "G4 npm run check"; tail -20 "$O/check.log"; }
(cd "$B" && TMPDIR="$T" npx vitest run >"$O/test.log" 2>&1) \
	&& pass "G4 full suite: $(sed 's/\x1b\[[0-9;]*m//g' "$O/test.log" | grep -E '^ +Tests ' | xargs)" \
	|| { fail "G4 test suite"; sed 's/\x1b\[[0-9;]*m//g' "$O/test.log" | grep -E ' FAIL |×' | head -20; }

# G5 mutations: the i18n tests must FAIL on each
mutate() {
	(cd "$B" && git checkout -q -- project.inlang/settings.json messages/en.json && sh -c "$2" \
		&& npx paraglide-js compile --project ./project.inlang >/dev/null 2>&1; \
		TMPDIR="$T" npx vitest run src/lib/i18n-catalog.test.ts src/routes/login/login-page.test.ts >"$O/mustfail-$1.log" 2>&1)
	local rc=$?
	(cd "$B" && git checkout -q -- project.inlang/settings.json messages/en.json)
	if [ $rc -ne 0 ] && grep -q 'FAIL' "$O/mustfail-$1.log"; then pass "G5 i18n tests fail on mutation: $1"
	else fail "G5 i18n tests still PASS on mutation: $1"; fi
}
mutate catalog-gone "sed -i 's#\"modules\": \\[[^]]*\\]#\"modules\": [\"./node_modules/@inlang/does-not-exist/index.js\"]#' project.inlang/settings.json"
mutate one-message-blank "sed -i 's#\"login_title\": \"[^\"]*\"#\"login_title\": \"\"#' messages/en.json && grep -q '\"login_title\": \"\"' messages/en.json"

# G6 docs drift (generated files excluded)
drift=0
while IFS= read -r tok; do
	[ -z "$tok" ] && continue
	if git -C "$B" grep -q -F "$tok" HEAD -- '*.md'; then echo "    still in docs: $tok"; drift=1; fi
done < <(git -C "$B" diff "origin/master...HEAD" -- . ':!*.generated.*' ':!package-lock.json' \
	| grep -E '^-[^-]' | grep -o -E 'https?://[^" )]+|cdn\.[a-z.]+' | sort -u)
[ $drift = 0 ] && pass "G6 no removed URL/host left in *.md" || fail "G6 docs drift"

rm -r "$T"
echo
if [ ${#fails[@]} -eq 0 ]; then echo "pr-gates: ALL GREEN"; exit 0; fi
echo "pr-gates: ${#fails[@]} FAILED: ${fails[*]}"; exit 1
