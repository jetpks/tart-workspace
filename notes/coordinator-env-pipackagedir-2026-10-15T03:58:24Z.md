# Coordinator env finding (rev4 relaunch) — PI_PACKAGE_DIR leaks into child sessions; the pinned 1.1.0 bundle honors it at runtime

UTC: 2026-10-15T03:58:24Z (coordinator session, run-resume from notes/exception-2026-10-15T03:39:58Z.md)

Measured facts:
1. Coordinator/child sessions inherit PI_PACKAGE_DIR=/Users/eric/.local/share/mise/installs/node/24.18.0/lib/node_modules/@earendil-works/pi-coding-agent (the GLOBAL 1.2.0 install), plus PI_MODEL/PI_PROVIDER/PI_CONTEXT_WINDOW-class keys. The repair session's smoke shell evidently did not carry it; every pi-subagent child DOES.
2. The pinned 1.1.0 build (repos/pi @ f1b2e77f, shim bin/pi) reads PI_PACKAGE_DIR at RUNTIME (dist getPackageDir honors it before findNodePackageDir). With the leak present, shimmed pi reports 1.2.0; with 'env -u PI_PACKAGE_DIR', it reports 1.1.0. Verified both ways this session.
3. Rig panes are IMMUNE: gems/tui-split-rig runner.rb env_flags scrubs every parent PI_*/TART_* key not in the staged set (-u flags) — this is why the repair smoke (repos/tart/tmp/oracle-pin-s1, rig s1 exit 0) is valid regardless of the operator shell.
4. Direct bin/tart runs with the shim first on PATH: tart resolves pi docs paths by realpath(walk-up) from the shim (system_prompt.rb pi_package_dir) → no package dir → NO <docs> section. The frozen wire-delta instruction-digest literal 2faaf667 stays unattainable = the standing E3 environment class (the builder's residual diff was the 1-line out-dir canonical-depth artifact; base==lane modulo that line).

Directive for every child shell that touches pi/tart directly:
  export PATH="/Users/eric/architect/spaces/20261009-pi-port/bin:$PATH"
  unset PI_PACKAGE_DIR PI_MODEL PI_PROVIDER PI_CONTEXT_WINDOW   # or env -u per call
Rig gates need only the PATH prepend (the rig self-scrubs PI_*/TART_*).
