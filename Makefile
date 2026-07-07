.PHONY: check docs serve clean distclean

check: docs

docs:
	uv run --group docs mkdocs build --strict

serve:
	uv run --group docs mkdocs serve

clean:
	rm -rf dist/ build/ site/ .cache/
	rm -rf .pytest_cache/ .ruff_cache/ .mypy_cache/ .ty/ .ty_cache/
	rm -rf htmlcov/ .coverage .coverage.* coverage.xml
	find . -path ./.venv -prune -o -type d -name '__pycache__' -exec rm -rf {} +
	find . -path ./.venv -prune -o -type d -name '*.egg-info' -exec rm -rf {} +
	find . -path ./.venv -prune -o -type f -name '*.py[co]' -exec rm -f {} +

distclean: clean
	rm -rf .venv/ uv.lock
