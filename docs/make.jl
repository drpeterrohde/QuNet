using Documenter, Main.QuNet

makedocs(
    sitename = "QuNet",
    modules = [QuNet]
)

# deploydocs(
#     deps = Deps.pip("pygments", "mkdocs", "python-markdown-math")
# )
