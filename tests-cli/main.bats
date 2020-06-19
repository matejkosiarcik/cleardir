#!/usr/bin/env bats

load './helpers'

function setup() {
    cd "${BATS_TEST_DIRNAME}/.."
    if [ -z "${TEST_COMMAND+x}" ] || [ "${TEST_COMMAND}" = '' ]; then
        printf 'TEST_COMMAND not specified\n' >&3
        exit 2
    fi
    export tmpdir="$(mktemp -d)"
}

function teardown() {
    rm -rf "${tmpdir}"
}

@test 'Deleting files' {
    # given
    mkdir "${tmpdir}/node_modules"
    touch "${tmpdir}/.DS_Store"
    mkdir "${tmpdir}/dir"
    touch "${tmpdir}/file"

    # when
    run ${TEST_COMMAND} -f "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    count_output 2
    count_files 2
    [ ! -e "${tmpdir}/node_modules" ]
    [ ! -e "${tmpdir}/.DS_Store" ]
    [ -d "${tmpdir}/dir" ]
    [ -f "${tmpdir}/file" ]
}

@test 'Deleting nested' {
    # given
    mkdir "${tmpdir}/node_modules"
    mkdir "${tmpdir}/node_modules/dir"
    mkdir "${tmpdir}/node_modules/node_modules"
    touch "${tmpdir}/node_modules/file"
    touch "${tmpdir}/file"

    # when
    run ${TEST_COMMAND} -f "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    count_output 1
    count_files 1
    [ ! -e "${tmpdir}/node_modules" ]
    [ -f "${tmpdir}/file" ]
}

@test 'Not deleting files (dry run)' {
    # given
    mkdir "${tmpdir}/node_modules"
    touch "${tmpdir}/.DS_Store"
    mkdir "${tmpdir}/dir"
    touch "${tmpdir}/file"

    # when
    run ${TEST_COMMAND} "${tmpdir}" --dry-run

    # then
    [ "${status}" -eq 0 ]
    count_output 2
    count_files 4
    [ -d "${tmpdir}/node_modules" ]
    [ -f "${tmpdir}/.DS_Store" ]
    [ -d "${tmpdir}/dir" ]
    [ -f "${tmpdir}/file" ]

    # when
    run ${TEST_COMMAND} -n "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    count_output 2
    count_files 4
    [ -d "${tmpdir}/node_modules" ]
    [ -f "${tmpdir}/.DS_Store" ]
    [ -d "${tmpdir}/dir" ]
    [ -f "${tmpdir}/file" ]
}

@test 'Not looking into nested junk directories' {
    # given
    mkdir "${tmpdir}/node_modules"
    mkdir "${tmpdir}/node_modules/node_modules"

    # when
    run ${TEST_COMMAND} "${tmpdir}" --dry-run

    # then
    [ "${status}" -eq 0 ]
    count_output 1
    count_files 1
    [ -d "${tmpdir}/node_modules" ]

    # when
    run ${TEST_COMMAND} "${tmpdir}" --force

    # then
    [ "${status}" -eq 0 ]
    count_output 1
    count_files 0
    [ ! -e "${tmpdir}/node_modules" ]
}

@test 'Deleting input files' {
    # given
    tmpdir="$(mktemp -d)"
    touch "${tmpdir}/.DS_Store"
    mkdir "${tmpdir}/node_modules"

    # when
    run ${TEST_COMMAND} -f "${tmpdir}/.DS_Store"

    # then
    [ "${status}" -eq 0 ]
    count_output 1
    count_files 1
    [ ! -e "${tmpdir}/.DS_Store" ]
    [ -d "${tmpdir}/node_modules" ]

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Not deleting root directory' {
    # given
    mkdir "${tmpdir}/node_modules"
    touch "${tmpdir}/node_modules/.DS_Store"

    # when
    run ${TEST_COMMAND} -f "${tmpdir}/node_modules"

    # then
    [ "${status}" -eq 0 ]
    count_output 1
    count_files 1
    [ -d "${tmpdir}/node_modules" ]
    [ ! -e "${tmpdir}/node_modules/.DS_Store" ]
}

@test 'Deleting in multiple directories' {
    # given
    mkdir "${tmpdir}/dir1"
    mkdir "${tmpdir}/dir2"
    touch "${tmpdir}/dir1/.DS_Store"
    mkdir "${tmpdir}/dir1/node_modules"
    mkdir "${tmpdir}/dir2/venv"

    # when
    run ${TEST_COMMAND} -f "${tmpdir}/dir1" "${tmpdir}/dir2"

    # then
    [ "${status}" -eq 0 ]
    count_output 3
    count_files 2
    [ -d "${tmpdir}/dir1" ]
    [ -d "${tmpdir}/dir2" ]
    [ ! -e "${tmpdir}/dir1/.DS_Store" ]
    [ ! -e "${tmpdir}/dir1/node_modules" ]
    [ ! -e "${tmpdir}/dir2/venv" ]
}

@test 'Not deleting inside vcs folders' {
    # given
    mkdir "${tmpdir}/.git"
    touch "${tmpdir}/.git/.DS_Store"

    # when
    run ${TEST_COMMAND} -f "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    count_output 0
    count_files 1
    [ -d "${tmpdir}/.git" ]
    [ -f "${tmpdir}/.git/.DS_Store" ]
}
