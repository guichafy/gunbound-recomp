"""Independent archive/payload checks for the original Thor's Hammer audio."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import gunbound_xfs as xfs
import import_xfs_audio as importer

OUTPUT = ROOT / 'assets/xfs/audio'
CATALOG = json.loads((OUTPUT / 'catalog.json').read_text())


class ClientAudio(unittest.TestCase):
    def test_delivery_inventory_and_hashes(self):
        self.assertEqual(CATALOG['source_sha256'], importer.SOURCE_SHA)
        self.assertEqual(len(CATALOG['records']), 96)
        self.assertEqual(sum(r['encoding'] == 'mp3_passthrough' for r in CATALOG['records']), 11)
        self.assertEqual(CATALOG['battle_playlist'], ['stage%d.mp3' % n for n in range(1, 7)])
        names = {r['entry'] for r in CATALOG['records']}
        self.assertIn('turn.xes', names)
        self.assertIn('turn2.xes', names)
        self.assertNotIn('itemblast.xes', names)
        self.assertNotIn('lightningblast.xes', names)
        self.assertIn('lightingblast.xes', names)
        for record in CATALOG['records']:
            raw = (OUTPUT / record['file']).read_bytes()
            self.assertEqual(len(raw), record['file_size'])
            self.assertEqual(hashlib.sha256(raw).hexdigest(), record['file_sha256'])
            if record['encoding'] == 'pcm_s16le':
                with wave.open(str(OUTPUT / record['file']), 'rb') as stream:
                    self.assertEqual((stream.getnchannels(), stream.getframerate(), stream.getsampwidth()), (2, 22050, 2))
                    pcm = stream.readframes(stream.getnframes())
                    self.assertEqual(hashlib.sha256(pcm).hexdigest(), record['pcm_sha256'])
                    self.assertEqual(stream.getnframes(), record['frames'])
            else:
                self.assertEqual(hashlib.sha256(raw).hexdigest(), record['entry_sha256'])

    def test_godot_import_preserves_pcm(self):
        for record in CATALOG['records']:
            if record['encoding'] == 'pcm_s16le':
                settings = (OUTPUT / (record['file'] + '.import')).read_text()
                self.assertIn('compress/mode=0', settings)
                self.assertIn('force/8_bit=false', settings)
                self.assertIn('force/mono=false', settings)
                self.assertIn('edit/normalize=false', settings)
                self.assertIn('edit/trim=false', settings)

    @unittest.skipUnless(importer.DEFAULT_SOURCE.exists(), 'local sound.xfs required')
    def test_original_bytes_and_16_byte_header(self):
        source = importer.DEFAULT_SOURCE
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), importer.SOURCE_SHA)
        toc = {r['name']: r for r in xfs.read_toc(source)}
        self.assertEqual(set(toc), {r['entry'] for r in CATALOG['records']})
        for record in CATALOG['records']:
            raw = xfs.read_entry(source, toc[record['entry']])
            self.assertEqual(hashlib.sha256(raw).hexdigest(), record['entry_sha256'])
            if record['entry'].endswith('.mp3'):
                self.assertEqual(raw, (OUTPUT / record['file']).read_bytes())
            else:
                self.assertEqual(struct.unpack_from('<HHIIHH', raw), (1, 2, 22050, 88200, 4, 16))
                with wave.open(str(OUTPUT / record['file']), 'rb') as stream:
                    self.assertEqual(stream.readframes(stream.getnframes()), raw[16:])

    @unittest.skipUnless(importer.DEFAULT_SOURCE.exists(), 'local sound.xfs required')
    def test_reproducible_and_wrong_source_rejected_before_write(self):
        with tempfile.TemporaryDirectory() as tmp:
            destination = Path(tmp) / 'extracted'
            importer.extract(importer.DEFAULT_SOURCE, destination)
            for record in CATALOG['records']:
                self.assertEqual((destination / record['file']).read_bytes(), (OUTPUT / record['file']).read_bytes())
            self.assertEqual((destination / 'catalog.json').read_bytes(), (OUTPUT / 'catalog.json').read_bytes())
            wrong = Path(tmp) / 'wrong.xfs'
            wrong.write_bytes(b'wrong')
            with self.assertRaisesRegex(ValueError, 'unexpected sound.xfs hash'):
                importer.extract(wrong, Path(tmp) / 'must_not_exist')
            self.assertFalse((Path(tmp) / 'must_not_exist').exists())

    def test_rejects_wrong_format_and_partial_frame(self):
        for raw in (b'', struct.pack('<HHIIHH', 1, 1, 22050, 44100, 2, 16),
                    struct.pack('<HHIIHH', 1, 2, 22050, 88200, 4, 16) + b'\x01'):
            with self.assertRaises(ValueError):
                importer.xes_wave(raw)


if __name__ == '__main__':
    unittest.main()
