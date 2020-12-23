-- `GITHUB_HEAD_REF` is the branch name, only defined for a PR
-- otherwise falls back to `GITHUB_REF`, where we have to strip the leading `refs/heads/`

-- NOTE: this is the bash equivalent of Workflow.Expr.branchRef,
-- it's terser but only works in bash, not GH expression syntax
"\$(if [[ -n \${GITHUB_HEAD_REF:-} ]]; then echo \"\$GITHUB_HEAD_REF\"; else echo \"\${GITHUB_REF##refs/heads/}\"; fi)"
