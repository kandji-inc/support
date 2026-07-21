# IruPrep Enrollment Compatibility Utility

**Version:** v1.5

This is a pre-enrollment diagnostic tool for Windows devices. Run checks before enrollment to confirm requirements, network access, and common migration blockers, so you can resolve issues on the device instead of troubleshooting after a failed enrollment.

---

## About

Windows enrollment depends on OS version, edition, permissions, network paths, and a clean MDM state on the device. When something is missing or left over from a previous MDM, enrollment can fail with generic Windows error codes that are hard to interpret.

Iru enrollment requirements are documented in [Device requirements](https://docs.iru.com/en/iru/requirements/device-requirements#windows) and related articles. **IruPrep Enrollment Compatibility Utility** runs those checks locally in a few minutes and reports clear pass/fail results with guidance, so you can fix problems before opening the enrollment portal or contacting support.

---

## What IruPrep does

**IruPrep Enrollment Compatibility Utility** (`IruPrep.ps1`) automates pre-enrollment checks aligned with Iru documentation and common issues seen during MDM migrations. It surfaces problems before you enroll, with actionable output for IT staff and end users.

The script uses a native Windows Form UI: no additional dependencies required, only the `.ps1` file and branding assets.

---

## Features

- ✅ Checks enrollment prerequisites aligned with current Iru documentation  
- ✅ Detects stale registry keys from previous MDM migrations that can block enrollment  
- ✅ Simple Windows Forms UI built on native PowerShell; no external installs needed  
- ✅ Region selection and subdomain entry via guided form inputs  
- ✅ Optional UUID entry for device-specific checks  
- ✅ Exports results to a shareable HTML report if you need to share context with Iru Support

---

## Requirements

| Requirement | Details |
| :---- | :---- |
| OS | [Windows 11 24H2 and higher (Pro, Pro Education, Enterprise, Education)](https://docs.iru.com/en/iru/requirements/device-requirements#windows) |
| PowerShell | 5.1 (does not support PowerShell 7+) |
| Permissions | Standard user (some checks may require local admin) |
| Dependencies | None (Windows Forms is built into Windows) |

---

## Usage

1. Download `IruPrep.ps1`, `iru-logo.png`, and `iru.ico` into the same folder on the target device.  
2. Open **Windows PowerShell** 5.1 (does not support PowerShell 7+). 
3. Go to the folder where `IruPrep.ps1` is saved:

```powershell
cd "FULL\PATH\TO\FOLDER_WITH_THE_SCRIPT"
```

4. In that same window, run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\IruPrep.ps1"
```

Runs IruPrep in a separate process with bypass enabled only for that run. Your open window, registry policy, and other scripts are unchanged.

5. In the form that opens:  
   - Select your **region**  
   - Enter your **subdomain**  
   - Optionally enter a **device UUID**  
6. Click **Run Checks** to execute all diagnostic tests.  
7. Review the results in the UI. Failed checks include guidance on what to change before you enroll.

---

## Output

You can export results as an **HTML report** when you want a record of the run or need to share details with Iru Support:

- Click **Export HTML** after checks complete  
- Share the generated `.html` file through your usual support channel  
- The report includes all check results, detected issues, and system context

---

## Notes

- IruPrep checks reflect the same requirements described in Iru enrollment documentation. Update the script when documentation changes so checks stay in sync.  
- Registry checks include known stale keys from common MDM migration paths. These are not always called out in public docs but can prevent enrollment until they are removed.
