#!/usr/bin/env python

# pylint: disable=invalid-name
import os
import sys
import pwd
import uuid
import shlex
import shutil
import pathlib
import unittest
import subprocess

EXPECTED_USER_NAME = 'dev'
EXPECTED_USER_HOME = '/home/dev'


class Tests(unittest.TestCase):

    def setUp(self) -> None:
        print(self._testMethodName)
        return super().setUp()

    def shell(self, command, environment=os.environ):
        split_command = shlex.split(command)
        try:
            output = subprocess.check_output(  # nosec
                split_command,
                env=environment,
                stderr=subprocess.STDOUT
            )  # nosec
            return (True, output.decode())
        except subprocess.CalledProcessError as e:
            return (False, e.output.decode())

    def shell_can_access(self, shell, command, environment={}):
        full_command = f'{shell} -c "{command}"'
        success, output = self.shell(
            command=full_command,
            environment=environment
        )
        self.assertTrue(success, msg=f'Command failed: {full_command}')
        return output

    def zsh_can_access(self, command):
        self.shell_can_access(shell='/bin/zsh', command=command, environment=os.environ)

    def bash_can_access(self, command):
        self.shell_can_access(shell='/bin/bash', command=command)

    def sh_can_access(self, command):
        self.shell_can_access(shell='/bin/sh', command=command)

    def all_shells_can_access(self, command):
        self.zsh_can_access(command)
        self.bash_can_access(command)
        self.sh_can_access(command)

    def file_creation_perms_and_deletion(self, path):
        file = os.path.join(path, uuid.uuid4().hex)

        try:
            with open(file, 'w') as f:
                f.write('anything')
        except Exception as e:
            self.fail(f'Failed to write file {file} due to exception: {e}')

        file_stat = os.stat(file)
        perms = oct(file_stat.st_mode)[-3:]
        self.assertEqual('644', perms, msg='Unexpected file permissions')
        self.assertEqual(os.geteuid(), file_stat.st_uid, msg='Unexpected file ownership user')
        self.assertEqual(os.getgid(), file_stat.st_gid, msg='Unexpected file ownership group')

        try:
            os.remove(file)
        except Exception as e:
            self.fail(f'Failed to delete file {file} due to exception: {e}')

    def test_user_name(self):
        self.assertEqual(EXPECTED_USER_NAME, pwd.getpwuid(os.getuid())[0])

    def test_user_home_path(self):
        self.assertEqual(
            EXPECTED_USER_HOME,
            str(pathlib.Path.home()),
            msg='Unexpected user home path'
        )
        self.assertEqual(
            EXPECTED_USER_HOME,
            os.path.expanduser('~'),
            msg='Unexpected user home path'
        )
        self.assertEqual(
            EXPECTED_USER_HOME,
            os.environ['HOME'],
            msg='Unexpected user home path in HOME envar'
        )

    def test_workspace_file_creation_perms_and_deletion(self):
        self.file_creation_perms_and_deletion('/workspace')

    def test_user_home_file_creation_perms_and_deletion(self):
        self.file_creation_perms_and_deletion(EXPECTED_USER_HOME)

    def test_python(self):
        self.assertEqual('/usr/local/bin/python', shutil.which('python'))
        self.assertEqual('3.', sys.version[:2])
        self.all_shells_can_access('python --version')

    def test_pip(self):
        self.assertEqual('/usr/local/bin/pip', shutil.which('pip'))
        self.all_shells_can_access('pip --version')

    def test_node(self):
        self.assertRegex(
            shutil.which('node'),
            '/home/dev/.nvm/versions/node/v[0-9]+.[0-9]+.[0-9]+/bin/node',
        )
        self.zsh_can_access('node --version')

    def test_aws_cli(self):
        self.assertEqual('/usr/local/bin/aws', shutil.which('aws'))
        self.zsh_can_access('aws --version')

    def test_awsume(self):
        self.assertEqual('/home/dev/.local/bin/awsume', shutil.which('awsume'))
        self.zsh_can_access('source awsume --version')

    def test_terraform(self):
        self.assertEqual('/usr/bin/terraform', shutil.which('terraform'))
        self.all_shells_can_access('terraform --version')

    def test_prospector(self):
        self.assertEqual('/home/dev/.local/bin/prospector', shutil.which('prospector'))
        self.all_shells_can_access('prospector --version')

    def test_autopep8(self):
        self.assertEqual('/home/dev/.local/bin/autopep8', shutil.which('autopep8'))
        self.all_shells_can_access('autopep8 --version')

    def test_cfn_lint(self):
        self.assertEqual('/home/dev/.local/bin/cfn-lint', shutil.which('cfn-lint'))
        self.all_shells_can_access('cfn-lint --version')

    def test_cfn_nag(self):
        self.assertEqual('/usr/local/bin/cfn_nag', shutil.which('cfn_nag'))
        self.all_shells_can_access('cfn_nag --version')


if __name__ == '__main__':
    unittest.main(buffer=False)
