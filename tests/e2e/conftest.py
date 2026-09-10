"""Prevent privileged installation tests from running on a real host by accident."""
import os
from pathlib import Path
import pytest


def pytest_sessionstart(session):
    if (os.environ.get('GN_TDD_DISPOSABLE') != '1'
            or not Path('/etc/ghostnodes-tdd-image').is_file()
            or not Path('/work/halfin/pre_install.sh').is_file()):
        pytest.exit('Installation tests require the disposable TDD image and runner.', returncode=2)
