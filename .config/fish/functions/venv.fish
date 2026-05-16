function venv
    if test -f .venv/bin/activate.fish
        source .venv/bin/activate.fish
    else
        python -m venv .venv
        source .venv/bin/activate.fish
    end
end
