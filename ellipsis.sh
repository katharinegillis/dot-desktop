#!/usr/bin/env bash

packages=(
    system
    git
    docker
    utils
    node
);

# Store the current package name because it changes in certain circumstances
packageName=$PKG_NAME;

pkg.install() {
    # Install the packages
    installUpdatePackages
}

pkg.link() {
    # Link up the dot files
    fs.link_files files
}

pkg.pull() {
    # Unlink files
    hooks.unlink

    # Pull down the updates
    git.pull

    # Re-link files
    pkg.link

    # Install new packages and update existing ones
    installUpdatePackages

    # Inform user of sourcing their bash to refresh their profile in case it changed
    echo "Please run \"source .bash_profile\" to refresh profile"
}

pkg.uninstall() {
    # Remove managed packages
    removePackages

    # Uninstall self
    hooks.uninstall
}

installUpdatePackages() {
    # Install new packages or update existing ones from the list
    for package in ${packages[*]}; do
        ellipsis.list_packages | grep "$ELLIPSIS_PACKAGES/$package" 2>&1 > /dev/null;
        if [ $? -ne 0 ]; then
            echo -e "\e[32mInstalling $package...\e[0m"
            ellipsis.install $package
        else
            echo -e "\e[32mUpdating $package...\e[0m"
            ellipsis.pull $package
        fi
    done

    # Uninstall orphaned packages
    for package in $(ellipsis.list_packages); do
        name=$(pkg.name_from_path $package)
        echo ${packages[*]} | grep "$name" 2>&1 > /dev/null
        if [ $? -ne 0 ] && [[ "$name" != "$packageName" ]]; then
            echo -e "\e[32mUninstalling $package...\e[0m"
            ellipsis.uninstall $package
        fi
    done
}

removePackages() {
    # Uninstall all installed packages on the list
    for package in ${packages[*]}; do
        ellipsis.list_packages | grep "$ELLIPSIS_PACKAGES/$package" 2>&1 > /dev/null;
        if [ $? -e 0 ]; then
            echo -e "\e[32mUninstalling $package...\e[0m"
            ellipsis.uninstall $package
        fi
    done
}