"""Publishing checks with mocked processes: no network or upload is performed."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from publish_itch import ITCH_TARGET, prepare_index, publish, read_version


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'pubspec.yaml').write_text('version: 0.1.0+1\n', encoding='utf-8')
        (self.root / 'butler.exe').touch()
        self.index = self.root / 'build' / 'web' / 'index.html'
        self.index.parent.mkdir(parents=True)
        self.index.write_text('<html><base href="/"><body>Sääsed</body></html>',
                              encoding='utf-8')

    @patch.dict(os.environ, {'ITCH_API_KEY': 'test-itch', 'BUTLER_API_KEY': 'test-butler'})
    @patch('publish_itch.getpass.getpass')
    @patch('publish_itch.subprocess.run')
    @patch('publish_itch.shutil.which', return_value='flutter.bat')
    def test_build_only_does_not_request_credentials_or_upload(self, which, run, prompt):
        (self.root / 'butler.exe').unlink()
        publish(self.root, build_only=True)
        run.assert_called_once()
        env = run.call_args.kwargs['env']
        self.assertNotIn('ITCH_API_KEY', env)
        self.assertNotIn('BUTLER_API_KEY', env)
        self.assertIn('--release', run.call_args.args[0])
        prompt.assert_not_called()
        self.assertIn('<base href="./">', self.index.read_text(encoding='utf-8'))

    @patch.dict(os.environ, {}, clear=True)
    @patch('publish_itch.getpass.getpass', return_value='test-hidden-token')
    @patch('publish_itch.subprocess.run')
    @patch('publish_itch.shutil.which', return_value='flutter.bat')
    def test_publish_uses_kuradi_target_version_and_token_only_in_upload_env(self, which, run, prompt):
        publish(self.root)
        prompt.assert_called_once()
        self.assertEqual(run.call_count, 2)
        build, upload = run.call_args_list
        self.assertEqual(ITCH_TARGET, 'lienthealien/kuradi-saased:HTML5')
        self.assertEqual(upload.args[0], [str(self.root / 'butler.exe'), 'push',
                         str(self.index.parent), ITCH_TARGET, '--userversion', '0.1.0+1'])
        self.assertEqual(upload.kwargs['env']['BUTLER_API_KEY'], 'test-hidden-token')
        self.assertNotIn('BUTLER_API_KEY', build.kwargs['env'])
        self.assertNotIn('test-hidden-token', ' '.join(upload.args[0]))

    @patch('publish_itch.getpass.getpass')
    @patch('publish_itch.subprocess.run', side_effect=subprocess.CalledProcessError(1, ['flutter']))
    @patch('publish_itch.shutil.which', return_value='flutter.bat')
    def test_failed_build_never_prompts_or_uploads(self, which, run, prompt):
        with self.assertRaises(subprocess.CalledProcessError):
            publish(self.root)
        run.assert_called_once()
        prompt.assert_not_called()

    def test_relative_base_preserves_artwork_text_and_is_repeatable(self):
        prepare_index(self.index)
        prepared = self.index.read_text(encoding='utf-8')
        self.assertIn('Sääsed', prepared)
        prepare_index(self.index)
        self.assertEqual(prepared, self.index.read_text(encoding='utf-8'))
        self.index.write_text('<html>No base</html>', encoding='utf-8')
        with self.assertRaises(ValueError):
            prepare_index(self.index)

    def test_version_reads_quoted_value_and_ignores_comment(self):
        path = self.root / 'pubspec.yaml'
        path.write_text('version: "1.2.3+4" # release\n', encoding='utf-8')
        self.assertEqual(read_version(path), '1.2.3+4')


if __name__ == '__main__':
    unittest.main()
