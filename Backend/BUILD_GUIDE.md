# Billing & Sales System — EXE Build Guide

This guide walks you through packaging the Django backend into a standalone
`BillingServer.exe` that can be deployed to any Windows machine **without
requiring Python or any other dependencies to be pre-installed**.

---

## Prerequisites (Build Machine Only)

| Requirement | Notes |
|---|---|
| Windows 10 / 11 | 64-bit recommended |
| Python 3.10+ | [python.org](https://www.python.org/downloads/) — add to PATH |
| MySQL 8+ | Must be running so Django checks can connect |
| MySQL C headers | Needed by `mysqlclient`; included when you install **MySQL Connector C** or the full MySQL Server dev package |
| Internet access | Required once to download packages |

---

## Step-by-Step Build Instructions

### Step 1 — Open a Command Prompt in the Backend folder

```
cd /d "D:\Freelance\Billing And Sales System\Backend"
```

> You can also **double-click** `build_exe.bat` directly from File Explorer.

---

### Step 2 — Create and activate a virtual environment

```bat
python -m venv env
call env\Scripts\activate
```

You only need to do this **once**. The `build_exe.bat` script will
automatically activate `env\` on every subsequent run.

---

### Step 3 — Install all dependencies

```bat
pip install -r requirements.txt
```

This installs Django, Django REST Framework, mysqlclient, PyInstaller,
pystray, Pillow, and all other required packages into the virtual environment.

---

### Step 4 — Ensure MySQL is running and the database exists

Open MySQL and run:

```sql
CREATE DATABASE IF NOT EXISTS pos_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

The build script runs Django's `manage.py check`, which needs a live
database connection to succeed.

---

### Step 5 — Run the build script

```bat
build_exe.bat
```

The script executes the following 7 stages automatically:

| Stage | What it does |
|---|---|
| **1 / 7** | Activates `env\` virtual environment |
| **2 / 7** | Runs `pip install -r requirements.txt` to ensure deps are current |
| **3 / 7** | Runs `python manage.py check` to validate the Django project |
| **4 / 7** | Kills any running `BillingServer.exe` and removes stale build artefacts |
| **5 / 7** | Runs **PyInstaller** with `django_app.spec` to produce `dist\BillingServer.exe` |
| **6 / 7** | Copies `media\` next to the exe (product images are NOT bundled inside) |
| **7 / 7** | Prints the distribution summary |

Build time is typically **3 – 8 minutes** depending on machine speed.

---

### Step 6 — Check the output

After a successful build you will find:

```
Backend\
└── dist\
    ├── BillingServer.exe    ← the server executable (~40–60 MB)
    └── media\               ← product image folder (ship alongside exe)
```

---

## Distributing to a Client / End-User Machine

### What to send

Copy the entire `dist\` folder to the target machine:

```
dist\
├── BillingServer.exe
└── media\
    └── product_images\
```

### Target machine setup

1. **Install MySQL 8+** — [mysql.com](https://dev.mysql.com/downloads/installer/)
2. **Start the MySQL service**
3. **Create the database**:
   ```sql
   CREATE DATABASE pos_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```
4. Place `BillingServer.exe` and the `media\` folder in the **same directory**
5. **Double-click `BillingServer.exe`**

The server will:
- Run database migrations automatically on first launch
- Start listening on `http://0.0.0.0:8000`
- Show a tray icon (teal **B** icon) in the Windows system tray

### Tray icon menu

Right-click the tray icon to access:

| Option | Action |
|---|---|
| Open Admin Panel | Opens `http://localhost:8000/admin/` in the default browser |
| Open Log File | Opens `billing_server.log` in Notepad |
| Exit | Stops the server gracefully |

---

## API Endpoints

| Endpoint | Description |
|---|---|
| `http://localhost:8000/admin/` | Django admin panel |
| `http://localhost:8000/api/` | REST API base |
| `http://localhost:8000/api/categories/` | Categories |
| `http://localhost:8000/api/products/` | Products |
| `http://localhost:8000/api/orders/` | Orders |
| `http://localhost:8000/api/dashboard/` | Dashboard data |

---

## Log File

All server output (startup messages, errors, migrations) is written to:

```
billing_server.log   (same folder as BillingServer.exe)
```

Check this file first when troubleshooting.

---

## Troubleshooting

### "Django check failed" during build

- Make sure MySQL is running
- Verify the database `pos_db` exists
- Confirm `Main/settings.py` has the correct `PASSWORD` for your MySQL root user

### "pip install failed"

- Check your internet connection
- If `mysqlclient` fails to compile, install **MySQL Connector C** first:
  `https://dev.mysql.com/downloads/connector/c/`
- Or install a pre-compiled wheel: `pip install mysqlclient --only-binary :all:`

### "PyInstaller failed"

- Read the full PyInstaller output in the terminal
- A missing hidden import is the most common cause — add it to the
  `app_hidden` list in `django_app.spec`

### Antivirus blocking the exe

- Some antivirus products flag freshly built PyInstaller executables as
  false positives. Add an exclusion for `dist\BillingServer.exe`.

### Port 8000 already in use

- Find and stop the conflicting process:
  ```bat
  netstat -ano | findstr :8000
  taskkill /F /PID <PID>
  ```

---

## Re-building After Code Changes

Just re-run `build_exe.bat`. The script cleans old artefacts automatically.
No need to delete `dist\` or `build\` manually.

---

## Project Files Created for the Build

| File | Purpose |
|---|---|
| `django_app.py` | PyInstaller entry point — launches Django with tray icon |
| `django_app.spec` | PyInstaller configuration (apps, hidden imports, output name) |
| `build_exe.bat` | One-click build script |
| `requirements.txt` | Python package list for the build environment |
| `BUILD_GUIDE.md` | This document |
