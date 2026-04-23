import os
import tarfile
import http.server
import socketserver
import threading

def create_tar():
    print("Creating beta.tar.gz...")
    exclude_dirs = {
        '.agent',
        '.git',
        '.venv',
        'node_modules',
        'tests',
        'Archive',
        'Memory',
        'dist',
        '__pycache__',
        'venv',
    }
    
    with tarfile.open("beta.tar.gz", "w:gz") as tar:
        for root, dirs, files in os.walk("."):
            # Exclude unwanted directories
            dirs[:] = [d for d in dirs if d not in exclude_dirs and not d.startswith('.')]
            
            for file in files:
                if file == "beta.tar.gz" or file == "serve_local.py":
                    continue
                file_path = os.path.join(root, file)
                arcname = os.path.join("GhostNodes-beta", os.path.relpath(file_path, "."))
                tar.add(file_path, arcname=arcname)
    print("Created beta.tar.gz!")

def start_server():
    PORT = int(os.environ.get("SERVE_LOCAL_PORT", "18080"))
    Handler = http.server.SimpleHTTPRequestHandler
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Serving at port {PORT}")
        httpd.serve_forever()

if __name__ == "__main__":
    create_tar()
    start_server()
