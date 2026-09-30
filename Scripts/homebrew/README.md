# Homebrew

Scripts for installing Homebrew and for auditing whether it is installed.

Add these scripts in a Custom Script Library Item on a Mac. For execution frequency, the audit script, and the remediation script, see [Custom Scripts Overview](https://docs.iru.com/en/endpoint/library/library-items-profiles/custom-scripts-overview#mac).

## Tested versions of macOS

These scripts were tested on the following versions of macOS:

- macOS Golden Gate 27
- macOS Tahoe 26
- macOS Sequoia 15

## homebrew_install.zsh

### Installation

Silently installs the latest stable Homebrew release for the user who is logged in. If no one is logged in, it uses the most-used local account with a user ID of 501 or higher. Run it as root. It can run every 15 minutes or once a day so Homebrew stays installed and up to date.

### Install method

Mac computers with Apple silicon running macOS Sequoia 15 or later use Homebrew's signed package. Earlier versions of macOS on Apple silicon, and Intel-based Mac computers, use a Git checkout. An existing installation that has no Git repository, such as one created from a tarball, is repaired in place and then updated.

Intel-based Mac computers are a Homebrew Tier 3 configuration and may need to build some formulae from source. Homebrew plans to end support for Intel-based Mac computers in or after September 2027. See [Homebrew support tiers](https://docs.brew.sh/Support-Tiers).

### PATH

On a Mac with Apple silicon, `/etc/paths.d/homebrew` makes `brew` available to new shells. A shell that is already open will not see that change until it is restarted. On an Intel-based Mac, `/usr/local/bin` is already on PATH.

### Source

Adapted in part from [homebrew-3.3.sh](https://github.com/Honestpuck/homebrew.sh/blob/master/homebrew-3.3.sh) by Tony Williams.

### Audit and remediation

Add `homebrew_audit.zsh` as the **Audit Script** in a Custom Script Library Item, and add this script as the **Remediation Script** when `PASS_WHEN` is set to `"installed"`.

### Skip a new installation

If `/etc/homebrew/brew.no_install` exists, a new installation is skipped.

## homebrew_audit.zsh

Checks whether Homebrew is installed and reports the installed version. Before you add it as the **Audit Script**, set `PASS_WHEN` near the top of the script:

- `"installed"`: The audit reports **Pass** when Homebrew is installed and reports its version. It reports **Error** when Homebrew is not installed, or when its version cannot be read. To install Homebrew when it is missing, add `homebrew_install.zsh` as the **Remediation Script**.
- `"not_installed"`: The audit reports **Pass** when Homebrew is not installed, and **Error** when it is.

An **Error** generates an alert. If you add a **Remediation Script**, it runs when the audit reports **Error**.

Homebrew counts as installed when `brew` is executable at any of these paths:

- `/opt/homebrew/bin/brew` (signed package, and a current Git install on a Mac with Apple silicon)
- `/opt/homebrew/Homebrew/bin/brew` (older Git install on a Mac with Apple silicon, including when the symlink is missing)
- `/usr/local/bin/brew` (Intel-based Mac, including an older tarball install)
- `/usr/local/Homebrew/bin/brew` (Intel-based Mac when the symlink is missing)
