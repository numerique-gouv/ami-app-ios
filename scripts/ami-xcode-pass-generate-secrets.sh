#!/usr/bin/env bash
#
# ami-xcode-pass-generate-secrets.sh — generate a Swift `Secrets` enum from a `.env` file.
#
# ---------------------------------------------------------------------------
# USAGE
# ---------------------------------------------------------------------------
#
#   ami-xcode-pass-generate-secrets.sh <env-file> <output-file>
#
# As an Xcode Run Script Build Phase, placed *before* Compile Sources:
#
#   "${SRCROOT}/Scripts/ami-xcode-pass-generate-secrets.sh" \
#       "${SRCROOT}/Config/.env.${TARGET_NAME}" \
#       "${DERIVED_FILE_DIR}/Secrets.swift"
#
# The same invocation works unchanged in CI under `xcodebuild`, since it only
# relies on environment variables Xcode sets in both cases.
#
# ---------------------------------------------------------------------------
# CONVENTIONS (.env syntax)
# ---------------------------------------------------------------------------
#
# Plain text file, CR / LF or CRLF line endings. Lines are trimmed of leading
# and trailing spaces and tabs, and in an assignment the key and the value are trimmed
# before processing. Each line is one of:
#
#   - a blank line: ignored
#   - a '#' comment (leading spaces allowed): ignored entirely; a trailing
#     '\' is just comment content (a comment never continues the next line)
#     and a comment line may not interrupt a line continuation (error)
#   - an assignment: KEY = value   (every other line must contain '=')
#
# Keys:
#   - snake_case; converted to camelCase in the generated enum
#
# Line continuation:
#   - a trailing '\' merges the line with the next one (the '\' is dropped);
#     a list may span several physical lines, but after merging it is a
#     single line (the closing ']' must be merged too)
#
# Values:
#   - a scalar: kept verbatim; it may hold several strings and operators,
#     e.g. 42.0, "example.org", 40.0 + 2.0 or "sub4" + ".example.org"
#   - a list: [ item, item, ... ] — items are separated by ',' outside of
#     double quotes; a trailing comma is allowed; the list ends at the first
#     unquoted ']' (a ']' inside a string or a comment does not end it) and
#     only a '//' comment may follow it (kept after the ']')
#   - a double-quoted string may contain ',' and escaped quotes (\"), and
#     may span a line continuation
#   - a '//' outside quotes starts a comment that runs till the end of the
#     merged line; the comment is kept in the output and everything inside
#     it (',' included) is inert
#
# Verbatim output:
#   - list items are emitted exactly as in the input, one per line: the
#     generator adds no data to the input (a last item without a comma
#     stays without one)
#   - original line boundaries are never value separators: between plain
#     values they are dropped (bad input stays bad); inside a quoted string
#     they are dropped (the string spans the continuation); after a '//'
#     comment they end the comment, whose fragment becomes its own item
#
# Errors (printed as file:line:column: error: message, clickable in the
# Xcode build log; messages name the key only — secret values are never
# printed):
#   - a non-comment line without '='
#   - an empty key
#   - a value ending inside an unclosed double-quoted string (an escaped
#     quote or a missing closing quote)
#   - a '#' comment line interrupting a line continuation
#   - a value starting with '[' is a list only when nothing but a '//'
#     comment follows the first unquoted ']'; otherwise it is not an error —
#     the value is printed verbatim as a scalar (bad input stays bad), unless
#     that leaves it ending inside an unclosed string (the error above)
#
# ---------------------------------------------------------------------------
# SANDBOXING
# ---------------------------------------------------------------------------
#
# This script's paths come from Xcode environment variables ($SRCROOT,
# $DERIVED_FILE_DIR), so Xcode cannot statically determine which files the
# phase reads and writes. With `ENABLE_USER_SCRIPT_SANDBOXING = YES` (the
# default for new projects) the phase will then fail with "Operation not
# permitted". Pick one of:
#
#   1. (Recommended) In the build phase, uncheck
#      "Based on command line arguments" (under the sandboxing / dependency
#      analysis options). Xcode stops trying to infer paths and the phase runs
#      with the normal build sandbox.
#
#   2. Declare the paths yourself, as Input/Output Files or File Lists:
#
#        Input Files:   $(SRCROOT)/Config/.env.$(TARGET_NAME)
#        Output Files:  $(DERIVED_FILE_DIR)/Secrets.swift
#
#      Listing the output gives Xcode correct dependency analysis and build
#      ordering. It does NOT add the file to Compile Sources — output files are
#      only build-system metadata. The generated file must be declared as a
#      source of the target separately (see GETTING COMPILED, below).
#
#      Note: this script writes "<output>.tmp" alongside the output before
#      renaming it into place. If the sandbox rejects that undeclared write,
#      declare the .tmp path as a second Output File. Do not relocate it to
#      $TMPDIR — a different filesystem turns the atomic rename into a
#      copy-then-unlink and loses the guarantee described below.
#
# ---------------------------------------------------------------------------
# GETTING COMPILED
# ---------------------------------------------------------------------------
#
# A file under $DERIVED_FILE_DIR cannot be referenced from project.yml: the
# path varies per configuration and does not exist at generation time. So when
# the project is generated by XcodeGen, write the output into the source tree
# instead and declare it on the target:
#
#     "${SRCROOT}/Scripts/ami-xcode-pass-generate-secrets.sh" \
#         "${SRCROOT}/Config/.env.${TARGET_NAME}" \
#         "${SRCROOT}/Generated/Secrets-Generated.swift"
#
#     # project.yml
#     targets:
#       MyApp:
#         sources:
#           - path: Sources
#           - path: Generated/Secrets-Generated.swift
#             optional: true      # absent on a fresh clone; it is gitignored
#
# `optional` applies to files, not directories — point at the file itself.
# The run script phase must still sit above Compile Sources, or the compiler
# reads a stale file (or none at all, on a clean checkout).
#
# Writing into $SRCROOT rather than the build directory has two consequences:
# user script sandboxing is far more likely to reject it (see above), and
# Xcode's change detection for outputs inside $SRCROOT is unreliable, so keep
# "Based on dependency analysis" unchecked and let the cmp check below decide.

set -euo pipefail

# Print the usage line (stderr: it is shown when the parameters are not ok).
usage() {
    printf 'Usage: %s <env-file> <output-file>\n' "$0" >&2
}

if [ "$#" -ne 2 ]; then
    printf 'error: expected 2 arguments, got %d\n' "$#" >&2
    usage
    exit 2
fi

input=$1
output=$2

if [ "$input" = "$output" ]; then
    printf '%s:1:1: error: output file is the same as the input file\n' "$output" >&2
    exit 2
fi

# From here on, any failure removes both the temporary file and the existing
# output, so no (old or partial) output survives a failed run.
# So a failed generation can never be compiled, even with "Continue building after errors" on.
tmp="${output}.tmp"
trap 'rm -f -- "$output" "$tmp" 2>/dev/null' EXIT

if [ ! -f "$input" ] || [ ! -r "$input" ]; then
    printf '%s:1:1: error: cannot read input file\n' "$input" >&2
    exit 2
fi

if [ -d "$output" ]; then
    printf '%s:1:1: error: output path is a directory\n' "$output" >&2
    exit 1
fi

output_dir=$(dirname -- "$output")
if [ ! -d "$output_dir" ]; then
    if ! mkdir -p -- "$output_dir" 2>/dev/null; then
        printf '%s:1:1: error: cannot create directory\n' "$output_dir" >&2
        exit 1
    fi
fi

if ! { : > "$tmp"; } 2>/dev/null; then
    printf '%s:1:1: error: cannot write to output file\n' "$output" >&2
    exit 1
fi

awk '
# --- helpers ---------------------------------------------------------------

# Print an error in Xcode build log format and abort.
function fail(lineno, message) {
    printf("%s:%d:1: error: %s\n", FILENAME, lineno, message) > "/dev/stderr"
    bad = 1
    exit 1
}

# Remove leading and trailing spaces and tabs.
function trim(s) {
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    return s
}

# Convert snake_case to camelCase.
function to_camel(s,    n, parts, i, out) {
    n = split(s, parts, "_")
    out = tolower(parts[1])
    for (i = 2; i <= n; i++)
        out = out toupper(substr(parts[i], 1, 1)) tolower(substr(parts[i], 2))
    return out
}

# Number of consecutive backslashes immediately before position pos in body.
# An even count means the character at pos is real (string delimiter), an
# odd count means it is escaped (\") and is string content.
function backslashes_before(body, pos,    k) {
    k = 0
    while (pos - k - 1 >= 1 && substr(body, pos - k - 1, 1) == "\\")
        k++
    return k
}

# Single quote scanner — the only place that decides what is string content
# and what is comment content (list detection and the error checks share it,
# so they cannot disagree).
# Returns -1 when the text ends inside an unclosed double-quoted string;
# otherwise the position of the first unquoted closing "]" (0 if there is
# none). The scan always runs to the end, so [1, 2] "dangling is
# unterminated, not a list.
#   - a quoted string may span line boundaries (sentinel S): a boundary does
#     not close it
#   - a "//" outside quotes starts a comment that runs till the next line
#     boundary; every character inside it (quotes, commas, ]) is inert
function scan_quote(text,    n, i, c, in_quote, in_comment, first) {
    n = length(text)
    in_quote = 0
    in_comment = 0
    first = 0
    for (i = 1; i <= n; i++) {
        c = substr(text, i, 1)
        if (c == S) {
            in_comment = 0            # a comment runs till the line boundary
            continue
        }
        if (in_quote) {
            if (c == "\"" && backslashes_before(text, i) % 2 == 0)
                in_quote = 0
        } else if (in_comment) {
            # comment text: every character (quotes included) is inert
        } else if (c == "\"" && backslashes_before(text, i) % 2 == 0) {
            in_quote = 1
        } else if (c == "/" && substr(text, i + 1, 1) == "/") {
            in_comment = 1
        } else if (c == "]" && first == 0) {
            first = i                 # remember it and keep scanning: the
        }                             # value must also be terminated
    }
    if (in_quote)
        return -1
    return first
}

# 1 if the text after a closing "]" holds nothing but blanks, at most
# one line boundary and a trailing "//" comment: only a comment may follow
# the list (a comment runs till the next line boundary, nothing else may).
function ok_list_suffix(t,    i, n, c) {
    n = length(t)
    i = 1
    while (i <= n && (substr(t, i, 1) == " " || substr(t, i, 1) == "\t"))
        i++
    if (i <= n && substr(t, i, 1) == S)
        i++
    while (i <= n && (substr(t, i, 1) == " " || substr(t, i, 1) == "\t"))
        i++
    if (i > n)
        return 1
    if (substr(t, i, 2) != "//")
        return 0
    i += 2
    while (i <= n && substr(t, i, 1) != S)
        i++
    # after that line boundary: only blanks or empty continuations
    i++
    while (i <= n) {
        c = substr(t, i, 1)
        if (c == " " || c == "\t" || c == S)
            i++
        else
            return 0
    }
    return 1
}

# Split the body of a list into items. Rules:
#   - a comma outside double quotes terminates the current item and stays
#     part of it (emitted verbatim); a comma inside quotes ("a,b") is
#     content; quote tracking handles several strings per item ("a" + "b")
#     and escaped quotes (\")
#   - an unquoted "]" ends the list: the open item is finalized and the rest
#     of the (merged) line (a trailing comment) is ignored
#   - an original line boundary (sentinel S) is never a value separator:
#     between plain values it is dropped (bad input stays bad); inside a
#     quoted string it is dropped (the string spans the continuation);
#     after a "//" comment it ends the comment and the comment fragment
#     becomes its own item
#   - a "//" outside quotes starts a comment: it runs from there till the
#     next line boundary; everything it contains (',', quotes, even text
#     that looks like values) is content of the current item
# nl[n] is 1 when item n starts on its own line (previous boundary was a
# line boundary) and 0 when it follows a comma on the same line.
function split_list(body, values, nl,    n, i, c, len, in_quote, in_comment, item, flag) {
    n = 0
    item = ""
    len = length(body)
    in_quote = 0
    in_comment = 0
    flag = 0
    for (i = 1; i <= len; i++) {
        c = substr(body, i, 1)
        if (c == S) {
            if (in_quote) {
                # a quoted string spans the boundary: drop it, no split
            } else if (in_comment) {
                # a comment ends at the boundary: its fragment is an item
                n++
                values[n] = item
                nl[n] = flag
                flag = 1
                item = ""
            } else {
                # a boundary between plain values: not a separator (dropped),
                # but the next item starts on a new line
                flag = 1
            }
            in_comment = 0
            continue
        }
        if (in_quote) {
            item = item c
            if (c == "\"" && backslashes_before(body, i) % 2 == 0)
                in_quote = 0            # a \" inside a string is content
        } else if (in_comment) {
            item = item c               # comment content: quotes are inert
        } else if (c == "\"" && backslashes_before(body, i) % 2 == 0) {
            in_quote = 1
            item = item c
        } else if (c == "/" && substr(body, i + 1, 1) == "/") {
            in_comment = 1
            item = item c               # the second '/' is appended on the next step
        } else if (c == "]") {
            # an unquoted "]" ends the list: finalize the open item and
            # ignore the rest of the (merged) line (a trailing comment)
            n++
            values[n] = item
            nl[n] = flag
            return n
        } else if (c == ",") {
            item = item c            # the comma belongs to this item
            n++
            values[n] = item
            nl[n] = flag
            flag = 0
            item = ""
        } else {
            item = item c
        }
    }
    n++
    values[n] = item
    nl[n] = flag
    return n
}

# Process one (already merged) logical line. Line boundaries are marked with
# the sentinel S so that comment handling can see the original lines.
function emit(line, lineno,    pos, key, value, n, values, nl, i, item, out, m, epos, list_suffix) {
    if (line == "")
        return
    if (index(line, "=") == 0)
        fail(lineno, "line does not contain \"=\"")
    pos   = index(line, "=")
    key   = to_camel(trim(substr(line, 1, pos - 1)))
    gsub(S, "", key)
    value = trim(substr(line, pos + 1))
    # A continuation may start the value on the next physical line: drop the
    # leading line boundaries (and the blanks around them) so a list still
    # begins with "[" and is recognised.
    sub("^[ \t" S "]*", "", value)
    if (key == "")
        fail(lineno, "line has an empty key")

    printf("    static let %s = ", key)

    # A list is "[" ... "]" with nothing but a "//" comment after the
    # closing "]" (scan_quote ignores what strings and comments hold, so a
    # "]" or a quote inside them cannot end or break the list).
    epos = 0
    list_suffix = ""
    if (substr(value, 1, 1) == "[") {
        epos = scan_quote(value)
        if (epos > 0 && ok_list_suffix(substr(value, epos + 1))) {
            list_suffix = substr(value, epos + 1)
            value = substr(value, 1, epos)
        } else
            epos = 0
    }

    if (epos > 0) {
        # List value: strip the outer [ ] and split the body into items.
        value = substr(value, 2, epos - 2)
        n = split_list(value, values, nl)

        # Merge comment-only fragments that follow a comma on the same line
        # ("a", // c) back into the previous item; a comment standing on its
        # own line is printed on its own line inside the array. Items are
        # printed verbatim: no data is added to the input.
        m = 0
        for (i = 1; i <= n; i++) {
            item = trim(values[i])
            if (item == "")
                continue
            if (item ~ /^\/\// && nl[i] == 0 && m > 0)
                out[m] = out[m] " " item
            else {
                m++
                out[m] = item
            }
        }

        printf("[\n")
        for (i = 1; i <= m; i++)
            printf("        %s\n", out[i])
        printf("    ]")
        if (list_suffix != "") {
            gsub(S, "", list_suffix)
            list_suffix = trim(list_suffix)
            if (list_suffix != "")
                printf(" %s", list_suffix)
        }
    } else {
        # Scalar value: kept verbatim (several strings and operators are
        # allowed), only dropping the line-boundary sentinels. The scan
        # doubles as the unterminated-string check (key only in the error).
        epos = scan_quote(value)
        if (epos < 0)
            fail(lineno, "unterminated string in " key)
        gsub(S, "", value)
        printf("%s", value)
    }
    printf("\n")
}

# --- main ------------------------------------------------------------------

BEGIN {
    S = sprintf("%c", 1)
    np = split(ARGV[1], p, "/")
    input_base = p[np]
    printf("// Generated from %s — do not edit\n\n", input_base)
    printf("import Foundation\n\n")
    printf("// swiftlint:disable all\n")
    printf("// swiftformat:disable all\n\n")
    printf("nonisolated enum Secrets {\n")
    pending    = ""
    start_line = 0
    bad        = 0
}

{
    sub(/\r$/, "")                      # normalize CRLF -> LF
    line = trim($0)                     # trim each physical line

    if (line ~ /^#/) {                  # "#" comments never continue: a
        if (pending != "")              # comment may not interrupt a merge
            fail(FNR, "# comment interrupts a line continuation")
        next
    }

    if (line ~ /\\$/) {                 # a trailing backslash merges with the next line
        if (pending == "")              # remember where the logical line starts
            start_line = FNR
        line = substr(line, 1, length(line) - 1)   # drop the trailing backslash
        pending = pending line S        # S marks the original line boundary
        next
    }

    emit(pending line, pending != "" ? start_line : FNR)
    pending = ""
}

END {
    if (bad)
        exit 1
    if (pending != "")
        emit(pending, start_line)       # trailing merged line with no newline
    printf("}\n\n")
    printf("// swiftformat:enable all\n")
    printf("// swiftlint:enable all\n")
}
' "$input" > "$tmp" || exit 1

# If the existing output is byte-identical to the new one, keep it: its
# modification time is preserved, so Xcode's incremental builds can skip
# recompiling the target. Otherwise rename the temporary file into place
# (atomic on the same volume).
if [ -f "$output" ] && cmp -s -- "$output" "$tmp"; then
    echo "note: ♻️  $(basename "$output") unchanged, kept existing file: $output"
    rm -f -- "$tmp"
else
    mv -f -- "$tmp" "$output" || exit 1
    echo "note: 🆕 generated $output from $input"
fi
trap - EXIT
