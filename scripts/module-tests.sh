#!/usr/bin/env bash

# this script is used by Github CI to tranverse all modules an run module tests.
# the script expects a diff to be generated in order to skip some modules.

# Executes go module tests and merges the coverage profile.
# If GIT_DIFF variable is set then it's used to test if a module has any file changes - if
# it doesn't have any file changes then we will ignore the module tests.
execute_mod_tests() {
    go_mod=$1;
    mod_dir=$(dirname "$go_mod");
    root_dir=$(pwd);

    # mod_in_dir=$(grep $mod_dir <<< $GIT_DIFF);
    # if [ -n "$GIT_DIFF" -a -z "$mod_in_dir" ]; then
    # TODO: in the future we will need to disable it once we go into multi module setup, because
    # we will have cross module dependencies.
    if [ -n "$GIT_DIFF" ] && ! grep $mod_dir <<< $GIT_DIFF; then
        echo "ignoring module $mod_dir - no changes in the module";
        return;
    fi;

    echo "executing $go_mod tests"
    cd $mod_dir;
    go test -mod=readonly -timeout 30m -coverprofile=${root_dir}/${coverage_file}.tmp -covermode=atomic -tags='norace ledger test_ledger_mock'  ./...
    cd -;
    # strip mode statement
    tail -n +1 ${coverage_file}.tmp >> ${coverage_file}
    rm ${coverage_file}.tmp;
}

#GIT_DIFF=`git status --porcelain`
echo "GIT DIFF:" ${GIT_DIFF}

coverage_file=coverage-go-submod-profile.out

for f in $(find -name go.mod -not -path "./go.mod"); do
    execute_mod_tests $f;
done
