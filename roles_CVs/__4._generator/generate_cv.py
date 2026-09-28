#!/usr/bin/env python3
"""Generate role-specific CV .tex files from base_cv_template.tex + roles.json.

Usage:
    python3 generate_cv.py            # generate all roles in roles.json
    python3 generate_cv.py math-teacher   # generate just one role by id

No third-party dependencies (stdlib only) so it runs with any Python 3.
This only writes .tex files -- compiling to PDF is left to your existing
latexmk / VS Code LaTeX Workshop setup, since that already works locally.
"""
import json
import os
import sys

GENERATOR_DIR = os.path.dirname(os.path.abspath(__file__))
ROLES_CVS_DIR = os.path.dirname(GENERATOR_DIR)  # .../roles_CVs
TEMPLATE_PATH = os.path.join(GENERATOR_DIR, "base_cv_template.tex")
ROLES_JSON_PATH = os.path.join(GENERATOR_DIR, "roles.json")


def escape_latex(text):
    """Escape characters that are special to LaTeX in plain-text data fields.

    roles.json fields like title/subtitle/quote are meant to be plain,
    human-readable text -- not raw LaTeX -- so a literal "&" or "%" must not
    silently corrupt compilation (this bit us once already: an unescaped "&"
    in a title broke the whole document).
    """
    for char in ("&", "%", "#", "_"):
        text = text.replace(char, "\\" + char)
    return text


def render_extra_sections(rel, section_files):
    lines = [f"\\input{{{rel}/__3._sections/{name}}}" for name in section_files]
    return "\n".join(lines)


def render_industry_sectors(pairs):
    lines = [
        f"\\cvlistdoubleitem{{{escape_latex(a)}}}{{{escape_latex(b)}}}"
        for a, b in pairs
    ]
    return "\n".join(lines)


def render_role(template, role):
    output_dir = os.path.join(ROLES_CVS_DIR, role["output_dir"])
    os.makedirs(output_dir, exist_ok=True)
    rel = os.path.relpath(ROLES_CVS_DIR, output_dir)

    text = template
    text = text.replace("$$TITLE_LINE1$$", escape_latex(role["title_line1"]))
    text = text.replace("$$TITLE_LINE2$$", escape_latex(role["title_line2"]))
    text = text.replace("$$SUBTITLE$$", escape_latex(role["subtitle"]))
    text = text.replace("$$QUOTE$$", escape_latex(role["quote"]))
    text = text.replace("$$SUMMARY_SECTION$$", role["summary_section"])
    text = text.replace(
        "$$EXTRA_SECTIONS$$", render_extra_sections(rel, role["extra_sections"])
    )
    text = text.replace(
        "$$INDUSTRY_SECTORS$$", render_industry_sectors(role["industry_sectors"])
    )
    text = text.replace("$$REL$$", rel)

    out_path = os.path.join(output_dir, role["output_file"])
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(text)
    return out_path


def main():
    requested_id = sys.argv[1] if len(sys.argv) > 1 else None

    with open(TEMPLATE_PATH, encoding="utf-8") as f:
        template = f.read()
    with open(ROLES_JSON_PATH, encoding="utf-8") as f:
        roles = json.load(f)["roles"]

    if requested_id:
        roles = [r for r in roles if r["id"] == requested_id]
        if not roles:
            print(f"No role with id '{requested_id}' found in roles.json")
            sys.exit(1)

    for role in roles:
        out_path = render_role(template, role)
        print(f"Generated: {out_path}")


if __name__ == "__main__":
    main()
