#!/bin/bash

WORKSPACE=${1:-"/tmp"}
MANIFEST_DIRNAME="wp-manifests"
REPO_TARGET_DIR="${WORKSPACE}/repos"

# Declare an associative array to contain the information for a single site (AKA, a "section") in the .ini file.
declare -A section=()

# Url encode a string to account for invalid characters.
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
if [ "$(echo $MANIFEST_INI_FILE | topname)" == $MANIFEST_DIRNAME ] ; then
  inifile="${WORKSPACE}/${MANIFEST_INI_FILE}"
else
  inifile="${WORKSPACE}/${MANIFEST_DIRNAME}/${MANIFEST_INI_FILE}"
fi

# Pull a wordpress repo from github and extract its content to the wp-content directory
pullContentRepo() {
  local repo_dir="${WORKSPACE}/$1"
  local target_dir="${REPO_TARGET_DIR}/${section['dest']}"
  local token="$(cat "$GIT_TOKEN_FILE" | urlencode)"
  local repo="$(echo ${section['source']} | cut -d'@' -f2 | cut -d'@' -f2 | sed 's|:|/|')"
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
  local repo_dir="${WORKSPACE}/${MANIFEST_DIRNAME}"
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
# content from a github repo bound for the wp-content directory for the repo identified by the section name.
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

# Pull a single "repo" from github and extract its content to the wp-content directory.
processSingleRepo() {
  local repo="$1"
  
  # Only git repos are supported for now.
  [ "${section['scm']}" != 'git' ] && echo "Not a git repo: ${section['name']}" && return 0
    
  pullContentRepo "${section['name']}"
}

# For each repos in REPOS, pull from the corresponding git repo and extract its content to the wp-content directory.
processIniFile() {
  # REPOS is a comma-delimited single line string. Iterate over each delimited value (repo).
  for repo in $(echo "$REPOS" | awk 'BEGIN{RS = ","}{print $1}') ; do

    echo "Processing ${repo}..."

    loadSection $repo

    processSingleRepo  $repo
  done
}


build() {

  pullManifestRepo

  processIniFile
}

env

build