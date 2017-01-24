#!/bin/bash
echo "Installing GateOne..."
virtualenv --no-site-packages venv
source venv/bin/activate
python setup.py install > /dev/null
./venv/bin/gateone --disable_ssl --port=8000 --configure