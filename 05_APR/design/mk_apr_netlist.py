#!/usr/bin/env python3
"""Merge DC core netlist (02_SYN) with IO pad shell for Innovus APR."""
import sys
from pathlib import Path

IOPORT_IN_W = 11   # follow CHIP.ioc pads i_data_0..10
IOPORT_OUT_W = 11


def _pad_shell() -> str:
    lines = [
        "// IO pad shell (APR kit; follows CHIP.ioc)",
        "module CHIP ( clk, rst_n, i_valid, i_ready, o_ready, o_valid, i_data, o_data );",
        "  input clk, rst_n, i_valid, o_ready;",
        "  output i_ready, o_valid;",
        f"  input [{IOPORT_IN_W - 1}:0] i_data;",
        f"  output [{IOPORT_OUT_W - 1}:0] o_data;",
        "",
        "  wire n_logic0, n_logic1;",
        "  wire i_clk, i_rst_n, i_i_valid, i_o_ready;",
        f"  wire [{IOPORT_IN_W - 1}:0] i_i_data;",
        "  wire i_i_ready, i_o_valid;",
        f"  wire [{IOPORT_OUT_W - 1}:0] i_o_data;",
        "",
        "  TIE0 U_TIE0 ( .O(n_logic0) );",
        "  TIE1 U_TIE1 ( .O(n_logic1) );",
        "",
        "  XMD ipad_clk      ( .O(i_clk),     .I(clk),     .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );",
        "  XMD ipad_rst_n    ( .O(i_rst_n),   .I(rst_n),   .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );",
        "  XMD ipad_i_valid  ( .O(i_i_valid), .I(i_valid), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );",
        "  XMD ipad_o_ready  ( .O(i_o_ready), .I(o_ready), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );",
    ]
    xmd = (
        "  XMD ipad_i_data_{i} ( .O(i_i_data[{i}]), .I(i_data[{i}]), "
        ".PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );"
    )
    for i in range(IOPORT_IN_W):
        lines.append(xmd.format(i=i))

    lines.append(
        "  YA2GSD opad_i_ready ( .O(i_ready), .I(i_i_ready), "
        ".E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );"
    )
    lines.append(
        "  YA2GSD opad_o_valid ( .O(o_valid), .I(i_o_valid), "
        ".E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );"
    )
    opad = (
        "  YA2GSD opad_o_data_{i} ( .O(o_data[{i}]), .I(i_o_data[{i}]), "
        ".E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );"
    )
    for i in range(IOPORT_OUT_W):
        lines.append(opad.format(i=i))

    lines += [
        "",
        "  CHIP_core U_CORE (",
        "    .clk(i_clk),",
        "    .rst_n(i_rst_n),",
        "    .i_valid(i_i_valid),",
        "    .i_ready(i_i_ready),",
        "    .o_ready(i_o_ready),",
        "    .o_valid(i_o_valid),",
        "    .i_data(i_i_data),",
        "    .o_data(i_o_data)",
        "  );",
        "endmodule",
        "",
    ]
    return "\n".join(lines)


def main():
    root = Path(__file__).resolve().parent
    core_src = (
        Path(sys.argv[1])
        if len(sys.argv) > 1
        else root.parent.parent / "02_SYN/Netlist/CHIP_syn.v"
    )
    out = root / "CHIP_syn.v"

    text = core_src.read_text(encoding="utf-8")
    marker = "module CHIP ( clk, rst_n, i_valid, i_ready, o_ready, o_valid, i_data, o_data"
    if marker not in text:
        raise SystemExit(f"ERROR: top module marker not found in {core_src}")

    text = text.replace(
        marker,
        "module CHIP_core ( clk, rst_n, i_valid, i_ready, o_ready, o_valid, i_data, o_data",
        1,
    )

    header = (
        "/////////////////////////////////////////////////////////////\n"
        f"// APR netlist: {core_src.name} (CHIP_core) + IO pad shell ({IOPORT_IN_W}-bit in)\n"
        f"// Regenerate: python3 mk_apr_netlist.py [{core_src}]\n"
        "/////////////////////////////////////////////////////////////\n\n"
    )
    merged = header + text.rstrip() + "\n\n" + _pad_shell()

    out.write_text(merged, encoding="utf-8")
    print(f"Wrote {out} ({out.stat().st_size // 1024} KB)")
    print(f"  - CHIP_core : {IOPORT_IN_W}-bit i_data from {core_src}")
    print(f"  - module CHIP : {IOPORT_IN_W} XMD + {IOPORT_OUT_W} YA2GSD + U_CORE")


if __name__ == "__main__":
    main()
