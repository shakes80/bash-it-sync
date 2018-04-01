if [ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ]; then
    echo "No changes to bash-it-sync"
else
    echo "Changes to bash-it-sync have been detected, syncing..."
    git pull -q
    # source ~/.bashrc
fi

