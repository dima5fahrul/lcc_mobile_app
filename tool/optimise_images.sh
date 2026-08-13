#!/usr/bin/env bash
#
# optimise_images.sh — B1b asset optimisation pipeline
#
# Spec: projects/lcc-mobile-app/docs/greenfield/GOR-246-b1b-assets/specs.md
#       § 6.2 (format/quality policy), § 6.3 (per-asset targets + ceilings),
#       § 6.4 (density rungs), § 6.5 (pipeline constraints).
#
# AMENDED by the binding ruling in the same folder's architecture-review.md
# (specs.md revision_history v1.1). Where the specs.md BODY and the ruling
# differ, the RULING WINS. What it changed, and nothing else:
#   § 4.1  the instrument is DECIBELS. The gate compares dB to dB with no
#          conversion in the gate path. The 0..1 column stays informational.
#   § 4.2  Tier A holds TWO bounds, both required: an absolute 14.00 dB floor
#          AND a per-asset regression bound of (baseline - 0.50 dB) against the
#          newly measured baseline table. § 6.2's escape hatch to q75 is
#          RESCINDED — Tier A ships at exactly § 6.3's q values (80 x9, 78, 82).
#   § 4.3  SSIM is ruled NOT a valid instrument for Tier B at any threshold.
#          Tier B ships `cwebp -lossless -m 6` UNCONDITIONALLY, gated at the
#          99.00 dB clamp. § 6.2's "encode both, ship whichever is smaller" is
#          overridden; `-exact` was evaluated and DECLINED (§ 3.3).
#   § 4.5  five Tier B ceilings rise. NO Tier A ceiling moves. AC-2's total
#          stays 1,048,576 B.
# Expected end state: 26 files, 949,262 B, 26 of 26 PASS.
#
# Converts the 16 sources in assets/images/ to 26 optimised .webp files
# (11 Tier A at the base path; 5 Tier B at base + 2.0x/ + 3.0x/ rungs),
# replacing the originals IN PLACE. No .orig/.bak/raw/ copy is left behind
# (§ 3.1) — that would defeat § 7.3 and re-import the weight.
#
# Contract (§ 6.5):
#   * idempotent      — same sources produce byte-identical output
#   * non-interactive — no prompts, no GUI, no eyeballed quality slider
#   * fails loudly    — exits non-zero on ANY per-asset ceiling breach,
#                       total-budget breach, or dB-floor breach
#   * prints a per-asset byte + dB table for verbatim paste into qa-report.md
#   * REFUSES to run if assets/images/ already contains .webp (generation-loss
#     guard) — re-running requires restoring the sources first, an explicit act
#
# SAFETY: all encoding happens in a temporary staging directory. The tree is
# only mutated (rungs created, originals deleted) after EVERY gate has passed.
# A gate failure therefore leaves the sources untouched and the tree unchanged.
#
# RESTORING SOURCES: the 16 originals are byte-identical (md5-verified) to
# ../lcc-app/src/imports/<same name>. That read-only port source (ADR-0001) is
# the recovery path if this pipeline must be re-run after a successful pass.
#
# SSIM NOTE (important, and not obvious):
#   `cwebp -print_ssim` does NOT print SSIM on the conventional 0..1 scale.
#   libwebp prints a dB transform:  dB = -10 * log10(1 - SSIM),  clamped to
#   99.00 for a mathematically perfect match. A pixel-identical encode prints
#   99.00, NOT 1.00.
#
#   Per architecture-review.md § 4.1 the gate is dB-to-dB: every threshold
#   below is a decibel value compared against the decibel value cwebp printed,
#   with NO conversion anywhere in the gate path — that conversion sitting in
#   the gate path is what caused the § 8 escalation. `db_to_ssim` is retained
#   and both columns are still printed, but the 0..1 column is INFORMATIONAL
#   ONLY and no comparison is made against it.
#
#   A second instrument defect, recorded so it is not rediscovered
#   (architecture-review.md § 3.4): cwebp's reference is the encoder's
#   post-preprocessing input, not the file on disk. A 99.00 certifies "the
#   codec added no loss"; it does NOT certify "the output is faithful to the
#   source". Tier B's guarantee therefore rests on lossless CODING, not on the
#   reported number.
#
# Host tools: cwebp (libwebp) and sips (macOS). Neither is a project
# dependency (§ 4.3) — they appear in no manifest and ship in no APK.
#
set -euo pipefail

CWEBP="${CWEBP:-/opt/homebrew/bin/cwebp}"

# B1b-AC-5 as amended (architecture-review.md § 6). ALL VALUES ARE DECIBELS.
TIER_A_ABS_FLOOR_DB="14.00"  # § 4.2(a) absolute floor        (0.960189 linear)
TIER_A_REGRESSION_DB="0.50"  # § 4.2(b) baseline - 0.50 dB, per asset
TIER_B_FLOOR_DB="99.00"      # § 4.3    the clamp; only -lossless reaches it

TOTAL_CEILING=1048576        # § 7.1 B1b-AC-2 — 1.00 MiB, UNCHANGED by the ruling

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
IMG="$ROOT/assets/images"

# ---------------------------------------------------------------------------
# Asset tables — every number here is from specs.md § 6.3. Do not edit these
# without an accompanying spec revision; the ceilings are the gate.
# ---------------------------------------------------------------------------

# Tier A (§ 6.1): photographic surfaces, no transparency, lossy WebP, no rungs.
#   name|source-ext|quality|target-w|target-h|ceiling|baseline_dB
#   Empty target-w/h means "native dimensions — DO NOT RESIZE" (§ 2.2 Finding D).
#
# baseline_dB is architecture-review.md § 4.2's measured table — the SSIM column
# § 6.3 never had. The per-asset gate is max(14.00, baseline - 0.50). NO Tier A
# ceiling moves under the ruling, and the q values are FIXED: § 6.2's escape
# hatch to q75 is RESCINDED (§ 4.2), so a quality change of any size is an
# escalation, not this script's to make.
TIER_A=(
  "civil-population|png|80|864|1152|100000|14.90"
  "immigration|png|80|864|1152|100000|14.99"
  "land-property|png|80|864|1152|100000|15.14"
  "health|png|80|864|1152|100000|15.38"
  "social-protection|png|80|864|1152|100000|15.90"
  "education|png|80|864|1152|100000|16.92"
  "transport|png|80|864|1152|100000|16.26"
  "tax-payment|png|80|864|1152|100000|16.46"
  "hero-bg|jpg|80|||220000|16.26"
  "bg-id|jpg|78|||165000|15.23"
  "user-photo|png|82|288|384|12000|17.46"
)

# Tier B (§ 6.1): marks/emblems with meaningful alpha, fixed small render.
# Three density rungs; ceiling applies to the SUM of the three (§ 7.1 AC-3).
#   name|1x|2.0x|3.0x|ceiling
# moha-sm's 3.0x is 160 (its native size), not 192 — no-upscale rule (§ 6.2).
#
# NO quality field: architecture-review.md § 4.3 withdraws lossy encoding for
# this tier entirely. All five assets, all fifteen rungs, ship -lossless -m 6.
# Ceilings are § 4.5's re-measured values (18000/34000/12000/18000/18000 ->
# 31000/71000/24000/37000/33000), ~1.10x over measured — TIGHTER than the ~1.3x
# convention they replace, because lossless output is deterministic.
TIER_B=(
  "logo-lcc|64|128|192|31000"
  "moha-sm|64|128|160|71000"
  "mops-sm|32|64|96|24000"
  "edl-logo|48|96|144|37000"
  "nampapa-logo|48|96|144|33000"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# libwebp dB -> conventional 0..1 SSIM.
# RETAINED per architecture-review.md § 4.1 as an INFORMATIONAL cross-reference
# for readers who know SSIM in its usual units. Its output is printed and
# recorded in qa-report.md; it is NEVER compared against a threshold.
db_to_ssim() {
  awk -v d="$1" 'BEGIN{ if (d == "") { print "ERROR"; exit }
                        if (d >= 99) { printf "%.6f", 1.0 }
                        else { printf "%.6f", 1 - 10 ^ (-d / 10) } }'
}

ge() { awk -v a="$1" -v b="$2" 'BEGIN{ exit !(a >= b) }'; }

# Tier A effective floor (§ 4.2): max(absolute floor, baseline - regression).
# Both bounds must hold, so the binding one is the larger — but each is also
# checked and reported separately below, so a failure says WHICH bound broke.
tier_a_floor() { # baseline_dB
  awk -v b="$1" -v r="$TIER_A_REGRESSION_DB" -v a="$TIER_A_ABS_FLOOR_DB" \
    'BEGIN{ f = b - r; if (f < a) f = a; printf "%.2f", f }'
}

native_dim() { # file axis(pixelWidth|pixelHeight)
  sips -g "$2" "$1" 2>/dev/null | awk -v k="$2" '$1 == k":" { print $2 }'
}

# Encode one file; echoes "<bytes> <ssim_db>".
encode() { # src out mode quality [w h]
  local src="$1" out="$2" mode="$3" q="$4" w="${5:-}" h="${6:-}"
  local args=()
  case "$mode" in
    lossy)    args=(-q "$q" -m 6 -mt) ;;                    # § 6.2 Tier A, unchanged
    lossless) args=(-lossless -m 6) ;;                      # § 4.3 Tier B, the only Tier B mode
    *) die "unknown encode mode: $mode" ;;
  esac
  # The `alpha` mode (-q 90 -alpha_q 100) is DELETED, not merely unused: § 4.3
  # withdraws lossy encoding for Tier B, and leaving a reachable lossy path here
  # is how a future edit silently reintroduces it.
  #
  # -exact is deliberately NOT passed (§ 3.3, evaluated and DECLINED). With
  # -resize it changes the alpha RESAMPLING CONVENTION, not just hidden pixels:
  # 333 of moha-sm's 340 differing pixels have alpha > 0, and the non-exact
  # default (premultiplied resampling) is the conventionally correct method.
  #
  # -metadata defaults to none; § 6.2 forbids overriding it, so it is not passed.
  args+=(-print_ssim)
  [ -n "$w" ] && args+=(-resize "$w" "$h")
  local log
  log="$("$CWEBP" "${args[@]}" "$src" -o "$out" 2>&1)" \
    || { printf '%s\n' "$log" >&2; die "cwebp failed on $src"; }
  printf '%s %s\n' \
    "$(stat -f%z "$out")" \
    "$(printf '%s\n' "$log" | grep '^SSIM:' | sed 's/.*Total:\([0-9.]*\).*/\1/')"
}

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------

[ -x "$CWEBP" ] || die "cwebp not found or not executable at '$CWEBP' (override with CWEBP=...)"
command -v sips >/dev/null 2>&1 || die "sips not found (macOS host required for dimension checks)"
[ -d "$IMG" ] || die "assets/images not found at $IMG"

# Generation-loss guard (§ 6.5). Exits 2 to distinguish "refused to run" from
# "ran and a gate failed" (exit 1).
if find "$IMG" -type f -name '*.webp' -print -quit | grep -q .; then
  cat >&2 <<'GUARD'
REFUSED: assets/images/ already contains .webp files.

This pipeline is an irreversible lossy transform. Re-encoding its own output
would compound generation loss (§ 6.5), so a second run is refused rather than
silently degrading the assets.

To re-run, restore the 16 PNG/JPG sources first — they are byte-identical to
../lcc-app/src/imports/ (read-only port source, ADR-0001) — and delete the
generated .webp files, including the 2.0x/ and 3.0x/ subtrees.
GUARD
  exit 2
fi

printf '%s\n' "cwebp: $("$CWEBP" -version | head -1)   root: $ROOT"
printf '%s\n' "B1b-AC-5 (as amended, architecture-review.md § 6) — ALL THRESHOLDS IN dB:"
printf '%s\n' "  Tier A: >= ${TIER_A_ABS_FLOOR_DB} dB absolute AND >= (baseline - ${TIER_A_REGRESSION_DB} dB) per asset"
printf '%s\n' "  Tier B: == ${TIER_B_FLOOR_DB} dB (the clamp) — lossless by construction"
printf '%s\n' "  SSIM column is INFORMATIONAL; no gate compares against it."
printf '%s\n' "total ceiling: $TOTAL_CEILING B (unchanged)"
printf '\n'

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/2.0x" "$STAGE/3.0x"

FAILURES=0
TOTAL=0
RULE="---------------------------------------------------------------------------------------------------------"
printf '%-22s %-11s %-9s %10s %10s %8s %9s %9s  %s\n' \
  ASSET DIMENSIONS MODE BYTES CEILING SSIM_dB FLOOR_dB SSIM VERDICT
printf '%s\n' "$RULE"

# --- Tier A ----------------------------------------------------------------
for row in "${TIER_A[@]}"; do
  IFS='|' read -r name ext q tw th ceil base <<< "$row"
  src="$IMG/$name.$ext"
  [ -f "$src" ] || die "missing source: $src"

  nw="$(native_dim "$src" pixelWidth)"; nh="$(native_dim "$src" pixelHeight)"
  # No-upscale rule (§ 6.2): a target above native is capped at native.
  if [ -n "$tw" ]; then
    [ "$tw" -gt "$nw" ] && tw="$nw"
    [ "$th" -gt "$nh" ] && th="$nh"
    dims="${tw}x${th}"
  else
    dims="${nw}x${nh}*"   # * = native, not resized
  fi

  read -r bytes db <<< "$(encode "$src" "$STAGE/$name.webp" lossy "$q" "$tw" "$th")"
  ssim="$(db_to_ssim "$db")"
  floor="$(tier_a_floor "$base")"

  verdict="PASS"
  ge "$ceil" "$bytes" || { verdict="CEILING-BREACH"; FAILURES=$((FAILURES+1)); }

  # § 4.2 — dB to dB, both bounds, no conversion in the gate path.
  dbnote=""
  ge "$db" "$TIER_A_ABS_FLOOR_DB" || dbnote="ABS<${TIER_A_ABS_FLOOR_DB}"
  ge "$db" "$floor"               || dbnote="${dbnote:+$dbnote,}REGR<${floor}"
  [ -z "$dbnote" ] || { verdict="${verdict/PASS/}dB-BREACH($dbnote)"; FAILURES=$((FAILURES+1)); }

  TOTAL=$((TOTAL + bytes))
  printf '%-22s %-11s %-9s %10s %10s %8s %9s %9s  %s\n' \
    "$name.webp" "$dims" "lossy/q$q" "$bytes" "$ceil" "$db" "$floor" "$ssim" "$verdict"
done

# --- Tier B ----------------------------------------------------------------
for row in "${TIER_B[@]}"; do
  IFS='|' read -r name r1 r2 r3 ceil <<< "$row"
  src="$IMG/$name.png"
  [ -f "$src" ] || die "missing source: $src"
  nw="$(native_dim "$src" pixelWidth)"

  sum=0; i=0
  for r in "$r1" "$r2" "$r3"; do
    i=$((i+1))
    # No-upscale rule (§ 6.2) — this is what caps moha-sm's 3.0x rung at 160.
    capped=""; if [ "$r" -gt "$nw" ]; then r="$nw"; capped=" (capped@native)"; fi
    case $i in 1) out="$STAGE/$name.webp"; label="$name.webp" ;;
               2) out="$STAGE/2.0x/$name.webp"; label="2.0x/$name.webp" ;;
               3) out="$STAGE/3.0x/$name.webp"; label="3.0x/$name.webp" ;; esac

    # § 4.3: lossless UNCONDITIONALLY. No dual encode, no comparison — § 6.2's
    # "ship whichever is smaller" optimised for bytes, and for this tier
    # fidelity is the binding constraint.
    read -r bytes db <<< "$(encode "$src" "$out" lossless "" "$r" "$r")"
    mode="lossless"

    ssim="$(db_to_ssim "$db")"
    verdict="-"
    # Gated at the clamp. Lossless satisfies this by construction; the best
    # lossy encode measured anywhere in this tier is 17.35 dB, so a
    # non-compliant encode fails by a margin of >= 81.65 dB.
    ge "$db" "$TIER_B_FLOOR_DB" \
      || { verdict="dB-BREACH(<${TIER_B_FLOOR_DB})"; FAILURES=$((FAILURES+1)); }
    sum=$((sum + bytes)); TOTAL=$((TOTAL + bytes))
    printf '%-22s %-11s %-9s %10s %10s %8s %9s %9s  %s\n' \
      "$label" "${r}x${r}${capped}" "$mode" "$bytes" "" "$db" "$TIER_B_FLOOR_DB" "$ssim" "$verdict"
  done

  # § 7.1 AC-3: for Tier B the ceiling applies to the sum of the three rungs.
  verdict="PASS"
  ge "$ceil" "$sum" || { verdict="CEILING-BREACH"; FAILURES=$((FAILURES+1)); }
  printf '%-22s %-11s %-9s %10s %10s %8s %9s %9s  %s\n' \
    "  └ $name (3 rungs)" "" "sum" "$sum" "$ceil" "" "" "" "$verdict"
done

# --- Totals ----------------------------------------------------------------
printf '%s\n' "$RULE"
count=$(find "$STAGE" -type f -name '*.webp' | wc -l | tr -d ' ')
printf 'FILES: %s (expected 26)   TOTAL: %s B   CEILING: %s B\n' "$count" "$TOTAL" "$TOTAL_CEILING"

[ "$count" -eq 26 ] || { printf 'FAIL: expected 26 output files, got %s\n' "$count"; FAILURES=$((FAILURES+1)); }
if ge "$TOTAL_CEILING" "$TOTAL"; then
  printf 'TOTAL BUDGET: PASS (%s B <= %s B)\n' "$TOTAL" "$TOTAL_CEILING"
else
  printf 'TOTAL BUDGET: FAIL (%s B > %s B)\n' "$TOTAL" "$TOTAL_CEILING"; FAILURES=$((FAILURES+1))
fi

if [ "$FAILURES" -ne 0 ]; then
  cat >&2 <<EOF

ABORTED: $FAILURES gate breach(es). The tree has NOT been modified — the 16
sources are untouched and no .webp was written into assets/images/.

Per B1b-AC-5 as amended (architecture-review.md § 6) and specs.md § 8, a
ceiling/floor conflict is escalated to sw-architect-lcc-mobile-app-greenfield.
Do not ship the lower quality, do not raise a ceiling, and do not change a
§ 6.3 quality value — the Tier A escape hatch to q75 is RESCINDED (§ 4.2).

A total that is not 949,262 B means a different pipeline ran than the one
specified (§ 7 step 5). Investigate; do not adjust a ceiling to fit.
EOF
  exit 1
fi

# --- Commit to tree (only reached when every gate passed) ------------------
# Originals are deleted in the same operation that installs the .webp (§ 3.1).
mkdir -p "$IMG/2.0x" "$IMG/3.0x"
cp "$STAGE"/*.webp "$IMG/"
cp "$STAGE"/2.0x/*.webp "$IMG/2.0x/"
cp "$STAGE"/3.0x/*.webp "$IMG/3.0x/"
find "$IMG" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' \) -delete

printf '\nOK: 26 .webp installed in assets/images/; 16 originals deleted. All gates passed.\n'
