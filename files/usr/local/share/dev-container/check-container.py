#!/usr/bin/env python

# pylint: disable=invalid-name
import os
import pathlib
import pwd
import shlex
import shutil
import subprocess
import sys
import unittest
import uuid

EXPECTED_USER_NAME = "dev"
EXPECTED_USER_HOME = "/home/dev"


class Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workspace_dir = os.environ.get("IMAGE_WORKSPACE_DIR")
        cls.python_version = os.environ.get("IMAGE_PYTHON_VERSION")
        cls.user_name = os.environ.get("IMAGE_USER_NAME")
        cls.user_home = os.environ.get("IMAGE_USER_HOME")

    def setUp(self) -> None:
        print(self._testMethodName)
        return super().setUp()

    @staticmethod
    def shell(command, environment=None):
        if environment is None:
            environment = os.environ

        split_command = shlex.split(command)
        try:
            output = subprocess.check_output(  # nosec
                split_command, env=environment, stderr=subprocess.STDOUT
            )  # nosec
            return (True, output.decode())
        except subprocess.CalledProcessError as e:
            return (False, e.output.decode())

    def shell_can_access(self, shell, command, environment=None):
        if environment is None:
            environment = {}
        full_command = f'{shell} -c "{command}"'
        success, output = self.shell(command=full_command, environment=environment)
        self.assertTrue(success, msg=f"Command failed: {full_command}")
        return output

    def zsh_can_access(self, command):
        command = f"source /home/dev/.zshrc && {command}"
        return self.shell_can_access(shell="/bin/zsh", command=command, environment=os.environ)

    def bash_can_access(self, command):
        return self.shell_can_access(shell="/bin/bash", command=command)

    def sh_can_access(self, command):
        return self.shell_can_access(shell="/bin/sh", command=command)

    def all_shells_can_access(self, command):
        self.zsh_can_access(command)
        self.bash_can_access(command)
        return self.sh_can_access(command)

    def file_creation_perms_and_deletion(self, path):
        file = os.path.join(path, uuid.uuid4().hex)

        try:
            with open(file, "w") as f:
                f.write("anything")
        except Exception as e:
            self.fail(f"Failed to write file {file} due to exception: {e}")

        file_stat = os.stat(file)
        perms = oct(file_stat.st_mode)[-3:]
        self.assertEqual("644", perms, msg="Unexpected file permissions")
        self.assertEqual(os.geteuid(), file_stat.st_uid, msg="Unexpected file ownership user")
        self.assertEqual(os.getgid(), file_stat.st_gid, msg="Unexpected file ownership group")

        try:
            os.remove(file)
        except Exception as e:
            self.fail(f"Failed to delete file {file} due to exception: {e}")

    def test__environmental_variables(self):
        envars = [
            "IMAGE_GROUP_NAME",
            "IMAGE_PYTHON_VERSION",
            "IMAGE_USER_GID",
            "IMAGE_USER_HOME",
            "IMAGE_USER_NAME",
            "IMAGE_USER_UID",
            "IMAGE_WORKSPACE_DIR",
        ]

        for envar in envars:
            self.assertIn(envar, os.environ)
            self.assertNotEqual("", os.environ[envar])

    def test_user_name(self):
        self.assertEqual(EXPECTED_USER_NAME, pwd.getpwuid(os.getuid())[0])

    def test_user_home_path(self):
        self.assertEqual(
            EXPECTED_USER_HOME,
            str(pathlib.Path.home()),
            msg="Unexpected user home path",
        )
        self.assertEqual(
            EXPECTED_USER_HOME, os.path.expanduser("~"), msg="Unexpected user home path"
        )
        self.assertEqual(
            EXPECTED_USER_HOME,
            os.environ["HOME"],
            msg="Unexpected user home path in HOME envar",
        )

    def test_workspace_file_creation_perms_and_deletion(self):
        self.file_creation_perms_and_deletion(self.workspace_dir)

    def test_user_home_file_creation_perms_and_deletion(self):
        self.file_creation_perms_and_deletion(EXPECTED_USER_HOME)

    def test_python(self):
        self.assertEqual(
            f"{self.workspace_dir}/.python/{self.python_version}/bin/python",
            shutil.which("python"),
        )
        self.assertEqual("3.", sys.version[:2])
        self.all_shells_can_access("python --version")

    def test_pip(self):
        self.assertEqual(
            f"{self.workspace_dir}/.python/{self.python_version}/bin/pip",
            shutil.which("pip"),
        )
        # self.all_shells_can_access("pip --version")

    def test_node(self):
        self.assertRegex(
            shutil.which("node"),
            "/home/dev/.nvm/versions/node/v[0-9]+.[0-9]+.[0-9]+/bin/node",
        )
        self.zsh_can_access("node --version")

    def test_aws_cli(self):
        self.assertEqual("/usr/local/bin/aws", shutil.which("aws"))
        self.all_shells_can_access("aws --version")

    def test_sam_cli(self):
        self.assertEqual("/usr/local/bin/sam", shutil.which("sam"))
        self.all_shells_can_access("sam --version")

    def test_awsume(self):
        self.assertEqual("/home/dev/.local/bin/awsume", shutil.which("awsume"))
        self.zsh_can_access("source awsume --version")

    def test_terraform(self):
        self.assertEqual("/usr/bin/terraform", shutil.which("terraform"))
        output = self.all_shells_can_access("terraform --version")
        version = os.environ.get("IMAGE_TERRAFORM_VERSION")
        self.assertIn(f"Terraform v{version}", output)

    def test_jq(self):
        self.assertEqual("/usr/bin/jq", shutil.which("jq"))
        self.all_shells_can_access("jq --version")

    def test_ruff(self):
        self.assertEqual("/home/dev/.local/bin/ruff", shutil.which("ruff"))
        self.zsh_can_access("ruff --version")

    def test_autopep8(self):
        self.assertEqual("/home/dev/.local/bin/autopep8", shutil.which("autopep8"))
        self.zsh_can_access("autopep8 --version")

    def test_black(self):
        # Black also installed as dependency of iPython for Python >= 3.8
        self.assertIn(
            shutil.which("black"),
            [
                "/home/dev/.local/bin/black",
                f"{self.workspace_dir}/.python/{self.python_version}/bin/black",
            ],
        )
        # self.zsh_can_access("black --version")

    def test_cfn_lint(self):
        self.assertEqual("/home/dev/.local/bin/cfn-lint", shutil.which("cfn-lint"))
        self.zsh_can_access("cfn-lint --version")

    def test_cfn_square(self):
        if self.python_version in ["3.9"]:
            self.assertEqual("/home/dev/.local/bin/cf", shutil.which("cf"))
            self.zsh_can_access("cf --version")

    def test_poetry(self):
        self.assertEqual("/home/dev/.local/bin/poetry", shutil.which("poetry"))
        self.zsh_can_access("poetry --version")

    def test_pip_compile(self):
        self.assertEqual("/home/dev/.local/bin/pip-compile", shutil.which("pip-compile"))
        self.zsh_can_access("pip-compile --version")

    def test_pip_sync(self):
        self.assertEqual("/home/dev/.local/bin/pip-sync", shutil.which("pip-sync"))
        self.zsh_can_access("pip-sync --version")

    def test_cfn_flip(self):
        self.assertEqual("/home/dev/.local/bin/cfn-flip", shutil.which("cfn-flip"))
        self.zsh_can_access("cfn-flip --version")

    def test_pyright(self):
        self.assertEqual("/home/dev/.local/bin/pyright", shutil.which("pyright"))
        self.zsh_can_access("pyright --version")

    def test_sass(self):
        self.assertEqual("/usr/local/bin/sass", shutil.which("sass"))
        self.zsh_can_access("sass --version")

    def test_mysql(self):
        self.assertEqual("/usr/bin/mysql", shutil.which("mysql"))
        self.zsh_can_access("mysql --version")

    def test_docker_compose(self):
        self.zsh_can_access("docker compose --version")

    def test_steampipe(self):
        self.assertEqual("/usr/local/bin/steampipe", shutil.which("steampipe"))
        self.zsh_can_access("steampipe -v")

    def test_7zip(self):
        self.assertEqual("/usr/bin/7za", shutil.which("7za"))
        self.zsh_can_access("7za --help")

    def test_linkchecker(self):
        self.assertEqual("/usr/bin/linkchecker", shutil.which("linkchecker"))
        self.zsh_can_access("linkchecker --version")

    def test_just(self):
        self.assertEqual("/usr/local/bin/just", shutil.which("just"))
        self.zsh_can_access("just --version")

    def test_csvtool(self):
        self.assertEqual("/usr/bin/csvtool", shutil.which("csvtool"))
        self.zsh_can_access("csvtool --help")

    def test_gh(self):
        self.assertEqual("/usr/bin/gh", shutil.which("gh"))
        self.zsh_can_access("gh --version")

    def test_biome(self):
        self.assertEqual("/usr/local/bin/biome", shutil.which("biome"))
        self.zsh_can_access("biome --version")

    def test_ansible_lint(self):
        self.assertEqual("/home/dev/.local/bin/ansible-lint", shutil.which("ansible-lint"))
        self.zsh_can_access("ansible-lint --version")

    def test_tflint(self):
        self.assertEqual("/usr/local/bin/tflint", shutil.which("tflint"))
        self.zsh_can_access("tflint --version")

    def test_tfsec(self):
        self.assertEqual("/usr/local/bin/tfsec", shutil.which("tfsec"))
        self.zsh_can_access("tfsec --version")

    def test_terragrunt(self):
        self.assertEqual("/usr/local/bin/terragrunt", shutil.which("terragrunt"))
        self.zsh_can_access("terragrunt --version")

    def test_graphviz(self):
        self.assertEqual("/usr/bin/dot", shutil.which("dot"))
        self.zsh_can_access("dot -V")

    def test_lastpass_cli(self):
        self.assertEqual("/usr/bin/lpass", shutil.which("lpass"))
        self.zsh_can_access("lpass --version")

    def test_shell_check(self):
        self.assertEqual("/usr/bin/shellcheck", shutil.which("shellcheck"))
        self.zsh_can_access("shellcheck --version")

    def test_azure_cli(self):
        self.assertEqual("/usr/bin/az", shutil.which("az"))
        self.zsh_can_access("az --version")

    def test_databricks_cli(self):
        self.assertEqual("/usr/local/bin/databricks", shutil.which("databricks"))
        self.zsh_can_access("databricks --version")

    def test_pdm(self):
        self.assertEqual("/home/dev/.local/bin/pdm", shutil.which("pdm"))
        self.zsh_can_access("pdm --version")

    def test_dc(self):
        self.assertEqual("/usr/local/bin/dc", shutil.which("dc"))
        self.zsh_can_access("dc")

    def test_bandit(self):
        self.assertEqual(
            f"/workspace/.python/{self.python_version}/bin/bandit", shutil.which("bandit")
        )
        self.zsh_can_access("bandit --version")

    def test_zsh_output(self):
        test_line = "just this line"
        self.assertEqual(f"{test_line}\n", self.zsh_can_access(f"echo {test_line}"))

    def test_locale(self):
        expected = "\n".join(
            [
                "LANG=en_GB.UTF-8",
                "LANGUAGE=en_GB:en",
                'LC_CTYPE="en_GB.UTF-8"',
                'LC_NUMERIC="en_GB.UTF-8"',
                'LC_TIME="en_GB.UTF-8"',
                'LC_COLLATE="en_GB.UTF-8"',
                'LC_MONETARY="en_GB.UTF-8"',
                'LC_MESSAGES="en_GB.UTF-8"',
                'LC_PAPER="en_GB.UTF-8"',
                'LC_NAME="en_GB.UTF-8"',
                'LC_ADDRESS="en_GB.UTF-8"',
                'LC_TELEPHONE="en_GB.UTF-8"',
                'LC_MEASUREMENT="en_GB.UTF-8"',
                'LC_IDENTIFICATION="en_GB.UTF-8"',
                "LC_ALL=en_GB.UTF-8",
                "",
            ]
        )
        self.assertEqual(expected, self.zsh_can_access("locale"))


if __name__ == "__main__":
    unittest.main(buffer=False)
