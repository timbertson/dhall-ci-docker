-- `GITHUB_HEAD_REF` is the branch name, only defined for a PR
-- otherwise falls back to `GITHUB_REF`, where we have to strip the leading `refs/heads/`
"\$(if [[ -n \${GITHUB_HEAD_REF:-} ]]; then echo \"\$GITHUB_HEAD_REF\"; else echo \"\${GITHUB_REF##refs/heads/}\"; fi)"
