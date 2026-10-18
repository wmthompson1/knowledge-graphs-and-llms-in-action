# Tier-1 Diagnostic Toolset

## Purpose

Tier-1 tools are read-only, non-mutating probes that allow the orchestrator to gather evidence without violating fail-closed safety rules. These tools are explicitly authorized for troubleshooting and should be distinguishable from Tier-2 destructive operations such as restarts, schema writes, or remote deploy actions.

## Risk tier model

| Tier | Purpose | Examples | Authorization |
|---|---|---|---|
| Tier-0 | Static audit | lint, schema parse, DDL inspection | Auto-allowed |
| Tier-1 | Diagnostic probe | file stats, health checks, log reads, read-only SQL | Auto-allowed for troubleshooting |
| Tier-2 | State mutation | restart, migration, write, deploy | Human/operator approval |

## Tool catalog

### File and filesystem inspection

- `ls -lh <path>`
- `stat <path>`
- `du -sh <path>`
- `find <path> -maxdepth 2 -type f`
- `file <path>`

### Container and runtime inspection

- `docker ps --format '{{.Names}} {{.Status}}'`
- `docker inspect <container>`
- `docker logs --tail 200 <container>`
- `systemctl status <service>`

### Network and service health

- `curl -f -I <url>`
- `curl -sS <url>`
- `ss -lntup`
- `netstat -tulpn`
- `nc -vz <host> <port>`

### Database and metadata inspection

- `sqlite3 <db> '.schema'`
- `sqlite3 <db> 'SELECT name FROM sqlite_master;'`
- read-only analysis queries on metadata tables
- file size checks for database or journaling files

## Safety contract

Tier-1 tools must satisfy all of the following:

- no state mutation,
- no destructive writes,
- no privileged restart or redeploy action,
- output is recorded as evidence,
- result must be referenced by the next state transition.

## Example adapter

```python
def run_probe(command: str) -> dict:
    import subprocess

    result = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True,
        timeout=20,
    )

    return {
        "command": command,
        "returncode": result.returncode,
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
        "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
    }
```

## Integration requirement

Any result from Tier-1 must be appended into the task state as a new empirical fact. This ensures the system cannot loop on documentation without converting probe output into state.

## Operational policy

If the agent has no Tier-1 tool available, the workflow must either:

- explicitly request a diagnostic grant,
- or stop and require human approval.

It must not simply create a narrative note and declare the problem “blocked.”
