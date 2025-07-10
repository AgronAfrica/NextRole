#!/usr/bin/env python3
"""
Simple HTTP server for NextRole web pages
Serves support.html, privacy.html, and terms.html
"""

import http.server
import socketserver
import os
import sys
from urllib.parse import urlparse

PORT = 8000

class NextRoleHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Parse the URL
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        # Default to support.html for root path
        if path == "/" or path == "":
            path = "/support.html"
        
        # Map common paths to our HTML files
        if path == "/support":
            path = "/support.html"
        elif path == "/privacy":
            path = "/privacy.html"
        elif path == "/terms":
            path = "/terms.html"
        
        # Set the path to serve from current directory
        self.path = path
        
        # Call the parent class to handle the file serving
        return http.server.SimpleHTTPRequestHandler.do_GET(self)
    
    def end_headers(self):
        # Add CORS headers for web access
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

def main():
    # Change to the directory containing the HTML files
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # Create the server
    with socketserver.TCPServer(("", PORT), NextRoleHTTPRequestHandler) as httpd:
        print(f"Server running at http://localhost:{PORT}")
        print(f"Support page: http://localhost:{PORT}/support.html")
        print(f"Privacy page: http://localhost:{PORT}/privacy.html")
        print(f"Terms page: http://localhost:{PORT}/terms.html")
        print("Press Ctrl+C to stop the server")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server...")
            httpd.shutdown()

if __name__ == "__main__":
    main() 