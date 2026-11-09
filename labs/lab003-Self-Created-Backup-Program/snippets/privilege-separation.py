# Portfolio excerpt — simplified privilege boundary.
# Intentionally not the complete RL_Backup implementation.

def privileged_command(action):
    allowed_actions = {"backup", "verify", "full-verify", "restore-local"}
    if action not in allowed_actions:
        raise ValueError("Unsupported privileged action")
    return ["/usr/bin/pkexec", "/usr/local/sbin/rl-backup-control", action]
