#!/bin/bash
trap "echo program aborted;exit 1" TERM
export TOP_PID=$$

test() {
    unset t_std t_err t_ret
    eval "$( eval $1 \
      2> >(t_err=$(cat); typeset -p t_err) \
      > >(t_std=$(cat); typeset -p t_std); t_ret=$?; typeset -p t_ret )"

    if ! [[ -z $t_err ]]; then
        echo $t_err >&2

		# do some cleanup
		# ...cleaning...

		kill -s TERM $TOP_PID
    fi

    echo $t_ret
}

if [[ $(test "git log $1") -eq 0 ]]; then
    echo "exists"
fi

exit 0
