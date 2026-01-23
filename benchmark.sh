#!/bin/bash

# Configuration
FLAGS=("--simple" "--medium" "--complex" "--adaptive")
SIZES=(100 500)
TRIALS=100
TIMEOUT=10s
SAVE_LOG=false
LOG_FILE="debug_oversize.log"
BINARY="push_swap"

# Check for -save flag
if [[ "$1" == "-save" ]]; then
    SAVE_LOG=true
    echo -n "" > "$LOG_FILE"
fi

# UI Colors
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; B='\033[0;34m'; P='\033[0;35m'; C='\033[0;36m'; NC='\033[0m'; DIM='\033[2m'

# --- PHASE DE COMPILATION ---
echo -e "${C}# Compiling project...${NC}"

if [ -f "Makefile" ]; then
    make > /dev/null 2>&1
    # On vérifie l'exécutable généré par le Makefile
    if [ ! -f "$BINARY" ] && [ -f "a.out" ]; then BINARY="a.out"; fi
else
    # Compilation robuste : cherche tous les .c dans le dossier actuel et sous-dossiers
    SOURCES=$(find . -name "*.c")
    if [ -z "$SOURCES" ]; then
        echo -e "${R}Error: No .c files found.${NC}"
        exit 1
    fi
    cc -Wall -Wextra -Werror $SOURCES -o a.out > /dev/null 2>&1
    BINARY="a.out"
fi

# Vérification finale de l'exécutable
if [ ! -f "$BINARY" ]; then
    echo -e "${R}Error: Compilation failed. Ensure your .c files are valid.${NC}"
    exit 1
fi
echo -e "${G}# Compilation successful: using $BINARY${NC}\n"

header() {
    clear
    echo -e "${C}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C}║                        ${NC}${Y}PUSH_SWAP DEBUG & STRESS TESTER${NC}${C}                   ║${NC}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${P}Trials:${NC} $TRIALS/category | ${P}Timeout:${NC} $TIMEOUT"
    if [ "$SAVE_LOG" = true ]; then echo -e "  ${Y}Logging enabled (Critical Only):${NC} $LOG_FILE"; fi
    echo -e "  ${DIM}Thresholds: ${G}Perfect (<700/5500)${NC} ${DIM}|${NC} ${Y}Valid (<2000/12000)${NC} ${DIM}|${NC} ${R}Fail${NC}"
    echo -e "${DIM}----------------------------------------------------------------------------${NC}"
}

SUMMARY_FILE=".stats.tmp"
echo -n "" > "$SUMMARY_FILE"
GLOBAL_PASS=true

header

for flag in "${FLAGS[@]}"; do
    for size in "${SIZES[@]}"; do
        ok=0; ko=0; to=0; total_lines=0; max_lines=0

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

            ARGS=$(python3 -c "import random; l=sorted(random.sample(range(-20000, 20000), $size)); n=int($size*$dis); idx=random.sample(range($size), n); v=[l[i] for i in idx]; random.shuffle(v); res=l[:]; [res.__setitem__(idx[i], v[i]) for i in range(n)]; print(*(res))")

            RAW_OUT=$(timeout "$TIMEOUT" ./"$BINARY" $ARGS "$flag" 2>/dev/null)
            EXIT_STATUS=$?

            if [ $EXIT_STATUS -eq 124 ]; then
                ((to++)); GLOBAL_PASS=false
                if [ "$SAVE_LOG" = true ]; then echo -e "[TIMEOUT] Flag: $flag | Size: $size\nStack: $ARGS\n" >> "$LOG_FILE"; fi
            else
                CHECK_RES=$(echo "$RAW_OUT" | ./checker_linux $ARGS 2>&1)
                if [[ "$CHECK_RES" == "OK" ]]; then
                    ((ok++))
                    count=$(echo "$RAW_OUT" | sed '/^\s*$/d' | wc -l | tr -d ' ')

                    if [ "$SAVE_LOG" = true ]; then
                        if ([ "$size" -eq 100 ] && [ "$count" -ge 2000 ]) || ([ "$size" -eq 500 ] && [ "$count" -ge 12000 ]); then
                            echo -e "[CRITICAL] Ops: $count | Flag: $flag | Size: $size\nStack: $ARGS\n" >> "$LOG_FILE"
                        fi
                    fi

                    total_lines=$((total_lines + count))
                    [ "$count" -gt "$max_lines" ] && max_lines=$count
                else
                    ((ko++)); GLOBAL_PASS=false
                    if [ "$SAVE_LOG" = true ]; then echo -e "[KO] Flag: $flag | Size: $size\nStack: $ARGS\n" >> "$LOG_FILE"; fi
                fi
            fi

            if [ $((i % 5)) -eq 0 ]; then
                printf "\r ${B}⚡${NC} Running %-10s [%-3s] : ${Y}%3d%%${NC}" "$flag" "$size" "$i"
            fi
        done

        if [ "$size" -eq 100 ] && [ "$max_lines" -ge 2000 ]; then GLOBAL_PASS=false; fi
        if [ "$size" -eq 500 ] && [ "$max_lines" -ge 12000 ]; then GLOBAL_PASS=false; fi

        success_rate=$(( (ok * 100) / TRIALS ))
        avg_lines=0
        [ $ok -gt 0 ] && avg_lines=$((total_lines / ok))

        echo "$flag|$size|$ok|$ko|$to|$success_rate|$max_lines|$avg_lines" >> "$SUMMARY_FILE"
        echo -e " - ${G}DONE${NC}"
    done
done

# --- FINAL TABLE ---
echo -e "\n${C}┌────────────┬─────┬──────┬──────┬─────┬────────┬──────────┬──────────┐${NC}"
echo -e "${C}│${NC} ${Y}CATEGORY${NC}   ${C}│${NC} ${Y}SIZE${NC}${C}│${NC}  ${G}OK${NC}  ${C}│${NC}  ${R}KO${NC}  ${C}│${NC} ${P}T/O${NC} ${C}│${NC} ${B}SCORE${NC}  ${C}│${NC} ${C}MAX LINE${NC} ${C}│${NC} ${C}AVG LINE${NC} ${C}│${NC}"
echo -e "${C}├────────────┼─────┼──────┼──────┼─────┼────────┼──────────┼──────────┤${NC}"

while IFS='|' read -r f s n_ok n_ko n_to rate max_l avg_l; do
    color_rate=$G; [ "$rate" -lt 100 ] && color_rate=$R
    get_color() {
        local val=$1; local sz=$2
        if [ "$sz" -eq 100 ]; then
            if [ "$val" -ge 2000 ]; then echo "$R"; elif [ "$val" -ge 700 ]; then echo "$Y"; else echo "$G"; fi
        else
            if [ "$val" -ge 12000 ]; then echo "$R"; elif [ "$val" -ge 5500 ]; then echo "$Y"; else echo "$G"; fi
        fi
    }
    c_max=$(get_color "$max_l" "$s")
    c_avg=$(get_color "$avg_l" "$s")
    c_ko=$NC; [ "$n_ko" -gt 0 ] && c_ko=$R
    c_to=$NC; [ "$n_to" -gt 0 ] && c_to=$R

    printf "${C}│${NC} %-10s ${C}│${NC} %-3s ${C}│${NC} %-4s ${C}│${NC} ${c_ko}%-4s${NC} ${C}│${NC} ${c_to}%-3s${NC} ${C}│${NC} ${color_rate}%5s%%${NC} ${C}│${NC} ${c_max}%-8s${NC} ${C}│${NC} ${c_avg}%-8s${NC} ${C}│${NC}\n" \
           "$f" "$s" "$n_ok" "$n_ko" "$n_to" "$rate" "$max_l" "$avg_l"
done < "$SUMMARY_FILE"

echo -e "${C}└────────────┴─────┴──────┴──────┴─────┴────────┴──────────┴──────────┘${NC}"

if [ "$GLOBAL_PASS" = true ]; then
    echo -e "\n${G}>>>> FINAL VERDICT: PASS${NC} 🎉"
else
    echo -e "\n${R}>>>> FINAL VERDICT: FAIL${NC} ❌"
fi

# --- NETTOYAGE ---
if [ -f "Makefile" ]; then
    make fclean > /dev/null 2>&1
else
    rm -f a.out
fi
rm -f "$SUMMARY_FILE"

if [ "$SAVE_LOG" = true ]; then echo -e "${Y}Critical failures logged to: ${NC}$LOG_FILE"; fi
