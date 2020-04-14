#!/usr/bin/env bash

# test the number of files left in DIR is N
function test_files() {
    [ "$(ls -A "${1}" | wc -l)" -eq "${2}" ]
}

# test output contains N number of "remove `file`" lines
function test_output() {
    [ "$(grep -iE 'remov(e|(ing))' --count <<<"${output}")" -eq "${1}" ]
}
