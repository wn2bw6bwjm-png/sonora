#!/usr/bin/env python3
"""Настройка платформенных файлов после `flutter create`:
интернет (обложки по ссылке) и фоновое воспроизведение аудио.
Идемпотентен: можно запускать повторно. Запускать из корня проекта."""
import glob
import plistlib
import re

changed = []

PERMS = ['INTERNET', 'WAKE_LOCK', 'FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_MEDIA_PLAYBACK']
SERVICES = '''
        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
    '''


def edit(path, fn):
    with open(path, encoding='utf-8') as f:
        s = f.read()
    n = fn(s)
    if n != s:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(n)
        changed.append(path)


def manifest(s):
    add = ''.join(
        f'\n    <uses-permission android:name="android.permission.{p}"/>'
        for p in PERMS
        if f'android.permission.{p}"' not in s
    )
    if add:
        s = re.sub(r'(<manifest[^>]*>)', lambda m: m.group(1) + add, s, count=1)
    if 'com.ryanheise.audioservice.AudioService' not in s:
        s = s.replace('</application>', SERVICES + '</application>', 1)
    return s


def activity(s):
    return (s.replace('io.flutter.embedding.android.FlutterActivity',
                      'com.ryanheise.audioservice.AudioServiceActivity')
             .replace(': FlutterActivity()', ': AudioServiceActivity()'))


for p in glob.glob('android/app/src/main/AndroidManifest.xml'):
    edit(p, manifest)
for p in glob.glob('android/app/src/main/**/MainActivity.kt', recursive=True):
    edit(p, activity)

for p in glob.glob('ios/Runner/Info.plist'):
    with open(p, 'rb') as f:
        d = plistlib.load(f)
    modes = list(d.get('UIBackgroundModes', []))
    if 'audio' not in modes:
        d['UIBackgroundModes'] = modes + ['audio']
        with open(p, 'wb') as f:
            plistlib.dump(d, f)
        changed.append(p)

print('configured:', changed or 'nothing to change')
