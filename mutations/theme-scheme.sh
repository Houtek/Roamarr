# shellcheck shell=bash disable=SC2034  # sourced by pr-gates.sh, which reads the MUT_* variables
# G5 mutations for the theme-scheme fix (no light-dark(): readable colours follow the selected theme).
# Each mutation asserts it actually changed the file (grep), so a no-op sed can't fake a pass.
MUT_FILES="src/app.css"
MUT_TESTS="src/lib/themeScheme.test.ts"
MUT_PREP=""
# The original bug: trip-page text back on light-dark() (follows the OS).
mutate trip-light-dark "sed -i 's#--trip-readable-strong: var(--theme-trip-readable, \#ffffff);#--trip-readable-strong: light-dark(\#111111, \#ffffff);#' src/app.css && grep -q 'trip-readable-strong: light-dark(' src/app.css"
# The light theme loses its trip override: dark-theme white text on the light theme.
mutate light-no-trip-override "sed -i '0,/--theme-trip-readable: #111111;/{/--theme-trip-readable: #111111;/d}' src/app.css && [ \"\$(grep -c 'theme-trip-readable: #111111;' src/app.css)\" = 1 ]"
# Danger bypasses the override and is hard-wired to the dark value.
mutate danger-hardwired "sed -i 's#--theme-readable-danger: var(--theme-danger-readable, var(--theme-danger-border));#--theme-readable-danger: var(--theme-danger-border);#' src/app.css && grep -q 'theme-readable-danger: var(--theme-danger-border);' src/app.css"
