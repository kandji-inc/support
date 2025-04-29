# monitor-power-assertions

This script checks for long-lived power management assertions on macOS that may prevent the system from entering idle sleep or starting the screensaver. If any assertion exceeds a specified time threshold, the script can either report it or attempt to terminate the owning process, depending on configuration. It is especially useful for detecting misbehaving apps (such as Adobe CEPHtmlEngine) that silently keep the system awake.

By default, the script only reports offending processes. When configured to `kill`, the script will automatically terminate long-lived assertion holders **only if they are owned by real user accounts** (not system or service users).

## Features

- Monitors `pmset -g assertions` for active power management assertions.
- Parses and calculates assertion lifetimes.
- Supports two modes:
  - **report**: Print details and exit with status `2` if any assertion exceeds the threshold.
  - **kill**: Attempt to terminate offending processes (only those owned by non-system users).
- Verifies if the assertion is successfully cleared after termination.
- Uses only native Zsh and POSIX tools (`pmset`, `ps`, `grep`, `sed`).

## Prerequisites

- macOS 11 or later
- A way to deploy and run this script regularly, Kandji Custom Script Library Item, Jamf Pro Policy, etc 

## Configure the Script

1. Open the script in a text editor (e.g., BBEdit, VSCode).
2. Adjust the top-level configuration options:

    ```zsh
    # Maximum allowed assertion age (in hours)
    notToExceedHours="5"

    # Set to "report" or "kill"
    killOrReport="report"
    ```

3. Save and close the script.

## Local Usage

1. Make the script executable:

    ```bash
    chmod +x monitor-power-assertions.zsh
    ```

2. Run it from the command line:

    ```bash
    ./monitor-power-assertions.zsh
    ```

3. Interpret exit codes:
    - `0`: No long-lived assertions found
    - `2`: One or more assertions exceeded the threshold (and were reported or killed)

## Example Output

```text
Script is set to kill power assertions lived for more than 5 hours.
Assertion too long lived by process: CEPHtmlEngine (PID: 54064) - Uptime 170h 43m 6s
Killing process CEPHtmlEngine (PID: 54064) owned by user nick...
SUCCESS: Assertion by CEPHtmlEngine cleared after killing PID 54064.
One or more long lived assertions detected.
```

```text 
Script is set to kill power assertions lived for more than 5 hours.
Assertion too long lived by process: CEPHtmlEngine (PID: 54064) - Uptime 171h 05m 17s
Killing process CEPHtmlEngine (PID: 54064) owned by user nick...
SUCCESS: Assertion by CEPHtmlEngine cleared after killing PID 54064.
One or more long lived assertions detected.
```

```text
Script is set to kill power assertions lived for more than 5 hours.
Assertion too long lived by process: CEPHtmlEngine (PID: 54064) - Uptime 171h 05m 03s
Killing process CEPHtmlEngine (PID: 54064) owned by user nick...
WARNING: Assertion still held by process name CEPHtmlEngine even after killing PID 54064.
One or more long lived assertions detected.
```
