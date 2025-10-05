if status is-interactive
	if not functions -q fisher
		curl -sL https://git.io/fisher | source
		fisher install jorgebucaran/fisher
	end
end

function _addpath_if_exists
	for p in $argv
		if test -d $p
			fish_add_path -U $p
		end
	end
end

_addpath_if_exists \
	$HOME/.cargo/bin \
	$HOME/.local/bin \
	/usr/local/bin \
	$HOME/.config \
	$HOME/.bun/bin \
	$HOME/.volta/bin

type -q starship; and starship init fish | source
type -q zoxide; and zoxide init fish | source
type -q atuin; and atuin init fish | source
type -q fzf; and fzf --fish | source

set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
if not test -d ~/.config/fish/completions
	mkdir -p ~/.config/fish/completions
end

if type -q carapace
	carapace _carapace | source
end

set -g fish_greeting ""

fish_vi_key_bindings

# Aliases
alias ls='ls --color=auto'
type -q eza; and alias ls='eza -lah --icons --group-directories-first'

alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
function fzfnvim --description "Fuzzy-open file in Neovim with bat preview"
    set -l file (fzf --preview 'bat --theme=gruvbox-dark --color=always {}')
    if test -n "$file"
        nvim "$file"
    end
end


set -l foreground F3F6F9 normal
set -l selection 263356 normal
set -l comment 8394A3 brblack
set -l red CB7C94 red
set -l orange DEBA87 orange
set -l yellow FFE066 yellow
set -l green B7CC85 green
set -l purple A3B5D6 purple
set -l cyan 7AA89F cyan
set -l pink FF8DD7 magenta

set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment
