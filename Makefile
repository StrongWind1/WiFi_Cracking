.PHONY: docs serve clean distclean

docs:
	uv run --group docs mkdocs build --strict

serve:
	uv run --group docs mkdocs serve

clean:
	rm -rf site/ .cache/ .ruff_cache/ .pytest_cache/
	find . -path ./.venv -prune -o -type d -name '__pycache__' -exec rm -rf {} +
	find . -path ./.venv -prune -o -type f -name '*.py[co]' -exec rm -f {} +

distclean: clean
	rm -rf .venv/
