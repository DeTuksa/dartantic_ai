.PHONY: serve

serve:
	gollum $$(git rev-parse --show-toplevel) \
	       --page-file-dir wiki \
	       --ref compat-only \
	       --no-edit