# Taste
- Communicates in Korean; prefers responses and status updates written in Korean. Confidence: 0.6
- Prefers to do final verification personally: asks the agent to build and launch the app on an emulator, then inspects it themselves rather than relying on agent-run UI checks. Confidence: 0.7
- Development environment is Windows (E:\ drive projects, Flutter + Android emulator workflow); shell commands must target PowerShell, not Unix (`tail`, pipes to `Select-Object`). Confidence: 0.6
- Workflow habit: before switching to a different project/device, expects the current work to be committed and pushed to GitHub (`origin/main`) so it can be pulled elsewhere — treat "is it safe/uploadable?" as a checkpoint step. Confidence: 0.7
- For git checkpoint uploads, prefers the low-ceremony path: one single commit containing everything (code + docs + assets) pushed straight to main, rather than logically-split commit series or feature branches. Confidence: 0.5
- Handles secret/credential incidents personally: chooses to rotate/re-issue leaked API keys themselves rather than having the agent rewrite git history (filter-repo + force-push). Agent should still surface and report such leaks. Confidence: 0.5
