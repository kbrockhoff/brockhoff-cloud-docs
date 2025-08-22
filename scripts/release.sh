#!/bin/bash

# Brockhoff Cloud Release Script
# Automates semantic versioning and release process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGELOG_FILE="$REPO_ROOT/CHANGELOG.md"
VERSION_FILE="$REPO_ROOT/VERSION"

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_help() {
    cat << EOF
Brockhoff Cloud Release Script

USAGE:
    $0 [OPTIONS] <VERSION_TYPE>

VERSION_TYPE:
    major       Increment major version (X.0.0)
    minor       Increment minor version (x.Y.0)
    patch       Increment patch version (x.y.Z)
    prerelease  Create prerelease version (x.y.z-alpha.N)
    custom      Specify custom version

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Show what would be done without making changes
    -f, --force         Skip confirmation prompts
    -p, --prerelease    Create prerelease version
    -v, --version       Specify custom version (use with 'custom' type)
    --skip-tests        Skip running tests before release
    --skip-changelog    Skip updating changelog

EXAMPLES:
    $0 patch                    # Create patch release (1.0.0 -> 1.0.1)
    $0 minor                    # Create minor release (1.0.1 -> 1.1.0)
    $0 major                    # Create major release (1.1.0 -> 2.0.0)
    $0 prerelease               # Create prerelease (1.1.0 -> 1.1.1-alpha.1)
    $0 custom -v 2.0.0-beta.1   # Create custom version
    $0 patch --dry-run          # Show what patch release would do
    $0 minor --force            # Create minor release without confirmation

EOF
}

get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        # Try to get from git tags
        git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0"
    fi
}

parse_version() {
    local version="$1"
    if [[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-zA-Z0-9]+)\.([0-9]+))?$ ]]; then
        MAJOR="${BASH_REMATCH[1]}"
        MINOR="${BASH_REMATCH[2]}"
        PATCH="${BASH_REMATCH[3]}"
        PRERELEASE="${BASH_REMATCH[5]}"
        PRERELEASE_NUM="${BASH_REMATCH[6]}"
        return 0
    else
        return 1
    fi
}

increment_version() {
    local version_type="$1"
    local current_version="$2"
    local custom_version="$3"
    
    if ! parse_version "$current_version"; then
        log_error "Invalid current version format: $current_version"
        exit 1
    fi
    
    case "$version_type" in
        major)
            echo "$((MAJOR + 1)).0.0"
            ;;
        minor)
            echo "$MAJOR.$((MINOR + 1)).0"
            ;;
        patch)
            echo "$MAJOR.$MINOR.$((PATCH + 1))"
            ;;
        prerelease)
            if [ -n "$PRERELEASE" ]; then
                # Increment existing prerelease
                echo "$MAJOR.$MINOR.$PATCH-$PRERELEASE.$((PRERELEASE_NUM + 1))"
            else
                # Create new prerelease
                echo "$MAJOR.$MINOR.$((PATCH + 1))-alpha.1"
            fi
            ;;
        custom)
            if [ -z "$custom_version" ]; then
                log_error "Custom version not specified"
                exit 1
            fi
            if ! parse_version "$custom_version"; then
                log_error "Invalid custom version format: $custom_version"
                exit 1
            fi
            echo "$custom_version"
            ;;
        *)
            log_error "Invalid version type: $version_type"
            exit 1
            ;;
    esac
}

validate_git_state() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    # Check if working directory is clean
    if [ -n "$(git status --porcelain)" ]; then
        log_error "Working directory is not clean. Please commit or stash changes."
        git status --short
        exit 1
    fi
    
    # Check if we're on main branch
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
        log_warning "Not on main/master branch (current: $current_branch)"
        if [ "$FORCE" != "true" ]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
    # Fetch latest changes
    log_info "Fetching latest changes..."
    git fetch origin
    
    # Check if local branch is up to date
    local local_commit=$(git rev-parse HEAD)
    local remote_commit=$(git rev-parse origin/$current_branch 2>/dev/null || echo "")
    
    if [ -n "$remote_commit" ] && [ "$local_commit" != "$remote_commit" ]; then
        log_error "Local branch is not up to date with remote"
        exit 1
    fi
}

run_tests() {
    if [ "$SKIP_TESTS" = "true" ]; then
        log_warning "Skipping tests"
        return 0
    fi
    
    log_info "Running tests..."
    
    cd "$REPO_ROOT"
    
    # Run different test commands based on what's available
    if [ -f "Makefile" ]; then
        make test
    elif [ -f "go.mod" ]; then
        go test ./...
    elif [ -f "package.json" ]; then
        npm test
    else
        log_warning "No test framework detected, skipping tests"
    fi
    
    log_success "Tests passed"
}

update_changelog() {
    if [ "$SKIP_CHANGELOG" = "true" ]; then
        log_warning "Skipping changelog update"
        return 0
    fi
    
    local new_version="$1"
    local current_version="$2"
    
    log_info "Updating changelog..."
    
    # Create changelog if it doesn't exist
    if [ ! -f "$CHANGELOG_FILE" ]; then
        cat > "$CHANGELOG_FILE" << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

EOF
    fi
    
    # Generate changelog entry
    local changelog_entry=""
    local date=$(date +%Y-%m-%d)
    
    # Get commits since last version
    local commit_range=""
    if [ "$current_version" != "0.0.0" ]; then
        local last_tag=$(git tag -l "v$current_version" | head -1)
        if [ -n "$last_tag" ]; then
            commit_range="$last_tag..HEAD"
        else
            commit_range="HEAD"
        fi
    else
        commit_range="HEAD"
    fi
    
    # Generate changelog from commits
    changelog_entry="## [v$new_version] - $date\n\n"
    
    # Categorize commits
    local features=$(git log $commit_range --pretty=format:"- %s" --grep="^feat" --grep="^feature" | head -10)
    local fixes=$(git log $commit_range --pretty=format:"- %s" --grep="^fix" --grep="^bugfix" | head -10)
    local docs=$(git log $commit_range --pretty=format:"- %s" --grep="^docs" | head -5)
    local other=$(git log $commit_range --pretty=format:"- %s" --invert-grep --grep="^feat" --grep="^fix" --grep="^docs" | head -5)
    
    if [ -n "$features" ]; then
        changelog_entry+="\n### Added\n$features\n"
    fi
    
    if [ -n "$fixes" ]; then
        changelog_entry+="\n### Fixed\n$fixes\n"
    fi
    
    if [ -n "$docs" ]; then
        changelog_entry+="\n### Documentation\n$docs\n"
    fi
    
    if [ -n "$other" ]; then
        changelog_entry+="\n### Other Changes\n$other\n"
    fi
    
    # Insert changelog entry after the header
    if [ "$DRY_RUN" != "true" ]; then
        # Create temporary file with new entry
        local temp_file=$(mktemp)
        
        # Copy header
        sed -n '1,/^$/p' "$CHANGELOG_FILE" > "$temp_file"
        
        # Add new entry
        echo -e "$changelog_entry" >> "$temp_file"
        
        # Add rest of changelog
        sed -n '/^## \[/,$p' "$CHANGELOG_FILE" >> "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$CHANGELOG_FILE"
        
        log_success "Updated changelog"
    else
        log_info "Would add changelog entry:"
        echo -e "$changelog_entry"
    fi
}

update_version_file() {
    local new_version="$1"
    
    if [ "$DRY_RUN" != "true" ]; then
        echo "$new_version" > "$VERSION_FILE"
        log_success "Updated version file to $new_version"
    else
        log_info "Would update version file to $new_version"
    fi
}

create_git_tag() {
    local new_version="$1"
    local tag_name="v$new_version"
    
    if [ "$DRY_RUN" != "true" ]; then
        # Stage changes
        git add "$CHANGELOG_FILE" "$VERSION_FILE"
        
        # Commit changes
        git commit -m "chore: release version $new_version

- Updated CHANGELOG.md
- Updated VERSION file

[skip ci]"
        
        # Create annotated tag
        git tag -a "$tag_name" -m "Release version $new_version"
        
        log_success "Created git tag $tag_name"
        
        # Push changes and tag
        log_info "Pushing changes and tag to remote..."
        git push origin main
        git push origin "$tag_name"
        
        log_success "Pushed changes and tag to remote"
    else
        log_info "Would create git tag $tag_name and push to remote"
    fi
}

show_release_summary() {
    local current_version="$1"
    local new_version="$2"
    local version_type="$3"
    
    echo
    log_info "Release Summary:"
    echo "  Current Version: $current_version"
    echo "  New Version:     $new_version"
    echo "  Version Type:    $version_type"
    echo "  Tag Name:        v$new_version"
    echo
    
    if [ "$DRY_RUN" != "true" ]; then
        log_info "Next Steps:"
        echo "  1. GitHub Actions will automatically create a release"
        echo "  2. Terraform Registry will publish the new version"
        echo "  3. Documentation will be updated automatically"
        echo
        echo "  Release URL: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/releases/tag/v$new_version"
        echo "  Registry URL: https://registry.terraform.io/modules/kbrockhoff/brockhoff-cloud-docs"
    fi
}

main() {
    local version_type=""
    local custom_version=""
    local DRY_RUN="false"
    local FORCE="false"
    local SKIP_TESTS="false"
    local SKIP_CHANGELOG="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -f|--force)
                FORCE="true"
                shift
                ;;
            -p|--prerelease)
                version_type="prerelease"
                shift
                ;;
            -v|--version)
                custom_version="$2"
                shift 2
                ;;
            --skip-tests)
                SKIP_TESTS="true"
                shift
                ;;
            --skip-changelog)
                SKIP_CHANGELOG="true"
                shift
                ;;
            major|minor|patch|prerelease|custom)
                version_type="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validate arguments
    if [ -z "$version_type" ]; then
        log_error "Version type is required"
        show_help
        exit 1
    fi
    
    if [ "$version_type" = "custom" ] && [ -z "$custom_version" ]; then
        log_error "Custom version must be specified with -v option"
        exit 1
    fi
    
    # Show dry run notice
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "DRY RUN MODE - No changes will be made"
        echo
    fi
    
    # Validate git state
    validate_git_state
    
    # Get current version
    local current_version=$(get_current_version)
    log_info "Current version: $current_version"
    
    # Calculate new version
    local new_version=$(increment_version "$version_type" "$current_version" "$custom_version")
    log_info "New version: $new_version"
    
    # Show summary and confirm
    show_release_summary "$current_version" "$new_version" "$version_type"
    
    if [ "$FORCE" != "true" ] && [ "$DRY_RUN" != "true" ]; then
        read -p "Proceed with release? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Release cancelled"
            exit 0
        fi
    fi
    
    # Run tests
    run_tests
    
    # Update changelog
    update_changelog "$new_version" "$current_version"
    
    # Update version file
    update_version_file "$new_version"
    
    # Create git tag and push
    create_git_tag "$new_version"
    
    # Show final summary
    echo
    log_success "Release $new_version completed successfully!"
    
    if [ "$DRY_RUN" != "true" ]; then
        echo
        log_info "The GitHub Actions workflow will now:"
        echo "  - Create a GitHub release"
        echo "  - Publish to Terraform Registry"
        echo "  - Update documentation"
        echo "  - Run security scans"
        echo
        log_info "Monitor the progress at:"
        echo "  https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/actions"
    fi
}

# Run main function with all arguments
main "$@"