# Project Rules — Calc-Calories

## Git Commit Rule (CRITICAL)
After **every single file change**, stop immediately and provide the user with the exact
git commands to stage, commit, and push that file before proceeding to the next change.

Use this exact format after each file edit:

```
> ✅ [filename] updated. Run this to commit:

git add <relative-file-path>
git commit -m "describe what changed"
git push origin main
```

Do NOT batch multiple file changes into one commit unless the user explicitly says so.
Wait for the user to confirm the commit before continuing to the next file.
