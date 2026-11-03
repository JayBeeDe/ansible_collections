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
    sudo apt-get install -y "$@"
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
export vdw="$(python3 -c 'from gi.repository import GLib; print(GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DOWNLOAD));')"
alias dw="cd $vdw"

# git related aliases

export MAX_CHARS=72
export AUTO_PUSH=1
export SIGNED_GPG=1

alias gs="git status"

function gpu {
    if [ "$LOCAL_GIT" == 1 ]; then
        return 0
    fi
    cmd=(git push --no-verify)
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
    cmd=(git rebase --no-verify "origin/${defaultBranch}")
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
    cmd+=(--graph "--date=iso8601" "--format=%C(yellow)commit %h %C(auto)%d%C(reset) %C(red)%G?%C(reset)%C(reset)%n%C(blue)%an <%ae>%C(reset)%n%C(green)%ad%C(reset)%n%s%n%b")
    if [ "$longFlag" == "0" ]; then
        cmd+=(--abbrev-commit)
    fi
    "${cmd[@]}"
}

function gprd {
    if [ -z "$1" ]; then
        defaultBranch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed -r "s:^refs/remotes/::g")
    else
        defaultBranch=$1
    fi
    prFlag="${2:-0}"
    prevCommitRef="$(human2GitHash "$defaultBranch" 0)"
    lastCommitRef="$(human2GitHash 1 0)"
    cmd=(git log)
    cmd+=("${prevCommitRef}..${lastCommitRef}")
    cmd2=("${cmd[@]}")
    cmd+=("--pretty=%x2a%x20%s")
    if [ "$prFlag" != "0" ]; then
        "${cmd[@]}" | sed -r "s:\s+\[ft/.*\]::g" | grep --color=never -i "pull request #"
    else
        "${cmd[@]}" | sed -r "s:\s+\[ft/.*\]::g" | grep --color=never -vi "pull request #"
    fi
    cmd2+=("--pretty=%b")
    "${cmd2[@]}" | awk -F'#' '/ref: #[A-Z]+-[0-9]+/ {
		ref_line = $2
		gsub(/[,:]/, " ", ref_line)
		for (i=1; i<=split(ref_line, refs_array, " "); i++) {
			if (refs_array[i] ~ /^[A-Z]+-[0-9]+$/) {
				refs[refs_array[i]] = 1
				nbRefs++
			}
		}
	}
	END {
		if (!nbRefs) {
			exit
		}
		printf "refs: ";
		first = 1
		PROCINFO["sorted_in"] = "@ind_str_asc"
		for (ref in refs) {
			if (!first) {
				printf ", "
			}
			printf "%s", ref
			first = 0
		}
		print ""
	}'
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
    if [ -n "$SIGNED_GPG" ]; then
        cmd=(git rebase --no-verify --exec "git commit --amend --no-edit -S" -i "$prevCommitRef")
    else
        cmd=(git rebase --no-verify -i "$prevCommitRef")
    fi
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
    if [ "$AUTO_PUSH" == 1 ]; then
        gpu 1
    fi
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
    if [ -n "$SIGNED_GPG" ]; then
        git rebase --no-verify --exec "git commit --amend --no-edit -S" -i "$prevCommitRef" >/dev/null 2>&1 &
    else
        git rebase --no-verify -i "$prevCommitRef" >/dev/null 2>&1 &
    fi
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
    if [ "$AUTO_PUSH" == 1 ]; then
        gpu 1
    fi
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
    line1=$1
    component="dedicated"
    if [ -n "$2" ]; then
        component=$1
        line1=$2
    fi
    if [ -n "$3" ]; then
        line2="${3,,}"
    fi
    line1="$(echo "$line1" | awk '{ split($0, chars, "¤"); lowerFlag=1; for (i=1; i <= length(chars); i++) { if(lowerFlag==1){newchars=newchars""tolower(chars[i]); lowerFlag=0} else{newchars=newchars""chars[i]; lowerFlag=1} }; print newchars}')"
    unset line2
    delim=""
    if [ "$DEBUG" == 1 ]; then
        delim="\""
    fi
    cmd=(git commit)
    if [ -n "$SIGNED_OFF" ]; then
        cmd+=(-s)
    fi
    if [ -n "$SIGNED_GPG" ]; then
        cmd+=(-S)
    fi
    currentBranch="$(git branch 2>/dev/null | awk '$1 == "*" {print $2}')"
    if [ -z "$currentBranch" ]; then
        return 1
    fi
    if [ -n "$ISSUE_TYPE" ]; then
        issueType="$ISSUE_TYPE"
    else
        issueType="$(awk -F / '{ if ( $1 ~ "^(fix|feat|test|specs|docs)$" ) {print $1} else {print "fix"} }' <<<"$currentBranch")"
    fi
    issueRef="$(sed -r "s:^.*\/([A-Z]+-[0-9]+).*$:\1:g" <<<"$currentBranch")"
    if [ -n "$ISSUE_REF" ]; then
        issueRef=$ISSUE_REF
    fi
    line1="${delim}${issueType}(${component}): ${line1}${delim}"
    if [ -n "$MAX_CHARS" ]; then
        if [ ${#line1} -gt "$MAX_CHARS" ]; then
            echo "Message is too long (${#line1} chars instead of ${MAX_CHARS} max)"
            return 1
        fi
    fi
    cmd+=(-m "${line1}")
    if [ -n "$issueRef" ] && [ "$issueRef" != "$currentBranch" ]; then
        cmd+=(-m "${delim}ref: #${issueRef}${delim}")
    elif [ -n "$line2" ]; then
        cmd+=(-m "${delim}${line2}${delim}")
    fi
    cmd+=(--no-verify)
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        return 0
    fi
    if git diff --cached --quiet; then
        git add -A
    fi
    "${cmd[@]}"
    if [ "$AUTO_PUSH" == 1 ]; then
        gpu 1
    fi
}

function gt {
    if [ -z "$1" ]; then
        return 1
    fi
    tagName="$1"
    if [ "${tagName/#v/}" == "$tagName" ] && [ "${tagName/_v/}" == "$tagName" ]; then
        tagName="v${tagName}"
    fi
    tagCommitRef="$(human2GitHash "${2:-1}" 0)"
    cmd=(git tag)
    if [ -n "$SIGNED_GPG" ]; then
        cmd+=(-s -m "Signed Tag") # yes that's a lowercase...
    fi
    cmd+=("$tagName" "$tagCommitRef")
    cmd2=(git push origin --tags)
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        echo "${cmd2[@]}"
        return 0
    fi
    "${cmd[@]}"
    "${cmd2[@]}"
}

function gtr {
    if [ -z "$1" ]; then
        return 1
    fi
    tagName="$1"
    if [ "${tagName/#v/}" == "$tagName" ] && [ "${tagName/_v/}" == "$tagName" ]; then
        tagName="v${tagName}"
    fi
    cmd=(git tag --delete "$tagName")
    cmd2=(git push origin ":refs/tags/${tagName}")
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        echo "${cmd2[@]}"
        return 0
    fi
    "${cmd[@]}"
    "${cmd2[@]}"
}

function ga {
    cmd=(git commit --amend --no-edit --no-verify)
    if [ -n "$SIGNED_OFF" ]; then
        cmd+=(-s)
    fi
    if [ -n "$SIGNED_GPG" ]; then
        cmd+=(-S)
    fi
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        return 0
    fi
    if git diff --cached --quiet; then
        git add -A
    fi
    "${cmd[@]}"
    if [ "$AUTO_PUSH" == 1 ]; then
        gpu 1
    fi
}

# log related aliases

function log {
    cat $1 | grep -v "end]" | grep -v "<ending>" | sed -r "s/\[<([0-9]+)\:.*>\]/[\1:]/g" | sed -r "s:((\[.*\].){1})(\[.*\].):\1:g" | sed -r "s:([A-Za-z]{3})\s([A-Za-z]{3})\s([0-9]+)\s([0-9]{2}\:)([0-9]{2}\:)([0-9]{2})\s([0-9]{4}):\7-\2-\3 \4\5\6 UTC:g" | sed -r "s:-Jan-:-01-:g" | sed -r "s:-Feb-:-02-:g" | sed -r "s:-Mar-:-03-:g" | sed -r "s:-Apr-:-04-:g" | sed -r "s:-May-:-05-:g" | sed -r "s:-Jun-:-06-:g" | sed -r "s:-Jul-:-07-:g" | sed -r "s:-Aug-:-08-:g" | sed -r "s:-Sep-:-09-:g" | sed -r "s:-Oct-:-10-:g" | sed -r "s:-Nov-:-11-:g" | sed -r "s:-Dec-:-12-:g"
}

function logc {
    cat $1 | grep -v "end]" | grep -v "<ending>" | sed -r "s/\[<([0-9]+)\:.*>\]/[\1:]/g" | sed -r "s:((\[.*\].){1})(\[.*\].):\1:g" | sed -r "s:([A-Za-z]{3})\s([A-Za-z]{3})\s([0-9]+)\s([0-9]{2}\:)([0-9]{2}\:)([0-9]{2})\s([0-9]{4}):\7-\2-\3 \4\5\6 UTC:g" | sed -r "s:-Jan-:-01-:g" | sed -r "s:-Feb-:-02-:g" | sed -r "s:-Mar-:-03-:g" | sed -r "s:-Apr-:-04-:g" | sed -r "s:-May-:-05-:g" | sed -r "s:-Jun-:-06-:g" | sed -r "s:-Jul-:-07-:g" | sed -r "s:-Aug-:-08-:g" | sed -r "s:-Sep-:-09-:g" | sed -r "s:-Oct-:-10-:g" | sed -r "s:-Nov-:-11-:g" | sed -r "s:-Dec-:-12-:g" | grep -v "error_details" | ccze -m ansi
}

# image manipulation aliases

function filigrane {
    if ! [ -r "$1" ]; then
        echo "Input file not readable"
    fi
    if [ -z "$2" ]; then
        echo "Please provide a text"
    fi
    text_content=$2
    input_file=$1
    output_file="${input_file%.*}-output.${input_file##*.}"
    convert -size 140x80 xc:none -fill grey -gravity NorthWest -draw 'text 10,10 "'$text_content'"' -gravity SouthEast -draw 'text 5,15 "'$text_content'"' miff:- | composite -tile - "$input_file" "$output_file"
}

# AI related aliases

export AI_MODEL="default"
export AI_INTERACTIVE=1

function ai {
    # set -x
    local config_file="$HOME/.continue/config.yaml"
    if ! yq eval '.models' "$config_file" >/dev/null; then
        echo "Error while reading file $config_file"
        return 1
    fi
    models_data=$(yq eval '.models' "$config_file")
    if [ "$AI_MODEL" == "default" ] || [ -z "$AI_MODEL" ]; then
        model_name=$(yq eval '.[0].name' <<<"$models_data")
        if [ "$DEBUG" == 1 ]; then
            echo "Using default model name $model_name"
        fi
    else
        model_name=$AI_MODEL
    fi
    if ! yq eval '.[].name' <<<"$models_data" | grep -q "$model_name"; then
        models_names="$(yq eval '.[].name' <<<"$models_data" | sed -zr "s:\n:, :g")"
        echo "Please choose on of ${models_names%??}"
        return 1
    fi
    # shellcheck disable=SC2086
    model_item=$(yq eval '.[] | select(.name == "'$model_name'")' <<<"$models_data")

    cmd=("tgpt")
    if [ "$AI_INTERACTIVE" == 1 ]; then
        cmd+=("-m")
    else
        cmd+=("-w")
    fi
    cmd+=("--provider" "$(yq eval '.provider' <<<"$model_item")")
    cmd+=("--key" "$(yq eval '.apiKey' <<<"$model_item")")
    cmd+=("--model" "$(yq eval '.model' <<<"$model_item")")
    cmd+=("--url" "$(yq eval '.apiBase' <<<"$model_item")/chat/completions")
    cmd+=("$@")
    if [ "$DEBUG" == 1 ]; then
        echo "${cmd[@]}"
        return 0
    fi
    "${cmd[@]}"
}

# desktop related aliases

function decrypt {
    xsel | gpg --decrypt | xsel --clipboard
}

function rm {
    local force=false
    local recursive=false
    local files=()
    local OPTIND=1
    # Parse options
    while getopts ":fr" opt; do
        case $opt in
        f)
            force=true
            ;;
        r)
            recursive=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            return 1
            ;;
        esac
    done
    shift $((OPTIND - 1))
    # Collect file arguments
    files=("$@")
    if [ ${#files[@]} -eq 0 ]; then # Check if any files were provided
        echo "No files specified." >&2
        return 1
    fi

    for file in "${files[@]}"; do
        volume_root="$(df "$file" | awk 'NR > 1 { print $6 }')"
        if [ "$volume_root" == "/" ]; then
            volume_root="/tmp"
        fi
        trash_dir="${volume_root}/.Trash-${UID}"
        cmd=("trash-put")
        if [ -d "$file" ] && [ "$recursive" = true ]; then # Call trash-put with the appropriate options
            cmd+=("-r")
        fi
        if [ "$volume_root" != "/home" ]; then
            mkdir -p "$trash_dir"
            cmd+=("--trash-dir" "$trash_dir")
        fi
        cmd+=("$file")
        "${cmd[@]}"
    done
}

function icode {
    # Check if a sub_folder argument is provided
    if [ -n "$1" ]; then
        # Subfolder provided as argument
        folder="$1"

        # Check if the folder exists
        if [ ! -d "$folder" ]; then
            echo "Error: Folder $folder does not exist"
            exit 1
        fi
    else
        root_folder=$vpj
        # No sub_folder provided, show dropdown UI
        mapfile -t sub_folders < <(find "$root_folder" -mindepth 2 -maxdepth 2 -type d -not -path '*/.*' -printf "%P\n" | sort)

        if [ ${#sub_folders[@]} -eq 0 ]; then
            echo "Error: No sub_folders found in $root_folder"
            exit 1
        fi

        # Display dropdown UI using zenity
        sub_folder=$(zenity --list --column="Projects" "${sub_folders[@]}")

        # Check if a sub_folder was chosen
        if [ $? -ne 0 ]; then
            echo "No sub_folder chosen. Exiting."
            exit 1
        fi
        folder="$root_folder/$sub_folder"
    fi
    # Open VSCode in the specified sub_folder
    code "$folder"
}

alias gnome-reload="killall -1 gnome-shell"
alias gnome-reload2="dbus-send --type=method_call --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'global.reexec_self()'"

export vcalc="/usr/bin/gnome-calculator"
alias calc="$vcalc"

function decrypt {
    xsel | gpg --decrypt | xsel --clipboard
}
export GOOGLE_API_KEY="no"
export GOOGLE_DEFAULT_CLIENT_ID="no"
export GOOGLE_DEFAULT_CLIENT_SECRET="no"
export QT_STYLE_OVERRIDE="{{ theme_primary_name }}"
