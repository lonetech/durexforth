C1541   = c1541
AS = acme
# deploy 1571 (d71) or 1581 (d81); e.g. make DISK_SUF=d81 deploy
DISK_SUF = d64

TAG := $(shell git describe --tags --abbrev=0 || svnversion --no-newline)
TAG_DEPLOY_DOT := $(shell git describe --tags --long --dirty=_m | sed 's/-g[0-9a-f]\+//' | tr _- -.)
TAG_DEPLOY := $(shell git describe --tags --abbrev=0 --dirty=_M | tr _. -_)
GIT_HASH := $(shell git rev-parse --short HEAD)

DEPLOY_NAME = durexforth-$(TAG_DEPLOY)
DISK_IMAGE = durexforth.$(DISK_SUF)

X64_OPTS = -warp
X64 = x64
X64_OPTS += +confirmonexit
# Load faster
X64_OPTS += -autostartprgmode 1 +drive8truedrive -virtualdev8
# Exit automatically, whether failure or success
X64_OPTS += -jamaction 5 -limitcycles 500000000
# Run headless and save screenshot of results
X64_OPTS += -exitscreenshot build/screenshot -console +sound

SRC_DIR = forth_src
SRC_NAMES = base debug v asm gfx gfxdemo rnd sin ls turtle fractals \
    sprite doloop sys labels mml mmldemo sid spritedemo test testcore \
    testcoreplus tester format require compat timer float viceutil turnkey \
    wordlist io open dos see testsee
SRCS = $(addprefix $(SRC_DIR)/,$(addsuffix .fs,$(SRC_NAMES)))

SEPARATOR_NAME1 = '=-=-=-=-=-=-=-=,s'
SEPARATOR_NAME2 = '=-------------=,s'
SEPARATOR_NAME3 = '=-=---=-=---=-=,s'

all: $(DISK_IMAGE)

.PHONY: deploy
deploy deploy/$(DEPLOY_NAME).$(DISK_SUF): $(DISK_IMAGE) asm_src/cart.asm
	rm -rf deploy
	mkdir deploy
	cp $(DISK_IMAGE) deploy/$(DEPLOY_NAME).$(DISK_SUF)
	$(X64) $(X64_OPTS) deploy/$(DEPLOY_NAME).$(DISK_SUF)
	# make cartridge
	c1541 -attach deploy/$(DEPLOY_NAME).$(DISK_SUF) -read durexforth build/durexforth
	@$(AS) asm_src/cart.asm
	cartconv -t simon -i build/cart.bin -o deploy/$(DEPLOY_NAME).crt -n "DUREXFORTH $(TAG_DEPLOY_DOT)"
	asciidoctor-pdf -o deploy/$(DEPLOY_NAME).pdf docs_src/index.adoc

build/words: deploy/$(DEPLOY_NAME).$(DISK_SUF)
	# include viceutil
	# 9 device
	# dump-labels
	cat build/header 'dump-labels here 2 c, execute' | ext/petcom - > build/makewords
	$(X64) $(X64_OPTS) -fs9 build +drive9truedrive -virtualdev9 -keybuf 'require viceutil 9 device include makewords\x0d' $<

forth.lbl: build/words
	petcat -text -o $@ $<

durexforth.prg acme.lbl: asm_src/*.asm
	@$(AS) --vicelabels acme.lbl -I asm_src asm_src/durexforth.asm

.ONESHELL:
$(DISK_IMAGE): durexforth.prg Makefile ext/petcom $(SRCS)
	mkdir -p build
	touch build/empty
	echo  >build/c1541.script format "durexforth,DF" $(DISK_SUF) $@
	echo >>build/c1541.script write durexforth.prg durexforth
	echo >>build/c1541.script write build/empty $(SEPARATOR_NAME1)
	echo >>build/c1541.script write build/empty $(TAG_DEPLOY_DOT),s
	echo >>build/c1541.script write build/empty '  '$(GIT_HASH),s
	echo >>build/c1541.script write build/empty $(SEPARATOR_NAME2)
	echo -n "aa" > build/header
	@for forth in $(SRC_NAMES); do\
		cat build/header $(SRC_DIR)/$$forth.fs | ext/petcom - > build/$$forth.pet; \
		echo >>build/c1541.script write build/$$forth.pet $$forth; \
	done;
	echo >>build/c1541.script write build/empty $(SEPARATOR_NAME3)
	c1541 <build/c1541.script

docs: docs/index.html

docs/index.html: docs_src/index.adoc docs_src/words.adoc docs_src/links.adoc docs_src/sid.adoc docs_src/asm.adoc \
	docs_src/mnemonics.adoc docs_src/memmap.adoc docs_src/anatomy.adoc LICENSE.txt docs_src/tutorial.adoc \
	docs_src/intro.adoc
	rm -rf docs
	asciidoctor -a revnumber=$(shell git describe --tags --dirty) -a revdate=$(shell git log -1 --format=%as) -o docs/index.html docs_src/index.adoc

clean:
	rm -f *.lbl *.prg *.$(DISK_SUF)
	rm -rf build deploy
