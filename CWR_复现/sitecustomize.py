try:
    import runners.runner_ce_save  # 触发 registry.register_runner
except Exception as _e:
    import sys; print("[sitecustomize] runner import failed:", _e, file=sys.stderr)
