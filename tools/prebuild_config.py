#!/usr/bin/env python3
"""Emit native link configuration for the Dear ImGui MoonBit module."""

from __future__ import annotations

import json
import os
import platform
import shlex
import shutil
import subprocess
import sys


def pkg_config(name: str) -> list[str] | None:
    if shutil.which("pkg-config") is None:
        return None
    exists = subprocess.run(
        ["pkg-config", "--exists", name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if exists.returncode != 0:
        return None
    result = subprocess.run(
        ["pkg-config", "--libs", name],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=True,
    )
    return shlex.split(result.stdout)


def system_name() -> str:
    env_os = os.environ.get("OS", "").lower()
    if env_os.startswith("windows"):
        return "windows"
    name = platform.system().lower()
    if name.startswith("darwin"):
        return "darwin"
    if name.startswith("windows") or name.startswith("msys") or name.startswith("mingw"):
        return "windows"
    return name


def quote_flags(flags: list[str]) -> str:
    return " ".join(shlex.quote(flag) for flag in flags)


def _vswhere_vc_installed() -> bool:
    """True if vswhere finds a VS install with x64 VC tools (cl.exe present).

    Lets the script detect MSVC even when `cl` is not on PATH (i.e. outside a
    Developer Command Prompt), so plain `moon build` works from any terminal.
    """
    vswhere = r"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    if not os.path.isfile(vswhere):
        return False
    try:
        result = subprocess.run(
            [
                vswhere,
                "-latest",
                "-products",
                "*",
                "-requires",
                "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
                "-property",
                "installationPath",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=False,
            timeout=15,
        )
    except (OSError, subprocess.SubprocessError):
        return False
    if result.returncode != 0:
        return False
    vs_root = result.stdout.strip()
    if not vs_root:
        return False
    msvc_dir = os.path.join(vs_root, "VC", "Tools", "MSVC")
    if not os.path.isdir(msvc_dir):
        return False
    try:
        versions = os.listdir(msvc_dir)
    except OSError:
        return False
    return any(
        os.path.isfile(
            os.path.join(msvc_dir, ver, "bin", "Hostx64", "x64", "cl.exe")
        )
        for ver in versions
    )


def toolchain_name() -> str:
    if system_name() != "windows":
        return "gnu"
    if os.environ.get("MSYSTEM"):
        return "gnu"
    cc = os.environ.get("CC", "")
    cxx = os.environ.get("CXX", "")
    configured = f"{cc} {cxx}".lower()
    if "clang-cl" in configured or configured.endswith(" cl") or configured.endswith(" cl.exe"):
        return "msvc"
    if shutil.which("cl") is not None or shutil.which("clang-cl") is not None:
        return "msvc"
    if _vswhere_vc_installed():
        return "msvc"
    return "gnu"


def include_flag(path: str) -> str:
    if toolchain_name() == "msvc":
        return f"/I{path}"
    return f"-I{path}"


def stub_flags(include_dirs: list[str]) -> list[str]:
    includes = [include_flag(path) for path in include_dirs]
    if toolchain_name() == "msvc":
        return [
            "/EHsc-",
            "/GR-",
            "/wd4244",
            "/wd4267",
            "/wd4819",
            "/wd4996",
            *includes,
        ]
    return [
        "-fno-exceptions",
        "-fno-rtti",
        "-fno-threadsafe-statics",
        "-Wno-deprecated-declarations",
        *includes,
    ]


def glfw_flags() -> list[str]:
    """GLFW link libraries for this platform.

    NOTE: no /LIBPATH here - moon places prebuild link args before the linker's
    `/link` switch, so `cl` silently drops any /LIBPATH (warning D9002). Instead
    the Windows import library `glfw3dll.lib` lives at the main module root
    (copied there from the vcpkg install by the consumer's pre-build step, e.g.
    <repo>/moonbit/glfw3dll.lib), which the linker searches as its working
    directory.
    """
    configured = pkg_config("glfw3")
    if configured is not None:
        return configured
    match system_name():
        case "darwin":
            return ["-L/opt/homebrew/lib", "-L/usr/local/lib", "-lglfw"]
        case "windows":
            if toolchain_name() == "msvc":
                return [
                    "glfw3dll.lib",
                    "opengl32.lib",
                    "gdi32.lib",
                    "user32.lib",
                    "shell32.lib",
                ]
            return ["-lglfw3", "-lopengl32", "-lgdi32", "-luser32", "-lshell32"]
        case _:
            return ["-lglfw"]


def macos_sdk_path() -> str | None:
    if shutil.which("xcrun") is None:
        return None
    result = subprocess.run(
        ["xcrun", "--show-sdk-path"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return None
    path = result.stdout.strip()
    return path if path else None


def macos_opengl_flags() -> list[str]:
    sdk = macos_sdk_path()
    if sdk is not None:
        tbd = os.path.join(
            sdk,
            "System/Library/Frameworks/OpenGL.framework/OpenGL.tbd",
        )
        if os.path.exists(tbd):
            return [tbd]
    return ["-framework", "OpenGL"]


def opengl_flags() -> list[str]:
    configured = pkg_config("gl")
    if configured is not None:
        return configured
    match system_name():
        case "darwin":
            return macos_opengl_flags()
        case "windows":
            if toolchain_name() == "msvc":
                return ["opengl32.lib"]
            return ["-lopengl32"]
        case _:
            return ["-lGL"]


def backend_stub_link_flags() -> list[str]:
    match system_name():
        case "darwin":
            return ["-undefined", "dynamic_lookup"]
        case "windows":
            if toolchain_name() == "msvc":
                return []
            return ["-Wl,--allow-shlib-undefined"]
        case _:
            return ["-Wl,--allow-shlib-undefined"]


def main() -> None:
    _ = sys.stdin.read()
    backend_stub = backend_stub_link_flags()
    glfw = quote_flags(backend_stub + glfw_flags())
    opengl3 = quote_flags(backend_stub + opengl_flags())
    # Resolve include dirs to absolute (forward-slash) paths so the stub
    # compilation succeeds regardless of the compiler's working directory.
    module_root = os.path.abspath(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    ).replace("\\", "/")
    bindings_dir = os.path.join(module_root, "bindings")
    upstream_imgui = os.path.join(bindings_dir, "upstream", "imgui")
    upstream_backends = os.path.join(upstream_imgui, "backends")
    glfw_include = os.path.join(
        upstream_imgui, "examples", "libs", "glfw", "include"
    )
    output = {
        "vars": {
            "IMGUI_CORE_STUB_FLAGS": quote_flags(
                stub_flags([bindings_dir, upstream_imgui, upstream_backends])
            ),
            "IMGUI_GLFW_STUB_FLAGS": quote_flags(
                stub_flags(
                    [bindings_dir, upstream_imgui, upstream_backends, glfw_include]
                )
            ),
            "IMGUI_OPENGL3_STUB_FLAGS": quote_flags(
                stub_flags([bindings_dir, upstream_imgui, upstream_backends])
            ),
        },
        "link_configs": [
            {
                "package": "moonbit-community/imgui/bindings/glfw",
                "link_flags": glfw,
            },
            {
                "package": "moonbit-community/imgui/bindings/opengl3",
                "link_flags": opengl3,
            },
        ],
    }
    print(json.dumps(output, separators=(",", ":")))


if __name__ == "__main__":
    main()
