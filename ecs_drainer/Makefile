.PHONY: test clean

install: clean venv
	. ./venv/bin/activate; \
	pip install -r drainer/requirements.txt -t package
	cp drainer/index.py package/
	(cd package && zip -r ../index.zip .)

clean:
	rm -rf venv package

test:
	. ./venv/bin/activate; \
	pip install -r drainer/requirements.txt -r test/requirements.txt


venv:
	virtualenv venv
