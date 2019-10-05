#!/usr/bin/env bats

load './helpers'

function setup() {
    cd "$(dirname ${BATS_TEST_FILENAME})/.."
    if [ -z "${TEST_COMMAND+x}" ]; then
        TEST_COMMAND='python3 main.py'
    fi
}

@test "Deleting empty folder (dry run)" {
    for folder in "${folders[@]}"; do
        # prepare
        workdir="$(mktemp -d)"
        mkdir "${workdir}/${folder}"

        # check folder contains exactly 1 folder
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 1 ]

        # run program
        run eval "${TEST_COMMAND}" --dry-run "${workdir}"
        [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 1 ]
        [ "${status}" -eq 0 ]

        # check folder is STILL there
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 1 ]

        # cleanup
        rm -rf "${workdir}"
    done
}

@test "Deleting empty folder" {
    for folder in "${folders[@]}"; do
        # prepare
        workdir="$(mktemp -d)"
        mkdir "${workdir}/${folder}"

        # check folder contains exactly 1 folder
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 1 ]

        # run program
        run eval "${TEST_COMMAND}" "${workdir}"
        [ "${output}" = '' ]
        [ "${status}" -eq 0 ]

        # check folder is deleted
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

        # cleanup
        rm -rf "${workdir}"
    done
}

@test "Deleting empty folder (verbose)" {
    for folder in "${folders[@]}"; do
        # prepare
        workdir="$(mktemp -d)"
        mkdir "${workdir}/${folder}"

        # check folder contains exactly 1 folder
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 1 ]

        # run program
        run eval "${TEST_COMMAND}" --verbose "${workdir}"
        [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 2 ]
        [ "${status}" -eq 0 ]

        # check folder is deleted
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

        # cleanup
        rm -rf "${workdir}"
    done
}

@test "Deleting nonempty folder (dry run)" {
    for folder in "${folders[@]}"; do
        # prepare
        workdir="$(mktemp -d)"
        mkdir "${workdir}/${folder}"
        touch "${workdir}/${folder}/file.txt"

        # check folder contains exactly 1 folder
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

        # run program
        run eval "${TEST_COMMAND}" --dry-run "${workdir}"
        [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 1 ]
        [ "${status}" -eq 0 ]

        # check folder is STILL there
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

        # cleanup
        rm -rf "${workdir}"
    done
}

@test "Deleting nonempty folder" {
    for folder in "${folders[@]}"; do
        # prepare
        workdir="$(mktemp -d)"
        mkdir "${workdir}/${folder}"
        touch "${workdir}/${folder}/file.txt"

        # check folder contains exactly 1 folder
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

        # run program
        run eval "${TEST_COMMAND}" "${workdir}"
        [ "${output}" = '' ]
        [ "${status}" -eq 0 ]

        # check folder is deleted
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

        # cleanup
        rm -rf "${workdir}"
    done
}

@test "Deleting nonempty folders (verbose)" {
    for folder in "${folders[@]}"; do
        # prepare
        workdir="$(mktemp -d)"
        mkdir "${workdir}/${folder}"
        touch "${workdir}/${folder}/file.txt"

        # check folder contains exactly 1 folder
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 2 ]

        # run program
        run eval "${TEST_COMMAND}" --verbose "${workdir}"
        [ "$(printf '%s\n' "${output}" | wc -l | tr -d '[:space:]')" -eq 2 ]
        [ "${status}" -eq 0 ]

        # check folder is deleted
        [ "$(find "${workdir}" -mindepth 1 | wc -l | tr -d '[:space:]')" -eq 0 ]

        # cleanup
        rm -rf "${workdir}"
    done
}
