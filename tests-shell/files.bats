#!/usr/bin/env bats

load './helpers'

function setup() {
    cd "$(dirname ${BATS_TEST_FILENAME})/.."
    if [ -z "${TEST_COMMAND+x}" ]; then
        TEST_COMMAND='python3 main.py'
    fi
}

@test "Deleting individual files (dry run)" {
    for file in "${files[@]}"; do
        # prepare
        workdir="$(mktemp -d)"
        touch "${workdir}/${file}"

        # check folder contains exactly 1 file
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 1 ]

        # run program
        run eval "${TEST_COMMAND}" --dry-run "${workdir}"
        [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 1 ]
        [ "${status}" -eq 0 ]

        # check file is STILL there
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 1 ]

        # cleanup
        rm -rf "${workdir}"
    done
}

@test "Deleting individual files" {
    for file in "${files[@]}"; do
        # prepare
        workdir="$(mktemp -d)"
        touch "${workdir}/${file}"

        # check folder contains exactly 1 file
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 1 ]

        # run program
        run eval "${TEST_COMMAND}" "${workdir}"
        [ "${output}" = '' ]
        [ "${status}" -eq 0 ]

        # check file is deleted
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

        # cleanup
        rm -rf "${workdir}"
    done
}

@test "Deleting individual files (verbose)" {
    for file in "${files[@]}"; do
        # prepare
        workdir="$(mktemp -d)"
        touch "${workdir}/${file}"

        # check folder contains exactly 1 file
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 1 ]

        # run program
        run eval "${TEST_COMMAND}" --verbose "${workdir}"
        [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 2 ]
        [ "${status}" -eq 0 ]

        # check file is deleted
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

        # cleanup
        rm -rf "${workdir}"
    done
}
