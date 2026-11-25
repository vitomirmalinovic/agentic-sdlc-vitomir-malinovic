"""Smoke test: proves the CI pipeline can import the package and run pytest.

Real tests replace this in Module 5 (TDD/BDD).
"""

import minesweeper


def test_package_is_importable():
    assert minesweeper.__name__ == "minesweeper"


def test_package_has_version():
    assert minesweeper.__version__ == "0.1.0"
