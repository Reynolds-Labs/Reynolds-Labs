# ReTune — Privilege Boundary Snippet

This excerpt demonstrates the allowlist used by the privileged ReTune helper.  
It is intentionally a **partial implementation**; the complete application source is not published.

```bash
case "${1:-}" in
    workstation) PROFILE="rlab-workstation" ;;
    balanced)    PROFILE="balanced" ;;
    eco)         PROFILE="rlab-eco" ;;
    performance) PROFILE="rlab-performance" ;;
    containers)  PROFILE="rlab-containers" ;;
    *)
        echo "ReTune: invalid profile request." >&2
        exit 2
        ;;
esac
```

The GUI runs unprivileged and requests only predefined profile changes through `pkexec`/PolicyKit.
