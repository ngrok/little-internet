#!/usr/bin/env python3
# Minimal black-and-white web dashboard for the two-VM lab. Shows both nodes'
# link state, address, ARP cache, serial-console log tail, and a live feed of the
# frames crossing the wire. Started by dashboard.sh (which brings the lab up).
import collections
import http.server
import json
import os
import re
import socketserver
import subprocess
import threading
import time

ANSI = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]")  # strip terminal color codes from logs

LAB_HOME = os.environ.get("LAB_HOME", os.path.expanduser("~/.little-internet/lab00-vm"))
KEY = os.path.join(LAB_HOME, "id_ed25519")
PORT = int(os.environ.get("DASH_PORT", "8099"))
NODES = {"a": 2201, "b": 2202}

SSH = ["ssh", "-i", KEY, "-o", "StrictHostKeyChecking=no",
       "-o", "UserKnownHostsFile=/dev/null", "-o", "LogLevel=ERROR",
       "-o", "ConnectTimeout=3", "-o", "SetEnv=LC_ALL=C.UTF-8"]

STATE = {"a": {"up": False}, "b": {"up": False}}
WIRE = collections.deque(maxlen=80)
WIRE_PROC = None


def ssh_run(port, cmd, timeout=6):
    try:
        r = subprocess.run(SSH + ["-p", str(port), "pi@127.0.0.1", cmd],
                           capture_output=True, text=True, timeout=timeout)
        return r.stdout
    except Exception:
        return ""


def poll_node(port):
    out = ssh_run(port,
                  "hostname; cat /sys/class/net/eth0/carrier 2>/dev/null || echo -; "
                  "ip -br -4 addr show eth0 2>/dev/null | awk '{print $3}'; "
                  "echo ==NEIGH==; ip neigh show dev eth0 2>/dev/null")
    st = {"up": bool(out), "host": "?", "carrier": "?", "addr": "", "neigh": []}
    lines = out.splitlines()
    if lines:
        try:
            idx = lines.index("==NEIGH==")
        except ValueError:
            idx = len(lines)
        head = lines[:idx]
        if len(head) > 0:
            st["host"] = head[0]
        if len(head) > 1:
            st["carrier"] = head[1]
        if len(head) > 2:
            st["addr"] = head[2]
        st["neigh"] = [l for l in lines[idx + 1:] if l.strip()]
    return st


def status_loop():
    while True:
        for n, p in NODES.items():
            STATE[n] = poll_node(p)
        time.sleep(1.5)


def wire_loop():
    global WIRE_PROC
    while True:
        WIRE_PROC = subprocess.Popen(
            SSH + ["-p", str(NODES["a"]), "pi@127.0.0.1", "sudo tshark -l -i eth0 -n 2>/dev/null"],
            stdout=subprocess.PIPE, text=True)
        for line in WIRE_PROC.stdout:
            line = line.rstrip()
            if line:
                WIRE.append(line)
        WIRE_PROC.wait()
        time.sleep(2)  # tshark exited (lab down?) — retry


def serial_tail(n, lines=24):
    path = os.path.join(LAB_HOME, "pi-%s-serial.log" % n)
    try:
        with open(path, "rb") as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            f.seek(max(0, size - 8000))
            data = f.read()
        text = data.decode("utf-8", "replace")
        return [ANSI.sub("", l) for l in text.splitlines() if l.strip()][-lines:]
    except Exception:
        return []


HTML = """<!doctype html><html><head><meta charset="utf-8"><title>lab00 dashboard</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#fff;color:#000;font:13px/1.5 ui-monospace,Menlo,Consolas,monospace}
header{border-bottom:2px solid #000;padding:10px 14px;font-weight:700;display:flex;justify-content:space-between}
.grid{display:grid;grid-template-columns:1fr 1fr}
.node{border-right:1px solid #000;padding:12px 14px;min-width:0}
.node:last-child{border-right:0}
.name{font-weight:700;font-size:15px;margin-bottom:6px}
.row{display:flex;gap:8px;margin:2px 0}
.k{color:#666;width:56px}
.pill{border:1px solid #000;padding:0 6px}
.sec{margin-top:10px;border-top:1px dashed #000;padding-top:6px}
.lbl{color:#666;margin-bottom:3px}
.log{white-space:pre-wrap;max-height:210px;overflow:auto;font-size:12px}
.wire{border-top:2px solid #000;padding:12px 14px}
.wire .log{max-height:280px;background:#000;color:#d7dae0;padding:8px 10px}
.wa{color:#e5c07b}.wq{color:#98c379}.wp{color:#56b6c2}.wo{color:#7f848e}.wr{color:#e06c75}
.dim{color:#666}
</style></head><body>
<header><span>little internet &middot; lab00</span><span id="clock" class="dim"></span></header>
<div class="grid"><div class="node" id="node-a"></div><div class="node" id="node-b"></div></div>
<div class="wire"><div class="name">wire &middot; frames crossing eth0</div><div class="log" id="wire"></div></div>
<script>
function esc(s){return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;');}
function skel(id){
  return '<div class="name" id="'+id+'-name"></div>'+
    '<div class="row"><span class="k">link</span><span class="pill" id="'+id+'-link"></span></div>'+
    '<div class="row"><span class="k">eth0</span><span id="'+id+'-addr"></span></div>'+
    '<div class="sec"><div class="lbl">arp / neighbor cache</div><div class="log" id="'+id+'-arp"></div></div>'+
    '<div class="sec"><div class="lbl">serial console</div><div class="log" id="'+id+'-serial"></div></div>';
}
var ARPCOL={REACHABLE:'wq',STALE:'wa',DELAY:'wa',PROBE:'wa',INCOMPLETE:'wa',FAILED:'wr',NONE:'wo'};
function arpHTML(lines){
  return (lines||[]).map(function(l){
    return esc(l).replace(/\\b(REACHABLE|STALE|DELAY|PROBE|INCOMPLETE|FAILED|NONE)\\b/g,function(m){return '<span class="'+ARPCOL[m]+'">'+m+'</span>';});
  }).join('\\n');
}
function atBottom(el){return (el.scrollHeight-el.scrollTop-el.clientHeight)<30;}
function setLog(el,val,isHTML){var stick=atBottom(el);if(isHTML)el.innerHTML=val;else el.textContent=val;if(stick)el.scrollTop=el.scrollHeight;}
function updateNode(id,d){
  var name=document.getElementById(id+'-name');
  if(!d||!d.up){name.textContent='pi-'+id+' (down)';return;}
  name.textContent=d.host||('pi-'+id);
  document.getElementById(id+'-link').textContent=d.carrier==='1'?'LINK UP':(d.carrier==='0'?'NO CARRIER':(d.carrier||'?'));
  document.getElementById(id+'-addr').textContent=d.addr||'no IPv4';
  var neigh=d.neigh&&d.neigh.length;
  setLog(document.getElementById(id+'-arp'), neigh?arpHTML(d.neigh):'(cache empty)', neigh?true:false);
  setLog(document.getElementById(id+'-serial'), (d.serial||[]).join('\\n'), false);
}
function wireHTML(lines){
  return (lines||[]).map(function(l){
    var c='wo';
    if(/ ARP /.test(l)) c='wa';
    else if(l.indexOf('Echo (ping) request')>=0) c='wq';
    else if(l.indexOf('Echo (ping) reply')>=0) c='wp';
    return '<span class="'+c+'">'+esc(l)+'</span>';
  }).join('\\n');
}
async function tick(){
  document.getElementById('clock').textContent=new Date().toLocaleTimeString();
  try{
    var j = await (await fetch('/data')).json();
    j.a.serial=j.serial_a; j.b.serial=j.serial_b;
    updateNode('a',j.a); updateNode('b',j.b);
    setLog(document.getElementById('wire'), wireHTML(j.wire), true);
  }catch(e){}
}
document.getElementById('node-a').innerHTML=skel('a');
document.getElementById('node-b').innerHTML=skel('b');
setInterval(tick,1000); tick();
</script></body></html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, body, ctype):
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/":
            self._send(HTML.encode(), "text/html; charset=utf-8")
        elif self.path == "/data":
            payload = {"a": STATE["a"], "b": STATE["b"],
                       "serial_a": serial_tail("a"), "serial_b": serial_tail("b"),
                       "wire": list(WIRE)}
            self._send(json.dumps(payload).encode(), "application/json")
        else:
            self.send_response(404)
            self.end_headers()


def main():
    threading.Thread(target=status_loop, daemon=True).start()
    threading.Thread(target=wire_loop, daemon=True).start()
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    httpd = socketserver.ThreadingTCPServer(("127.0.0.1", PORT), Handler)
    print("dashboard on http://127.0.0.1:%d  (Ctrl-C to stop)" % PORT)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        if WIRE_PROC:
            WIRE_PROC.terminate()


if __name__ == "__main__":
    main()
