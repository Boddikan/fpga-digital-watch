import pytest
from conftest import rtl_exists

SOURCES = [
    "mod_n_counter.sv",
    "cascade_counter.sv",
    "restartable_rate_generator.sv",
    "rising_edge_detector.sv",
    "snapshot_mux.sv",
    "stopwatch_counter.sv",
    "stopwatch_control.sv",
    "user_top_stopwatch_v1.sv",
]

# CYCLES_PER_SECOND=200 gives CSTICK=2 (one centisecond tick every 2 clock
# cycles), keeping simulations fast while remaining well above button-press
# granularity (2 cycles per press).
CYCLES_PER_SECOND = 200


@pytest.mark.skipif(
    not rtl_exists("user_top_stopwatch_v1.sv"),
    reason="user_top_stopwatch_v1 module not implemented yet",
)
def test_user_top_stopwatch_v1(cocotb_runner):
    """Stopwatch: start/stop, lap/resume, and reset."""
    cocotb_runner(
        top="user_top_stopwatch_v1",
        sources=SOURCES,
        test_module="tb_user_top_stopwatch_v1",
        parameters={"CYCLES_PER_SECOND": CYCLES_PER_SECOND},
    )
