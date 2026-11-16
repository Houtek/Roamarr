# shellcheck shell=bash disable=SC2034  # sourced by pr-gates.sh, which reads the MUT_* variables
# G5 mutations for the notice contrast fix (warning/success text on light themes).
# Each mutation asserts it actually changed the file (grep), so a no-op sed can't fake a pass.
MUT_FILES="src/app.css"
MUT_TESTS="src/lib/noticeContrast.test.ts"
MUT_PREP=""
# Back to the fixed dark-theme shade for warnings (the original bug).
mutate warning-fixed-shade "sed -i 's#@apply bg-amber-500/10 ring-amber-400/30;#@apply bg-amber-500/10 text-amber-300 ring-amber-400/30;#' src/app.css && grep -q 'text-amber-300 ring-amber-400/30' src/app.css"
# The light themes lose their success override: the dark default (300) shows on light.
mutate success-no-light-override "sed -i '/--theme-success-text: var(--color-emerald-800);/d' src/app.css && ! grep -q 'theme-success-text: var(--color-emerald-800)' src/app.css"
# A light override that is still too pale (500 shade).
mutate warning-pale-override "sed -i 's#--theme-warning-text: var(--color-amber-800);#--theme-warning-text: var(--color-amber-500);#' src/app.css && grep -q 'theme-warning-text: var(--color-amber-500)' src/app.css"
