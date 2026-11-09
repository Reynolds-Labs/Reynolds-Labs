# ReTune — Live Status Snippet

This excerpt demonstrates how ReTune reads selected live host state.  
It is intentionally a **partial implementation**; the complete application source is not published.

```python
def get_active_profile():
    output = run(["tuned-adm", "active"])
    prefix = "Current active profile:"

    if prefix in output:
        return output.split(prefix, 1)[1].strip()

    return output or "Unknown"


def get_swappiness():
    return run(["sysctl", "-n", "vm.swappiness"]) or "Unknown"


def get_pstate():
    return read_file("/sys/devices/system/cpu/intel_pstate/status")
```

The complete tool also reports the TuneD service state, CPU governor, energy-performance bias,
turbo state, disk read-ahead, and I/O scheduler.
