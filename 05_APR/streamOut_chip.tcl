# Stream out merged GDS for Calibre DRC / LVS.
# Run in Innovus from 05_APR after route + filler + bond pads:
#   source streamOut_chip.tcl

streamOut CHIP.gds \
  -mapFile streamOut.map \
  -merge {./Phantom/fsa0m_a_generic_core_cic.gds ./Phantom/fsa0m_a_t33_generic_io_cic.gds ./Phantom/BONDPAD.gds} \
  -stripes 1 -units 1000 -mode ALL

puts "Done. Copy for DRC: cp CHIP.gds ../06_DRC/CHIP.gds"
