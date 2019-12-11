#!/usr/bin/env ksh
# -*- coding: utf-8 -*-

#
# Defines install bitwarden for osx or linux.
#
# Authors:
#   Luis Mayta <slovacus@gmail.com>
#
bw_package_name=@bitwarden/cli

ZSH_BW_PATH_ROOT=$(dirname "${0}":A)

# shellcheck source=/dev/null
source "${ZSH_BW_PATH_ROOT}"/src/helpers/messages.zsh

# shellcheck source=/dev/null
source "${ZSH_BW_PATH_ROOT}"/src/helpers/tools.zsh

_get_type () {
    local bw_type
    bw_type="${1}"
    echo "${bw_type}" \
        | awk '{
            split($0, array, "|")
            print array[1]
        }'
}

_get_id () {
    local bw_id
    bw_id=${1}
    echo "$bw_id" \
        | awk '{
            split($0, array, "|")
            print array[2]
        }'
}

_get_type_field () {
    local bw_type
    bw_type=$(_get_type "${1}")
    if [ "${bw_type}" -eq "1" ]
    then
        echo ".login.password"
    elif [ "${bw_type}" -eq "2" ]
    then
        echo ".notes";
    fi
}

_get_item_by_type() {
    local bw_id
    local bw_type_field
    bw_type_field=$(_get_type_field "${1}")
    bw_id=$(_get_id "${1}")
    bw get item "${bw_id}"  \
        | jq "${bw_type_field}" \
        | sed 's/\"//g' \
        | perl -pe 'chomp' \
        | pbcopy
}

function bw::validation {
    if ! type -p node > /dev/null; then
        message_error "is Neccesary Node"
    else
        bw::dependences
    fi
}

function bw::dependences {
    if ! type -p yarn > /dev/null; then
        message_info "Installing yarn"
        curl -o- -L https://yarnpkg.com/install.sh | bash
    fi
}

function bw::install {
    message_info "Installing ${bw_package_name}"
    bw::validation
    yarn global add ${bw_package_name}
    message_success "Installed {bw_package_name}"
}

function bw::search {
    if hash bw 2>/dev/null; then
        local bw_type_id
        bw_type_id=$(bw list items \
                         | jq '.[] | "\(.type) | \(.name) | username: \(.login.username) | id: \(.type)|\(.id)" ' \
                         | fzf \
                         | awk '{print $(NF -0)}' \
                         | perl -pe 'chomp' \
                         | sed 's/\"//g'
                  )
        _get_item_by_type "${bw_type_id}"

    fi
}

if ! type -p bw > /dev/null; then
    bw::install
fi