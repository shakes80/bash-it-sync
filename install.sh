git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
~/.bash_it/install.sh --interactive

echo "using --> BASH_IT VAR:$BASH_IT"

source ~/.bashrc

mkdir -p $BASH_IT/themes/shakes
ln -s -f ~/bash-it-sync/shakes.theme.bash $BASH_IT/themes/shakes/shakes.theme.bash
ln -s -f ~/bash-it-sync/custom.bash $BASH_IT/lib/custom.bash
ln -s -f ~/bash-it-sync/custom.aliases.bash $BASH_IT/aliases/custom.aliases.bash

source ~/.bashrc

install_custom_support
