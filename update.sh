if git diff-index --quiet HEAD --; then
    echo "No changes to bash-it-sync"
else
    echo "Changes to bash-it-sync have been detected, syncing..."
    git pull
    # source ~/.bashrc
fi
