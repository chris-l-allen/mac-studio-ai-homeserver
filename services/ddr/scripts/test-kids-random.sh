#!/usr/bin/env bash
# End-to-end test: the kids SongSelectMusic wheel must open on a *random* song
# and Start must actually play that song (not always the first item).
#
# This drives the real OutFox engine via AppleScript key events and reads its
# logs. It is an integration test, not a unit test: the MusicWheel/GAMESTATE
# bindings only exist inside the running engine.
#
# It restarts OutFox for every visit so each run starts from a known screen
# (the engine's Back does not reliably return from song select to the chooser).
#
# Preconditions:
#   - OutFox installed with the mermaid-kids theme.
#   - The terminal/ssh session may post key events (Accessibility -> System Events).
#
# Env overrides:
#   OUTFOX_APP  default "$HOME/Applications/OutFox/OutFox.app"
#   LOG_DIR     default "$HOME/Library/Logs/Project OutFox"
#   VISITS      default 4
set -euo pipefail

OUTFOX_APP="${OUTFOX_APP:-$HOME/Applications/OutFox/OutFox.app}"
LOG_DIR="${LOG_DIR:-$HOME/Library/Logs/Project OutFox}"
VISITS="${VISITS:-4}"
THEME="${THEME:-mermaid-kids}"

RET=0
say() { printf '%s\n' "$*"; }
fail() { say "FAIL: $*"; RET=1; }

newest() { ls -t "$LOG_DIR"/$1 2>/dev/null | head -1 || true; }

key() {  # key <keycode>
	osascript \
		-e 'tell application "System Events" to set frontmost of process "OutFox" to true' \
		-e 'delay 0.4' \
		-e "tell application \"System Events\" to key code $1" >/dev/null 2>&1
}

wait_after() {  # wait_after <start_line> <file> <pattern> [timeout_s]
	local start="$1" file="$2" pat="$3" t="${4:-15}" i=0
	while [ "$i" -lt "$t" ]; do
		if tail -n "+$((start + 1))" "$file" | grep -aq "$pat"; then return 0; fi
		sleep 1; i=$((i + 1))
	done
	return 1
}

restart() {
	local before
	before=$(newest "ProjectOutfox.MainLog.*" || true)
	pkill -9 -x OutFox 2>/dev/null || true
	sleep 2
	open -n "$OUTFOX_APP"
	local i=0 M
	while [ "$i" -lt 40 ]; do
		M=$(newest "ProjectOutfox.MainLog.*")
		if [ -n "$M" ] && [ "$M" != "$before" ] \
			&& grep -aq 'PushScreen: "ScreenSelectPlayers"' "$M" 2>/dev/null; then
			sleep 1
			return 0
		fi
		sleep 1; i=$((i + 1))
	done
	return 1
}

enter_music() {  # enter_music <start_line> <main_log>
	local m0="$1" M="$2"
	key 36
	if wait_after "$m0" "$M" 'PushScreen: "ScreenSelectMusic"' 8; then return 0; fi
	key 36
	wait_after "$m0" "$M" 'PushScreen: "ScreenSelectMusic"' 10
}

last_field() {  # last_field <file> <grep-re> <sed-expr>
	grep -a "$2" "$1" | tail -1 | sed -E "$3" || true
}

# ---- Phase A: the picked song is what actually plays -----------------------
say "== Phase A: random pick is committed and played =="
picked="" banner="" firstb=""
attempt=1
while [ "$attempt" -le 3 ]; do
	restart || { fail "OutFox did not reach ScreenSelectPlayers"; exit "$RET"; }
	T=$(newest "ProjectOutfox-${THEME}.ThemeLua.*")
	M=$(newest "ProjectOutfox.MainLog.*")
	t0=$(wc -l < "$T"); m0=$(wc -l < "$M")
	if ! enter_music "$m0" "$M"; then
		fail "attempt $attempt: did not reach ScreenSelectMusic"
		exit "$RET"
	fi
	sleep 4  # allow the preferred-sort commit

	picked=$(tail -n "+$((t0 + 1))" "$T" | grep -a 'KIDPOP picked ' | tail -1 | sed 's/.*KIDPOP picked //' || true)
	firstb=$(tail -n "+$((m0 + 1))" "$M" | grep -a 'LoadFromCachedBanner' | head -1 \
		| sed -E 's#.*/Songs/[^/]+/([^/]+)/.*#\1#' || true)
	banner=$(tail -n "+$((m0 + 1))" "$M" | grep -a 'LoadFromCachedBanner' | tail -1 \
		| sed -E 's#.*/Songs/[^/]+/([^/]+)/.*#\1#' || true)
	say "attempt $attempt: picked='$picked' initial='$firstb' committed-banner='$banner'"
	if [ -n "$picked" ] && [ "$firstb" != "$banner" ]; then
		break
	fi
	say "  pick matched the initial song; restarting"
	attempt=$((attempt + 1))
done
[ -n "$picked" ] || { fail "no KIDPOP picked trace (theme not deployed?)"; exit "$RET"; }
if [ "$firstb" = "$banner" ]; then
	fail "could not get a pick different from the initial song"
	exit "$RET"
fi

m1=$(wc -l < "$M")
key 36   # song select -> gameplay
if ! wait_after "$m1" "$M" 'Loading screen: "ScreenGameplay"' 15; then
	fail "Start did not enter gameplay"
	exit "$RET"
fi
sleep 1
played=$(tail -n "+$((m1 + 1))" "$M" | grep -a "Preferences.ini" | head -1 \
	| sed -E 's#.*/Songs/[^/]+/([^/]+)/.*#\1#' || true)
say "played-folder='$played'"
if [ -z "$played" ]; then
	fail "could not read played song from log"
elif [ "$played" != "$banner" ]; then
	fail "played '$played' but wheel committed '$banner'"
else
	say "OK: played the committed random song ($played)"
fi

# ---- Phase B: repeated visits pick different songs ------------------------
say "== Phase B: first song varies across $VISITS visits =="
picks=""
n=1
while [ "$n" -le "$VISITS" ]; do
	restart || { fail "visit $n: OutFox did not start"; break; }
	T=$(newest "ProjectOutfox-${THEME}.ThemeLua.*")
	M=$(newest "ProjectOutfox.MainLog.*")
	T0=$(wc -l < "$T"); m0=$(wc -l < "$M")
	if ! enter_music "$m0" "$M"; then
		fail "visit $n: did not reach ScreenSelectMusic"
		break
	fi
	sleep 4
	p=$(tail -n "+$((T0 + 1))" "$T" | grep -a 'KIDPOP picked ' | tail -1 | sed 's/.*KIDPOP picked //' || true)
	say "visit $n: picked '$p'"
	picks="$picks$p"$'\n'
	n=$((n + 1))
done

distinct=$(printf '%s' "$picks" | sed '/^$/d' | sort -u | wc -l | tr -d ' ')
count=$(printf '%s' "$picks" | sed '/^$/d' | wc -l | tr -d ' ')
say "distinct picks: $distinct of $count"
if [ "$count" -lt 2 ]; then
	fail "not enough successful visits"
elif [ "$distinct" -lt 2 ]; then
	fail "the wheel always picked the same song"
else
	say "OK: first song is randomized"
fi

# Leave the game at the 1P/2P chooser.
restart >/dev/null 2>&1 || true

if [ "$RET" -eq 0 ]; then say PASS; else say FAILED; fi
exit "$RET"
