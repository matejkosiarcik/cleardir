#!/usr/bin/env bats

load './helpers'
# TODO: simplify file checking with bats libraries (bats-file/bats-support/bats-assert)
# TODO: update bats

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
    grep -i 'usage: cleardir' <<<"${output}"

    run ${TEST_COMMAND} --help
    [ "${status}" -eq 0 ]
    [ "${output}" != '' ]
    grep -i usage <<<"${output}"
    grep -i 'usage: cleardir' <<<"${output}"
}

@test 'Running without -f/-n' {
    tmpdir="$(mktemp -d)"
    run ${TEST_COMMAND} "${tmpdir}"
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]
}

@test 'Running with both -f/-n' {
    tmpdir="$(mktemp -d)"
    run ${TEST_COMMAND} -f -n "${tmpdir}"
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]

    run ${TEST_COMMAND} -n -f "${tmpdir}"
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]

    run ${TEST_COMMAND} --force -n "${tmpdir}"
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]
}

@test 'Deleting junk files' {
    # given
    tmpdir="$(mktemp -d)"
    touch "${tmpdir}/.DS_Store"
    mkdir "${tmpdir}/node_modules"

    # when
    run ${TEST_COMMAND} --force "${tmpdir}"

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
    run ${TEST_COMMAND} -f "${tmpdir}"

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
    run ${TEST_COMMAND} -f "${tmpdir}"

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

@test 'Not deleting files (interactive - no)' {
    # given
    tmpdir="$(mktemp -d)"
    mkdir "${tmpdir}/node_modules"
    mkdir "${tmpdir}/foo"

    workdir="$(mktemp -d)"
    no_file="${workdir}/yes"
    mkfifo "${no_file}"
    yes n >"${no_file}" &

    # when
    run ${TEST_COMMAND} "${tmpdir}" --interactive <"${no_file}"

    # then
    [ "${status}" -eq 0 ]
    test_output 1
    test_files "${tmpdir}" 2

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Deleting junk files' {
    # given
    tmpdir="$(mktemp -d)"
    touch "${tmpdir}/.DS_Store"
    mkdir "${tmpdir}/node_modules"

    workdir="$(mktemp -d)"
    yes_file="${workdir}/yes"
    mkfifo "${yes_file}"
    yes y >"${yes_file}" &

    # when
    run ${TEST_COMMAND} -i "${tmpdir}" <"${yes_file}"

    # then
    [ "${status}" -eq 0 ]
    test_output 2
    test_files "${tmpdir}" 0

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
    run ${TEST_COMMAND} "${tmpdir}" --force

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
    run ${TEST_COMMAND} -f "${tmpdir}"

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
    run ${TEST_COMMAND} -f "${tmpdir}/.DS_Store"

    # then
    [ "${status}" -eq 0 ]
    test_output 1
    test_files "${tmpdir}" 0

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Not deleting root directory' {
    # given
    tmpdir="$(mktemp -d)"
    mkdir "${tmpdir}/node_modules"

    # when
    run ${TEST_COMMAND} -f "${tmpdir}/node_modules"

    # then
    [ "${status}" -eq 0 ]
    test_output 1
    test_files "${tmpdir}" 0

    # cleanup
    rm -rf "${tmpdir}"
}

@test 'Deleting in multiple directories' {
    # given
    tmpdir="$(mktemp -d)"
    touch "${tmpdir}/.DS_Store"
    tmpdir2="$(mktemp -d)"
    mkdir "${tmpdir2}/node_modules"

    # when
    run ${TEST_COMMAND} -f "${tmpdir}" "${tmpdir2}"

    # then
    [ "${status}" -eq 0 ]
    test_output 2
    test_files "${tmpdir}" 0
    test_files "${tmpdir2}" 0

    # cleanup
    rm -rf "${tmpdir}" "${tmpdir2}"
}

@test 'Not deleting inside vcs folders' {
    # given
    tmpdir="$(mktemp -d)"
    mkdir "${tmpdir}/.git"
    touch "${tmpdir}/.git/.DS_Store"

    # when
    run ${TEST_COMMAND} -f "${tmpdir}"

    # then
    [ "${status}" -eq 0 ]
    test_output 0
    test_files "${tmpdir}" 1
    [ -f "${tmpdir}/.git/.DS_Store" ]

    # cleanup
    rm -rf "${tmpdir}"
}
