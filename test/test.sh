#! /usr/bin/env bash
scriptPath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

testFailed=false

testExitCode() {
  expectedExitCode="$2"
  actualExitCode="$3"
  test="When vulnerabilities are present and ${1} then exit code is ${expectedExitCode}"

  printf "\n"

  if [ "${actualExitCode}" -eq "${expectedExitCode}" ]; then
    printf "✔"
  else
    printf "Expected error code: ${expectedExitCode} - Recieved error code: ${actualExitCode}\n"
    printf "✗"

    testFailed=true
  fi

  printf " ${test}\n\n"

  rm -f .iyarc
}

callIya() {
  "${scriptPath}/../bin/improved-yarn-audit" -r "$@"
}

runTests() {
  cd "/tmp"
  rm -rf /tmp/* &> /dev/null || :

  rm -f package.json
  rm -f yarn.lock
  rm -rf .yarn
  rm -rf node_modules
  rm -f .iyarc

  cp "${scriptPath}/vunerable-package.json" package.json
  cp "${scriptPath}/vunerable-yarn.lock" yarn.lock

  yarn install

  # test 1
  callIya
  testExitCode "not excluded" "12" "$?"

  # test 2
  excludedAdvisories=$(<${scriptPath}/mocks/test-2.args)
  callIya -e "${excludedAdvisories}"
  testExitCode "vulnerabilities are present and they are excluded on the command line" "0" "$?"

  # test 3
  touch .iyarc
  cp ${scriptPath}/mocks/test-3.iyarc .iyarc
  callIya
  testExitCode "vulnerabilities are present and they are excluded in .iyarc" "0" "$?"
  rm .iyarc

  # test 4
  touch .iyarc
  cp ${scriptPath}/mocks/test-4.iyarc .iyarc
  callIya
  testExitCode "they are excluded in .iyarc file with comments" "0" "$?"

  # test 5
  rm -f .iyarc
  touch .iyarc
  cp ${scriptPath}/mocks/test-5.iyarc .iyarc
  callIya -e GHSA-3fw8-66wf-pr7m,GHSA-42xw-2xvc-qx8m,GHSA-f9cm-p3w6-xvr3,GHSA-gpvr-g6gh-9mc2
  testExitCode "vulnerabilities are present and they are excluded in .iyarc but exclusions are in the command line" "8" "$?"

  # test 6
  rm -f .iyarc
  touch .iyarc
  cp ${scriptPath}/mocks/test-6.iyarc .iyarc
  callIya -i
  testExitCode "dev dependencies flag is present then dev vulnerabilities are ignored" "9" "$?"

  # test 7
  callIya -s moderate
  testExitCode "min severity is moderate" "11" "$?"

  # test 8
  callIya -s high
  testExitCode "min severity is high" "7" "$?"

  # test 9
  # Moderate values = GHSA-gpvr-g6gh-9mc2,GHSA-wrvr-8mpx-r7pp
  # High Severity values = GHSA-jjv7-qpx3-h62q,GHSA-f9cm-p3w6-xvr3,GHSA-gqgv-6jq5-jjj9,GHSA-42xw-2xvc-qx8m,GHSA-4w2v-q235-vp99,GHSA-cph5-m8f7-6c5x
  callIya -s moderate -e GHSA-gpvr-g6gh-9mc2,GHSA-wrvr-8mpx-r7pp,GHSA-jjv7-qpx3-h62q,GHSA-f9cm-p3w6-xvr3,GHSA-gqgv-6jq5-jjj9,GHSA-42xw-2xvc-qx8m,GHSA-cph5-m8f7-6c5x,GHSA-hrpp-h998-j3pp,GHSA-rch9-xh7r-mqgw,GHSA-4w2v-q235-vp99
  testExitCode "they are excluded on the command line and min severity is moderate" "0" "$?"

  # test 10
  # High Severity values = GHSA-jjv7-qpx3-h62q,GHSA-f9cm-p3w6-xvr3,GHSA-gqgv-6jq5-jjj9,GHSA-42xw-2xvc-qx8m,GHSA-4w2v-q235-vp99,GHSA-cph5-m8f7-6c5x
  callIya -s high -e GHSA-jjv7-qpx3-h62q,GHSA-f9cm-p3w6-xvr3,GHSA-gqgv-6jq5-jjj9,GHSA-42xw-2xvc-qx8m,GHSA-cph5-m8f7-6c5x,GHSA-hrpp-h998-j3pp
  testExitCode "they are excluded on the command line and min severity is high" "0" "$?"

  # test 11
  rm -f .iyarc
  touch .iyarc
  cp ${scriptPath}/mocks/test-11.iyarc .iyarc
  callIya -s moderate
  testExitCode "they are excluded in .iyarc and min severity is moderate" "0" "$?"

  # test 12
  rm -f .iyarc
  touch .iyarc
  cp ${scriptPath}/mocks/test-12.iyarc .iyarc
  callIya -s high
  testExitCode "they are excluded in .iyarc and min severity is high" "0" "$?"

  # test 13
  rm -f package.json
  rm -f yarn.lock
  rm -rf .yarn
  rm -rf node_modules

  cp "${scriptPath}/huge-package.json" package.json
  cp "${scriptPath}/huge-yarn.lock" yarn.lock

  yarn install

  rm -f .iyarc
  touch .iyarc
  cp ${scriptPath}/mocks/test-13.iyarc .iyarc
  callIya -s high
  testExitCode "the package JSON has a large number of dependencies" "0" "$?"

  rm -f package.json
  rm -f yarn.lock
  rm -rf .yarn
  rm -rf node_modules

  cp ${scriptPath}/vunerable-package.json package.json
  cp ${scriptPath}/vunerable-yarn.lock yarn.lock

  yarn install

  # test 14
  excludedAdvisories=$(<${scriptPath}/mocks/test-14.args)
  callIya -e "${excludedAdvisories},9999,1234"
  testExitCode "some of the exclusions passed via cli are missing" "0" "$?"

  # test 15
  rm -f .iyarc
  touch .iyarc
  cp ${scriptPath}/mocks/test-15.iyarc .iyarc
  callIya
  testExitCode "some of the exclusions passed via .iyarc are missing" "0" "$?"

  # test 16
  rm -f .iyarc
  excludedAdvisories=$(<${scriptPath}/mocks/test-16.args)
  callIya -e "${excludedAdvisories}" -f
  testExitCode "some of the exclusions passed via cli are missing and --fail-on-missing-exclusions is passed" "2" "$?"

  # test 17
  rm -f .iyarc
  touch .iyarc
  cp ${scriptPath}/mocks/test-17.iyarc .iyarc
  callIya -f
  testExitCode "some of the exclusions passed via .iyarc are missing and --fail-on-missing-exclusions is passed" "1" "$?"

  # test 18
  expectedVersion=$(echo $(grep '"version": ' "${scriptPath}/../package.json" | cut -d '"' -f 4))

  outputVersion=$(callIya -v 2>&1)
  testExitCode "--version is passed" "1" "$?"

  if [ "${outputVersion}" != "${expectedVersion}" ]; then
    echo "✗ TEST FAILURE: Incorrect version was output: ${outputVersion} - Expected: ${expectedVersion}"
    testFailed=true
  fi

  # test 19
  callIya -h
  testExitCode "--help is passed" "1" "$?"

  # test 20
  callIya -d
  testExitCode "--debug is passed" "12 " "$?"

  # test 21
  rm -f .iyarc
  touch .iyarc
  cp ${scriptPath}/mocks/test-21.iyarc .iyarc
  callIya
  testExitCode ".iyarc contains no exclusions" "12" "$?"
}

runTests

if [ "${testFailed}" == true ]; then
  echo "Test Result: FAILURE"
  echo "There were test failures"

  exit 1
else
  echo "Test Result: PASS"
fi
