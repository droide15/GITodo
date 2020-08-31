#!/bin/bash
trap "echo program aborted;exit 1" TERM
export TOP_PID=$$

readonly RETVAL=0
readonly STDVAL=1

printUsage() {
    echo ""
    echo "Usage:"
    echo ""
    echo "TODO -e arg   Commit a new todo in TODOs branch."
    echo "     --enter arg"
    echo "TODO -o       Create TODOs branch or checkout if already exists."
    echo "     --open"
    echo "TODO -s arg   Merge last work done on develop in a single commit."
    echo "     --sync arg"
    echo "TODO -p       Push TODOs branch to remote repository."
    echo "     --publish"
    echo "TODO -l       Show log of branch TODOs in readable format."
    echo "     --list"
    echo "TODO -c arg   Remove todo entry specified by arg from TODOs log."
    echo "     --complete arg"
    echo "TODO -h       Print help."
    echo "     --help"
    echo ""
}

safeEval() {
    unset t_std t_err t_ret
    eval "$( eval $1 \
      2> >(t_err=$(cat); typeset -p t_err) \
      > >(t_std=$(cat); typeset -p t_std); t_ret=$?; typeset -p t_ret )"
    if ! [[ -z $t_std ]]; then
        echo $t_std >&2
    fi
    if ! [[ -z $t_err ]]; then
        echo $t_err >&2
    fi
    if [[ $# -eq 1 || $2 = STDVAL ]]; then
        echo $t_std
        if [[ $t_ret -ne 0 ]]; then
            kill -s TERM $TOP_PID
        fi
    elif [[ $2 = RETVAL ]]; then
        echo $t_ret
    fi
}

validateExist() {
    local branch_exists=$(safeEval "git branch --list TODOs")
    if [[ -z ${branch_exists} ]]; then
        echo 1
    else
        echo 0
    fi
}

checkCurrent() {
    local current_branch=$(safeEval "git branch --show-current")
    if [[ $current_branch != $1 ]]; then
        echo $(safeEval "git checkout $1" RETVAL)
    else
        echo 0
    fi
}

if [[ $# = 1 ]]; then
    case "$1" in
        -o|--open)
                previous_branch=$(git branch --show-current)
                if [[ $(validateExist) -eq 0 ]]; then
                    echo "TODOs branch already exists." >&2
                    exit 1
                fi
                if [[ $(checkCurrent develop) -eq 0 ]]; then
                    safeEval "git checkout -b TODOs"
                    if [[ $(safeEval "git push --set-upstream origin TODOs" RETVAL) -ne 0 ]]; then
                        checkCurrent ${previous_branch}
                        safeEval "git branch -d TODOs"
                        exit 1
                    fi
                else
                    exit 1
                fi
                checkCurrent ${previous_branch}
                exit 0
                ;;
        -p|--publish)
                previous_branch=$(git branch --show-current)
                if [[ $(validateExist) -eq 1 ]]; then
                    echo "TODOs branch does not exist yet." >&2
                    echo "Create TODOs branch with TODO -o or TODO --open."
                    exit 1
                fi
                if [[ $(checkCurrent TODOs) -eq 0 ]]; then
                    if [[ $(safeEval "git push --force" RETVAL) -ne 0 ]]; then
                        checkCurrent ${previous_branch}
                        exit 1
                    fi
                else
                    exit 1
                fi
                checkCurrent ${previous_branch}
                exit 0
                ;;
        -l|--list)
                if [[ $(validateExist) -eq 1 ]]; then
                    echo "TODOs branch does not exist yet." >&2
                    echo "Create TODOs branch with TODO -o or TODO --open."
                    exit 1
                fi
                git log TODOs --pretty=format:"%cr %h %s"|less
                exit 0
                ;;
        -h|--help)
                echo ""
                echo "TODO is a utility made for Git to commit todo messages in a branch called TODOs which is based on the branch develop."
                printUsage
                exit 0
                ;;
        *)
                echo ""
                echo "Invalid option $@." >&2
                printUsage
                exit 1
                ;;
    esac
elif [[ $# = 2 ]]; then
    case "$1" in
        -e|--enter)
                previous_branch=$(git branch --show-current)
                if [[ $(validateExist) -eq 1 ]]; then
                    echo "TODOs branch does not exist yet." >&2
                    echo "Create TODOs branch with TODO -o or TODO --open."
                    exit 1
                fi
                if [[ $(checkCurrent TODOs) -eq 0 ]]; then
                    if [[ $(safeEval "git commit --allow-empty -m \"TODO: $2\"" RETVAL) -ne 0 ]]; then
                        checkCurrent ${previous_branch}
                        safeEval "git merge --abort"
                        exit 1
                    fi
                else
                    exit 1
                fi

                checkCurrent ${previous_branch}
                exit 0
                ;;
        -s|--sync)
                previous_branch=$(git branch --show-current)
                if [[ $(validateExist) -eq 1 ]]; then
                    echo "TODOs branch does not exist yet." >&2
                    echo "Create TODOs branch with TODO -o or TODO --open."
                    exit 1
                fi
                if [[ $(checkCurrent TODOs) -eq 0 ]]; then
                    safeEval "git merge --squash develop"
                    if [[ $(safeEval "git commit -m \"$2\"" RETVAL) -ne 0 ]]; then
                        checkCurrent ${previous_branch}
                        safeEval "git merge --abort"
                        exit 1
                    fi
                else
                    exit 1
                fi
                checkCurrent ${previous_branch}
                exit 0
                ;;
        -c|--complete)
                previous_branch=$(git branch --show-current)
                if [[ $(validateExist) -eq 1 ]]; then
                    echo "TODOs branch does not exist yet." >&2
                    echo "Create TODOs branch with TODO -o or TODO --open."
                    exit 1
                fi
                if [[ $(checkCurrent TODOs) -eq 0 ]]; then
                    if [[ $(safeEval "git rebase -r --onto $2^ $2" RETVAL) -ne 0 ]]; then
                        checkCurrent ${previous_branch}
                        safeEval "git merge --abort"
                        exit 1
                    fi
                else
                    exit 1
                fi
                checkCurrent ${previous_branch}
                exit 0
                ;;
        *)
                echo ""
                echo "Invalid options $@." >&2
                printUsage
                exit 1
                ;;
    esac
else
    echo ""
    echo "Invalid options $@." >&2
    printUsage
    exit 1
fi
