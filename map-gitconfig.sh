#!/bin/bash
# @brief Set up gitconfig by mapping from a source gitconfig file.

# Only these specified keys will be mapped to gitconfig.
KEYS_TO_COPY=(
  user.name
  user.email
  push.default
  commit.template
)

# @decsription Update the specified key based on the source gitconfig.
#
# @arg $1 str Destination gitconfig flag, like --global, --local, etc.
# @arg $2 str Source gitconfig file.
# @arg $3 str Key to update.
#
# @exitcode 0 Successful.
# @exitcode 1 Invalid number of arguments.
copy-from-source() {
  local -r NUM_ARGS=3
  if [[ $# != "${NUM_ARGS}" ]]; then
    (2>&1 echo "Invalid number of arguments ($# != ${NUM_ARGS})")
    return 1
  fi
  local -r destination_flag="$1"
  local -r source_gitconfig="$2"
  local -r key="$3"

  local -r value="$(git config --file "${source_gitconfig}" "${key}")"
  echo "Mapping ${key}=${value}"
  git config "${destination_flag}" "${key}" "${value}"
}

# @description Map values from git configuration which work in docker.
#
# @arg $1 str Flag to pass to gitconfig to specify the destination.
# @arg $2 str Source gitconfig file from which to map.
#
# @example
#   map-git-config --local source.gitconfig
#   map-git-config --global source.gitconfig
#   map-git-config --worktree source.gitconfig
#
# @exitcode 0 Successful.
# @exitcode 1 Invalid number of arguments.
map-git-config() {
  local -r NUM_ARGS=2
  if [[ $# != "${NUM_ARGS}" ]]; then
    (2>&1 echo "Invalid number of arguments ($# != ${NUM_ARGS})")
    return 1
  fi
  local -r destination_flag="$1"
  local -r source_gitconfig="$2"

  for key in ${KEYS_TO_COPY[@]}; do
    copy-from-source "${destination_flag}" "${source_gitconfig}" "${key}"
  done
}

# @description Set up gitconfig before entering executing the docker command.
#
# Map some gitconfig values from the host configuration.
#
# The mapping only works if the user has mounted a gitconfig file to
# ${HOME}/.host.gitconfig.
main() {
  local -r source_gitconfig="${HOME}/.host.gitconfig"
  (
    set -e
    if [[ -f "${source_gitconfig}" ]]; then
      echo "Mapping host gitconfig."
      map-git-config --global "${source_gitconfig}"
    fi
  )

  . /opt/ros/"${ROS_DISTRO}"/setup.bash
  exec "$@"
}

main "$@"
