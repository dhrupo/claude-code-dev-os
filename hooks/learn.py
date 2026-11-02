import hashlib, json, os, sys
try:
    ev = json.load(sys.stdin)
except Exception:
    sys.exit(0)
sid = ev.get("session_id")
if not sid:
    sys.exit(0)
os.umask(0o077)
state = os.environ.get("DEV_OS_STATE") or os.path.expanduser("~/.claude/state")

def rows(name):
    try:
        return [json.loads(l) for l in open(os.path.join(state, name)) if l.strip()]
    except (OSError, ValueError):
        return []

reflected = max([r.get("time", 0) for r in rows("skill-usage.jsonl") if r.get("skill") in ("reflect", "dev-os:reflect") and r.get("sid") == sid] or [0])
pending = [m for m in rows("learn-" + sid + ".jsonl") if m.get("time", 0) >= reflected]
marker = os.path.join(state, "learn-" + sid + ".warned")
if not pending:
    if os.path.exists(marker):
        os.remove(marker)
    sys.exit(0)
key = hashlib.sha1(json.dumps(pending).encode()).hexdigest()
if os.path.exists(marker) and open(marker).read() == key:
    sys.exit(0)
open(marker, "w").write(key)
notes = "; ".join(m["type"] + ": " + m.get("note", "")[:80] for m in pending[-5:])
print(json.dumps({"decision": "block", "reason": f"LEARN: {len(pending)} unlearned mistake(s) this session ({notes}). Run the reflect skill on each: turn it into a check or a skill edit if it will happen again, else drop it. Then continue."}))
