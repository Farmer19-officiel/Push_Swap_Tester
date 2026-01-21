#!/bin/bash

FLAGS=("--simple" "--medium" "--complex" "--adaptive")
SIZES=(100 500)
TRIALS=100
TIMEOUT=10s

# UI Colors
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; B='\033[0;34m'; P='\033[0;35m'; C='\033[0;36m'; NC='\033[0m'

header() {
    clear
    echo -e "${C}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C}║                     ${NC}${Y}PUSH_SWAP STRESS TESTER${NC}${C}                      ║${NC}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${P}Trials:${NC} $TRIALS/category | ${P}Timeout:${NC} $TIMEOUT"
    echo -e "--------------------------------------------------------------------"
}

SUMMARY_FILE=".stats.tmp"
echo -n "" > "$SUMMARY_FILE"
GLOBAL_PASS=true

header

for flag in "${FLAGS[@]}"; do
    for size in "${SIZES[@]}"; do
        ok=0; ko=0; to=0

        case "$flag" in
            "--simple") d_fixed="0.2" ;;
            "--medium") d_fixed="0.5" ;;
            "--complex") d_fixed="0.8" ;;
            *) d_fixed="random" ;;
        esac

        printf " ${B}⚡${NC} Running %-10s [%-3s] : " "$flag" "$size"

        for i in $(seq 1 "$TRIALS"); do
            if [ "$d_fixed" == "random" ]; then
                dis=$(python3 -c "import random; print(round(random.uniform(0.1, 0.9), 2))")
            else
                dis="$d_fixed"
            fi

            # Args Generation (Push_Swap compatible)
            ARGS=$(python3 -c "import random; l=sorted(random.sample(range(-10000, 10000), $size)); n=int($size*$dis); idx=random.sample(range($size), n); v=[l[i] for i in idx]; random.shuffle(v); res=l[:]; [res.__setitem__(idx[i], v[i]) for i in range(n)]; print(*(res))")

            # Execution
            OUT=$(timeout "$TIMEOUT" ./a.out $ARGS "$flag" 2>/dev/null)
            EXIT_STATUS=$?

            if [ $EXIT_STATUS -eq 124 ]; then
                ((to++)); GLOBAL_PASS=false
            else
                CHECK_RES=$(echo "$OUT" | ./checker_linux $ARGS 2>&1)
                if [[ "$CHECK_RES" == "OK" ]]; then
                    ((ok++))
                else
                    ((ko++)); GLOBAL_PASS=false
                fi
            fi

            if [ $((i % 5)) -eq 0 ]; then
                printf "\r ${B}⚡${NC} Running %-10s [%-3s] : ${Y}%3d%%${NC}" "$flag" "$size" "$i"
            fi
        done

        # Calculate Success Rate %
        success_rate=$(( (ok * 100) / TRIALS ))
        echo "$flag|$size|$ok|$ko|$to|$success_rate" >> "$SUMMARY_FILE"
        echo -e " - ${G}DONE${NC}"
    done
done

# --- FINAL TABLE ---
echo -e "\n${C}┌──────────────┬──────┬────────────┬────────────┬────────────┬─────────┐${NC}"
echo -e "${C}│${NC} ${Y}CATEGORY${NC}     ${C}│${NC} ${Y}SIZE${NC} ${C}│${NC}     ${G}OK${NC}     ${C}│${NC}     ${R}KO${NC}     ${C}│${NC}   ${P}T/O${NC}      ${C}│${NC} ${B}SCORE${NC}   ${C}│${NC}"
echo -e "${C}├──────────────┼──────┼────────────┼────────────┼────────────┼─────────┤${NC}"

while IFS='|' read -r f s n_ok n_ko n_to rate; do
    # Column Colors
    color_rate=$G; [ "$rate" -lt 100 ] && color_rate=$Y; [ "$rate" -lt 50 ] && color_rate=$R
    color_ko=$NC; [ "$n_ko" -gt 0 ] && color_ko=$R
    color_to=$NC; [ "$n_to" -gt 0 ] && color_to=$R

    printf "${C}│${NC} %-12s ${C}│${NC} %-4s ${C}│${NC} ${G}%-10s${NC} ${C}│${NC} ${color_ko}%-10s${NC} ${C}│${NC} ${color_to}%-10s${NC} ${C}│${NC} ${color_rate}%5s%%${NC}  ${C}│${NC}\n" \
           "$f" "$s" "$n_ok" "$n_ko" "$n_to" "$rate"
done < "$SUMMARY_FILE"

echo -e "${C}└──────────────┴──────┴────────────┴────────────┴────────────┴─────────┘${NC}"

# --- VERDICT ---
if [ "$GLOBAL_PASS" = true ]; then
    echo -e "\n${G}>>>> FINAL VERDICT: SUCCESS (100% Correctness)${NC} 🎉"
else
    echo -e "\n${R}>>>> FINAL VERDICT: FAIL (Issues detected in sorting logic)${NC} ❌"
fi

rm -f "$SUMMARY_FILE"
