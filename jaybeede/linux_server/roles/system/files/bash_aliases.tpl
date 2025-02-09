# aliases

# generic system related aliases

alias sd="sudo bash"
alias cls="clear"

function localip() {
    ip -j address | jq -r '[map(select(.operstate=="UNKNOWN" or .operstate=="UP")) | .[] as $item | $item.addr_info[] | select(.local != null and .scope == "global") | {ifname: $item.ifname, ip: "\(.local)/\(.prefixlen)", type: (if .family == "inet6" then "ipv6" else "ipv4" end)}] | sort_by(.type,.ifname)'
}

function localroutes() {
    local routesIpv4
    local routesIpv6
    routesIpv4=$(ip -j route | jq -c -r 'map(select(.flags | index("linkdown") | not)) | map(select(.dev | index("lo") | not)) | map({ifname: .dev, dst: (if .dst == "default" then "0.0.0.0/0" else .dst end), metric: .metric, type: "ipv4"}) | sort_by(.metric,.dst)')
    routesIpv6=$(ip -j -6 route | jq -c -r 'map(select(.flags | index("linkdown") | not)) | map(select(.dev | index("lo") | not)) | map({ifname: .dev, dst: (if .dst == "default" then "0.0.0.0" else .dst end), metric: .metric, type: "ipv6"}) | sort_by(.metric,.dst) | (.[] | select(.dst | index("0.0.0.0"))).dst |= "::/0"')
    jq -n --argjson var1 "$routesIpv4" --argjson var2 "$routesIpv6" '[$var1 | .[], ($var2 | .[])]'
}

alias rs="rsync -avr --progress"

alias agu="sudo apt-get update"
alias agg="sudo apt-get upgrade"
function agi() {
    sudo apt-get install -y "$1"
}

export HISTTIMEFORMAT="%F %T  "
if [ -n "$PROMPT_COMMAND" ] && echo "$PROMPT_COMMAND" | grep -qv "history -a"; then
    PROMPT_COMMAND="${PROMPT_COMMAND}; history -a"
elif [ -z "$PROMPT_COMMAND" ]; then
    PROMPT_COMMAND="history -a"
fi
export EDITOR=nano
export LANG=C

## personal aliases

export vd="[% home %]/Documents" # Will be replaced by ansible
alias d="cd $vd"
export vpjp="[% git_rootrepo %]" # Will be replaced by ansible
alias pjp="cd $vpjp"
export vdw="[% home %]/Downloads"
alias dw="cd $vdw"

# git related aliases

export MAXCHARS=72
export ISSUE_TYPE=fix

alias gs="git status"

function gpu {
    if [ "$LOCAL_GIT" == 1 ]; then
        return 0
    fi
    cmd=(git push)
    remote="origin"
    if [ -n "$1" ] && [ -n "$2" ]; then
        remote="$2"
    fi
    cmd+=("$remote")
    currentBranch="$(git branch 2>/dev/null | awk '$1 == "*" {print $2}')"
    if [ -z "$currentBranch" ]; then
        return 1
    fi
    cmd+=("$currentBranch")
    if [ "$1" == "f" ] || [ "$1" == "1" ]; then
        cmd+=(--force-with-lease)
    fi
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        return 0
    fi
    "${cmd[@]}" 2>&1 | awk '$1 == "remote:" && $2 ~ "^http(s?)://" {print $2}'
}

function gpl {
    git fetch origin
    unset defaultBranch
    if [ "$1" == "f" ] || [ "$1" == "1" ]; then
        defaultBranch=$(git branch 2>/dev/null | awk '$1 == "*" {print $2}')
    else
        if [ -z "$1" ]; then
            defaultBranch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed -r "s:^refs/remotes/origin/::g")
        else
            defaultBranch=$1
        fi
    fi
    if [ -z "$defaultBranch" ]; then
        defaultBranch="master"
    fi
    cmd=(git rebase "origin/${defaultBranch}")
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        return 0
    fi
    "${cmd[@]}"
}

function human2GitHash {
    lastCommit=${1:-1}
    lastCommit="${lastCommit#-}"
    previousFlag=${2:-1}
    if [ "${lastCommit,,}" == "all" ] || [ "${lastCommit,,}" == "0" ]; then
        echo 0
        return 0
    fi
    if [ "${lastCommit,,}" == "last" ] || [ "${lastCommit,,}" == "latest" ]; then
        lastCommit=1
    fi
    if [ "$(git branch --list "$lastCommit")" != "" ] || git ls-remote --exit-code --heads origin "$lastCommit" >/dev/null 2>&1; then
        # is a branch: get last commit since branch fork
        lastCommit="$(git log --format="%H" "${lastCommit}" | head -n 1)"
    elif [[ $lastCommit =~ ^[0-9]{1,4}$ ]]; then
        lastCommit="$(git log --format="%H" "-${lastCommit}" | tail -n -1)"
        # convert number to full hash commit
    elif ! git cat-file -t "$lastCommit" >/dev/null 2>&1; then
        return 1
    fi
    if [ "$previousFlag" == "0" ]; then
        git rev-parse "$lastCommit" 2>/dev/null || "$lastCommit"
        return 0
    fi
    git rev-list --parents -n 1 "$lastCommit" | awk '{print $NF}' || "$lastCommit"
    # ensure get the full hash
}

function gl {
    prevCommitRef="$(human2GitHash "${1:-all}")"
    longFlag="${2:-0}"
    cmd=(git log)
    if [ "$prevCommitRef" != "0" ]; then
        cmd+=("${prevCommitRef}..HEAD")
    fi
    cmd+=(--graph)
    if [ "$longFlag" == "0" ]; then
        cmd+=(--abbrev-commit)
    fi
    "${cmd[@]}"
}

function grb {
    prevCommitRef="$(human2GitHash "${1:-0}" 0)"
    lastCommitRef="$(human2GitHash "${2:-0}" 0)"
    if [ "$lastCommitRef" != "0" ] && [ "$(git log -1 --format='%ct' "$prevCommitRef")" -gt "$(git log -1 --format='%ct' "$lastCommitRef")" ]; then
        swapTmp=$prevCommitRef # swap variable if user made order mistake
        prevCommitRef=$lastCommitRef
        lastCommitRef=$swapTmp
    fi
    prevCommitRef="$(human2GitHash "$prevCommitRef")"
    if [ "$prevCommitRef" == "0" ]; then
        prevCommitRef="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed -r "s:^refs/remotes/origin/::g")"
    fi
    cmd=(git rebase -i "$prevCommitRef")
    if [ "$lastCommitRef" != "0" ]; then
        cmd+=("$lastCommitRef")
    fi
    "${cmd[@]}"
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        sleep 0.5
        gl "$prevCommitRef" 0
        DEBUG=0
        gpl 1 # revert change
        DEBUG=1
        return 0
    fi
    gpu 1
}

function autoRebase {
    repoRootPath="$(git rev-parse --show-toplevel)"
    actionType=$1
    prevCommitRef="$(human2GitHash "${2:-1}" 0)"
    lastCommitRef="$(human2GitHash "${3:-0}" 0)"
    if [ "$lastCommitRef" != "0" ] && [ "$(git log -1 --format='%ct' "$prevCommitRef")" -gt "$(git log -1 --format='%ct' "$lastCommitRef")" ]; then
        swapTmp=$prevCommitRef # swap variable if user made order mistake
        prevCommitRef=$lastCommitRef
        lastCommitRef=$swapTmp
    fi
    prevCommitRef="$(human2GitHash "$prevCommitRef")"
    fifoPath="$(mktemp -d)/wtp"
    currentCoreEditor="$(git config --global --get core.editor)"
    currentRebaseInstructionFormat="$(git config --get rebase.instructionFormat)"
    git config --global --replace-all core.editor "sleep 0.5 && mkfifo $fifoPath && cat $fifoPath #"
    git config --add rebase.instructionFormat "%H %s"
    git rebase -i "$prevCommitRef" >/dev/null 2>&1 &
    sleep 0.5
    rebaseTodoPath="$(mktemp)"
    cp "${repoRootPath}/.git/rebase-merge/git-rebase-todo" "$rebaseTodoPath"

    awk -v stopCommit="$lastCommitRef" -v action="$actionType" -v reachedFlag=0 '{ (NR>1 || action == "reword") && (reachedFlag == 0 || stopCommit == 0) && gsub("pick",action,$1); NR>1 && $3 == stopCommit && reachedFlag=1; print $0}' "$rebaseTodoPath" >"${repoRootPath}/.git/rebase-merge/git-rebase-todo"

    rm "$rebaseTodoPath"
    if [ "$DEBUG" == 1 ]; then
        cat "${repoRootPath}/.git/rebase-merge/git-rebase-todo"
    fi
    git config --add rebase.instructionFormat "$currentRebaseInstructionFormat" # restablished previous format
    echo 1>"$fifoPath"
    rm "$fifoPath"
    sleep 1
    while [ -p "$fifoPath" ]; do
        "$currentCoreEditor" "${repoRootPath}/.git/COMMIT_EDITMSG"
        echo 1>"$fifoPath"
        rm "$fifoPath"
        sleep 1
    done
    git config --global core.editor "$currentCoreEditor" # restablished previous editor
    # git config --global core.editor "nano"
    rm -fr "$(dirname "$fifoPath")"
    if [ "$DEBUG" == 1 ]; then
        sleep 0.5
        gl "$prevCommitRef" 0
        DEBUG=0
        gpl 1 # revert change
        DEBUG=1
    fi
    gpu 1
}

function gfi { # fixup
    if [ -n "$(git status --porcelain)" ]; then
        # uncommited changes, need to commit before
        old_LOCAL_GIT="$LOCAL_GIT"
        LOCAL_GIT=1
        gc "temporary"
        LOCAL_GIT=$old_LOCAL_GIT
    fi
    autoRebase fixup "${1:-2}" "$2"
}

function gre { # fixup
    autoRebase reword "$1" "$2"
}

function gc {
    if [ -z "$1" ]; then
        return 1
    fi
    line1="$(echo "$1" | awk '{ split($0, chars, "¤"); lowerFlag=1; for (i=1; i <= length(chars); i++) { if(lowerFlag==1){newchars=newchars""tolower(chars[i]); lowerFlag=0} else{newchars=newchars""chars[i]; lowerFlag=1} }; print newchars}')"
    component="dedicated"
    unset line2
    if [ -n "$2" ]; then
        if [ -n "$3" ]; then
            line2="${2,,}"
            component=$3
        else
            component=$2
        fi
    fi
    delim=""
    if [ "$DEBUG" == 1 ]; then
        delim="\""
    fi
    cmd=(git commit)
    if [ -n "$SIGNEDOFF" ]; then
        cmd+=(-s)
    fi
    currentBranch="$(git branch 2>/dev/null | awk '$1 == "*" {print $2}')"
    if [ -z "$currentBranch" ]; then
        return 1
    fi
    issueType="$(awk -F / -v issuetype="$ISSUE_TYPE" '{ if ( $1 ~ "^(fix|feat|test)$" ) {print $1} else {print issuetype} }' <<<"$currentBranch")"
    linkedIssue="$(awk -F / '$NF ~ "[A-Z]+-[0-9]+" {print $NF}' <<<"$currentBranch")"
    line1="${delim}${issueType}(${component}): ${line1}${delim}"
    if [ -n "$MAXCHARS" ]; then
        if [ ${#line1} -gt "$MAXCHARS" ]; then
            echo "Message is too long (${#line1} chars instead of ${MAXCHARS} max)"
            return 1
        fi
    fi
    cmd+=(-m "${line1}")
    if [ -n "$linkedIssue" ]; then
        cmd+=(-m "${delim}ref: ${linkedIssue}${delim}")
    elif [ -n "$line2" ]; then
        cmd+=(-m "${delim}${line2}${delim}")
    fi
    cmd+=(--no-verify)
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        return 0
    fi
    git add -A
    "${cmd[@]}"
    gpu 1
}

function gcs {
    SIGNEDOFF=1
    gc "$@"
    unset SIGNEDOFF
}

function ga {
    cmd=(git commit --amend --no-edit --no-verify)
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        return 0
    fi
    git add -A
    "${cmd[@]}"
}

function gac {
    ga
    if [ "$DEBUG" == 1 ]; then
        return 0
    fi
    gpu 1
}

# log related aliases

function log {
    cat $1 | grep -v "end]" | grep -v "<ending>" | sed -r "s/\[<([0-9]+)\:.*>\]/[\1:]/g" | sed -r "s:((\[.*\].){1})(\[.*\].):\1:g" | sed -r "s:([A-Za-z]{3})\s([A-Za-z]{3})\s([0-9]+)\s([0-9]{2}\:)([0-9]{2}\:)([0-9]{2})\s([0-9]{4}):\7-\2-\3 \4\5\6 UTC:g" | sed -r "s:-Jan-:-01-:g" | sed -r "s:-Feb-:-02-:g" | sed -r "s:-Mar-:-03-:g" | sed -r "s:-Apr-:-04-:g" | sed -r "s:-May-:-05-:g" | sed -r "s:-Jun-:-06-:g" | sed -r "s:-Jul-:-07-:g" | sed -r "s:-Aug-:-08-:g" | sed -r "s:-Sep-:-09-:g" | sed -r "s:-Oct-:-10-:g" | sed -r "s:-Nov-:-11-:g" | sed -r "s:-Dec-:-12-:g"
}

function logc {
    cat $1 | grep -v "end]" | grep -v "<ending>" | sed -r "s/\[<([0-9]+)\:.*>\]/[\1:]/g" | sed -r "s:((\[.*\].){1})(\[.*\].):\1:g" | sed -r "s:([A-Za-z]{3})\s([A-Za-z]{3})\s([0-9]+)\s([0-9]{2}\:)([0-9]{2}\:)([0-9]{2})\s([0-9]{4}):\7-\2-\3 \4\5\6 UTC:g" | sed -r "s:-Jan-:-01-:g" | sed -r "s:-Feb-:-02-:g" | sed -r "s:-Mar-:-03-:g" | sed -r "s:-Apr-:-04-:g" | sed -r "s:-May-:-05-:g" | sed -r "s:-Jun-:-06-:g" | sed -r "s:-Jul-:-07-:g" | sed -r "s:-Aug-:-08-:g" | sed -r "s:-Sep-:-09-:g" | sed -r "s:-Oct-:-10-:g" | sed -r "s:-Nov-:-11-:g" | sed -r "s:-Dec-:-12-:g" | grep -v "error_details" | ccze -m ansi
}

# docker related aliases

function dk_getTarget() {
    target=$1
    res1=$(docker ps -a --format "{{.Names}}" | grep "$target" | head -n1)
    if [ "$res1" != "" ]; then
        trgt=$res1
    else
        res2=$(docker ps -a --format "{{.Names}}\t{{.Image}}" | grep "$target" | head -n1)
        trgt=$(echo "$res2" | awk '{print $1}')
    fi
    echo "$trgt"
}

function dk_getStatus {
    echo "===Volumes STATUS==="
    docker volume ls --format "{{.Name}}"
    echo "===Images STATUS==="
    docker image ls --format "{{.Size}}\t{{.Tag}}\t{{.Repository}}"
    echo "===Containers STATUS==="
    docker ps -a --format "{{.Status}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}"
}

function dk_bash {
    target=$1
    trgt=$(dk_getTarget "$target")
    echo "===Starting SHELL ON $trgt==="
    docker exec -it "$trgt" bash || docker exec -it "$trgt" sh
}

function dk_logs {
    target=$1
    trgt=$(dk_getTarget "$target")
    echo "===Starting LOGS ON $trgt==="
    docker logs -n 10 -f "$trgt"
}

# server specific

function kdbxQuery() {
    "/opt/scripts/lib/kdbxQuery.py" "$@"
}

