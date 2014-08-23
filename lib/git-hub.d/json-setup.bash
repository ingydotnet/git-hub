set -e

source json.bash

get-var json-lib
if [ -n "$json_lib" ]; then
  source "$json_lib"
fi


#------------------------------------------------------------------------------
# JSON support functions:
#------------------------------------------------------------------------------
# Format a JSON object from an input list of key/value pairs.
json-dump-object() {
  local json='{' key= value=
  while [ $# -gt 0 ]; do
    if [[ "$2" =~ (^[\[\{]|^(null|true|false)$|^[0-9]+$) ]]; then
      json="$json\"$1\":$2"
    else
      json-escape "$2" value
      json="$json\"$1\":\"$value\""
    fi
    shift; shift || true
    if [ $# -gt 0 ]; then
      json="$json,"
    fi
  done
  json="$json}"
  echo "$json"
}

json-escape() {
  local escaped= back='\'
  escaped="${1//\\/$back$back}"
  escaped="${escaped//\"/$back\"}"
  escaped="${escaped//$'\t'/${back}t}"
  escaped="${escaped//$'\n'/${back}n}"
  printf -v "$2" "%s" "$escaped"
}

json-dump-array() {
  local json='['
  while [ $# -gt 0 ]; do
    json="$json\"$1\""
    shift
    if [ $# -gt 0 ]; then
      json="$json,"
    fi
  done
  json="$json]"
  echo "$json"
}

# Format a JSON object from an array.
json-dump-object-pairs() {
  local regex='(^\[|^null$|^[0-9]+$)'
  local json='{'
  for ((i = 0; i < ${#pairs[@]}; i = i+2)); do
    local value="${pairs[$((i+1))]}"
    value="${value//\"/\\\"}"
    if [[ "$value" =~ $regex ]]; then
      json="$json\"${pairs[$i]}\":$value"
    else
      json="$json\"${pairs[$i]}\":\"$value\""
    fi
    if [ $((${#pairs[@]} - $i)) -gt 2 ]; then
      json="$json,"
    fi
  done
  json="$json}"
  echo "$json"
}

pretty-json-list() {
  local num="$(JSON.cache | tail -n1 | cut -d '/' -f2)"
  declare -a keys=("$@")

  echo '['
  for (( i = 0; i <= $num; i++)); do
    echo '  {'
    for (( j = 0; j < ${#keys[@]}; j++)); do
      local key="${keys[$j]}"
      local key="${key//__/\/}"
      local value="$(JSON.get "/$i/$key" - || true)"
      if [ -n "$value" ]; then
        printf "    \"%s\": %s" "$key" "$value"
        [[ $(($j+1)) -lt ${#keys[@]} ]] && printf ','
        printf "\n"
      fi
    done
    printf '  }'
    if [ $i -lt $num ]; then
      echo ,
    else
      echo
    fi
  done
  echo ']'
}

pretty-json-object() {
  declare -a keys=("$@")

  echo '{'
  for (( i = 0; i < ${#keys[@]}; i++)); do
    local key="${keys[$i]}"
    local key="${key//__/\/}"
    local value="$(JSON.get "/$key" - || true)"
    if [ -n "$value" ]; then
      printf "    \"%s\": %s" "$key" "$value"
      [[ $(($i+1)) -lt ${#keys[@]} ]] && printf ','
      printf "\n"
    fi
  done
  echo '}'
}

json-var-list() {
  local fields="$@"
  while IFS='\n' read -r line; do
    [[ -z "$line" ]] && break
    if [[ "$line" =~ ^$key_prefix/([0-9]+)/([^\	]+)\	(.*) ]]; then
      local value="${BASH_REMATCH[3]}"
      # XXX This should use `JSON.get -a`
      [ "$value" == null ] && value=''
      value="${value#\"}"
      value="${value%\"}"
      value="${value//\\n/$'\n'}"
      value="${value//\\t/$'\t'}"
      value="${value//\\\"/\"}"
      value="${value//\\\\/$back}"
      key="${BASH_REMATCH[2]}_${BASH_REMATCH[1]}"
      key="${key//\//__}"
      printf -v "$key" "%s" "$value"
    else
      die "Unexpected line '$line'"
    fi
  done < <(
    echo "$JSON__cache" |
      grep -E "^$key_prefix/[0-9]+/(${fields// /|})\b" || echo ''
  )
}

json-prune-cache() {
  JSON__cache="$(echo "$JSON__cache" | grep -E "$1" || echo '')"
}

json-prune-hash() {
  local fields="$@"
  fields="${fields//__/\/}"
  json-prune-cache "^/(${fields// /|})\b"
}

# vim: set lisp:
