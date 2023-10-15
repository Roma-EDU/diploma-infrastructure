#!/usr/bin/env python

import argparse
import json
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

class ServerHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            content_length = int(self.headers['Content-Length'])
            body = self.rfile.read(content_length)
            print("POST request, path:", self.path, "body:", body.decode('utf-8'))
            data_dict = json.loads(body.decode('utf-8'))
            token = data_dict['token']
            if token == AUTH_TOKEN:
                subprocess.run(['kubectl', 'rollout', 'restart', DEPLOYMENT])
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(b"OK")
            else:
                self.send_response(403, 'Bad Request: Authentication failed')
                self.send_header('Content-Type', 'text/plain')
                self.end_headers()
                self.wfile.write(b"Authentication failed")
        except Exception as err:
            print("Internal error: ", str(err))
            self.send_response(500, 'Internal error')
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()


parser = argparse.ArgumentParser()
parser.add_argument('-t', '--token', type=str, required=True, help='webhook authentication token')
parser.add_argument('-d', '--deployment', type=str, default='deployment/diploma-app', help='deployment to reload, default is "deployment/diploma-app"')
parser.add_argument('-p', '--port', type=int, default=5252, help='specifies port, default is 5252')
args = parser.parse_args()
AUTH_TOKEN = args.token
DEPLOYMENT = args.deployment

server_address = ('', args.port)     
httpd = HTTPServer(server_address, ServerHandler)
try:
    httpd.serve_forever()
except KeyboardInterrupt:
    pass
httpd.server_close()
