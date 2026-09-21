"""Exercise the real TCP switch with QEMU framing, no VM dependencies."""
import asyncio
import importlib.util
from pathlib import Path
import struct
import unittest

spec = importlib.util.spec_from_file_location(
    'lab_switch', Path(__file__).parents[1] / 'scripts/virtual-vm/switch.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

A = bytes.fromhex('b827eb020001')
B = bytes.fromhex('b827eb020002')
C = bytes.fromhex('b827eb0200fe')
BROADCAST = b'\xff' * 6


def packet(src, dst):
    frame = dst + src + b'\x08\x06' + bytes(28)
    return struct.pack('!I', len(frame)) + frame


class Switching(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.switch = module.Switch()
        self.server = await asyncio.start_server(self.switch.connect, '127.0.0.1', 0)
        port = self.server.sockets[0].getsockname()[1]
        self.clients = [await asyncio.open_connection('127.0.0.1', port) for _ in range(3)]

    async def asyncTearDown(self):
        for _, writer in self.clients:
            writer.close()
            await writer.wait_closed()
        self.server.close()
        await self.server.wait_closed()

    async def receive(self, index, expected):
        actual = await asyncio.wait_for(self.clients[index][0].readexactly(len(expected)), 1)
        self.assertEqual(actual, expected)

    async def quiet(self, index):
        with self.assertRaises(asyncio.TimeoutError):
            await asyncio.wait_for(self.clients[index][0].readexactly(1), .03)

    async def send(self, index, payload):
        self.clients[index][1].write(payload)
        await self.clients[index][1].drain()

    async def test_broadcast_then_learned_unicast(self):
        request = packet(A, BROADCAST)
        await self.send(0, request)
        await self.receive(1, request)
        await self.receive(2, request)
        await self.quiet(0)
        reply = packet(B, A)
        await self.send(1, reply)
        await self.receive(0, reply)
        await self.quiet(2)
        followup = packet(A, B)
        await self.send(0, followup)
        await self.receive(1, followup)
        await self.quiet(2)

    async def test_unknown_unicast_and_multicast_flood(self):
        for dst in (B, bytes.fromhex('333300000001')):
            payload = packet(A, dst)
            await self.send(0, payload)
            await self.receive(1, payload)
            await self.receive(2, payload)

    async def test_fragmented_and_coalesced_tcp_frames(self):
        payload = packet(A, BROADCAST)
        await self.send(0, payload[:2])
        await self.send(0, payload[2:8])
        await self.send(0, payload[8:] + payload)
        for index in (1, 2):
            await self.receive(index, payload + payload)

    async def test_invalid_length_disconnects_only_sender(self):
        await self.send(0, struct.pack('!I', 1000000))
        self.assertEqual(await asyncio.wait_for(self.clients[0][0].read(), 1), b'')
        payload = packet(B, BROADCAST)
        await self.send(1, payload)
        await self.receive(2, payload)

    async def test_aging_and_disconnect_forget_destinations(self):
        await self.send(0, packet(A, BROADCAST))
        await self.receive(1, packet(A, BROADCAST))
        await self.receive(2, packet(A, BROADCAST))
        self.switch.age = 0
        payload = packet(B, A)
        await self.send(1, payload)
        await self.receive(0, payload)
        await self.receive(2, payload)
        self.clients[1][1].close()
        await self.clients[1][1].wait_closed()
        await asyncio.sleep(.01)
        self.assertNotIn(B, self.switch.learned)


if __name__ == '__main__':
    unittest.main()
