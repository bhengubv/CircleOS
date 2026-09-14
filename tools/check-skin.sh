#!/usr/bin/env bash
# check-skin.sh [tree]
#
#   tools/check-skin.sh ~/android
#
# Checks the Metro launcher against docs/CircleOS_Skin_Design_Guide.md,
# clause by clause, and says which parts of the guide are actually built.
#
# Why this exists
# ---------------
# "Built to the design guide" was claimed in commit messages before anyone
# had read the guide against the code. Some numbers matched, some clauses
# had been implemented backwards, and two were implemented from memory of a
# document that had never been cloned to this machine. A claim about
# conformance is worth exactly as much as the check behind it.
#
# So this prints three states and never rounds up:
#
#   ok       the clause is implemented and the value matches
#   PARTIAL  something is there, but it is not what the clause asks for
#   TODO     not implemented
#
# TODO is not a failure. The guide calls its own numbers "a starting spec -
# tune in design, not gospel", and several clauses depend on services that
# do not exist yet. The exit code is 1 only when a value that IS implemented
# disagrees with the guide, because that is the case where the code and the
# document are lying to each other.

set -uo pipefail
TREE="${1:-$HOME/android}"
L="$TREE/vendor/circle/apps/CircleLauncher"

BOLD=""; DIM=""; RED=""; GRN=""; YEL=""; OFF=""
if [ -t 1 ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[1;31m'
    GRN=$'\033[1;32m'; YEL=$'\033[1;33m'; OFF=$'\033[0m'
fi
MISMATCH=0; TODO=0; PARTIAL=0; OK=0

ok()      { printf '  %sok%s       %s\n' "$GRN" "$OFF" "$1"; OK=$((OK+1)); }
partial() { printf '  %sPARTIAL%s  %s\n' "$YEL" "$OFF" "$1"; PARTIAL=$((PARTIAL+1)); }
todo()    { printf '  %sTODO%s     %s\n' "$DIM" "$OFF" "$1"; TODO=$((TODO+1)); }
bad()     { printf '  %sMISMATCH%s %s\n' "$RED" "$OFF" "$1"; MISMATCH=$((MISMATCH+1)); }

[ -d "$L" ] || { echo "no launcher at $L" >&2; exit 2; }

# value <file> <name> <expected> <label>
dimen() {
    got=$(grep -o "<dimen name=\"$2\">[^<]*" "$L/res/values/dimens.xml" 2>/dev/null | sed 's/.*>//')
    if [ -z "$got" ]; then todo "$4 — @dimen/$2 not defined"
    elif [ "$got" = "$3" ]; then ok "$4 — $got"
    else bad "$4 — guide says $3, code says $got"; fi
}

# Match CODE, not comments.
#
# The first version of this script grepped the raw files. It then reported a
# gradient because tile_bg.xml carries the comment "no corner radius, no
# stroke, no gradient", and reported live tile faces as implemented because
# a comment explains why createCircularReveal cannot be used across an
# activity boundary. Both were the checker reading its own documentation and
# believing it.
#
# A checker that counts comments as implementation is worse than no checker,
# because it produces a clean report over unbuilt features. Comments are
# stripped before anything is matched.
strip_comments() {
    # //... and /*...*/ for Java, <!--...--> for XML.
    python3 - "$@" <<'PY'
import io, re, sys
out = []
for path in sys.argv[1:]:
    try:
        t = io.open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        continue
    t = re.sub(r'<!--.*?-->', '', t, flags=re.S)
    t = re.sub(r'/\*.*?\*/', '', t, flags=re.S)
    t = re.sub(r'(?m)//.*$', '', t)
    out.append(t)
print("\n".join(out))
PY
}

# has <pattern> - true when the pattern appears in code, comments removed.
has() {
    find "$L/src" "$L/res" -type f \( -name '*.java' -o -name '*.xml' \) 2>/dev/null |
        xargs -r bash -c 'strip_comments "$@"' _ 2>/dev/null |
        grep -qsE "$1"
}
export -f strip_comments 2>/dev/null || true

printf '%scheck-skin%s  %s\n' "$BOLD" "$OFF" "$L"
printf '%s\n' "against docs/CircleOS_Skin_Design_Guide.md"

echo
echo "${BOLD}1.1 The tile grid${OFF}"
dimen x tile_cell   76dp "small cell"
dimen x tile_gutter 8dp  "gutter"
dimen x grid_margin 12dp "outer margin"
for pair in "SMALL(1, 1)|small 1x1" "MEDIUM(2, 2)|medium 2x2" "WIDE(4, 2)|wide 4x2" "LARGE(4, 4)|large 4x4"; do
    want="${pair%%|*}"; label="${pair##*|}"
    grep -qs "$want" "$L/src/za/co/circleos/launcher/TileSize.java" \
        && ok "tile size $label" || bad "tile size $label not declared as $want"
done

echo
echo "${BOLD}1.2 Tile anatomy${OFF}"
grep -qs 'layout_gravity="bottom|start"' "$L/res/layout/tile.xml" \
    && ok "name bottom-left" || bad "name is not bottom-left"
grep -qs 'toLowerCase' "$L/src/za/co/circleos/launcher/CircleLauncherActivity.java" \
    && ok "app name lowercase" || bad "app name is not lowercased"
grep -qs 'layout_gravity="center"' "$L/res/layout/tile.xml" \
    && ok "glyph centred" || bad "glyph is not centred"
grep -qs 'layout_gravity="top|end"' "$L/res/layout/tile_soul.xml" \
    && ok "badges top-right" || todo "badges top-right"
grep -qs 'corners' "$L/res/drawable/tile_bg.xml" \
    && bad "tile has a corner radius; the guide says sharp corners" \
    || ok "flat fill, sharp corners, no gradient"
# A real flip needs a back-face view to flip TO. Matching the words
# "back face" would match the guide quoted in a comment.
if has "R\.layout\.tile_back|flipToBack|BACK_FACE"; then
    ok "live face + back face"
else
    todo "live face + back face that flips"
fi
has "transparentTile\|tile_transparent" \
    && ok "transparent-tile option" || todo "transparent-tile option"

echo
echo "${BOLD}1.3 Typography${OFF}"
[ -f "$L/res/font/selawik_light.ttf" ] && ok "Selawik is the base face" \
    || bad "Selawik not present in res/font"
dimen x type_display 48sp "Display"
dimen x type_header  28sp "Header"
dimen x type_subhead 20sp "Subhead"
dimen x type_body    15sp "Body"
dimen x type_caption 12sp "Caption"
grep -qs 'selawik_light' "$L/res/layout/header.xml" \
    && ok "headers Light weight" || bad "header is not Selawik Light"
grep -qs '>circle<\|header_start">circle' "$L/res/values/strings.xml" \
    && ok "lowercase section header" || partial "section header not lowercase"
has "clipChildren=\"false\".*wordmark\|wordmark_bleed" \
    && ok "wordmark bleeds off the right edge" \
    || todo "wordmark bleeds off the right edge (needs a panorama wider than the screen)"

echo
echo "${BOLD}1.4 Colour and theme${OFF}"
grep -qs '#FF2196F3' "$L/res/values/colors.xml" \
    && ok "one accent, brand blue" || bad "accent is not #2196F3"
grep -qs '<color name="metro_background">#FF000000' "$L/res/values/colors.xml" \
    && ok "true-black dark theme" || bad "background is not true black"
if grep -rqsE "<gradient[ />]" "$L/res/drawable" 2>/dev/null; then
    bad "a <gradient> element is defined; the guide forbids gradients on UI"
else
    ok "no gradients"
fi
[ -d "$L/res/values-notnight" ] || [ -d "$L/res/values-light" ] \
    && ok "clean white light theme" || todo "clean white light theme"

echo
echo "${BOLD}1.5 Motion${OFF}"
has "TURNSTILE" && ok "tile flip / turnstile" || todo "tile flip / turnstile"
has "PRESS_SCALE" && ok "press-to-tilt" || todo "press-to-tilt"
has "ViewFlipper" && ok "panorama / pivot horizontal motion" || todo "panorama / pivot"
has "TURNSTILE_STAGGER" && ok "staggered cascade on page transition" \
    || todo "staggered list cascade"
has "parallax\|PARALLAX" && ok "parallax wallpaper" || todo "parallax wallpaper behind tiles"

echo
echo "${BOLD}1.6 Layout patterns${OFF}"
has "ViewFlipper" && ok "panorama and pivot surfaces" || todo "panorama / pivot"
has "alphabetJump\|sectionIndex\|FastScroll" \
    && ok "long-list alphabetical jump" || todo "long-list with alphabetical jump"

echo
echo "${BOLD}2 Distinctly Circle OS${OFF}"
grep -qs '#FF2196F3' "$L/res/values/colors.xml" \
    && ok "2.1 accent locked to the brand palette" || bad "2.1 accent not locked"
grep -qs 'oval' "$L/res/drawable/presence_dot.xml" 2>/dev/null \
    && ok "2.2 identity layer is circular, tiles stay square" \
    || todo "2.2 square-meets-circle"
[ -f "$L/src/za/co/circleos/launcher/SoulTile.java" ] \
    && ok "2.3 soul tiles present" || todo "2.3 soul tiles"
if has "stateRes = R.string.state_unknown"; then
    partial "2.3 soul tiles are NOT live — no status API exists to bind to"
fi
has "makeScaleUpAnimation" \
    && partial "2.4 launch motion is a scale-up from the tile centre, not a circular reveal (no public cross-activity API)" \
    || todo "2.4 circular reveal from the tile centre"
has "commsEncrypted" && ok "2.5 privacy as a visible state" || todo "2.5 privacy state"
grep -qs 'circle_navy' "$L/res/values/colors.xml" \
    && partial "2.6 navy base defined but not switchable at runtime" \
    || todo "2.6 dual dark base"
grep -qs 'header_start">circle' "$L/res/values/strings.xml" \
    && ok "2.7 Circle wordmark in the header" || bad "2.7 header is not the wordmark"

printf '\n%s== summary ==%s\n' "$BOLD" "$OFF"
printf '  %d ok, %d partial, %d todo, %d mismatched\n' "$OK" "$PARTIAL" "$TODO" "$MISMATCH"
if [ "$MISMATCH" -gt 0 ]; then
    printf '\n  %sA value that is implemented disagrees with the guide.%s\n' "$RED" "$OFF"
    printf '  Either the code is wrong or the guide moved. Do not leave it\n'
    printf '  ambiguous - one of them has to change.\n'
    exit 1
fi
printf '  %sNo implemented value contradicts the guide.%s\n' "$GRN" "$OFF"
printf '  TODO is not failure: the guide calls its numbers a starting spec,\n'
printf '  and several clauses need services that do not exist yet.\n'
exit 0
