# CONSTANTS
readonly PROJECT_NAME="bb"
readonly PROGNAME="$( basename $0 )"
readonly LOG_FILE=""
readonly SCRIPT_DEPENDENCIES=( "ssh" "openssl" "rsync" )

readonly REPOSITORY_DIR="${HOME_DIR}/repository"
readonly LOCAL_DIR="${REPOSITORY_DIR}/local"
readonly PUBLIC_DIR="${REPOSITORY_DIR}/public"
readonly PUBLIC_POSTS_DIR="${PUBLIC_DIR}/posts"
readonly PUBLIC_POSTS_SHARED_ASSETS_DIR="${PUBLIC_POSTS_DIR}/assets"
readonly PUBLIC_INDEX_FILE="${PUBLIC_DIR}/index.html"
readonly ASSETS_DIR="${REPOSITORY_DIR}/assets"

# POST CONSTANTS
readonly MIN_TITLE_LENGTH=3
readonly MAX_TITLE_LENGTH=200
readonly POSTS_PER_PAGE=5

# TEMPLATES
readonly TEMPLATES_DIR="${HOME_DIR}/templates"

# PUSH CONSTANTS
readonly PUSH_HOSTS_FILE="${HOME_DIR}/hosts.txt"
readonly RSYNC_TIMEOUT=30