#!/usr/bin/env bash

MODE="home"
if [ ! -f "$HOME/.ellipsis-desktop-mode" ]; then
    echo "Install home dotfiles or work dotfiles? [home/work]: "
    read var
    if [ "$var" != "home" ] && [ "$var" != "work" ]; then
        echo "Invalid selection - please enter home or work on your next attempt. Exiting."
        exit 1
    fi

    echo "$var" > "$HOME/.ellipsis-desktop-mode"
    MODE="$var"
else
    MODE=$(cat "$HOME/.ellipsis-desktop-mode")
fi

KERNEL_VERSION=$(cat /proc/version)

if [ "$MODE" == "home" ]; then
    packages=(
        katharinegillis/common
        katharinegillis/vim
        katharinegillis/git
        kathrinegillis/phpstorm
    );
else
    packages=(
        katharinegillis/common
        katharinegillis/windowsterminal
        katharinegillis/vcxsrv
        katharinegillis/firefox
        katharinegillis/sublime
        katharinegillis/dockerdesktop
        katharinegillis/system
        katharinegillis/git
        katharinegillis/docker
        katharinegillis/utils
        katharinegillis/node
        katharinegillis/php
        katharinegillis/phpstorm
        katharinegillis/dev
    );
fi

# Store the current package name because it changes in certain circumstances
packageName=$PKG_NAME;

pkg.install() {
    # Install the packages
    installUpdatePackages

    # Summarize the installs.
    printSummary
}

pkg.link() {
    # Link up the dot files
    fs.link_files files
}

pkg.pull() {
    # Check for updates on git
    git remote update 2>&1 > /dev/null
    if git.is_behind; then
        # Unlink files
        hooks.unlink

        # Pull down the updates
        git.pull

        # Re-link files
        pkg.link
    fi

    # Install new packages and update existing ones
    installUpdatePackages

    # Summarize the updates.
    printSummary
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
	IFS='/' read -ra packageParsed <<< "$package"
        ellipsis.list_packages | grep "$ELLIPSIS_PACKAGES/${packageParsed[1]}" 2>&1 > /dev/null;
        if [ $? -ne 0 ]; then
            echo -e "\e[32mInstalling $package...\e[0m"
            $ELLIPSIS_PATH/bin/ellipsis install $package;

            if [ "$?" == "1" ]; then
                exit 1
            fi
        else
            echo -e "\e[32mUpdating $package...\e[0m"
            $ELLIPSIS_PATH/bin/ellipsis pull ${packageParsed[1]};

            if [ "$?" == "1" ]; then
                exit 1
            fi
        fi
    done

    # Uninstall orphaned packages
    for package in $(ellipsis.list_packages); do
        name=$(pkg.name_from_path $package)
        echo ${packages[*]} | grep "$name" 2>&1 > /dev/null
        if [ $? -ne 0 ] && [[ "$name" != "$packageName" ]]; then
            echo -e "\e[32mUninstalling $package...\e[0m"
            $ELLIPSIS_PATH/bin/ellipsis uninstall $package;

            if [ "$?" == "1" ]; then
                exit 1
            fi
        fi
    done
}

removePackages() {
    # Uninstall all installed packages on the list
    for package in ${packages[*]}; do
        ellipsis.list_packages | grep "$ELLIPSIS_PACKAGES/$package" 2>&1 > /dev/null;
        if [ $? = 0 ]; then
            echo -e "\e[32mUninstalling $package...\e[0m"
            $ELLIPSIS_PATH/bin/ellipsis uninstall $package;

            if [ "$?" == "1" ]; then
                exit 1
            fi
        fi
    done
}

printSummary() {
    echo -e "\n\e[32mSUMMARY\e[0m\n"

    installed=0
    updated=0
    uninstalled=0
    errored=0
    warned=0

    if [ -f "$HOME/ellipsis_installed.log" ]; then
        installed=$(cat "$HOME/ellipsis_installed.log" | wc -l)
        rm -rf "$HOME/ellipsis_installed.log"
    fi
    if [ -f "$HOME/ellipsis_updated.log" ]; then
        updated=$(cat "$HOME/ellipsis_updated.log" | wc -l)
        rm -rf "$HOME/ellipsis_updated.log"
    fi
    if [ -f "$HOME/ellipsis_uninstalled.log" ]; then
        uninstalled=$(cat "$HOME/ellipsis_uninstalled.log" | wc -l)
        rm -rf "$HOME/ellipsis_uninstalled.log"
    fi
    if [ -f "$HOME/ellipsis_errored.log" ]; then
        errored=$(cat "$HOME/ellipsis_errored.log" | wc -l)
        rm -rf "$HOME/ellipsis_errored.log"
    fi
    if [ -f "$HOME/ellipsis_warned.log" ]; then
        warned=$(cat "$HOME/ellipsis_warned.log" | wc -l)
        rm -rf "$HOME/ellipsis_warned.log"
    fi

    echo -e "\e[32m$installed packages installed"
    echo -e "\e[32m$updated packages updated"
    echo -e "\e[32m$uninstalled packages uninstalled\n"
    echo -e "\e[31m$errored packages errored"
    echo -e "\e[33m$warned packages issued warnings\n\e[0m"

    if [[ "$KERNEL_VERSION" == *"microsoft"* ]]; then
        echo "If you are installing for the first time, the above counts may be wrong due to having to restart the installation process after a reboot.\n"
    fi

    if [ -f "$HOME/ellipsis_errors.log" ]; then
        cat "$HOME/ellipsis_errors.log"
        rm -rf "$HOME/ellipsis_errors.log"
    fi

    if [ -f "$HOME/ellipsis_warnings.log" ]; then
        cat "$HOME/ellipsis_warnings.log"
        rm -rf "$HOME/ellipsis_warnings.log"
    fi

    if [ "$installed" != "0" ] || [ "$updated" != "0" ] || [ "$uninstalled" != "0" ]; then
        echo -e "\e[33mPlease run \"source .bash_profile\" to refresh profile\e[0m"
    fi
}