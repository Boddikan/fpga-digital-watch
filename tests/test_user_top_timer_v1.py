import pytest
from conftest import rtl_exists

SOURCES = [
    "mod_n_counter.sv",
    "up_down_counter_rst.sv",
    "restartable_rate_generator.sv",
    "editable_countdown.sv",
    "rising_edge_detector.sv",
    "button_hold_detect.sv",
    "button_hold_pulse.sv",
    "arming_latch.sv",
    "edit_mode_selector.sv",
    "pwm_generator.sv",
    "button_auto_repeat.sv",
    "user_top_timer_v1.sv",
]

# CYCLES_PER_SECOND=10 gives:
#   1 Hz tick every 10 cycles
#   edit_mode_selector long-press threshold: 10 cycles
#   button_auto_repeat hold threshold: 5 cycles, repeat interval: 1 cycle
#   PWM period: 5 cycles, high duration: 1 cycle
CYCLES_PER_SECOND = 10


@pytest.mark.skipif(
    not rtl_exists("user_top_timer_v1.sv"),
    reason="user_top_timer_v1 module not implemented yet",
)
def test_user_top_timer_v1(cocotb_runner):
    """Timer: start/stop, countdown, auto-stop at zero, and edit mode."""
    cocotb_runner(
        top="user_top_timer_v1",
        sources=SOURCES,
        test_module="tb_user_top_timer_v1",
        parameters={"CYCLES_PER_SECOND": CYCLES_PER_SECOND},
    )
