#!/usr/bin/env bash
WORKSPACE=${1:-"/tmp"}
MANIFEST_DIR="wp-manifests"

# Declare an associative array to contain the information for a single site (AKA, a "section") in the .ini file.
declare -A section=()

urlencode() { (xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g') < /dev/stdin; }
# Get the topmost directory in a path, ie: "usr" in "/usr/local/bin"
topname() { (rev | (basename "$(</dev/stdin)") | rev) < /dev/stdin; }
# "Pop" the topmost directory in a path off, ie: returns "local/bin" for "/usr/local/bin"
poptop() { (rev | (dirname "$(</dev/stdin)") | rev) < /dev/stdin; }
trim() {
  local input="${1:-$(</dev/stdin)}"
  echo -n "$(echo -n "$input" | sed -E 's/^[ \t\n]*//' | sed -E 's/[ \t\n]*$//')"
}

# Example MANIFEST_INI_FILE: wp-manifests/devl/jaydub-bulb.ini
if [ "$(echo $MANIFEST_INI_FILE | topname)" == $MANIFEST_DIR ] ; then
  inifile="${WORKSPACE}/${MANIFEST_INI_FILE}"
else
  inifile="${WORKSPACE}/${MANIFEST_DIR}/${MANIFEST_INI_FILE}"
fi

# Pull a wordpress site from github and extract its content to the wp-content directory
pullContentRepo() {
  local repo_dir="${WORKSPACE}/$1"
  local token="$(cat "$GIT_TOKEN_FILE" | urlencode)"
  local repo="$(echo ${section['source']} | cut -d'@' -f2 | cut -d'@' -f2 | sed 's|:|/|')"
  local target_dir="/usr/src/wordpress/${section['dest']}"
  echo "Pulling ${repo}..."
  rm -rf $repo_dir 2> /dev/null || true
  mkdir $repo_dir
  [ ! -d $target_dir ] && mkdir -p $target_dir
  (
    cd $repo_dir
    git init
    git remote add origin https://${GIT_USER}:${token}@${repo}
    git fetch --depth 1 origin ${section['rev']}
    git archive --format=tar FETCH_HEAD | (cd $target_dir && tar xf -)
  )
}

# Pull the manifest repo from github.
pullManifestRepo() {
  local repo_dir="${WORKSPACE}/${MANIFEST_DIR}"
  local token="$(cat "$GIT_TOKEN_FILE" | urlencode)"
  echo "Pulling github.com/bu-ist/wp-manifests.git..."
  rm -rf $repo_dir 2> /dev/null || true
  mkdir $repo_dir
  (
    cd $repo_dir
    git init
    git remote add origin https://${GIT_USER}:${token}@github.com/bu-ist/wp-manifests.git
    git pull --depth 1 origin master
  )
}

# Load a single section, identified by section name, from the specified .ini file.
# What gets loaded is about 6 lines from the ini file that contain all information needed to pull the specific
# content from a github repo bound for the wp-content directory for the site identified by the section name.
loadSection() {
  local section_name="$1"
  local first_line='true'

  echo "Loading $section_name data from ${inifile}..."

  while read line ; do
    if [ $first_line == 'true' ] ; then
      section["name"]="$(echo $line | grep -oP '[^\[\]]+' | trim)"
      first_line='false'
    else
      local fld="$(echo $line | cut -d'=' -f1 | trim)"
      local val="$(echo $line | cut -d'=' -f2 | trim)"
      section["$fld"]="$val"
    fi    
    first_line='false'
  done <<< $(cat $inifile | grep -A 6 -iP '^\s*\[\s*'${section_name}'\s*\]\s*$')
}

# Just for testing.
printSection() {
  for fld in ${!section[@]} ; do
    echo "$fld = ${section[$fld]}"
  done
}

# Pull a single "site" from github and extract its content to the wp-content directory.
processSingleSite() {
  local site="$1"
  
  # Only git repos are supported for now.
  [ "${section['scm']}" != 'git' ] && echo "Not a git repo: ${section['name']}" && return 0
    
  pullContentRepo "${section['name']}"
}

# For each site in SITES, pull from the corresponding git repo and extract its content to the wp-content directory.
processIniFile() {
  # SITES is a comma-delimited single line string. Iterate over each delimited value (site).
  for site in $(echo "$SITES" | awk 'BEGIN{RS = ","}{print $1}') ; do

    echo "Processing ${site}..."

    loadSection $site

    processSingleSite  $site
  done
}


build() {

  pullManifestRepo

  processIniFile
}

env

build