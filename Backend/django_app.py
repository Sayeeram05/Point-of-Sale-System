"""
Billing & Sales System Server Launcher
=======================================
Single-file entry point for the PyInstaller-packaged Django server.

Behaviour when running as .exe
-------------------------------
- Resolves all paths relative to the folder that contains the .exe
- Redirects stdout / stderr to  billing_server.log  (next to the .exe)
- Runs `migrate` at startup (safe / idempotent)
- Starts the ASGI server on 0.0.0.0:8001 in a background thread using Daphne when available
- Shows a Windows system-tray icon (pystray) so the user can see the server
  is running and can open the admin panel or shut down cleanly
"""

import importlib
import os
import sys
import threading
import logging
import webbrowser

# ---------------------------------------------------------------------------
# 1. Resolve base directory  (works for both script and frozen .exe)
# ---------------------------------------------------------------------------
if getattr(sys, 'frozen', False):
    EXE_DIR = os.path.dirname(sys.executable)
    # PyInstaller unpacks the bundle to a temp folder accessible via _MEIPASS.
    # We add _MEIPASS to sys.path so Django can find its own internal packages.
    if hasattr(sys, '_MEIPASS'):
        if sys._MEIPASS not in sys.path:
            sys.path.insert(0, sys._MEIPASS)
    # When the .exe lives inside a 'dist' subfolder, use the *parent* as the
    # data root so that MEDIA_ROOT and the DB path resolve to the same location
    # used by the development server.
    _parent = os.path.dirname(EXE_DIR)
    if os.path.basename(EXE_DIR).lower() == 'dist' and os.path.isdir(_parent):
        DATA_DIR = _parent
    else:
        DATA_DIR = EXE_DIR
    BASE_DIR = EXE_DIR
else:
    EXE_DIR = os.path.dirname(os.path.abspath(__file__))
    DATA_DIR = EXE_DIR
    BASE_DIR = EXE_DIR

os.chdir(BASE_DIR)
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

# Expose DATA_DIR to Django settings so MEDIA_ROOT resolves correctly.
os.environ['BSS_BASE_DIR'] = DATA_DIR

# ---------------------------------------------------------------------------
# 2. Set up file logging (critical for windowed exe — no console output)
# ---------------------------------------------------------------------------
LOG_FILE = os.path.join(BASE_DIR, 'billing_server.log')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s  %(levelname)-8s  %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
    ],
)

# Redirect bare print / Django's stdout to the log file
log_file_handle = open(LOG_FILE, 'a', encoding='utf-8', buffering=1)
sys.stdout = log_file_handle
sys.stderr = log_file_handle

logger = logging.getLogger('billing')

# ---------------------------------------------------------------------------
# 3. Django environment setup
# ---------------------------------------------------------------------------
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Main.settings')

# PyMySQL acts as a drop-in replacement for mysqlclient (pure Python, no C build needed)
import pymysql  # noqa: E402
pymysql.install_as_MySQLdb()

import django  # noqa: E402
from django.core.management import execute_from_command_line  # noqa: E402

def run_migrations():
    """Apply any pending database migrations.  Safe to call on every startup."""
    try:
        logger.info("Running database migrations ...")
        execute_from_command_line(['manage.py', 'migrate', '--run-syncdb'])
        logger.info("Migrations complete.")
    except Exception as exc:
        logger.error("Migration error: %s", exc)

def run_server():
    """Start ASGI/Daphne server in a daemon thread."""
    try:
        if importlib.util.find_spec('daphne') is not None:
            logger.info("Starting Daphne ASGI server on 0.0.0.0:8001 ...")
            execute_from_command_line([
                'manage.py',
                'runserver',
                '0.0.0.0:8001',
                '--noreload',
            ])
        else:
            logger.info("Daphne not available, falling back to Django runserver.")
            execute_from_command_line([
                'manage.py',
                'runserver',
                '0.0.0.0:8001',
                '--noreload',
            ])
    except Exception as exc:
        logger.error("Server error: %s", exc)

# ---------------------------------------------------------------------------
# 4. Build the tray icon image dynamically (no external .ico file needed)
# ---------------------------------------------------------------------------
def _make_tray_image():
    """Create a simple coloured square as the tray icon via Pillow."""
    from PIL import Image, ImageDraw
    img = Image.new('RGBA', (64, 64), color=(0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Teal circle background
    draw.ellipse([2, 2, 62, 62], fill=(0, 150, 136), outline=(0, 105, 92), width=3)
    # White 'B' letter in the centre
    try:
        from PIL import ImageFont
        font = ImageFont.truetype("arial.ttf", 36)
    except Exception:
        font = ImageFont.load_default()
    draw.text((18, 10), "B", fill=(255, 255, 255), font=font)
    return img

# ---------------------------------------------------------------------------
# 5. System-tray icon (pystray)
# ---------------------------------------------------------------------------
def start_tray(stop_event: threading.Event):
    """Create and run the system-tray icon.  Blocks until the user clicks Exit."""
    try:
        import pystray
        from pystray import MenuItem, Menu

        icon_image = _make_tray_image()

        def on_open_admin(icon, item):
            webbrowser.open('http://localhost:8001/admin/')

        def on_open_log(icon, item):
            os.startfile(LOG_FILE)

        def on_exit(icon, item):
            logger.info("Exit requested from tray menu.")
            icon.stop()
            stop_event.set()
            # Force-kill the process after giving Django a moment to clean up
            threading.Timer(2.0, lambda: os._exit(0)).start()

        menu = Menu(
            MenuItem('Billing & Sales Server  |  port 8001', None, enabled=False),
            Menu.SEPARATOR,
            MenuItem('Open Admin Panel', on_open_admin),
            MenuItem('Open Log File',    on_open_log),
            Menu.SEPARATOR,
            MenuItem('Exit', on_exit),
        )

        icon = pystray.Icon(
            name='BillingServer',
            icon=icon_image,
            title='Billing & Sales Server (port 8001)',
            menu=menu,
        )
        logger.info("System tray icon started.")
        icon.run()

    except Exception as exc:
        # pystray not available — fall back to a blocking wait so the process stays alive
        logger.warning("Tray icon unavailable (%s). Server running. Close this process to stop.", exc)
        stop_event.wait()

# ---------------------------------------------------------------------------
# 6. Main entry point
# ---------------------------------------------------------------------------
def main():
    logger.info("=" * 60)
    logger.info("Billing & Sales System Server starting up ...")
    logger.info("Exe  directory : %s", BASE_DIR)
    logger.info("Data directory : %s", DATA_DIR)
    logger.info("Log file       : %s", LOG_FILE)
    logger.info("=" * 60)

    # Initialise Django (settings, apps registry, etc.)
    try:
        django.setup()
        logger.info("Django initialised successfully.")
    except Exception as exc:
        logger.critical("Django setup failed: %s", exc)
        return

    # Run migrations
    run_migrations()

    # Start the server in a background daemon thread
    stop_event = threading.Event()
    server_thread = threading.Thread(target=run_server, daemon=True, name='DjangoServer')
    server_thread.start()
    logger.info("Server thread started.")

    # Block on the tray icon (returns only when user clicks Exit)
    start_tray(stop_event)


if __name__ == '__main__':
    main()