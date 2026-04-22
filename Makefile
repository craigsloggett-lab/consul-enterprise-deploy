MODULE_REPO ?= https://github.com/craigsloggett/terraform-aws-consul-enterprise.git
BRANCH      ?=

.PHONY: help sha update upgrade validate format lint docs

help:
	@echo "Usage:"
	@echo "  make sha    BRANCH=<name>                Print latest commit SHA on BRANCH"
	@echo "  make update BRANCH=<name>                Update ref= in main.tf to that SHA"
	@echo ""
	@echo "Override: MODULE_REPO=<url>"

sha:
	@: $${BRANCH:?BRANCH is required, e.g. make sha BRANCH=cool-new-feature}
	@git ls-remote $(MODULE_REPO) refs/heads/$(BRANCH) | cut -f1

update:
	@: $${BRANCH:?BRANCH is required, e.g. make update BRANCH=cool-new-feature}
	@SHA=$$(git ls-remote $(MODULE_REPO) refs/heads/$(BRANCH) | cut -f1); \
	[ -n "$$SHA" ] || { echo "Error: Branch '$(BRANCH)' not found on $(MODULE_REPO)" >&2; exit 1; }; \
	TMP=$$(mktemp -d)/main.tf; \
	trap 'rm -f "$$TMP" "$$TMP.new"' EXIT INT TERM; \
	sed '/# tflint-ignore: terraform_module_pinned_source/d' main.tf > "$$TMP" && \
	sed "s|ref=[^\"]*|ref=$$SHA|" "$$TMP" > "$$TMP.new" && mv "$$TMP.new" "$$TMP" && \
	awk '/source *= *"git::/ { print "# tflint-ignore: terraform_module_pinned_source" } 1' "$$TMP" > "$$TMP.new" && mv "$$TMP.new" "$$TMP" && \
	terraform fmt "$$TMP" && \
	mv "$$TMP" main.tf

all: upgrade validate format lint docs

# Linting

.PHONY: lint-yamllint lint-shellcheck lint-tflint

lint-yamllint:
	yamllint .

lint-shellcheck:
	find . -type f -name '*.sh' \
		-not -path './.git/*' \
	| while IFS= read -r file; do shellcheck "$${file}"; done

lint-tflint:
	tflint --recursive --format=compact

# All

upgrade:
	terraform init -upgrade

validate:
	terraform validate

format:
	terraform fmt --recursive

lint: lint-yamllint lint-shellcheck lint-tflint

docs: upgrade
	terraform-docs .

test:
	git ls-remote https://github.com/craigsloggett/terraform-aws-consul-enterprise.git refs/heads/align-variables-outputs | cut -f1
