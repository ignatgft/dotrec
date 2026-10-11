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

def get_app_dir():
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))

def is_server_running(port=48212):
    try:
        req = urllib.request.Request(f'http://127.0.0.1:{port}/api/status', headers={'User-Agent': 'DotRec-Shell'})
        with urllib.request.urlopen(req, timeout=0.8) as resp:
            return resp.status == 200
    except Exception:
        return False

def start_backend_if_needed():
    if is_server_running(48212):
        return None
    
    app_dir = get_app_dir()
    candidates = [
        os.path.join(app_dir, 'DotRec-Link.exe'),
        os.path.join(app_dir, 'dotrec-link.exe'),
        os.path.join(os.getcwd(), 'DotRec-Link.exe'),
        os.path.join(os.getcwd(), 'dotrec-link.exe'),
        os.path.join(app_dir, '..', 'build', 'dist', 'DotRec-Link-v1.0.0-windows-x64', 'DotRec-Link.exe'),
        os.path.join(app_dir, '..', 'build', 'dist', 'DotRec-Link-v1.0.0-windows-x64', 'dotrec-link.exe'),
    ]
    for c in candidates:
        if os.path.exists(c):
            creationflags = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
            return subprocess.Popen([c], cwd=app_dir, creationflags=creationflags)
    
    # Fallback in dev workspace
    dart_script = os.path.join(app_dir, 'dotrec_link.dart')
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
        for _ in range(40):
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
    try:
        main()
    except Exception:
        import traceback
        try:
            log_path = os.path.join(get_app_dir(), 'debug_crash.log')
            with open(log_path, 'w', encoding='utf-8') as f:
                traceback.print_exc(file=f)
        except Exception:
            pass
