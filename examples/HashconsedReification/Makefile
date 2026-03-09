COQBIN?=

%: Makefile.rocq

Makefile.rocq: _RocqProject
	$(COQBIN)rocq makefile -f _RocqProject -o Makefile.rocq

-include Makefile.rocq
