import subprocess

import pytest
from conftest import resolve_sby_path, rtl_exists, sby_exists

MODULES = [
    "up_down_counter_rst",
    "cascade_counter",
    "stopwatch_counter",
    "snapshot_mux",
    "editable_countdown",
    "user_top_timer_v1",
]


@pytest.mark.formal
@pytest.mark.parametrize("module", MODULES)
def test_formal_sby(module):
    if not rtl_exists(module + ".sv"):
        pytest.skip(f"{module} module not implemented yet")
    if not sby_exists(module + ".sby"):
        pytest.skip(f"{module} sby spec not implemented yet")
    sby_filename = resolve_sby_path(module + ".sby")
    result = subprocess.run(["sby", "-f", sby_filename], check=False)

    assert result.returncode == 0, "SBY failed!"
