#!/usr/bin/env bash

# test the number of files left in DIR is N
function count_files {
    [ "$(ls -A "${tmpdir}" | wc -l)" -eq "${1}" ]
}

# test output contains N number of "remove `file`" lines
function count_output {
    [ "$(grep -iE 'remov((ed?)|(ing))' <<<"${output}" | wc -l)" -eq "${1}" ]
}
