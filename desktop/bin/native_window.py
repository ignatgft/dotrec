"""
DotRec Link Desktop — Native Window Shell (Windows x64)
Native desktop window with Microsoft Edge WebView2 hardware acceleration.
Zero browser chrome (no tabs, no URL bar, no bookmarks, no devtools).
Authentic Nothing OS Aesthetic.
"""
import sys
import os
import time
import subprocess
import urllib.request
import webview

def is_server_running(port=48212):
    try:
        with urllib.request.urlopen(f'http://127.0.0.1:{port}/api/status', timeout=0.8) as resp:
            return resp.status == 200
    except Exception:
        return False

def start_backend_if_needed():
    if is_server_running(48212):
        return None
    
    # Candidate backend executables
    candidates = [
        os.path.join(os.path.dirname(__file__), 'dotrec-link.exe'),
        os.path.join(os.path.dirname(__file__), '..', 'build', 'dist', 'DotRec-Link-v1.0.0-windows-x64', 'dotrec-link.exe'),
        'dotrec-link.exe',
    ]
    for c in candidates:
        if os.path.exists(c):
            return subprocess.Popen([c], creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
    
    # Fallback to dart run bin/dotrec_link.dart if in dev workspace
    dart_script = os.path.join(os.path.dirname(__file__), 'dotrec_link.dart')
    if os.path.exists(dart_script):
        dart_exe = r'D:\flutter\bin\cache\dart-sdk\bin\dart.exe'
        if not os.path.exists(dart_exe):
            dart_exe = 'dart'
        return subprocess.Popen([dart_exe, 'run', dart_script], cwd=os.path.dirname(os.path.dirname(dart_script)), creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
    
    return None

def main():
    target_url = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:48212'
    
    backend_proc = start_backend_if_needed()
    if backend_proc:
        for _ in range(30):
            if is_server_running(48212):
                break
            time.sleep(0.1)

    # Custom Nothing OS title
    title = '● DOTREC LINK'
    
    # Create native standalone window
    window = webview.create_window(
        title=title,
        url=target_url,
        width=1320,
        height=880,
        min_size=(980, 640),
        background_color='#000000',
        resizable=True,
        fullscreen=False,
        confirm_close=False,
        text_select=False,
    )
    
    # Start WebView2 native GUI
    try:
        webview.start(gui='edgechromium', debug=False)
    finally:
        if backend_proc:
            try:
                backend_proc.terminate()
            except Exception:
                pass

if __name__ == '__main__':
    main()
