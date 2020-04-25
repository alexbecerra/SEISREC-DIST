# -*- mode: python ; coding: utf-8 -*-

block_cipher = None


a = Analysis(['/home/pi/SEISREC-DIST/SEISREC-DEV/modules/station/unit_dyndns-manager/unit_dyndns-manager.py'],
             pathex=['/home/pi/SEISREC-DIST'],
             binaries=[],
             datas=[],
             hiddenimports=['pkg_resources.py2_warn'],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          [],
          name='unit_dyndns-manager',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          upx_exclude=[],
          runtime_tmpdir=None,
          console=True )
