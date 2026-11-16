# shellcheck shell=bash disable=SC2034  # sourced by pr-gates.sh, which reads the MUT_* variables
# G5 mutations for the default page title branch (issue #12): sourced by pr-gates.sh.
# Each mutation asserts it actually changed the file (grep), so a no-op sed can't fake a pass.
MUT_FILES="src/routes/+layout.svelte"
MUT_TESTS="src/routes/layoutTitle.test.ts"
MUT_PREP=""
mutate title-removed "sed -i '/<title>{data.instanceName || .Roamarr.}<\/title>/d' src/routes/+layout.svelte && ! grep -q '<title>{data.instanceName' src/routes/+layout.svelte"
mutate fallback-removed "sed -i \"s#<title>{data.instanceName || 'Roamarr'}</title>#<title>{data.instanceName}</title>#\" src/routes/+layout.svelte && grep -q '<title>{data.instanceName}</title>' src/routes/+layout.svelte"
