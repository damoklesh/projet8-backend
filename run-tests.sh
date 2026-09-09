#!/usr/bin/env bash

# Unified test runner for Angular and Spring Boot projects.

RESULTS_DIR="test-results"

echo "Cleaning previous test results..."
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

run_backend_tests() {
    echo "Spring Boot / Gradle project detected"

    # Check required dependencies
    if ! command -v java >/dev/null 2>&1; then
        echo "ERROR: Java is not installed or not available in PATH."
        return 2
    fi

    if [ ! -f "./gradlew" ]; then
        echo "ERROR: Gradle wrapper not found."
        return 2
    fi

    echo "Running backend tests..."

    ./gradlew clean test
    TEST_EXIT_CODE=$?

    # Copy JUnit reports even if some tests failed
    if compgen -G "build/test-results/test/*.xml" > /dev/null; then
        cp build/test-results/test/*.xml "$RESULTS_DIR/"
        echo "JUnit reports copied to $RESULTS_DIR/"
    else
        echo "ERROR: No JUnit test report was generated."

        if [ "$TEST_EXIT_CODE" -eq 0 ]; then
            TEST_EXIT_CODE=3
        fi
    fi

    return "$TEST_EXIT_CODE"
}


run_frontend_tests() {
    echo "Angular / npm project detected"

    # Check required dependencies
    if ! command -v npm >/dev/null 2>&1; then
        echo "ERROR: npm is not installed or not available in PATH."
        return 2
    fi

    if [ ! -d "node_modules" ]; then
        echo "ERROR: Node dependencies are not installed."
        echo "Run 'npm ci' before executing the tests."
        return 2
    fi

    # Remove previous Karma reports
    rm -rf reports

    echo "Running frontend tests..."

    npm test
    TEST_EXIT_CODE=$?

    # Copy Karma JUnit reports
    if compgen -G "reports/*.xml" > /dev/null; then
        cp reports/*.xml "$RESULTS_DIR/"
        echo "JUnit reports copied to $RESULTS_DIR/"
    else
        echo "ERROR: No JUnit test report was generated."

        if [ "$TEST_EXIT_CODE" -eq 0 ]; then
            TEST_EXIT_CODE=3
        fi
    fi

    return "$TEST_EXIT_CODE"
}


# Detect project type
if [ -f "gradlew" ] && { [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; }; then

    run_backend_tests
    EXIT_CODE=$?

elif [ -f "package.json" ] && [ -f "angular.json" ]; then

    run_frontend_tests
    EXIT_CODE=$?

else

    echo "ERROR: Unable to detect project type."
    echo "Expected an Angular or Gradle/Spring Boot project."
    EXIT_CODE=2

fi

echo "Test runner finished with exit code: $EXIT_CODE"

exit "$EXIT_CODE"