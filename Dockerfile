FROM squidfunk/mkdocs-material:9.7

# Install additional python dependencies.
RUN pip install markdown-callouts mkdocs-nav-weight

USER guest
