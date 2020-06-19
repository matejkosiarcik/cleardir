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

@test 'Running without mode' {
    run ${TEST_COMMAND}
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]
}

@test 'Running with both -f/-n' {
    run ${TEST_COMMAND} -f -n
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]

    run ${TEST_COMMAND} --force -n
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]

    run ${TEST_COMMAND} --dry-run -f
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]


    run ${TEST_COMMAND} --dry-run --force
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]
}

@test 'Unknown arguments' {
    run ${TEST_COMMAND} --foo
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]

    run ${TEST_COMMAND} -x
    [ "${status}" -ne 0 ]
    [ "${output}" != '' ]
}
