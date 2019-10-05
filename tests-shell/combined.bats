#!/usr/bin/env bats

load './helpers'

function setup() {
    cd "$(dirname ${BATS_TEST_FILENAME})/.."
    if [ -z "${TEST_COMMAND+x}" ]; then
        TEST_COMMAND='python3 main.py'
    fi
}

@test "Deleting files nested in folders (dry run)" {
    # prepare
    workdir="$(mktemp -d)"
    mkdir "${workdir}/build"
    touch "${workdir}/build/.DS_Store"

    # check folder contains exactly 1 file
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

    # run program
    run eval "${TEST_COMMAND}" --dry-run "${workdir}"
    [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 1 ]
    [ "${status}" -eq 0 ]

    # check file is STILL there
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

    # cleanup
    rm -rf "${workdir}"
}

@test "Deleting files nested in folders" {
    # prepare
    workdir="$(mktemp -d)"
    mkdir "${workdir}/build"
    touch "${workdir}/build/.DS_Store"

    # check folder contains exactly 1 file
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

    # run program
    run eval "${TEST_COMMAND}" "${workdir}"
    [ "${output}" = '' ]
    [ "${status}" -eq 0 ]

    # check file is STILL there
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

    # cleanup
    rm -rf "${workdir}"
}

@test "Deleting files nested in folders (verbose)" {
    # prepare
    workdir="$(mktemp -d)"
    mkdir "${workdir}/build"
    touch "${workdir}/build/.DS_Store"

    # check folder contains exactly 1 file
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

    # run program
    run eval "${TEST_COMMAND}" --verbose "${workdir}"
    echo "${output}" >~/Desktop/log.txt
    [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 2 ]
    [ "${status}" -eq 0 ]

    # check file is STILL there
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

    # cleanup
    rm -rf "${workdir}"
}

@test "Deleting combined files and folders (dry run)" {
    # prepare
    workdir="$(mktemp -d)"
    mkdir "${workdir}/build"
    touch "${workdir}/.DS_Store"

    # check folder contains exactly 1 file
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

    # run program
    run eval "${TEST_COMMAND}" --dry-run "${workdir}"
    [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 2 ]
    [ "${status}" -eq 0 ]

    # check file is STILL there
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

    # cleanup
    rm -rf "${workdir}"
}

@test "Deleting combined files and folders" {
    # prepare
    workdir="$(mktemp -d)"
    mkdir "${workdir}/build"
    touch "${workdir}/.DS_Store"

    # check folder contains exactly 1 file
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

    # run program
    run eval "${TEST_COMMAND}" "${workdir}"
    [ "${output}" = '' ]
    [ "${status}" -eq 0 ]

    # check file is STILL there
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

    # cleanup
    rm -rf "${workdir}"
}

@test "Deleting combined files and folders (verbose)" {
    # prepare
    workdir="$(mktemp -d)"
    mkdir "${workdir}/build"
    touch "${workdir}/.DS_Store"

    # check folder contains exactly 1 file
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

    # run program
    run eval "${TEST_COMMAND}" --verbose "${workdir}"
    [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 3 ]
    [ "${status}" -eq 0 ]

    # check file is STILL there
    [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

    # cleanup
    rm -rf "${workdir}"
}
