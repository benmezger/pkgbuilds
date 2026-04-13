set shell := ["/bin/bash", "-c", "-eu", "-o", "pipefail"]
makepkg_flags := "-f"

arch := "x86_64"

# Build order:
# 1. build <package>
# 2. pkgcheck <package>
# 3. copy <package>

single target:
        just makepkg_flags={{makepkg_flags}} build {{target}}
        just pkgcheck {{target}}

build target:
        @echo "Building {{target}}"
        cd {{target}} && rm -f *.pkg.tar.zst
        cd {{target}} && MAKEFLAGS="-j $(nproc)" makepkg -s --noconfirm {{makepkg_flags}}

pkgcheck target:
        @echo "Checking if there is no new package update"
        # NOTE: this check is for in case we ran makepkg on a git-based package,
        # and that package was updated. In this case, we want to exit so we can
        # manually fix the package
        if git status --porcelain | grep -q {{target}}; then \
            echo "WARNING: Package was updated, check the new version, commit and rebuild."; \
            git diff {{target}}; \
        fi ; \
        if ! ls {{target}} | grep -q pkg.tar.zst ; then \
              echo "WARNING: No generated PKG found for {{target}}"; \
        fi

check-updates:
        @echo "Using {{PACKAGE_FILE}} file"
        for pkg in `cat {{PACKAGE_FILE}}`; do \
            just check-update $pkg
        done

check-update target:
        just makepkg_flags="--nobuild" build {{target}}; \
        cd {{target}} && git diff
