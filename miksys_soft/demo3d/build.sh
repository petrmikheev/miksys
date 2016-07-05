../compile.py main.S demo3d.bin
cat textures/brick.bin textures/roof.bin textures/wood.bin textures/window.bin >> demo3d.bin
../pack.py demo3d.bin ../serial_in
../pack_usb.py demo3d.bin demo3d.usb_packed
#cd ../../qt_sim_build
#./qt_sim
