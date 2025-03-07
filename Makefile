MAKEFILE:=$(abspath $(firstword $(MAKEFILE_LIST)))
SRCDIR:=$(shell dirname $(abspath $(firstword $(MAKEFILE_LIST))))
JULIA ?= julia --startup-file=no
# PREFIX ?= ${SRCDIR}/build
YGGBINDIR ?= ${SRCDIR}/build/bin
MAKEFLAGS += --no-print-directory

export JULIA_LOAD_PATH=${SRCDIR}/Project.toml:@stdlib
export JULIA_PROJECT=

ygg: ${YGGBINDIR}/ygg

install-ygg:
	$(MAKE) ygg

uninstall-ygg:
	rm -f ${YGGBINDIR}/ygg

update-ygg: ${YGGBINDIR}/ygg
	git -C ${SRCDIR} pull
	$(MAKE) uninstall-ygg
	$(MAKE) ygg

.PHONY: ygg install-ygg uninstall-ygg update-ygg

${YGGBINDIR}/ygg: ${YGGBINDIR}
	echo '#!/bin/bash' > $@
	@echo 'export YGGBINDIR=$${YGGBINDIR:-$(YGGBINDIR)}' >> $@
	@echo 'pat='\''^(install|uninstall|update) .*$$'\' >> $@
	@echo 'if [[ $$# == 2 ]] && [[ "$$*" =~ $$pat ]]; then' >> $@
	@echo '    make -C '"${SRCDIR}"' "$$1"-"$$2"' >> $@
	@echo '    exit $$?' >> $@
	@echo 'fi' >> $@
	@echo 'if [[ "$$*" == "--help" ]]; then' >> $@
	@echo '    exitcode=0' >> $@
	@echo 'else' >> $@
	@echo '    exitcode=1' >> $@
	@echo 'fi' >> $@
	@echo '' >> $@
	@echo 'echo "Usage:' >> $@
	@echo '    ygg install <binary>' >> $@
	@echo '    ygg update <binary>' >> $@
	@echo '    ygg uninstall <binary>' >> $@
	@echo '' >> $@
	@echo 'Install, update or uninstall <binary> to the configured \$${YGGBINDIR} location ($${YGGBINDIR}).' >> $@
	@echo '' >> $@
	@echo 'Examples:' >> $@
	@echo '    ygg install zstd' >> $@
	@echo '    ygg update zstd' >> $@
	@echo '    ygg uninstall zstd"' >> $@
	@echo '' >> $@
	@echo 'exit $$exitcode' >> $@
	chmod +x ${YGGBINDIR}/ygg

${YGGBINDIR}:
	mkdir -p $@

${SRCDIR}/Project.toml:
	touch ${SRCDIR}/Project.toml

${SRCDIR}/Manifest.toml: ${SRCDIR}/Project.toml
	${JULIA} -e 'import Pkg; Pkg.instantiate()'

install-%:
	@echo "Unknown package $*\n" 1>&2
	@exit 1

uninstall-%:
	@echo "Unknown package $*\n" 1>&2
	@exit 1

update-%:
	@echo "Unknown package $*\n" 1>&2
	@exit 1

.PHONY: install-% uninstall-% update-%

## Installation rule for "simple" binaries that need nothing except
## PATH and LD_LIBRARY_PATH set up. Usage:
##     simple-install binary jll_package jll_func
define simple-install

install-$(1): ${YGGBINDIR}/$(1)

${YGGBINDIR}/$(1): ${SRCDIR}/Manifest.toml
	grep -q $(2) ${SRCDIR}/Project.toml || \
	    ${JULIA} -e 'import Pkg; Pkg.add("$(2)")'
	${JULIA} -e 'import Pkg; Pkg.instantiate()'
	${JULIA} ${SRCDIR}/generate_shims.jl $(1) $(2) $(3) ${YGGBINDIR}

uninstall-$(1):
	${JULIA} -e 'import Pkg; try Pkg.rm("$(2)") catch e end'
	rm -f ${YGGBINDIR}/$(1)

update-$(1):
	${JULIA} -e 'import Pkg; Pkg.update("$(2)")'
	${JULIA} ${SRCDIR}/generate_shims.jl $(1) $(2) $(3) ${YGGBINDIR}

.PHONY: install-$(1) uninstall-$(1) update-$(1)
endef

$(eval $(call simple-install,convert,ImageMagick_jll,imagemagick_convert))
$(eval $(call simple-install,duf,duf_jll,duf))
$(eval $(call simple-install,ffmpeg,FFMPEG_jll,ffmpeg))
$(eval $(call simple-install,ffprobe,FFMPEG_jll,ffprobe))
$(eval $(call simple-install,fzf,fzf_jll,fzf))
$(eval $(call simple-install,gh,gh_cli_jll,gh))
$(eval $(call simple-install,ghr,ghr_jll,ghr))
$(eval $(call simple-install,git,Git_jll,git))
$(eval $(call simple-install,git-crypt,git_crypt_jll,git_crypt))
$(eval $(call simple-install,gof3r,s3gof3r_jll,gof3r))
$(eval $(call simple-install,identify,ImageMagick_jll,identify))
$(eval $(call simple-install,kubectl,kubectl_jll,kubectl))
$(eval $(call simple-install,pandoc,pandoc_jll,pandoc))
$(eval $(call simple-install,pandoc-crossref,pandoc_crossref_jll,pandoc_crossref))
$(eval $(call simple-install,rr,rr_jll,rr))
$(eval $(call simple-install,unpaper,unpaper_jll,unpaper))
$(eval $(call simple-install,tectonic,tectonic_jll,tectonic))
$(eval $(call simple-install,tokei,Tokei_jll,tokei))
$(eval $(call simple-install,tmux,tmux_jll,tmux))
$(eval $(call simple-install,zstd,Zstd_jll,zstd))
$(eval $(call simple-install,zstdmt,Zstd_jll,zstdmt))
$(eval $(call simple-install,rclone,Rclone_jll,rclone))
$(eval $(call simple-install,node,NodeJS_16_jll,node))
$(eval $(call simple-install,npm,NodeJS_16_jll,node))
$(eval $(call simple-install,clang,Clang_jll,clang))
$(eval $(call simple-install,clang++,Clang_jll,clang))
$(eval $(call simple-install,rg,ripgrep_jll,rg))
$(eval $(call simple-install,htop,Htop_jll,htop))
$(eval $(call simple-install,7z,p7zip_jll,p7zip))
$(eval $(call simple-install,rsvg-convert,Librsvg_jll,rsvg_convert))
$(eval $(call simple-install,gmsh,gmsh_jll,gmsh))
$(eval $(call simple-install,neper,neper_jll,neper))
$(eval $(call simple-install,make,GNUMake_jll,make))

### Poppler-utils
$(eval $(call simple-install,pdfattach,Poppler_jll,pdfattach))
$(eval $(call simple-install,pdfdetach,Poppler_jll,pdfdetach))
$(eval $(call simple-install,pdffonts,Poppler_jll,pdffonts))
$(eval $(call simple-install,pdfimages,Poppler_jll,pdfimages))
$(eval $(call simple-install,pdfinfo,Poppler_jll,pdfinfo))
$(eval $(call simple-install,pdfseparate,Poppler_jll,pdfseparate))
$(eval $(call simple-install,pdftocairo,Poppler_jll,pdftocairo))
$(eval $(call simple-install,pdftohtml,Poppler_jll,pdftohtml))
$(eval $(call simple-install,pdftoppm,Poppler_jll,pdftoppm))
$(eval $(call simple-install,pdftops,Poppler_jll,pdftops))
$(eval $(call simple-install,pdftotext,Poppler_jll,pdftotext))
$(eval $(call simple-install,pdfunite,Poppler_jll,pdfunite))
