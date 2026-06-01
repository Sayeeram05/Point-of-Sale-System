# -*- mode: python ; coding: utf-8 -*-
"""
PyInstaller spec for BillingServer.exe
=======================================
Produces a single windowed .exe (no console window).
The system-tray icon is provided by pystray + Pillow.

Target:   dist/BillingServer.exe
Requires: pyinstaller, pystray, pillow  (see build_exe.bat)
"""

import os
from PyInstaller.utils.hooks import (
    collect_data_files,
    collect_submodules,
    collect_dynamic_libs,
)

# ---------------------------------------------------------------------------
# Data files  (templates, static assets, migration files, etc.)
# NOTE: media/ is intentionally excluded — it must sit NEXT TO the .exe
#       on the target machine and should never be bundled inside the archive.
# ---------------------------------------------------------------------------
django_datas       = collect_data_files('django')
drf_datas          = collect_data_files('rest_framework')
corsheaders_datas  = collect_data_files('corsheaders')

app_datas = [
    ('manage.py',    '.'),
    ('Main/',        'Main/'),
    ('Category/',    'Category/'),
    ('Product/',     'Product/'),
    ('Order/',       'Order/'),
    ('Auxiliary/',   'Auxiliary/'),
    ('Dashboard/',   'Dashboard/'),
]

# ---------------------------------------------------------------------------
# Hidden imports
# ---------------------------------------------------------------------------
django_hidden       = collect_submodules('django')
drf_hidden          = collect_submodules('rest_framework')
corsheaders_hidden  = collect_submodules('corsheaders')
pystray_hidden      = collect_submodules('pystray')
pil_hidden          = collect_submodules('PIL')

app_hidden = [
    # Main project package
    'Main', 'Main.settings', 'Main.urls',
    'Main.wsgi', 'Main.asgi',
    # Category app
    'Category', 'Category.models', 'Category.views',
    'Category.admin', 'Category.apps', 'Category.urls',
    'Category.serializers', 'Category.migrations',
    # Product app
    'Product', 'Product.models', 'Product.views',
    'Product.admin', 'Product.apps', 'Product.urls',
    'Product.serializers', 'Product.migrations',
    # Order app
    'Order', 'Order.models', 'Order.views',
    'Order.admin', 'Order.apps', 'Order.urls',
    'Order.serializers', 'Order.migrations',
    # Auxiliary app
    'Auxiliary', 'Auxiliary.models', 'Auxiliary.views',
    'Auxiliary.admin', 'Auxiliary.apps', 'Auxiliary.urls',
    'Auxiliary.serializers', 'Auxiliary.migrations',
    # Dashboard app
    'Dashboard', 'Dashboard.models', 'Dashboard.views',
    'Dashboard.admin', 'Dashboard.apps', 'Dashboard.urls',
]

db_hidden = [
    'MySQLdb',
    'MySQLdb._mysql',
    'MySQLdb.connections',
    'MySQLdb.cursors',
    'MySQLdb.converters',
    'MySQLdb.constants',
    'MySQLdb.times',
    'MySQLdb.charset',
    'MySQLdb.release',
]

misc_hidden = [
    'decimal', 'uuid', 'datetime', 'json', 'logging',
    'threading', 'webbrowser', 'email.mime.text',
    'email.mime.multipart', 'email.mime.base',
    'encodings.utf_8', 'encodings.ascii',
]

all_hidden = (
    django_hidden + drf_hidden + corsheaders_hidden +
    pystray_hidden + pil_hidden +
    app_hidden + db_hidden + misc_hidden
)

# ---------------------------------------------------------------------------
# Binaries  (mysqlclient .pyd / .dll)
# ---------------------------------------------------------------------------
try:
    mysql_binaries = collect_dynamic_libs('MySQLdb')
except Exception:
    mysql_binaries = []

# Ensure the _mysql .pyd is included even if collect_dynamic_libs misses it
import glob
_site_pkg = os.path.join(os.path.dirname(os.path.abspath('.')), 'env', 'Lib', 'site-packages')
_mysql_pyds = glob.glob(os.path.join(_site_pkg, 'MySQLdb', '_mysql*.pyd'))
for _pyd in _mysql_pyds:
    _dest = os.path.join('MySQLdb', os.path.basename(_pyd))
    if (_pyd, _dest) not in mysql_binaries:
        mysql_binaries.append((_pyd, 'MySQLdb'))

# ---------------------------------------------------------------------------
# Analysis
# ---------------------------------------------------------------------------
a = Analysis(
    ['django_app.py'],
    pathex=[],
    binaries=mysql_binaries,
    datas=(
        django_datas +
        drf_datas +
        corsheaders_datas +
        app_datas
    ),
    hiddenimports=all_hidden,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'tkinter',
        'turtle',
        'matplotlib',
        'numpy',
        'pandas',
        'scipy',
        'IPython',
        'notebook',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='BillingServer',          # output:  dist\BillingServer.exe
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,                  # no terminal window — tray icon only
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,                      # optional: set to 'icon.ico' path if you add one
)
