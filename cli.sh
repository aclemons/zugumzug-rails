#!/bin/sh
#
# Copyright (C) 2016 Powershop New Zealand Ltd
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Simple cli interface to a zugumzug instance running somewhere

set -e

macosx=false
case "$(uname)" in
Darwin) macosx=true;;
esac

usage() {
  cat << EOF
Usage: cli.sh

Connect to a remote zugumzug server like this:
  cli.sh

Environment variables affect how the script runs:
  URL      - url of the remote server - default http://localhost:3000
  VERBOSE  - verbose output on start
  COLOURS  - enable|disable colours - default yes

Options mirror the environment variables above:
  --url       - same as URL
  --verbose   - same as VERBOSE=yes
  --no-colours - same as COULOURS=no

Examples
  URL=http://10.43.0.13:3000 ./cli.sh
  ./cli.sh --url http://10.43.0.13:3000

Requirements:
posix compliant sh
sed
awk
curl
dialog
jsawk
gnuplot

Exit codes:
0 - normal
1 - Invalid arguments
2 - Missing dependencies

EOF
}

VERSION="0.0.1"

quote() { printf "%s" "$1" | sed "s/'/\'\\\\'\'/g" | sed "s/^/\'/" | sed "s/$/\'/" ; }
escape_sed_value() { printf "%s\n" "$1" | sed -e 's/[\/&]/\\&/g' ; }
escape_for_dialog() { awk 1 ORS='\\n' ; }

backtitle() {
  printf "Zug um Zug CLI (version %s)" "$VERSION"
  if [ "x$game_id" != "x" ] ; then
    printf " - Game %s" "$game_id"
  fi

  if [ "x$player" = "x" ] ; then
    if [ "x$userid" != "x" ] ; then
      printf " | User %s" "$userid"
    fi
  else
    printf " | %s%s: %s / Train(s) %s / Points %s / Phase %s%s" "$player_dialog_colour" "$player_colour_name" "$player_name" "$player_trains" "$player_points" "$game_phase_name" "$DLRESET"
  fi

  printf "\n"
}

status_string() {
  (
    {
      if [ "x$game_data" != "x" ] ; then
        if [ "$player_count" -gt 0 ] ; then
          printf "\n"

          for i in $(seq 1 "$player_count") ; do
            idx=$((i-1))

            local_user_id="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.user_id)')"
            if [ "x$userid" = "x$local_user_id" ] && [ "$game_phase" -ne 4 ] ; then
              continue
            fi

            local_points="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.points)')"
            local_name="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.name)')"
            local_trains="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.train_cars)')"
            local_colour="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.colour_name)')"
            local_phase="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.phase_name)')"
            local_dialog_colour="$(dialog_colour_for_name "$local_colour")"
            local_player_colour_name="$(printf "%s" "$local_colour" | tr '[:lower:]' '[:upper:]')"

            if [ "$game_phase" -eq 4 ] ; then
              local_player_id="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.player_id)')"
              local_longest_route="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.longest_continuous_path ? "yes" : "no")')"
              winner="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.winner === '"$local_player_id"' ? "yes" : "no")')"

              printf "%s%s: %s / Train(s) %s / Points %s%s\n" "$local_dialog_colour" "$local_player_colour_name" "$local_name" "$local_trains" "$local_points" "$DLRESET"
              printf "Destination Tickets\n\n" "$local_longest_route"
              print_destination_tickets "$(printf "%s\n" "$game_data" | jsawk -n "out(this.players[$idx])")"
              printf "Longest route: %s\n" "$local_longest_route"

              if [ "x$winner" = "xyes" ] ; then
                printf "WINNER!\n"
              fi

              printf "\n"
            else
              printf "%s%s: %s / Train(s) %s / Points %s / Phase %s%s\n" "$local_dialog_colour" "$local_player_colour_name" "$local_name" "$local_trains" "$local_points" "$local_phase" "$DLRESET"
            fi
          done

          printf "\nTrain Card Deck\n"
          print_train_cards "deck" | dialog_colourise
        fi
      fi
    } | escape_for_dialog
  )
}

# shellcheck disable=SC2034
print_divider() { for divider in $(seq 1 "$1") ; do printf "%s" "$2" ; done ; printf "\n" ; }

colourise() {
  sed "s/black /$CLBLACK""black$CLRESET /g" \
    | sed "s/blue /$CLBLUE""blue$CLRESET /g" \
    | sed "s/green /$CLGREEN""green$CLRESET /g" \
    | sed "s/locomotive /$CLLOC""locomotive$CLRESET /g" \
    | sed "s/orange /$CLORANGE""orange$CLRESET /g" \
    | sed "s/purple /$CLMAGENTA""purple$CLRESET /g" \
    | sed "s/red /$CLRED""red$CLRESET /g" \
    | sed "s/white /$CLWHITE""white$CLRESET /g" \
    | sed "s/yellow /$CLYELLOW""yellow$CLRESET /g"
}

dialog_colourise() {
  sed "s/black /$(escape_sed_value "$DLBLACK")black$(escape_sed_value "$DLRESET") /" \
    | sed "s/blue /$(escape_sed_value "$DLBLUE")blue$(escape_sed_value "$DLRESET") /" \
    | sed "s/green /$(escape_sed_value "$DLGREEN")green$(escape_sed_value "$DLRESET") /" \
    | sed "s/locomotive /$(escape_sed_value "$DLLOC")locomotive$(escape_sed_value "$DLRESET") /" \
    | sed "s/purple /$(escape_sed_value "$DLPURPLE")purple$(escape_sed_value "$DLRESET") /" \
    | sed "s/red /$(escape_sed_value "$DLRED")red$(escape_sed_value "$DLRESET") /" \
    | sed "s/white /$(escape_sed_value "$DLWHITE")white$(escape_sed_value "$DLRESET") /" \
    | sed "s/yellow /$(escape_sed_value "$DLYELLOW")yellow$(escape_sed_value "$DLRESET") /"
}

dialog_colour_for_name() {
  case "$1" in
    black) printf "%s" "$DLBLACK" ;;
    blue) printf "%s" "$DLBLUE" ;;
    green) printf "%s" "$DLGREEN" ;;
    red) printf "%s" "$DLRED" ;;
    yellow) printf "%s" "$DLYELLOW" ;;
    *) printf "" ;;
  esac
}

colour_id_for_name() {
  case "$1" in
    black) printf "%d" 1 ;;
    blue) printf "%d" 2 ;;
    green) printf "%d" 3 ;;
    grey) printf "%d" 0 ;;
    orange) printf "%d" 4 ;;
    purple) printf "%d" 5 ;;
    red) printf "%d" 6 ;;
    white) printf "%d" 7 ;;
    yellow) printf "%d" 8 ;;
    *) printf "" ;;
  esac
}

colour_name_for_id() {
  case "$1" in
    0) printf "%s" "0x007F7F7F" ;;
    1) printf "%s" "0x00858585" ;;
    2) printf "%s" "0x000000AA" ;;
    3) printf "%s" "0x0000AA00" ;;
    4) printf "%s" "orange" ;;
    5) printf "%s" "purple" ;;
    6) printf "%s" "0x00AA0000" ;;
    7) printf "%s" "0x00FFFFFF" ;;
    8) printf "%s" "0x00AA5500" ;;
    *) printf "" ;;
  esac
}

print_table() {
  (
    header="$(printf "%s\n" "$1" | head -1)"
    cols="$(printf "%s\n" "$header" | awk '{ print length($0) }')"
    body="$(printf "%s\n" "$1" | sed 1d)"

    {
      printf "%s\n" "$header"
      print_divider "$cols" "="
      printf "%s\n" "$body"
      print_divider "$cols" "="
    } | sed 's/^/|/'
  )
}

print_destination_tickets() {
  (
    local_player="$1"
    if [ "x$local_player" = "x" ] ; then
      local_player="$player"
    fi

    ticket_data="$(printf "%s\n" "$local_player" | jsawk "return this.destination_tickets" | jsawk -n 'out(this.from_name + "|" + this.to_name + "|" + this.points + "|" + (this.completed ? "yes" : "no"))' | sort -k 2 -t '|')"
    ticket_data="$(printf "%s\n%s\n" "From|To|Points|Completed" "$ticket_data" | column -t -s'|')"

    print_table "$ticket_data"
  )
}

show_destination_tickets() {
  (
    table="$(print_destination_tickets | escape_for_dialog)"
    eval dialog "$DIALOG_OPTIONS" --msgbox "$(quote "$table")" 17 75
  )
}

show_routes() {
  (
    terminal_width="$(stty size | awk '{ print $2 }')"

    route_data="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.routes)' | jsawk -n 'out(this.from_name + "|" + this.to_name + "|" + this.colour_name + "|" + this.length + "|" + this.player_name)' | sort | sed 's/null/-/')"

    max_line_width="$(printf "%s\n" "$route_data" | awk '{ if (length($0) > max) max = length($0) } END { print max }')"
    double_width=$((max_line_width * 2))

    map_header="From|To|Colour|Length|Player"
    if [ "$terminal_width" -gt "$double_width" ] ; then
      line_count="$(printf "%s\n" "$route_data" | awk 'END { print NR }')"

      middle_line=$((line_count / 2))
      if [ $((line_count % 2)) -eq 1 ] ; then
        middle_line=$((middle_line + 1))
      fi

      printf "%s\n" "$route_data" | awk "NR <= $middle_line" > "$ROUTE_STATUS_LEFT"
      printf "%s\n" "$route_data" | awk "NR > $middle_line" > "$ROUTE_STATUS_RIGHT"

      map_header="$map_header|#|$map_header"
      route_data="$(paste -d"#\n" "$ROUTE_STATUS_LEFT" "$ROUTE_STATUS_RIGHT" | sed 's/#/|#|/')"
    fi

    route_data="$(printf "%s\n%s\n" "$map_header" "$route_data" | column -t -s'|' | sed 's/#/||/' | colourise)"

    {
      print_table "$route_data"
      printf "Routes are always shown West to East, i.e. Vancouver - Seattle and not the other way around\n\n"
    } | less -X -r
  )
}

show_map() {
  reset
  plot_map
}

plot_map() {
  size="$(stty size | awk '{ print $2", "$1}')"

  # first output all the route data with colour
  # shifting some bits where the routes overlap
  printf "%s\n" "$game_data" | jsawk -n 'out(this.routes)' | jsawk -n "out(this.from_latitude + ',' + this.from_longitude + ',' + this.to_latitude + ',' + this.to_longitude + ',' + this.from_name + ',' + this.to_name + ',' + this.length + ',' + this.colour_name + ',' + (this.player_id === null ? this.colour + 10 : this.player_colour + 20));" | sort | awk -F, '
BEGIN { multiplier = 0.2 }
$1$2$3$4 != key {
  if (key != "") shift_and_output_data(last, count)

  key=$1$2$3$4

  count = 1

  last[1,0] = $2
  last[1,1] = $1
  last[1,2] = $4
  last[1,3] = $3
  last[1,4] = $9

  next
}

{
  count = count + 1

  last[count,0] = $2
  last[count,1] = $1
  last[count,2] = $4
  last[count,3] = $3
  last[count,4] = $9
}

END { shift_and_output_data(last, count) }

function shift_and_output_data(array, array_size) {
  if (array_size == 1) {
    multipliers[1] = 0.0
  } else if (array_size == 2) {
    multipliers[1] = multiplier
    multipliers[2] = multiplier * -1
  }

  for (x = 1; x <= array_size; x++) {
    if (array_size > 1) {
      angle = abs(atan2(array[x,3], array[x,2]) * 180.0 / atan2(0, -1))
      angle_int = int(angle)

      if (angle_int == 90) {
        x_offset = multipliers[x]
        y_offset = 0
      } else if (angle_int == 0) {
        y_offset = multipliers[x]
        x_offset = 0
      } else {
        x_offset = (angle / 90) * multipliers[x]
        y_offset = ((90 - angle) / 90) * multipliers[x]
      }

      array[x,0] = array[x,0] + x_offset
      array[x,1] = array[x,1] + y_offset
      array[x,2] = array[x,2] + x_offset
      array[x,3] = array[x,3] + y_offset
    }

    printf("%s,%s,%s,%s,%s\n", array[x,0], array[x,1], array[x,2] - array[x,0], array[x,3] - array[x,1], array[x,4])
  }
}
function abs(v) {return v < 0 ? -v : v}
' > "$ROUTE_DATA"

  > "$BUILT_ROUTE_DATA"
  printf "%s\n" "$game_data" | jsawk -n 'out(this.routes)' | jsawk -n "if (this.player_name !== null) { out(this.from_latitude + ',' + this.from_longitude + ',' + this.to_latitude + ',' + this.to_longitude + ',' + this.player_name); }" | sort | awk -F, '$1$2$3$4 != key { if (key != "") print out ; key=$1$2$3$4 ; player=$5 ; out=sprintf("%s,%s,%s,%s,%s",$1, $2, $3, $4, player); next } { player=$5; out=sprintf("%s|%s", out, player) } END { print out }' > "$BUILT_ROUTE_DATA"

  > "$PLAYER_CITY_DATA"
  cat "$CITY_DATA" > "$NON_PLAYER_CITY_DATA"

  printf "%s\n" "$player" | jsawk -n "out(this.destination_tickets)" | jsawk -n 'out(this.from_name); out(this.to_name);' | sort -u | while read -r city ; do
    grep "$city" "$CITY_DATA" >> "$PLAYER_CITY_DATA"

    results="$(grep -v "$city" "$NON_PLAYER_CITY_DATA")"
    printf "%s\n" "$results" > "$NON_PLAYER_CITY_DATA"
  done

  STYLES="$(for colour in $(seq 0 8) ; do
    printf "set style line %s linecolor rgb \"%s\" linewidth 4 dt 2\n" "$((colour + 10))" "$(colour_name_for_id "$colour")"
    printf "set style line %s linecolor rgb \"%s\" linewidth 2\n" "$((colour + 20))" "$(colour_name_for_id "$colour")"

    printf "set style arrow %s nohead linestyle %s\n" "$((colour + 10))" "$((colour + 10))"
    printf "set style arrow %s nohead linestyle %s\n" "$((colour + 20))" "$((colour + 20))"
  done)"

  STATUS="$(for i in $(seq 1 "$player_count") ; do
    idx=$((i-1))

    local_user_id="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.user_id)')"

    local_points="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.points)')"
    local_name="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.name)')"
    local_trains="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.train_cars)')"
    local_colour="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.colour_name)')"
    local_player_colour_name="$(printf "%s" "$local_colour" | tr '[:lower:]' '[:upper:]')"
    local_colour_id="$(printf "%s\n" "$game_data" | jsawk "return this.players[$idx]" | jsawk -n 'out(this.colour)')"
    local_gnuplot_colour="$(colour_name_for_id "$local_colour_id")"

    printf "set label %s \"%s: %s / Train(s) %s / Points %s\"\n" "$((i + 1))" "$local_player_colour_name" "$local_name" "$local_trains" "$local_points"
    printf "set label %s at -84.35,%s tc rgb \"%s\"\n" "$((i + 1))" "$(awk "BEGIN { print 49.899444 - ($i * 0.5); exit }")" "$local_gnuplot_colour"
  done)";

  destination_tickets="$(print_destination_tickets "$player" | escape_for_dialog)"
  cards_label="$destination_tickets"
  label_coordinates="-122.416667, 31.75"

  if [ "$game_phase" -ne 4 ] ; then
    train_cards="$(print_train_cards "$player" | escape_for_dialog)"
    cards_label="$train_cards\\n$cards_label"
    label_coordinates="-122.416667, 34.45"
  fi

  cards_label="$(printf "%s\n" "$cards_label" | sed 's/|//g')"

  cat << EOF > "$GNUPLOT_TMP"
reset
set encoding utf8
set term caca driver ncurses $CACATERMCOLOUR truecolor enhanced inverted size $size charset blocks title "Ticket to Ride"

set autoscale

unset border
unset xtics
unset ytics
unset colorbox

set noclip points
set noclip one
set noclip two

set datafile separator ","

set label 1 "$cards_label" at $label_coordinates
$STATUS

$STYLES

plot '$ROUTE_DATA' using 1:2:3:4:5 with vectors arrowstyle variable notitle, \
     '$NON_PLAYER_CITY_DATA' using 2:1:3 with labels center offset 1,1 point pt 4 ps 0.5 notitle, \
     '$PLAYER_CITY_DATA' using 2:1:3 with labels center offset 1,1 point pt 4 ps 0.5 lc rgb "$player_colour" notitle, \
     '$BUILT_ROUTE_DATA' using (\$2 + (\$4-\$2) / 2):(\$1 + (\$3-\$1) / 2):5 with labels notitle
EOF

  gnuplot -c "$GNUPLOT_TMP"
}

print_train_cards() {
  (
    if [ "x$1" = "xdeck" ] ; then
      card_data="$(printf "%s\n" "$game_data" | jsawk "return this.train_cards")"
    elif [ "x$1" = "x" ] ; then
      card_data="$(printf "%s\n" "$player" | jsawk "return this.train_cards")"
    else
      card_data="$(printf "%s\n" "$1" | jsawk "return this.train_cards")"
    fi

    card_data="$(printf "%s\n" "$card_data" | jsawk -n 'out(this.colour_name + "|" + this.card_id)' | sort | awk -F'|' '{counts[$1] += 1; } END {for (i in counts) {print i"|"counts[i]}}' | sort | sed 's/| /|/')"
    card_data="$(printf "%s\n%s\n" "Colour|Count" "$card_data" | column -t -s'|')"

    print_table "$card_data"
  )
}

show_train_cards() {
  (
    table="$(print_train_cards "$1" | dialog_colourise | escape_for_dialog)"
    eval dialog "$DIALOG_OPTIONS" --msgbox "$(quote "$table")" 17 75
  )
}

draw_train_card() {
  (
    # shellcheck disable=SC2159
    while [ 0 ]; do
      card_data="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.train_cards)' | jsawk -n 'out(this.card_id + " " + this.colour_name)' | sort -k 2 | dialog_colourise | tr '\n' ' ')"

      eval dialog "$DIALOG_OPTIONS" --cancel-label "$(quote "Back")" --title "$(quote "Ticket ID - Colour")" --menu "$(quote "Select card to draw")" 17 75 7 "$(quote "x")" "$(quote "draw from deck")" "$card_data"  2> "$DIALOG_TMP" || break
      card_id=$(cat "$DIALOG_TMP")

      local_url="$URL/games/$game_id/players/$player_id/train_cards"
      if [ "x$card_id" = "x" ]; then
        continue
      elif [ "x$card_id" != "xx" ]; then
        local_url="$local_url/$card_id"
      fi
      response="$(curl -b "$COOKIESTORE" -c "$COOKIESTORE" -v -H "Content-Type: application/json" -H "Accept: application/json" -X PATCH "$local_url" 2>&1 | tr -d '\r')"

      if printf "%s\n" "$response" | grep "HTTP/1.1 204 No Content" > /dev/null 2>&1 ; then
        break
      fi

      show_error "$response"
    done
  )
}

draw_destination_tickets() {
  (
    response="$(curl -b "$COOKIESTORE" -c "$COOKIESTORE" -v -H "Content-Type: application/json" -H "Accept: application/json" -X PATCH "$URL/games/$game_id/players/$player_id/destination_tickets/assign" 2>&1 | tr -d '\r')"

    if ! printf "%s\n" "$response" | grep "HTTP/1.1 204 No Content" > /dev/null 2>&1 ; then
      show_error "$response"
    fi
  )
}

build_route() {
  (
    # shellcheck disable=SC2159
    while [ 0 ]; do
      route_data="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.routes)' | jsawk -n 'if (this.player_id !== null) return null ; out(this.route_id + " \"" + this.from_name + "|" + this.to_name + "|" + this.colour_name + "|" + this.length + "\"")' | sort -k 2 | tr '\n' ' ')"

      eval dialog "$DIALOG_OPTIONS" --title "$(quote "Route ID - From To Colour Length")" --column-separator "$(quote '|')" --menu "$(quote "Select route to build")" 17 75 7 "$route_data" 2> "$DIALOG_TMP" || return 1
      route_id=$(cat "$DIALOG_TMP")

      card_data="$(printf "%s\n" "$player" | jsawk "return this.train_cards" | jsawk -n 'out(this.card_id + " " + this.colour_name + " off")' | sort -k 2 | tr '\n' ' ')"

      eval dialog "$DIALOG_OPTIONS" --separate-output  --title "$(quote "Ticket ID - Colour")" --checklist "$(quote "Please choose cards to use to build or leave empty to automatically choose cards from your hand.")" 17 75 7 "$card_data" 2> "$DIALOG_TMP" || return 1
      card_id="$(tr '\n' ',' < "$DIALOG_TMP" | sed 's/,$//')"

      route_url="$URL/games/$game_id/players/$player_id/routes"
      if [ "x$card_ids" = "x" ] ; then
        response="$(curl -b "$COOKIESTORE" -c "$COOKIESTORE" -v -H "Content-Type: application/json" -H "Accept: application/json" -X POST "$route_url" -d '{"train_card_ids": [], "route_id": '"$route_id"' }' 2>&1 | tr -d '\r')"
      else
        # shellcheck disable=SC2031
        card_ids="$(printf "%s\n" "$card_ids" | sed 's/[[:space:]]\{1,\}/,/')"
        response="$(curl -b "$COOKIESTORE" -c "$COOKIESTORE" -v -H "Content-Type: application/json" -H "Accept: application/json" -X POST "$route_url" -d '{"train_card_ids": ['"$card_ids"'], "route_id": '"$route_id"' }' 2>&1 | tr -d '\r')"
      fi

      if printf "%s\n" "$response" | grep "HTTP/1.1 204 No Content" > /dev/null 2>&1 ; then
        break
      fi

      show_error "$response"
    done
  )
}

discard_destination_tickets() {
  (
    # shellcheck disable=SC2159
    while [ 0 ]; do
      ticket_data="$(printf "%s\n" "$player" | jsawk "return this.destination_tickets" | jsawk -n 'if (this.status !== 0) return null; out(this.ticket_id + " \"" + this.from_name + "|" + this.to_name + "|" + this.points + "|" + this.status_name + "\" off")' | tr '\n' ' ')"

      set +e
      eval dialog "$DIALOG_OPTIONS" --no-cancel --help-button --help-label "$(quote "Show Map")" --separate-output --column-separator "$(quote '|')" --title "$(quote "Game ID - From To Points Status")" --checklist "$(quote "Please choose cards to discard")" 17 75 7 "$ticket_data" 2> "$DIALOG_TMP"
      res=$?
      set -e

      if [ "$res" -ne 0 ] && [ "$res" -ne 2 ] ; then
        exit 1 # error
      fi

      destination_ids="$(tr '\n' ',' < "$DIALOG_TMP" | sed 's/,$//')"

      if [ "$res" -eq 2 ] ; then
        destination_ids="routes"
      fi

      if [ "x$destination_ids" = "x" ] ; then
        response="$(curl -b "$COOKIESTORE" -c "$COOKIESTORE" -v -H "Content-Type: application/json" -H "Accept: application/json" -X DELETE "$URL/games/$game_id/players/$player_id/destination_tickets" -d '{"destination_ids": []}' 2>&1 | tr -d '\r')"
      elif [ "x$destination_ids" = "xroutes" ] ; then
        show_map
        continue
      else
        destination_ids="$(printf "%s\n" "$destination_ids" | sed 's/[[:space:]]\{1,\}/,/')"
        response="$(curl -b "$COOKIESTORE" -c "$COOKIESTORE" -v -H "Content-Type: application/json" -H "Accept: application/json" -X DELETE "$URL/games/$game_id/players/$player_id/destination_tickets" -d '{"destination_ids": ['"$destination_ids"']}' 2>&1 | tr -d '\r')"
      fi

      if printf "%s\n" "$response" | grep "HTTP/1.1 204 No Content" > /dev/null 2>&1 ; then
        break
      fi

      show_error "$response"
    done
  )
}

check_user() {
  # shellcheck disable=SC2159
  while [ 0 ] ; do
    eval dialog "$DIALOG_OPTIONS" --cancel-label "$(quote "Back")" --title "$(quote "Login")" --mixedform "$(quote "Enter your login credentials")" 17 75 9 \
      "$(quote "Email")" 1 1 \"\" 1 25 40 512 0 \
      "$(quote "Password")" 2 1 \"\" 2 25 25 512 1 2> "$DIALOG_TMP" || return 1

    email=$(sed '1!d' < "$DIALOG_TMP")
    password=$(sed '2!d' < "$DIALOG_TMP")
    > "$DIALOG_TMP"

    if login ; then
      break
    fi
  done

  return 0
}

logout() {
  curl -s -f -X DELETE -b "$COOKIESTORE" -c "$COOKIESTORE" -H "Accept: application/json" -H "Content-Type: application/json" "$URL/users/sign_out" > /dev/null 2>&1
  userid=""
  useremail=""
  username=""
  > "$COOKIESTORE"
}

login() {
  > "$COOKIESTORE"

  response="$(curl -b "$COOKIESTORE" -c "$COOKIESTORE" -v -H "Accept: application/json" "$URL/users/sign_in" --data "user[email]=$email" --data "user[password]=$password" 2>&1 | tr -d '\r')"

  if printf "%s\n" "$response" | grep "HTTP/1.1 201 Created" > /dev/null 2>&1 ; then
    userid="$(printf "%s\n" "$response" | tail -n 1 | jsawk -n 'out(this.id)')"
    useremail="$(printf "%s\n" "$response" | tail -n 1 | jsawk -n 'out(this.email)')"
    username="$(printf "%s\n" "$response" | tail -n 1 | jsawk -n 'out(this.name)')"
    return 0
  fi

  show_error "$response"
  return 1
}

register_user() {
  # shellcheck disable=SC2159
  while [ 0 ] ; do
    > "$COOKIESTORE"

    eval dialog "$DIALOG_OPTIONS" --cancel-label "$(quote "Back")" --title "$(quote "Register")" --mixedform "$(quote "Enter you registration details\\nPasswords do not echo")" 17 75 9 \
      "$(quote "Email")" 1 1 \"\" 1 25 40 512 0 \
      "$(quote "Name")" 2 1 \"\" 2 25 40 512 0 \
      "$(quote "Password")" 3 1 \"\" 3 25 25 512 1 \
      "$(quote "Password confirmation")" 4 1 \"\" 4 25 25 512 1 2> "$DIALOG_TMP" || return 1

    email=$(sed '1!d' < "$DIALOG_TMP")
    name=$(sed '2!d' < "$DIALOG_TMP")
    password=$(sed '3!d' < "$DIALOG_TMP")
    password_confirmation=$(sed '4!d' < "$DIALOG_TMP")
    > "$DIALOG_TMP"

    response="$(curl -v -H "Accept: application/json" "$URL/users" --data "user[email]=$email" --data "user[name]=$name" --data "user[password]=$password" --data "user[password_confirmation]=$password_confirmation" 2>&1 | tr -d '\r')"

    if printf "%s\n" "$response" | grep "HTTP/1.1 201 Created" > /dev/null 2>&1 ; then
      login
      break
    fi

    show_error "$response"
  done
}

create_game() {
  # shellcheck disable=SC2159
  while [ 0 ] ; do
    response="$(printf "%s" "{ \"game\": {} }" | curl -v -b "$COOKIESTORE" -c "$COOKIESTORE" -H "Accept: application/json" -H "Content-Type: application/json" "$URL/games" -d "@-" 2>&1 | tr -d '\r')"

    if printf "%s\n" "$response" | grep "HTTP/1.1 201 Created" > /dev/null 2>&1 ; then
      game_id="$(printf "%s\n" "$response" | grep ocation | sed 's/^.*games\/\(.\{1,\}\)/\1/')"
      break
    fi

    show_error "$response"
  done
}

join_game() {
  # shellcheck disable=SC2159
  while [ 0 ] ; do
    eval dialog "$DIALOG_OPTIONS" --no-items --menu "$(quote "Please choose a colour")" 17 75 7 \
        "$(quote "blue")" \
        "$(quote "red")" \
        "$(quote "green")" \
        "$(quote "yellow")" \
        "$(quote "black")" 2> "$DIALOG_TMP" || return 1

    player_colour_name="$(cat "$DIALOG_TMP")"
    player_colour="$(colour_id_for_name "$player_colour_name")"

    if [ "x$player_colour" = "x" ] ; then
      continue
    fi

    player_data="{\"colour\": $player_colour, \"user_id\": $userid }"
    response="$(printf "%s" "{ \"player\": $player_data }" | curl -v -b "$COOKIESTORE" -c "$COOKIESTORE" -H "Accept: application/json" -H "Content-Type: application/json" "$URL/games/$game_id/players" -d "@-" 2>&1 | tr -d '\r')"

    if printf "%s\n" "$response" | grep "HTTP/1.1 204 No Content" > /dev/null 2>&1 ; then
      break
    fi

    show_error "$response"
  done
}

resume_game() {
  # shellcheck disable=SC2159
  while [ 0 ] ; do
    eval dialog "$DIALOG_OPTIONS" --cancel-label "$(quote "Back")" --title "$(quote "Please enter the game id, or leave empty for a list of games to join")" --inputbox "$(quote "Game ID: ")" 17 75 2> "$DIALOG_TMP" || break
    game_id=$(cat "$DIALOG_TMP")

    if [ "x$game_id" = "xlist" ] || [ "x$game_id" = "x" ] ; then
      max_status="3"
      min_status="0"

      if [ "x$1" = "xtrue" ] ; then
        min_status="4"
        max_status="4"
      fi

      pending_games="$(for i in $(seq "$min_status" "$max_status") ; do
        response="$(curl -s -f -b "$COOKIESTORE" -c "$COOKIESTORE" -H "Accept: application/json" -H "Content-Type: application/json" "$URL/games?phase=$i" 2> /dev/null || printf "")"

        if [ "x$response" = "x" ] ; then
          break
        fi
        printf "%s\n" "$response" | jsawk -n 'out(this.id + " \"" + this.players.length + " players / phase " + this.phase_name + "\"")'
      done | sort -n | tr '\n' ' ')"

      if [ "x$pending_games" = "x" ] ; then
        continue
      fi

      pending_games="$(printf "%s\n" "$pending_games")"

      eval dialog "$DIALOG_OPTIONS" --cancel-label "$(quote "Back")" --title "$(quote "Game ID - Players Phase")" --menu "$(quote "Please choose a game")" 17 75 7 "$pending_games" 2> "$DIALOG_TMP" || continue
      game_id=$(cat "$DIALOG_TMP")
    fi

    response="$(curl -b "$COOKIESTORE" -c "$COOKIESTORE" -v -H "Accept: application/json" "$URL/games/$game_id" 2>&1 | tr -d '\r')"

    if printf "%s\n" "$response" | grep "HTTP/1.1 200 OK" > /dev/null 2>&1 ; then
      break
    fi

    show_error "$response"
  done

  if [ "x$game_id" = "x" ] ; then
    return 1
  fi
}

refresh_turn_status() {
  refresh_game

  turn_user_id="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.turn_user_id)')"
  turn_status="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.turn_status)')"
}

refresh_game() {
  game_data="$(curl -b "$COOKIESTORE" -c "$COOKIESTORE" -s -f -H "Accept-Encoding: gzip" -H "Accept: application/json" "$URL/games/$game_id" | gunzip -)"
  game_phase="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.phase)')"
  game_phase_name="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.phase_name)')"
  player="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.players)' | jsawk -n "if (this.user_id !== $userid) return null; out(this)")"

  if [ "x$player" != "x" ] ; then
    player_count="$(printf "%s\n" "$game_data" | jsawk -n 'out(this.players.length)' | tr -d '\n')"
    player_id="$(printf "%s\n" "$player" | jsawk -n 'out(this.player_id)')"
    player_name="$(printf "%s\n" "$player" | jsawk -n 'out(this.name)')"
    player_points="$(printf "%s\n" "$player" | jsawk -n 'out(this.points)')"
    player_colour="$(printf "%s\n" "$player" | jsawk -n 'out(this.colour_name)')"
    player_colour_name="$(printf "%s\n" "$player" | jsawk -n 'out(this.colour_name)' | tr '[:lower:]' '[:upper:]')"
    player_dialog_colour="$(dialog_colour_for_name "$player_colour")"
    player_trains="$(printf "%s\n" "$player" | jsawk -n 'out(this.train_cars)')"
  fi
}

wait_for_other_player() {
  # shellcheck disable=SC2159
  while [ 0 ] ; do
    refresh_turn_status

    if [ "x$turn_user_id" = "x$userid" ] ; then
      break
    fi

    sleep 5
  done | eval dialog "$DIALOG_OPTIONS" --title "$(quote "Waiting for player(s) to finish")" --progressbox "$(quote "$(status_string)")" 17 75
}

show_players() {
  eval dialog "$DIALOG_OPTIONS" --title "$(quote "Player status")" --msgbox "$(quote "$(status_string)")" 17 75
}

login_or_register() {
  # shellcheck disable=SC2159
  while [ 0 ] ; do
    eval dialog "$DIALOG_OPTIONS" --cancel-label "$(quote "Exit")" --menu "$(quote "Please choose an option")" 17 75 7 \
      "1" "Login" \
      "2" "Register" 2> "$DIALOG_TMP"

    action="$(cat "$DIALOG_TMP")"

    if [ "x$action" = "x1" ] ; then
      if check_user ; then
        break
      fi
    elif [ "x$action" = "x2" ] ; then
      if register_user ; then
        break
      fi
    fi
  done
}

edit_profile() {
  (
    # shellcheck disable=SC2159
    while [ 0 ] ; do
      eval dialog "$DIALOG_OPTIONS" --cancel-label "$(quote "Back")" --title "$(quote "Edit Profile")" --mixedform "$(quote "Enter new values\\nLeave password blank if you do not want to change it\\nYour current password is required to confirm your changes\\nPasswords do not echo")" 17 75 9 \
        "$(quote "Email")" 1 1 "$(quote "$useremail")" 1 25 25 512 0 \
        "$(quote "Name")" 2 1 "$(quote "$username")" 2 25 25 512 0 \
        "$(quote "Password")" 3 1 \"\" 3 25 25 512 1 \
        "$(quote "Password confirmation")" 4 1 \"\" 4 25 25 512 1 \
        "$(quote "Current password")" 5 1 \"\" 5 25 25 512 1 2> "$DIALOG_TMP" || return 1

      new_email=$(sed '1!d' < "$DIALOG_TMP")
      new_name=$(sed '2!d' < "$DIALOG_TMP")
      new_password=$(sed '3!d' < "$DIALOG_TMP")
      new_password_confirmation=$(sed '4!d' < "$DIALOG_TMP")
      current_password=$(sed '5!d' < "$DIALOG_TMP")
      > "$DIALOG_TMP"

      data="{ \"user\": { $(
        {
          [ "x$new_email" != "x" ] && printf '"%s":"%s"\n' "email" "$new_email"
          [ "x$new_name" != "x" ] && printf '"%s":"%s"\n' "name" "$new_name"
          [ "x$new_password" != "x" ] && printf '"%s":"%s"\n' "password" "$new_password"
          [ "x$new_password_confirmation" != "x" ] && printf '"%s":"%s"\n' "password_confirmation" "$new_password_confirmation"
          printf '"%s":"%s"\n' "current_password" "$current_password"
        } | paste -s -d,
      )}}"

      response="$(printf "%s\n" "$data" | curl -b "$COOKIESTORE" -c "$COOKIESTORE" -X PATCH -v -H "Content-Type: application/json" -H "Accept: application/json" "$URL/users" -d "@-" 2>&1 | tr -d '\r')"

      if printf "%s\n" "$response" | grep "HTTP/1.1 204 No Content" > /dev/null 2>&1 ; then
        login
        break
      fi
    done
  )
}

show_error() {
  eval dialog "$DIALOG_OPTIONS" --msgbox "$(quote "$(printf "%s\n" "$DLRED$1$DLRESET" | tail -n 1)")" 17 75 || exit 1
}

# shellcheck disable=SC2159
while [ 0 ]; do
  if [ "x$1" = "x-h" ] || [ "x$1" = "x-help" ] || [ "x$1" = "x--help" ]; then
    usage | less -F -X
    exit 0

  elif [ "x$1" = "x--url" ]; then
    shift

    if [ "x$1" = "x" ]; then
      >&2 printf "%s\n" "--url requires an argument."
      exit 1
    fi

    URL="$1"

    shift
  elif [ "x$1" = "x--verbose" ]; then
    shift

    VERBOSE="yes"
  elif [ "x$1" = "x--no-colours" ] ; then
    shift

    COLOURS=no

  elif [ "x$1" = "x" ]; then
    break
  else
    >&2 printf "Unknown token %s.\n" "$1"
    exit 1
  fi
done

for dependency in jsawk gnuplot curl dialog ; do
  if ! command -v "$dependency" > /dev/null 2>&1 ; then
    >&2 printf "%s is required.\n" "$dependency"
    exit 2
  fi
done

if ! printf "set term caca\n" | gnuplot > /dev/null 2>&1 ; then
  >&2 printf "gnuplot was not compiled with libcaca support. This is required for rendering in the console\n"
  exit 2
fi

if $macosx ; then
  COOKIESTORE="$(mktemp -t tmp.XXXXXXXXXX)"
  CITY_DATA="$(mktemp -t tmp.XXXXXXXXXX)"
  ROUTE_STATUS_LEFT="$(mktemp -t tmp.XXXXXXXXXX)"
  ROUTE_STATUS_RIGHT="$(mktemp -t tmp.XXXXXXXXXX)"
  ROUTE_DATA="$(mktemp -t tmp.XXXXXXXXXX)"
  BUILT_ROUTE_DATA="$(mktemp -t tmp.XXXXXXXXXX)"
  PLAYER_CITY_DATA="$(mktemp -t tmp.XXXXXXXXXX)"
  NON_PLAYER_CITY_DATA="$(mktemp -t tmp.XXXXXXXXXX)"
  DIALOG_TMP="$(mktemp -t tmp.XXXXXXXXXX)"
  GNUPLOT_TMP="$(mktemp -t tmp.XXXXXXXXXX)"
else
  COOKIESTORE="$(mktemp)"
  CITY_DATA="$(mktemp)"
  ROUTE_STATUS_LEFT="$(mktemp)"
  ROUTE_STATUS_RIGHT="$(mktemp)"
  ROUTE_DATA="$(mktemp)"
  BUILT_ROUTE_DATA="$(mktemp)"
  PLAYER_CITY_DATA="$(mktemp)"
  NON_PLAYER_CITY_DATA="$(mktemp)"
  DIALOG_TMP="$(mktemp)"
  GNUPLOT_TMP="$(mktemp)"
fi

cleanup() { rm -f "$COOKIESTORE" "$CITY_DATA" "$ROUTE_STATUS_LEFT" "$ROUTE_STATUS_RIGHT" "$ROUTE_DATA" "$BUILT_ROUTE_DATA" "$PLAYER_CITY_DATA" "$NON_PLAYER_CITY_DATA" "$DIALOG_TMP" "$GNUPLOT_TMP" ; }

trap "cleanup" INT TERM HUP QUIT EXIT

VERBOSE=${VERBOSE:-no}
COLOURS=${COLOURS:-yes}

# shellcheck disable=SC2016
DIALOG_OPTIONS='--cr-wrap --backtitle "$(backtitle)" --no-shadow --ascii-lines'

if [ "x$COLOURS" = "xyes" ] || [ "x$COLOURS" = "xtrue" ] || [ "x$COLOURS" = "x1" ] ; then
  CLRED=$(printf '\033[31m')
  CLGREEN=$(printf '\033[32m')
  CLYELLOW=$(printf '\033[33m')
  CLBLUE=$(printf '\033[34m')
  CLMAGENTA=$(printf '\033[35m')
  CLRESET=$(printf '\033[0m')
  CLBLACK=$(printf '\033[7m')
  CLWHITE=$(printf '\033[4m')
  CLLOC=$(printf '\033[5m')
  CLORANGE="$(printf '\033[95;38;5;214m')"

  DLRED="\Z1"
  DLGREEN="\Z2"
  DLYELLOW="\Z3"
  DLBLUE="\Z4"
  DLPURPLE="\Z5"
  DLBOLD="\Zb"
  DLBOLDRESET="\ZB"
  DLRESET="\Zn"
  DLBLACK="\Z7"
  DLLOC="\Zb\Z7"
  DLWHITE="\Z0"

  CACATERMCOLOUR="colour"

  DIALOG_OPTIONS="$DIALOG_OPTIONS --colors"
else
  CLRED=""
  CLGREEN=""
  CLBLUE=""
  CLMAGENTA=""
  CLRESET=""
  CLBLACK=""
  CLWHITE=""
  CLLOC=""
  CLORANGE=""

  DLRED=""
  DLGREEN=""
  DLYELLOW=""
  DLBLUE=""
  DLPURPLE=""
  DLBOLD=""
  DLBOLDRESET=""
  DLRESET=""
  DLBLACK=""
  DLWHITE=""

  CACATERMCOLOUR="monochrome"
fi

URL=${URL:-http://localhost:3000}


if [ "x$VERBOSE" = "xyes" ] || [ "x$VERBOSE" = "xtrue" ] || [ "x$VERBOSE" = "x1" ] ; then
  if command -v ddate > /dev/null 2>&1 ; then
    today="$(ddate)"
  else
    today="$(date)"
  fi

  eval dialog "$DIALOG_OPTIONS" --msgbox "$(quote "Welcome to Zug um Zug\n\nDate: $DLBLUE$today$DLRESET\nTarget server: $DLPURPLE$URL$DLRESET\n\nPress OK to begin.")" 17 75
else
  eval dialog "$DIALOG_OPTIONS" --msgbox "$(quote "Welcome to Zug um Zug\nPress OK to begin.")" 17 75
fi

curl -s -f -H 'Accept: application/json' "$URL/cities" | jsawk -n "out(this.latitude + ', ' + this.longitude + ', ' + this.name)" > "$CITY_DATA"

# shellcheck disable=SC2159
while [ 0 ] ; do
  if [ "x$email" = "x" ] ; then
    login_or_register
  fi

  # shellcheck disable=SC2159
  while [ 0 ] ; do
    if ! eval dialog "$DIALOG_OPTIONS" --cancel-label "$(quote "Back")" --menu "$(quote "Please choose an option")" 17 75 7 \
      "$(quote "1")" "$(quote "Create a new game")" \
      "$(quote "2")" "$(quote "Join a game")" \
      "$(quote "3")" "$(quote "View completed games")" \
      "$(quote "4")" "$(quote "Edit profile")" 2> "$DIALOG_TMP" ; then

      logout

      login_or_register
    fi

    action="$(cat "$DIALOG_TMP")"

    if [ "x$action" = "x1" ] ; then
      if create_game ; then
        break
      fi
    elif [ "x$action" = "x2" ] ; then
      if resume_game ; then
        break
      fi
    elif [ "x$action" = "x3" ] ; then
      if resume_game "true" ; then
        break
      fi
    elif [ "x$action" = "x4" ] ; then
      if edit_profile ; then
        continue
      fi
    fi
  done

  refresh_game

  while [ "$game_phase" -eq 0 ] ; do
    if [ "x$player" = "x" ] ; then
      if ! join_game ; then
        break
      fi
    else
      set +e
      eval dialog "$DIALOG_OPTIONS" --default-button cancel --cancel-label "$(quote "Start")" --ok-label "$(quote "Refresh")" --extra-button --extra-label "$(quote "Back")" --pause "$(quote "Other players can now join game $DLBOLD$game_id$DLBOLDRESET. Press enter when you are ready to start the game.")" 17 75 5
      res=$?
      set -e

      refresh_game

      if [ "$res" -eq 1 ] && [ "$game_phase" -eq 0 ] ; then
        response="$(curl -v -X PATCH -b "$COOKIESTORE" -c "$COOKIESTORE" -H "Accept: application/json" "$URL/games/$game_id" 2>&1 | tr -d '\r')"

        if ! printf "%s\n" "$response" | grep "HTTP/1.1 204 No Content" > /dev/null 2>&1 ; then
          show_error "$response"
        fi
      elif [ "$res" -eq 3 ] ; then
        break
      elif [ "$res" -eq 0 ] ; then
        continue
      else
        exit "$res"
      fi
    fi

    refresh_game
  done

  refresh_turn_status

  while [ "$game_phase" -eq 1 ] ; do
    if [ "x$turn_user_id" = "x$userid" ] ; then
      discard_destination_tickets
    else
      wait_for_other_player
    fi

    refresh_turn_status
  done

  while [ "$game_phase" -gt 1 ] && [ "$game_phase" -ne 4 ] ; do
    if [ "x$turn_user_id" = "x$userid" ] ; then
      turn_options="1 \"Draw train card\" 2 \"Draw destination tickets\" 3 \"Build route\" 4 \"View train cards\" 5 \"View destination tickets\" 6 \"View deck train cards\" 7 \"View map\" 8 \"View route status\" 9 \"View other players\""

      if [ "x$turn_status" = "x0" ] || [ "x$turn_status" = "x2" ]; then
        height=9
        if [ "x$turn_status" = "x2" ]; then
          turn_options="$(printf "%s\n" "$turn_options" | sed -e 's/ 2 "Draw destination tickets" 3 "Build route"//')"
          height=$((height - 2))
        fi

        eval dialog "$DIALOG_OPTIONS" --cancel-label "$(quote "Back")" --menu "$(quote "Please choose an option")" 17 75 "$height" "$turn_options" 2> "$DIALOG_TMP" || break

        action="$(cat "$DIALOG_TMP")"

        if [ "x$action" = "x1" ] ; then
          draw_train_card || continue
        elif [ "x$action" = "x2" ] ; then
          draw_destination_tickets || continue
        elif [ "x$action" = "x3" ] ; then
          build_route || continue
        elif [ "x$action" = "x4" ] ; then
          show_train_cards || continue
        elif [ "x$action" = "x5" ] ; then
          show_destination_tickets || continue
        elif [ "x$action" = "x6" ] ; then
          show_train_cards "deck" || continue
        elif [ "x$action" = "x7" ] ; then
          show_map || continue
        elif [ "x$action" = "x8" ] ; then
          show_routes || continue
        elif [ "x$action" = "x9" ] ; then
          show_players || continue
        fi
      elif [ "x$turn_status" = "x1" ] ; then
        discard_destination_tickets
      fi
    else
      wait_for_other_player
    fi

    refresh_turn_status
  done

  while [ "$game_phase" -eq 4 ] ; do
    set +e
    eval dialog "$DIALOG_OPTIONS" --extra-button --extra-label "$(quote "Show Map")" --no-cancel --title "$(quote "Game finished")" --msgbox "$(quote "$(status_string)")" 50 75
    res=$?
    set -e

    if [ "$res" -eq 3 ] ; then
      show_map || exit 0
      show_routes || exit 0
      continue
    fi

    break
  done
done

exit 0
