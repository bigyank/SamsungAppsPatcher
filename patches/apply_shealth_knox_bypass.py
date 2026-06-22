#!/usr/bin/env python3
"""Apply Knox/root bypass patches to decompiled Samsung Health 6.32+ smali."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DECOMPILED = ROOT / "decompiled" / "shealth"


def find_smali(relative_suffix: str) -> Path:
    matches = list(DECOMPILED.rglob(relative_suffix))
    if not matches:
        raise FileNotFoundError(f"Missing smali: {relative_suffix}")
    if len(matches) > 1:
        matches.sort(key=lambda p: len(str(p)))
    return matches[0]


def replace_method_body(content: str, method_pattern: str, new_body: str) -> str:
    regex = re.compile(
        rf"(\.method {method_pattern}\n)(.*?)(\.end method)",
        re.DOTALL,
    )
    match = regex.search(content)
    if not match:
        raise ValueError(f"Method not found: {method_pattern}")
    return content[: match.start(2)] + new_body + content[match.end(2) :]


def stub_bool(method_pattern: str) -> str:
    return "    .locals 1\n\n    const/4 v0, 0x0\n\n    return v0\n"


def stub_int(method_pattern: str) -> str:
    return "    .locals 1\n\n    const/4 v0, 0x0\n\n    return v0\n"


def stub_string_null(method_pattern: str) -> str:
    return "    .locals 1\n\n    const/4 v0, 0x0\n\n    return-object v0\n"


def stub_void(method_pattern: str) -> str:
    return "    .locals 0\n\n    return-void\n"


def patch_file(relative_suffix: str, replacements: list[tuple[str, str]]) -> None:
    path = find_smali(relative_suffix)
    content = path.read_text(encoding="utf-8")
    for method_pattern, body in replacements:
        content = replace_method_body(content, method_pattern, body)
    path.write_text(content, encoding="utf-8")
    print(f"  patched {path.relative_to(ROOT)}")


def main() -> int:
    if not DECOMPILED.is_dir():
        print("Run wearable-patcher.sh shealth --no-patch first", file=sys.stderr)
        return 1

    print("Applying Knox bypass patches...")

    patch_file(
        "com/samsung/android/service/health/security/KnoxAdapter.smali",
        [
            (
                r"public static checkKnoxCompromisedExternal\(Landroid/content/Context;\)Ljava/lang/String;",
                stub_string_null(""),
            ),
            (
                r"public static checkKnoxCompromisedInternal\(Landroid/content/Context;\)I",
                stub_int(""),
            ),
            (r"public static isKnoxAvailable\(Landroid/content/Context;\)Z", stub_bool("")),
            (r"public static isKnoxAvailableCore\(Landroid/content/Context;\)Z", stub_bool("")),
            (r"public static isAksSakMandatory\(\)Z", stub_bool("")),
            (r"private static shouldUseKnox\(Landroid/content/Context;\)Z", stub_bool("")),
            (r"public static isSupportedTimaVersion\(\)Z", stub_bool("")),
        ],
    )

    patch_file(
        "com/samsung/android/service/health/security/IcccAdapter.smali",
        [
            (
                r"public static checkKnoxCompromised\(Landroid/content/Context;Z\)I",
                stub_int(""),
            ),
        ],
    )

    patch_file(
        "com/samsung/android/sdk/healthdata/privileged/KnoxControl.smali",
        [
            (r"public isKnoxAvailable\(\)Z", stub_bool("")),
            (r"public checkKnoxCompromised\(\)Ljava/lang/String;", stub_string_null("")),
            (r"public static checkWarrantyBit\(Ljava/lang/String;\)I", stub_int("")),
        ],
    )

    patch_file(
        "com/samsung/android/sdk/healthdata/privileged/IKnoxControl$Stub$Proxy.smali",
        [
            (r"public isKnoxAvailable\(\)Z", stub_bool("")),
        ],
    )

    patch_file(
        "com/samsung/android/service/health/security/sak/SakChecker.smali",
        [
            (r"public static isSupported\(\)Z", stub_bool("")),
        ],
    )

    patch_file(
        "c6r.smali",
        [
            (r"public final isSakSupported\(\)Z", stub_bool("")),
        ],
    )

    # Neutralize OOBE flows that block Knox-tripped devices.
    for suffix in ("idc.smali", "h4d.smali", "j32.smali"):
        try:
            path = find_smali(suffix)
            content = path.read_text(encoding="utf-8")
            if "HomeAppCloseActivity" in content and "OOBE_ERROR_KNOX" in content:
                for method in (
                    r"public final p\(Landroid/app/Activity;\)V",
                    r"public final q\(Landroid/app/Activity;Lcom/samsung/android/app/shealth/home/oobe2/viewmodel/KnoxHandlerViewModel\$KnoxInitResult;\)V",
                ):
                    if re.search(rf"\.method {method}\n", content):
                        content = replace_method_body(content, method, stub_void(""))
                path.write_text(content, encoding="utf-8")
                print(f"  patched {path.relative_to(ROOT)}")
        except (FileNotFoundError, ValueError):
            pass

    # Stub root-file checks if present (obfuscated kotlin helper).
    for path in DECOMPILED.rglob("*.smali"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        if "$this$isRooted" not in text:
            continue
        for match in re.finditer(
            r"(\.method public static final b\(Ljava/io/File;\)Z\n)(.*?)(\.end method)",
            text,
            re.DOTALL,
        ):
            text = text[: match.start(2)] + stub_bool("") + text[match.end(2) :]
        path.write_text(text, encoding="utf-8")
        print(f"  patched root check in {path.relative_to(ROOT)}")

    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
