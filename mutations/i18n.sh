# shellcheck shell=bash disable=SC2034  # sourced by pr-gates.sh, which reads the MUT_* variables
# G5 mutations for the i18n branch (PR #11): sourced by pr-gates.sh.
MUT_FILES="project.inlang/settings.json messages/en.json"
MUT_TESTS="src/lib/i18n-catalog.test.ts src/routes/login/login-page.test.ts"
MUT_PREP="npx paraglide-js compile --project ./project.inlang"
mutate catalog-gone "sed -i 's#\"modules\": \\[[^]]*\\]#\"modules\": [\"./node_modules/@inlang/does-not-exist/index.js\"]#' project.inlang/settings.json"
mutate one-message-blank "sed -i 's#\"login_title\": \"[^\"]*\"#\"login_title\": \"\"#' messages/en.json && grep -q '\"login_title\": \"\"' messages/en.json"
