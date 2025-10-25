#!/bin/bash

# Simple Flutter Project Manager Script
# Handles pub get and build runner operations for multiple Flutter/Dart projects

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if project has build_runner dependency
has_build_runner() {
    local project_dir="$1"
    local pubspec_path="$project_dir/pubspec.yaml"
    
    if [ -f "$pubspec_path" ]; then
        grep -q "build_runner:" "$pubspec_path" 2>/dev/null
    else
        return 1
    fi
}

# Execute flutter pub get
run_pub_get() {
    local project_dir="$1"
    local project_name="$2"
    
    print_info "Running 'flutter pub get' in $project_name..."
    
    if (cd "$project_dir" && flutter pub get); then
        print_success "Successfully completed 'flutter pub get' in $project_name"
        return 0
    else
        print_error "Failed to run 'flutter pub get' in $project_name"
        return 1
    fi
}

# Execute build runner
run_build_runner() {
    local project_dir="$1"
    local project_name="$2"
    
    if ! has_build_runner "$project_dir"; then
        print_warning "Skipping build_runner for $project_name (no build_runner dependency found)"
        return 0
    fi
    
    print_info "Running 'dart run build_runner build' in $project_name..."
    
    if (cd "$project_dir" && dart run build_runner build --delete-conflicting-outputs); then
        print_success "Successfully completed 'dart run build_runner build' in $project_name"
        return 0
    else
        print_error "Failed to run 'dart run build_runner build' in $project_name"
        return 1
    fi
}

# Execute flutter clean
run_flutter_clean() {
    local project_dir="$1"
    local project_name="$2"
    
    print_info "Running 'flutter clean' in $project_name..."
    
    if (cd "$project_dir" && flutter clean); then
        print_success "Successfully completed 'flutter clean' in $project_name"
        return 0
    else
        print_error "Failed to run 'flutter clean' in $project_name"
        return 1
    fi
}

# Clean pub get (remove pubspec.lock and .dart_tool)
clean_pub_get() {
    local project_dir="$1"
    local project_name="$2"
    
    print_info "Cleaning pub dependencies in $project_name..."
    
    (cd "$project_dir" && rm -f pubspec.lock && rm -rf .dart_tool)
    
    print_success "Successfully cleaned pub dependencies in $project_name"
    return 0
}

# Main script
main() {
    echo "==============================="
    print_info "Flutter Project Manager"
    echo "==============================="
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check if Dart is installed
    if ! command -v dart &> /dev/null; then
        print_error "Dart is not installed or not in PATH"
        exit 1
    fi
    
    # Find all Flutter/Dart projects
    print_info "Scanning for Flutter/Dart projects..."
    
    local workspace_root="$(pwd)"
    local -a projects=()
    local -a project_names=()
    
    # Find projects using simple approach
    for pubspec in $(find "$workspace_root" -name "pubspec.yaml" -type f 2>/dev/null); do
        local project_dir=$(dirname "$pubspec")
        local project_name=$(basename "$project_dir")
        projects+=("$project_dir")
        project_names+=("$project_name")
        print_info "Found project: $project_name at $project_dir"
    done
    
    if [ ${#projects[@]} -eq 0 ]; then
        print_error "No Flutter/Dart projects found!"
        exit 1
    fi
    
    # Display project selection menu
    echo
    print_info "Available projects:"
    for i in "${!project_names[@]}"; do
        echo "  $((i+1)). ${project_names[$i]}"
    done
    echo "  $((${#projects[@]}+1)). All projects"
    
    # Get project selection
    echo
    while true; do
        printf "Select projects (comma-separated numbers, 'all' for all projects, or 'q' to quit): "
        read -r selection
        
        if [[ "$selection" == "q" ]]; then
            print_info "Exiting..."
            exit 0
        fi
        
        local -a selected_indices=()
        
        if [[ "$selection" == "all" ]] || [[ "$selection" == "$((${#projects[@]}+1))" ]]; then
            # Select all projects
            for i in "${!projects[@]}"; do
                selected_indices+=("$i")
            done
            break
        else
            # Parse comma-separated selection
            IFS=',' read -ra nums <<< "$selection"
            local valid=true
            
            for num in "${nums[@]}"; do
                # Remove whitespace
                num=$(echo "$num" | tr -d ' ')
                
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#projects[@]} ]; then
                    selected_indices+=("$((num-1))")
                else
                    print_error "Invalid selection: $num"
                    valid=false
                    break
                fi
            done
            
            if [ "$valid" = true ] && [ ${#selected_indices[@]} -gt 0 ]; then
                break
            fi
        fi
    done
    
    # Display operation menu
    echo
    print_info "Available operations:"
    echo "  1. Run 'flutter pub get'"
    echo "  2. Run 'dart run build_runner build'"
    echo "  3. Clean flutter pub get and run pub get"
    echo "  4. Run 'flutter clean', 'pub get', then 'dart run build_runner build'"
    
    # Get operation selection
    echo
    while true; do
        printf "Select operation (1-4, or 'q' to quit): "
        read -r operation
        
        if [[ "$operation" == "q" ]]; then
            print_info "Exiting..."
            exit 0
        fi
        
        if [[ "$operation" =~ ^[1-4]$ ]]; then
            break
        else
            print_error "Invalid selection. Please choose 1, 2, 3, or 4."
        fi
    done
    
    # Execute operations
    echo
    print_info "Starting operations..."
    
    local failed_projects=()
    local total_projects=${#selected_indices[@]}
    
    for i in "${!selected_indices[@]}"; do
        local idx="${selected_indices[$i]}"
        local project_dir="${projects[$idx]}"
        local project_name="${project_names[$idx]}"
        
        echo
        print_info "Processing project $((i+1))/$total_projects: $project_name"
        
        local failed=false
        
        case "$operation" in
            1)
                run_pub_get "$project_dir" "$project_name" || failed=true
                ;;
            2)
                run_build_runner "$project_dir" "$project_name" || failed=true
                ;;
            3)
                clean_pub_get "$project_dir" "$project_name" && \
                run_pub_get "$project_dir" "$project_name" || failed=true
                ;;
            4)
                run_flutter_clean "$project_dir" "$project_name" && \
                run_pub_get "$project_dir" "$project_name" && \
                run_build_runner "$project_dir" "$project_name" || failed=true
                ;;
        esac
        
        if [ "$failed" = true ]; then
            failed_projects+=("$project_name")
        fi
    done
    
    # Print summary
    echo
    echo "=================="
    print_info "OPERATION SUMMARY"
    echo "=================="
    
    local successful_count=$((total_projects - ${#failed_projects[@]}))
    print_success "Successfully processed: $successful_count/$total_projects projects"
    
    if [ ${#failed_projects[@]} -gt 0 ]; then
        print_error "Failed projects: ${failed_projects[*]}"
        exit 1
    else
        print_success "All operations completed successfully!"
    fi
}

# Run main function
main "$@"