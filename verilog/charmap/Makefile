charmap:
	wget http://downloads.sourceforge.net/project/terminus-font/terminus-font-4.40/terminus-font-4.40.tar.gz
	tar xvzf terminus-font-4.40.tar.gz
	ln -sf terminus-font-4.40/ter-u12n.bdf ter-u12n.bdf
	python2 gen_hex.py > charmap.hex

clean:
	rm -rf terminus-font-* charmap.hex ter-u12n.bdf
