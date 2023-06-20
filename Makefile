# **************************************************************************** #
# General Make configuration

# This suppresses make's command echoing. This suppression produces a cleaner output. 
# If you need to see the full commands being issued by make, comment this out.
MAKEFLAGS += -s

# **************************************************************************** #
# Development Targets

# run the application
run: venv
	$(VENV_PYTHON) src/main.py

# run the application in pdb
debug: venv
	$(VENV_PYTHON) -m pdb src/main.py

# ---------------------------------------------------------------------------- #

# remove the various build outputs
clean:
	-@ $(RM) build
	-@ $(RM) dist

# **************************************************************************** #
# python venv settings
VENV_NAME := .venv
REQUIREMENTS := requirements.txt

VENV_DIR := $(VENV_NAME)

ifeq ($(OS),Windows_NT)
	VENV := $(VENV_DIR)/Scripts
	PYTHON := python
else
	VENV := $(VENV_DIR)/bin
	PYTHON := python3
endif

VENV_CANARY_DIR := $(VENV_DIR)/canary
VENV_CANARY_FILE := $(VENV_CANARY_DIR)/$(REQUIREMENTS)
VENV_TMP_DIR := $(VENV_DIR)/tmp
VENV_TMP_FREEZE := $(VENV_TMP_DIR)/freeze.txt
VENV_PYTHON := $(VENV)/$(PYTHON)
VENV_PYINSTALLER := $(VENV)/pyinstaller
RM := rm -rf 
CP := cp

# Add this as a requirement to any make target that relies on the venv
.PHONY: venv
venv: $(VENV_DIR) $(VENV_CANARY_FILE)

# Create the venv if it doesn't exist
$(VENV_DIR):
	$(PYTHON) -m venv $(VENV_DIR)

# Update the venv if the canary is out of date
$(VENV_CANARY_FILE): $(REQUIREMENTS)
	$(VENV_PYTHON) -m pip install --upgrade pip
	$(VENV_PYTHON) -m pip install -r $(REQUIREMENTS)
	-$(RM) $(VENV_CANARY_DIR)
	-mkdir $(VENV_CANARY_DIR)
	-$(CP) $(REQUIREMENTS) $(VENV_CANARY_FILE)

# forcibly update the canary file
canary: $(VENV_CANARY_DIR)
	-$(RM) $(VENV_CANARY_DIR)
	-mkdir $(VENV_CANARY_DIR)
	$(CP) $(REQUIREMENTS) $(VENV_CANARY_FILE)

# update requirements.txt to match the state of the venv
freeze_reqs: venv
	$(VENV_PYTHON) -m pip freeze > $(REQUIREMENTS)

# try to update the venv - expirimental feature, don't rely on it
update_venv: venv
	$(VENV_PYTHON) -m pip install --upgrade pip
	$(VENV_PYTHON) -m pip install --upgrade -r $(REQUIREMENTS)
	-$(RM) $(VENV_CANARY_DIR)
	-mkdir $(VENV_CANARY_DIR)
	-$(CP) $(REQUIREMENTS) $(VENV_CANARY_FILE)

# remove all packages from the venv
clean_venv:
	$(RM) $(VENV_CANARY_DIR)
	mkdir $(VENV_TMP_DIR)
	$(VENV_PYTHON) -m pip freeze > $(VENV_TMP_FREEZE)
	$(VENV_PYTHON) -m pip uninstall -y -r $(VENV_TMP_FREEZE)
	$(RM) $(VENV_TMP_DIR)

# clean the venv and rebuild it
reset_venv: clean_venv update_venv

# **************************************************************************** #
# expirimental, probably not reliable

# If the first argument is "pip"...
ifeq (pip,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "pip"
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

# forward pip commands to the venv
pip: venv
	$(VENV_PYTHON) -m pip $(RUN_ARGS)
