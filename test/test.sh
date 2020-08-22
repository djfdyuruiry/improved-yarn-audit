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
  excludedAdvisories="3,8,28,29,535,880,1469"

  cd "${scriptPath}"

  rm -f package.json
  rm -f yarn.lock
  rm -f .iyarc

  cp vunerable-package.json package.json
  cp vunerable-yarn.lock yarn.lock

  # test 1
  callIya
  testExitCode "vulnerabilities are present and not excluded" "7" "$?"

  # test 2
  callIya -e "${excludedAdvisories}"
  testExitCode "vulnerabilities are present and they are excluded on the command line" "0" "$?"

  # test 3
  echo "${excludedAdvisories}" > .iyarc

  callIya
  testExitCode "vulnerabilities are present and they are excluded in .iyarc" "0" "$?"

  # test 4
  echo "# excluding 3 because I feel like it, ok?" > .iyarc
  echo "#" >> .iyarc
  echo "##" >> .iyarc
  echo "${excludedAdvisories}" >> .iyarc

  callIya
  testExitCode "they are excluded in .iyarc file with comments" "0" "$?"

  # test 5
  echo "${excludedAdvisories}" > .iyarc

  callIya -e 1469
  testExitCode "vulnerabilities are present and they are excluded in .iyarc but exclusions are in the command line" "6" "$?"

  # test 6
  callIya -i
  testExitCode "dev dependencies flag is present then dev vulnerabilities are ignored" "6" "$?"

  # test 7
  callIya -s moderate
  testExitCode "min severity is moderate" "6" "$?"

  # test 8
  callIya -s high
  testExitCode "min severity is high" "3" "$?"

  # test 9
  callIya -s moderate -e 8,28,29,535,880,1469
  testExitCode "they are excluded on the command line and min severity is moderate" "0" "$?"

  # test 10
  callIya -s high -e 28,29,1469
  testExitCode "they are excluded on the command line and min severity is high" "0" "$?"

  # test 11
  echo "8,28,29,535,880,1469" > .iyarc
  callIya -s moderate
  testExitCode "they are excluded in .iyarc and min severity is moderate" "0" "$?"

  # test 12
  echo "28,29,1469" > .iyarc
  callIya -s high 
  testExitCode "they are excluded in .iyarc and min severity is high" "0" "$?"

  # test 13  
  rm -f package.json
  rm -f yarn.lock

  cp huge-package.json package.json
  cp huge-yarn.lock yarn.lock

  callIya -s high -e 1213,1550
  testExitCode "the package JSON has a large number of dependencies" "0" "$?"

  rm -f package.json
  rm -f yarn.lock

  cp vunerable-package.json package.json
  cp vunerable-yarn.lock yarn.lock

  # test 14
  callIya -e "${excludedAdvisories},9999,1234"
  testExitCode "some of the exclusions passed via cli are missing" "0" "$?"

  # test 15
  echo "${excludedAdvisories},9999" > .iyarc

  callIya
  testExitCode "some of the exclusions passed via .iyarc are missing" "0" "$?"

  # test 16

  callIya -e "${excludedAdvisories},1234,9999" -f
  testExitCode "some of the exclusions passed via cli are missing and --fail-on-missing-exclusions is passed" "2" "$?"

  # test 17
  echo "${excludedAdvisories},1234" > .iyarc

  callIya -f
  testExitCode "some of the exclusions passed via .iyarc are missing and --fail-on-missing-exclusions is passed" "1" "$?"

  # test 18
  expectedVersion=$(echo $(grep '"version": ' ../package.json | cut -d '"' -f 4))

  outputVersion=$(callIya -v 2>&1)
  testExitCode "--version is passed" "1" "$?"

  if [ "${outputVersion}" != "${expectedVersion}" ]; then
    echo "TEST FAILURE: Incorrect version was output: ${outputVersion} - Expected: ${expectedVersion}"
    testFailed=true
  fi

  # test 19
  callIya -h
  testExitCode "--help is passed" "1" "$?"

  # test 20
  callIya -d
  testExitCode "--debug is passed" "7" "$?"

  #test 21
  echo "#" > .iyarc
  callIya
  testExitCode ".iyarc contains no exclusions" "7" "$?"
}

runTests

if [ "${testFailed}" == true ]; then
  echo "Test Result: FAILURE"
  echo "There were test failures"

  exit 1
else
  echo "Test Result: PASS"
fi
