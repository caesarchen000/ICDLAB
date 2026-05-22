#!/usr/bin/env python3
"""Merge DC core netlist (02_SYN) with IO pad shell for Innovus APR."""
import re
import sys
from pathlib import Path

PAD_SHELL = r'''
// IO pad shell (from APR kit; not synthesized by DC)
module CHIP ( clk, rst_n, i_valid, i_ready, o_ready, o_valid, i_data, o_data );
  input clk, rst_n, i_valid, o_ready;
  output i_ready, o_valid;
  input [15:0] i_data;
  output [10:0] o_data;

  wire n_logic0, n_logic1;
  wire i_clk, i_rst_n, i_i_valid, i_o_ready;
  wire [15:0] i_i_data;
  wire i_i_ready, i_o_valid;
  wire [10:0] i_o_data;

  TIE0 U_TIE0 ( .O(n_logic0) );
  TIE1 U_TIE1 ( .O(n_logic1) );

  XMD ipad_clk      ( .O(i_clk),     .I(clk),     .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_rst_n    ( .O(i_rst_n),   .I(rst_n),   .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_valid  ( .O(i_i_valid), .I(i_valid), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_o_ready  ( .O(i_o_ready), .I(o_ready), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_0 ( .O(i_i_data[0]), .I(i_data[0]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_1 ( .O(i_i_data[1]), .I(i_data[1]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_2 ( .O(i_i_data[2]), .I(i_data[2]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_3 ( .O(i_i_data[3]), .I(i_data[3]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_4 ( .O(i_i_data[4]), .I(i_data[4]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_5 ( .O(i_i_data[5]), .I(i_data[5]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_6 ( .O(i_i_data[6]), .I(i_data[6]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_7 ( .O(i_i_data[7]), .I(i_data[7]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_8 ( .O(i_i_data[8]), .I(i_data[8]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_9 ( .O(i_i_data[9]), .I(i_data[9]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_10 ( .O(i_i_data[10]), .I(i_data[10]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_11 ( .O(i_i_data[11]), .I(i_data[11]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_12 ( .O(i_i_data[12]), .I(i_data[12]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_13 ( .O(i_i_data[13]), .I(i_data[13]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_14 ( .O(i_i_data[14]), .I(i_data[14]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );
  XMD ipad_i_data_15 ( .O(i_i_data[15]), .I(i_data[15]), .PU(n_logic0), .PD(n_logic0), .SMT(n_logic0) );

  YA2GSD opad_i_ready ( .O(i_ready), .I(i_i_ready), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_valid ( .O(o_valid), .I(i_o_valid), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_0 ( .O(o_data[0]), .I(i_o_data[0]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_1 ( .O(o_data[1]), .I(i_o_data[1]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_2 ( .O(o_data[2]), .I(i_o_data[2]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_3 ( .O(o_data[3]), .I(i_o_data[3]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_4 ( .O(o_data[4]), .I(i_o_data[4]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_5 ( .O(o_data[5]), .I(i_o_data[5]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_6 ( .O(o_data[6]), .I(i_o_data[6]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_7 ( .O(o_data[7]), .I(i_o_data[7]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_8 ( .O(o_data[8]), .I(i_o_data[8]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_9 ( .O(o_data[9]), .I(i_o_data[9]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );
  YA2GSD opad_o_data_10 ( .O(o_data[10]), .I(i_o_data[10]), .E(n_logic1), .E2(n_logic0), .E4(n_logic0), .E8(n_logic0), .SR(n_logic0) );

  CHIP_core U_CORE (
    .clk(i_clk),
    .rst_n(i_rst_n),
    .i_valid(i_i_valid),
    .i_ready(i_i_ready),
    .o_ready(i_o_ready),
    .o_valid(i_o_valid),
    .i_data(i_i_data),
    .o_data(i_o_data)
  );
endmodule
'''


def main():
    root = Path(__file__).resolve().parent
    core_src = Path(sys.argv[1]) if len(sys.argv) > 1 else root.parent.parent / "02_SYN/Netlist/CHIP_syn.v"
    out = root / "CHIP_syn.v"
    core_only_backup = root / "CHIP_syn_core_only.v"

    text = core_src.read_text(encoding="utf-8")
    marker = "module CHIP ( clk, rst_n, i_valid, i_ready, o_ready, o_valid, i_data, o_data"
    if marker not in text:
        raise SystemExit(f"ERROR: top module marker not found in {core_src}")

    # Rename DC top CHIP -> CHIP_core for pad shell instantiation
    text = text.replace(marker, "module CHIP_core ( clk, rst_n, i_valid, i_ready, o_ready, o_valid, i_data, o_data", 1)

    header = (
        "/////////////////////////////////////////////////////////////\n"
        f"// APR netlist: {core_src.name} (CHIP_core) + IO pad shell\n"
        f"// Regenerate: python3 mk_apr_netlist.py [{core_src}]\n"
        "/////////////////////////////////////////////////////////////\n\n"
    )
    merged = header + text.rstrip() + "\n\n" + PAD_SHELL.lstrip()

    if out.exists() and not core_only_backup.exists():
        core_only_backup.write_text(out.read_text(encoding="utf-8"), encoding="utf-8")
        print(f"Backed up previous {out.name} -> {core_only_backup.name}")

    out.write_text(merged, encoding="utf-8")
    print(f"Wrote {out} ({out.stat().st_size // 1024} KB)")
    print("  - CHIP_core : from", core_src)
    print("  - module CHIP : IO pads (XMD/YA2GSD) + U_CORE")


if __name__ == "__main__":
    main()
