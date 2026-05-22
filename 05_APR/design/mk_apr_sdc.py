#!/usr/bin/env python3
"""Build Innovus CHIP.sdc from DC CHIP_syn.sdc (minimal edits only)."""
import re
import sys
from pathlib import Path

def main():
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent / "CHIP_syn.sdc"
    out = Path(__file__).parent / "CHIP.sdc"
    text = src.read_text(encoding="utf-8")

    text = re.sub(r"^#.*DC synthesis.*\n", "", text, flags=re.M)
    text = re.sub(r"^#.*write_sdc.*\n", "", text, flags=re.M)
    text = re.sub(r"^#{3,}.*\n", "", text, count=2, flags=re.M)

    text = re.sub(r"^set_units[^\n]*\n", "", text, flags=re.M)
    text = re.sub(
        r"^set_operating_conditions.*?fsa0m_a_generic_core_ff1p98vm40c\n",
        "",
        text,
        flags=re.M | re.S,
    )
    # Innovus MMMC ignores wire_load_model; commenting avoids TCLCMD-290
    def _comment_wire_load(m):
        return (
            "# Innovus MMMC: wire_load from RC corners, not SDC wire_load_model\n"
            "# " + m.group(0)
        )
    text = re.sub(r"^set_wire_load_model[^\n]*\n", _comment_wire_load, text, flags=re.M)
    fanout_note = (
        "# Innovus: no set_max_fanout in SDC (CTS clocks violate global limit; use fixFanoutLoad)\n"
    )
    text = re.sub(
        r"^set_max_fanout \d+ \[get_designs \$DESIGN\]\n",
        fanout_note,
        text,
        flags=re.M,
    )
    text = re.sub(
        r"^set_max_fanout \d+ \[current_design\]\n",
        fanout_note,
        text,
        flags=re.M,
    )
    text = re.sub(r"^set_max_area 0\n", "# set_max_area 0\n", text, flags=re.M)
    text = re.sub(
        r"^set_input_delay -clock CLK  -max 1  \[get_ports clk\]\n",
        "# Innovus: no set_input_delay on clock root (TCLNL-330)\n"
        "# set_input_delay -clock CLK  -max 1  [get_ports clk]\n",
        text,
        flags=re.M,
    )

    header = """###################################################################
# Innovus APR (mmmc.view → design/CHIP.sdc)
# Source: CHIP_syn.sdc + minimal Innovus edits (see CHIP_previous.sdc)
# Regenerate: python3 mk_apr_sdc.py [CHIP_syn.sdc]
###################################################################
"""
    innovus_note = (
        "# Innovus: set_units / set_max_area unsupported (CTE-25). MMMC owns corners.\n"
        "# set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA\n"
        "# set_operating_conditions -max WCCOM -max_library fsa0m_a_generic_core_ss1p62v125c \\\n"
        "#                          -min BCCOM -min_library fsa0m_a_generic_core_ff1p98vm40c\n"
    )
    text = text.replace("set sdc_version 1.8\n", "set sdc_version 1.8\n\n" + innovus_note, 1)
    out.write_text(header + text, encoding="utf-8")
    print(f"Wrote {out} from {src}")

if __name__ == "__main__":
    main()
