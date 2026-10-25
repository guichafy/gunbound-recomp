"""Run caller-installed Ghidra headless; keep its profile and evidence local."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ghidra-dir", default=os.environ.get("GHIDRA_INSTALL_DIR"), required=not os.environ.get("GHIDRA_INSTALL_DIR"))
    parser.add_argument("--java-home", default=os.environ.get("JAVA_HOME"))
    parser.add_argument("--binary", type=Path, required=True)
    parser.add_argument("--work-dir", type=Path, required=True, help="Persistent project/profile/cache; no hidden path components")
    parser.add_argument("--output", type=Path, required=True, help="New evidence directory; never overwritten")
    parser.add_argument("--functions", nargs="+", default=[], help="Known VA selectors, e.g. 0x004a6200")
    parser.add_argument("--data", nargs="+", default=[], help="VA:length byte ranges, e.g. 0x005564f0:32 (max 4096)")
    parser.add_argument("--seed-known-entries", action="store_true", help="Create absent functions at proven entry VAs, in the analysis DB only")
    parser.add_argument("--timeout", type=int, default=360)
    args = parser.parse_args()
    binary, work, output = (p.resolve() for p in (args.binary, args.work_dir, args.output))
    if any(part.startswith(".") for part in work.parts):
        parser.error("hidden project path: choose a work-dir without dot-prefixed components")
    if output.exists():
        parser.error("output already exists; choose a new evidence directory")
    if not args.functions and not args.data:
        parser.error("request at least one --functions or --data selector")
    if args.timeout < 1:
        parser.error("timeout must be positive")
    for value in args.functions:
        if not re.fullmatch(r"0x[0-9a-fA-F]{1,8}", value):
            parser.error("function selectors must be x86 VAs written as 0xhex")
    for value in args.data:
        if not re.fullmatch(r"0x[0-9a-fA-F]{1,8}:[0-9]+", value) or not 1 <= int(value.split(":")[1]) <= 4096:
            parser.error("data selectors must be VA:length, length 1..4096")
    if not binary.is_file():
        parser.error("binary not found")
    install = Path(args.ghidra_dir).resolve()
    if not (install / "support/analyzeHeadless").is_file():
        install = install / "libexec"
    launcher = install / "support/analyzeHeadless"
    properties = install / "Ghidra/application.properties"
    if not launcher.is_file() or not properties.is_file():
        parser.error("Ghidra installation must contain support/analyzeHeadless and Ghidra/application.properties")
    source = {"path": str(binary), "sha256": hashlib.sha256(binary.read_bytes()).hexdigest(), "program": binary.name}
    identity_file = work / "source.json"
    project = work / "projects/GunboundClient.gpr"
    if identity_file.exists():
        saved = json.loads(identity_file.read_text())
        if (saved["sha256"], saved["program"]) != (source["sha256"], source["program"]):
            parser.error("project source identity mismatch; choose a separate work-dir")
    elif project.exists():
        parser.error("existing project without source identity; choose a separate work-dir")
    for folder in (work, work / "projects", work / "profile", work / "cache", work / "tmp"):
        folder.mkdir(parents=True, exist_ok=True)
    output.mkdir(parents=True)
    identity_file.write_text(json.dumps(source, indent=2) + "\n")
    env = os.environ.copy()
    if args.java_home:
        env["JAVA_HOME"] = str(Path(args.java_home).resolve())
    options = {"user.home": work / "profile", "application.cachedir": work / "cache", "application.tempdir": work / "tmp", "java.io.tmpdir": work / "tmp"}
    env["JAVA_TOOL_OPTIONS"] = env.get("JAVA_TOOL_OPTIONS", "") + " " + " ".join(json.dumps("-D" + key + "=" + str(value)) for key, value in options.items())
    reuse = project.exists()
    command = [str(launcher), str(work / "projects"), "GunboundClient"]
    command += ["-process", binary.name, "-noanalysis"] if reuse else ["-import", str(binary), "-analysisTimeoutPerFile", "240"]
    if reuse and not args.seed_known_entries:
        command += ["-readOnly"]
    command += ["-max-cpu", "2", "-scriptPath", str(Path(__file__).resolve().parent), "-postScript", "ExportClientEvidence.java", str(output), "seed" if args.seed_known_entries else "inspect", ",".join(args.functions) or "-", ",".join(args.data) or "-", "-log", str(output / "analysis.log"), "-scriptlog", str(output / "scripts.log")]
    run = {"source": source, "ghidra_properties": properties.read_text(), "command": command, "java_home": env.get("JAVA_HOME"), "isolated_java_options": env["JAVA_TOOL_OPTIONS"], "reused_project": reuse}
    status = 1
    try:
        with (output / "console.log").open("w") as log:
            process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            try:
                status = process.wait(timeout=args.timeout)
            except (subprocess.TimeoutExpired, KeyboardInterrupt):
                # The launcher forks Java; terminate our whole process group, not just bash.
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    pass
                # The shell may exit before a resistant Java/descendant process.
                # Always finish cleanup of our group, even after its leader exits.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()
                raise
    except subprocess.TimeoutExpired:
        run["error"] = "headless timeout; inspect logs before reopening the project"
    run["exit_code"] = status
    run["source_unchanged"] = hashlib.sha256(binary.read_bytes()).hexdigest() == source["sha256"]
    manifest_file = output / "manifest.json"
    manifest = json.loads(manifest_file.read_text()) if manifest_file.exists() else {}
    logs = (output / "console.log").read_text(errors="replace")
    run["analysis_timed_out"] = "analysis timed out" in logs.lower() or "analysis timeout" in logs.lower()
    run["ok"] = status == 0 and run["source_unchanged"] and manifest.get("source_sha256") == source["sha256"] and manifest.get("ok") is True and not run["analysis_timed_out"] and not re.search(r"^ERROR\b", logs, re.M)
    (output / "run.json").write_text(json.dumps(run, indent=2) + "\n")
    print(json.dumps({"ok": run["ok"], "output": str(output), "manifest": str(manifest_file)}, indent=2))
    return 0 if run["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
