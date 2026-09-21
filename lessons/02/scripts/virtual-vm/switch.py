#!/usr/bin/env python3
"""Small learning Ethernet switch for QEMU's socket netdev (stdlib only).

QEMU frames TCP packets with a four-byte network-order length: see
https://github.com/qemu/qemu/blob/master/net/socket.c (net_socket_receive).
No IP stack, DHCP, routing, VLANs, STP, or physical switch simulation here.
"""
import argparse
import asyncio
import signal
import struct
import time


class Switch:
    def __init__(self, age=300):
        self.ports = set()
        self.learned = {}
        self.age = age

    def destinations(self, sender, frame):
        now = time.monotonic()
        self.learned = {mac: entry for mac, entry in self.learned.items()
                        if now - entry[1] < self.age and entry[0] in self.ports}
        dst, src = frame[:6], frame[6:12]
        if not src[0] & 1:
            self.learned[src] = (sender, now)
        if not dst[0] & 1 and dst in self.learned:
            port = self.learned[dst][0]
            return {port} - {sender}
        return self.ports - {sender}

    async def connect(self, reader, writer):
        self.ports.add(writer)
        try:
            while True:
                length, = struct.unpack('!I', await reader.readexactly(4))
                if not 14 <= length <= 65535:
                    break
                frame = await reader.readexactly(length)
                packet = struct.pack('!I', length) + frame
                for port in self.destinations(writer, frame):
                    # Bound memory if a guest stops consuming packets.
                    if port.transport.get_write_buffer_size() > 1024 * 1024:
                        port.close()
                        continue
                    port.write(packet)
                await writer.drain()
        except (asyncio.IncompleteReadError, ConnectionError, OSError):
            pass
        finally:
            self.ports.discard(writer)
            self.learned = {mac: entry for mac, entry in self.learned.items()
                            if entry[0] is not writer}
            writer.close()


async def main(port):
    switch = Switch()
    server = await asyncio.start_server(switch.connect, '127.0.0.1', port)
    done = asyncio.Event()
    for sig in (signal.SIGTERM, signal.SIGINT):
        asyncio.get_running_loop().add_signal_handler(sig, done.set)
    print(f'READY 127.0.0.1:{port}', flush=True)
    async with server:
        await done.wait()
    for writer in list(switch.ports):
        writer.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=10002)
    asyncio.run(main(parser.parse_args().port))
