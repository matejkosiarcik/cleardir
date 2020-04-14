#!/usr/bin/env bats

load './helpers'

function setup() {
    cd "${BATS_TEST_DIRNAME}/.."
    if [ -z "${TEST_COMMAND+x}" ] || [ "${TEST_COMMAND}" = '' ]; then
        printf 'TEST_COMMAND not specified\n' >&3
        exit 2
    fi
}

@test 'Get help' {
    run ${TEST_COMMAND} -h
    [ "${status}" -eq 0 ]
    [ "${output}" != '' ]
    grep -i usage <<<"${output}"

    run ${TEST_COMMAND} --help
    [ "${status}" -eq 0 ]
    [ "${output}" != '' ]
    grep -i usage <<<"${output}"
}

@test 'Deleting junk files' {
    # given
    tmpdir="$(mktemp -d)"
    touch "${tmpdir}/.DS_Store"
    mkdir "${tmpdir}/node_modules"

    # when
    run ${TEST_COMMAND} "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    test_output 2
    test_files "${tmpdir}" 0

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Not deleting other files' {
    # given
    tmpdir="$(mktemp -d)"
    touch "${tmpdir}/bar"
    mkdir "${tmpdir}/foo"

    # when
    run ${TEST_COMMAND} "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    test_output 0
    test_files "${tmpdir}" 2

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Deleting only junk files' {
    # given
    tmpdir="$(mktemp -d)"
    touch "${tmpdir}/bar"
    mkdir "${tmpdir}/foo"
    touch "${tmpdir}/.DS_Store"
    mkdir "${tmpdir}/node_modules"
    mkdir "${tmpdir}/venv"

    # when
    run ${TEST_COMMAND} "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    test_output 3
    test_files "${tmpdir}" 2

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Not deleting files (dry run)' {
    # given
    tmpdir="$(mktemp -d)"
    mkdir "${tmpdir}/node_modules"
    mkdir "${tmpdir}/foo"

    # when
    run ${TEST_COMMAND} "${tmpdir}" --dry-run

    # then
    [ "${status}" -eq 0 ]
    test_output 1
    test_files "${tmpdir}" 2

    # when
    run ${TEST_COMMAND} -n "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    test_output 1
    test_files "${tmpdir}" 2

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Not looking into nested junk directories' {
    # given
    tmpdir="$(mktemp -d)"
    mkdir "${tmpdir}/node_modules"
    mkdir "${tmpdir}/node_modules/node_modules"

    # when
    run ${TEST_COMMAND} "${tmpdir}" --dry-run

    # then
    [ "${status}" -eq 0 ]
    test_output 1
    test_files "${tmpdir}" 1

    # when
    run ${TEST_COMMAND} "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    test_output 1
    test_files "${tmpdir}" 0

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Deleting nested trees' {
     # given
    tmpdir="$(mktemp -d)"
    mkdir "${tmpdir}/node_modules"
    touch "${tmpdir}/node_modules/.DS_Store"
    mkdir "${tmpdir}/node_modules/node_modules"
    mkdir "${tmpdir}/node_modules/venv"
    touch "${tmpdir}/node_modules/venv/.DS_Store"

    # when
    run ${TEST_COMMAND} "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    test_output 1
    test_files "${tmpdir}" 0

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Deleting input files' {
     # given
    tmpdir="$(mktemp -d)"
    touch "${tmpdir}/.DS_Store"

    # when
    run ${TEST_COMMAND} "${tmpdir}/.DS_Store"

    # then
    [ "${status}" -eq 0 ]
    test_output 1
    test_files "${tmpdir}" 0

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Deleting multiple input directories' {
     # given
    tmpdir="$(mktemp -d)"
    touch "${tmpdir}/.DS_Store"
    tmpdir2="$(mktemp -d)"
    mkdir "${tmpdir2}/node_modules"

    # when
    run ${TEST_COMMAND} "${tmpdir}" "${tmpdir2}"

    # then
    echo "${output}" >&3
    [ "${status}" -eq 0 ]
    test_output 2
    test_files "${tmpdir}" 0
    test_files "${tmpdir2}" 0

    # cleanup
    rm -rf "${tmpdir}" "${tmpdir2}"
}
