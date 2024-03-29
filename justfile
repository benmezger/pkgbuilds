set shell := ["/bin/bash", "-c", "-eu", "-o", "pipefail"]
PACKAGE_FILE := "PACKAGES"
makepkg_flags := "-f"

arch := "x86_64"
pkgsdir := "./sedspkgs"

# Build order:
# 1. build <package>
# 2. pkgcheck <package>
# 3. copy <package>
# 4. manually run ./build-db.sh in $pkgsdir

all:
        @echo "Using {{PACKAGE_FILE}} file"
        just clone
        for pkg in `cat {{PACKAGE_FILE}}`; do \
            just single $pkg; \
        done

single target:
        just makepkg_flags={{makepkg_flags}} build {{target}}
        just pkgcheck {{target}}
        just pkgsdir={{pkgsdir}} copy {{target}}

build target:
        @echo "Building {{target}}"
        cd {{target}} && rm -f *.pkg.tar.zst
        cd {{target}} && MAKEFLAGS="-j $(nproc)" makepkg -s --noconfirm {{makepkg_flags}}

clean:
        find . -not -path "{{pkgsdir}}/*" -name *.pkg.tar.zst -exec rm -rfv {} \;

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

copy target:
        cp -v {{target}}/*.pkg.tar.zst {{pkgsdir}}/{{arch}}/

check-updates:
        @echo "Using {{PACKAGE_FILE}} file"
        for pkg in `cat {{PACKAGE_FILE}}`; do \
            just check-update $pkg
        done

check-update target:
        just makepkg_flags="--nobuild" build {{target}}; \
        cd {{target}} && git diff

clone:
        @echo "Initializing and cloning submodules"
        git submodule update --init --recursive
        git pull --recurse-submodules --jobs=10

push-packages:
        cd {{pkgsdir}} && ./build-db.sh
        cd {{pkgsdir}} && git add .
        cd {{pkgsdir}} && git status
        cd {{pkgsdir}} && git commit -m "Build at $(date)"
        cd {{pkgsdir}} && git push
