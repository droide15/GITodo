#!/bin/bash

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

validateExist() {
    local branch_exists=$(git branch --list TODOs)
    if [[ -z ${branch_exists} ]]; then
        echo 1
    else
        echo 0
    fi
}

checkCurrent() {
    local current_branch=$(git branch --show-current)
    if [[ $current_branch != $1 ]]; then
        git checkout $1 > /dev/null 2>&1
        echo $?
    else
        echo 0
    fi
}

case "$1" in
    -e|--enter)
            previous_branch=$(git branch --show-current)
            if [[ $(validateExist) -eq 1 ]]; then
                echo "TODOs branch does not exist yet." >&2
                echo "Create TODOs branch with TODO -o or TODO --open."
                exit 1
            fi
            if [[ $(checkCurrent TODOs) -eq 0 ]]; then
                git commit --allow-empty -m "TODO: $2"
            else
                exit 1
            fi

            checkCurrent ${previous_branch}
            exit 0
            ;;
    -o|--open)
            previous_branch=$(git branch --show-current)
            if [[ $(validateExist) -eq 0 ]]; then
                echo "TODOs branch already exists." >&2
                exit 1
            fi
            if [[ $(checkCurrent develop) -eq 0 ]]; then
                git checkout -b TODOs
                git push --set-upstream origin TODOs
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
                git merge --squash develop
                git commit -m "$2"
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
                git push --force
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
    -c|--complete)
            previous_branch=$(git branch --show-current)
            if [[ $(validateExist) -eq 1 ]]; then
                echo "TODOs branch does not exist yet." >&2
                echo "Create TODOs branch with TODO -o or TODO --open."
                exit 1
            fi
            if [[ $(checkCurrent TODOs) -eq 0 ]]; then
                git rebase -r --onto $2^ $2
            else
                exit 1
            fi
            checkCurrent ${previous_branch}
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