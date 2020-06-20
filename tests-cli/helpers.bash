#!/usr/bin/env bash

# test the number of files left in DIR is N
count_files() {
    # shellcheck disable=SC2154
    [ "$(find "${tmpdir}" -mindepth 1 -maxdepth 1 -print0 | tr -cd '\0' | wc -c)" -eq "${1}" ]
}

# test output contains N number of "remove `file`" lines
count_output() {
    # shellcheck disable=SC2154
    [ "$(grep -iEc 'remov((ed?)|(ing))' <<<"${output}")" -eq "${1}" ]
}
