# usage: prints script usage
usage() {
  echo
  echo "Usage: ${PROGNAME} <options>"
  echo
  echo "${t_bold}OPTIONS${t_normal}"
  echo " new <post title>                   Creates a new post with specified title"
  echo " edit <id>                          Edits post by ID"
  echo " set <id> [publish|unpublish]       Sets post status to 'publish' or 'unpublish'"
  echo " delete <id>                        Deletes post by ID"
  echo " list                               Lists all posts"
  echo " generate                           Generates 'public' output"
  echo " push                               Pushes latest generated content to servers"
}


# Sets up directories (usually on first run only)
bb::setup() {

  [ ! -d "${REPOSITORY_DIR}" ] && mkdir "${REPOSITORY_DIR}"
  [ ! -d "${LOCAL_DIR}" ] && mkdir "${LOCAL_DIR}"
  [ ! -d "${PUBLIC_DIR}" ] && mkdir "${PUBLIC_DIR}"
  [ ! -d "${PUBLIC_POSTS_DIR}" ] && mkdir "${PUBLIC_POSTS_DIR}"

  [ ! -f "${HOME_DIR}/bb.conf" ] && bp::abrt "Please copy ${t_bold}bb.conf-setup${t_normal} to ${t_bold}bb.conf${t_normal} before running"
}

# Tests that exact args are met
req_args() {

  local supplied_args=$1
  local required_args=$2

  if [ ${supplied_args} -eq "${required_args}" ]; then
    return 0
  else
    return 1
  fi 

}

# Tests that min. args are met
min_args() {

  local supplied_args=$1
  local required_args=$2

  if [ ${supplied_args} -ge "${required_args}" ]; then
    return 0
  else
    return 1
  fi
}

# Gets a total post count
post_count() {

  local total_posts="$( ls "${LOCAL_DIR}" | wc -l | awk '{ print $1 }' )"
  [ ${total_posts} -eq 0 ] && echo 0
  [ ${total_posts} -ge 1 ] && echo "${total_posts}"
}

# Checks if no posts exist
no_posts() {

  total_post_count=$( post_count )

  if [ ${total_post_count} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

# Generates a new post index number
new_index() {

  if no_posts; then
    local index="0"
  else  
    local last_index="$( ls "${LOCAL_DIR}/" | sort -n | tail -n1 )"
    local index=$((last_index + 1))
  fi

  echo "${index}"
}

# Generates a "friendly" URL
generate_friendly_url() {

  local unfriendly_url="$@"

  local friendly_url="$( echo "${unfriendly_url}" | sed 's/ /XXSPACEXX/g' | sed 's/_/XXUNDERSCOREXX/g' | sed 's/-/XXDASHXX/g' | tr -dc '[:alnum:]' | sed 's/XXUNDERSCOREXX/_/g' | sed 's/XXDASHXX/-/g' | sed 's/XXSPACEXX/-/g' | tr '[A-Z]' '[a-z]' )"

  echo "${friendly_url}"
}

# Checks if a friendly URL is already in use
url_exists() {

  if no_posts; then
    return 1
  fi

  local friendly_url="$1"

  local existing_friendly_urls="$( cat "${LOCAL_DIR}"/*/url )"

  local friendly_url_exists="$( echo "${existing_friendly_urls}" | grep "^${friendly_url}$" )"

  [ -n "${friendly_url_exists}" ] && return 0
  [ -z "${friendly_url_exists}" ] && return 1

}

# Creates a new post
post::create() {

  local post_title="$@"

  local post_title_lenght="${#post_title}"

  [ ${#post_title} -eq 0 ] && bp::abrt "Please enter a post title"

  [ ${#post_title} -le ${MIN_TITLE_LENGTH} ] && bp::abrt "Post title needs to be longer than ${MIN_TITLE_LENGTH} characters"

  local post_id="$( new_index )"
  local post_dir="${LOCAL_DIR}/${post_id}"
  local this_post_url="$( generate_friendly_url "${post_title}" )"

  if url_exists "${this_post_url}" ; then
    bp::abrt "Post with this URL \"${t_bold}${this_post_url}${t_normal}\" already exists. Try add -page2 -page3 etc if this is intentional"
  fi

  bp::msg ""
  bp::msg "Creating new post..."
  bp::msg "Title: ${post_title}"
  bp::msg "ID: ${post_id}"

  # Set up post directory and file structure...
  mkdir "${post_dir}"
  touch "${post_dir}"/{author,categories,checksum,content,status,tags,title,updated,url}

  # Populate files
  echo "${post_title}" > "${post_dir}/title"
  echo "${BLOG_DEFAULT_AUTHOR}" > "${post_dir}/author"
  echo "unpublished" > "${post_dir}/status"
  echo "${this_post_url}" > "${post_dir}/url"

  bp::msg ""
  bp::msg "New post created. To create content for this post, edit: ${post_dir}/content"
  bp::msg ""
  
}

# Lists all posts
post::list() {
  
  if no_posts; then
    bp::msg "${t_yellow}WARNING: ${t_normal}No posts found."
    exit 1
  fi

  local post_ids=( $( ls "${LOCAL_DIR}") )

  for this_post_id in "${post_ids[@]}" ; do
    
    local this_post_dir="${LOCAL_DIR}/${this_post_id}"
    local this_post_title="$( cat "${this_post_dir}/title" )"
    local this_post_author="$( cat "${this_post_dir}/author" )"
    local this_post_url="$( cat "${this_post_dir}/url" )"
    local this_post_status="$( cat "${this_post_dir}/status" )"
    local this_post_last_updated="$( cat "${this_post_dir}/updated" )"

    [ -z "${this_post_last_updated}" ] && this_post_last_updated="never"

    bp::msg ""

    echo "${t_bold}${this_post_id}. ${this_post_title}${t_normal}"
    echo "${t_bold}Author ${t_normal}${this_post_author} - ${t_bold}Status: ${t_normal}${this_post_status} - ${t_bold}Last updated: ${t_normal}${this_post_last_updated}"

  done


}

# Deletes a post by ID
post::delete() {

  if no_posts; then
    bp::msg "${t_yellow}WARNING: ${t_normal}No posts found."
    exit 1
  fi

  if ! req_args $# 1; then
    bp::abrt "No post ID specified"
  fi

  local post_id="$1"

  if [ ! -d "${LOCAL_DIR}/${post_id}" ]; then
    bp::abrt "Unable to find post with ID ${post_id}"
  else
    if bp::yesno "Are you sure you want to delete post ID ${post_id} ?" ; then
      set -u
      rm -rf "${LOCAL_DIR}/${post_id}"
    else
      msg "Skipping delete at user request.."
      exit 0
    fi
  fi

}

# Push content
post::push() {
  
  if no_posts; then
    bp::msg "${t_yellow}WARNING: ${t_normal}No posts found."
    exit 1
  fi

  [ ! -f "${PUSH_HOSTS_FILE}" ] && bp::abrt "Unable to find hosts file ${PUSH_HOSTS_FILE}"

  local push_hosts=( $( grep -v ^# "${PUSH_HOSTS_FILE}") )

  [ ${#push_hosts} -eq 0 ] && bp::abrt "Unable to push content. No hosts defined"

  for push_host in "${push_hosts[@]}" ; do

    local this_host_type="$( echo "${push_host}" | cut -d, -f1 )"

    local host_local=1
    local host_remote=1

    case "${this_host_type}" in
      "local") host_local=0 ;;
      "remote") host_remote=0 ;;
      *) bp::abrt "Unknown host type specified"
    esac

    if [ ${host_local} -eq 0 ]; then
      local this_dest_dir="$( echo "${push_host}" | cut -d, -f2 )"
      
      echo -n "Pushing to local directory ${this_dest_dir}: "
      
      # Two syncs. Root directory gets rsync WITHOUT delete option, to be safe. Second rsync command has delete option, for posts directory only.
      if ! { rsync -az "${PUBLIC_DIR}/" "${this_dest_dir}" && rsync -az --delete "${PUBLIC_POSTS_DIR}/" "${this_dest_dir}/posts" ;} ; then
        bp::abrt "There was an error pushing locally"
      else
        bp::msg " OK"
      fi

    elif [ ${host_remote} -eq 0 ]; then
      
      local this_address="$( echo "${push_host}" | cut -d, -f2 )"
      local this_ssh_user="$( echo "${push_host}" | cut -d, -f3 )"
      local this_dest_dir="$( echo "${push_host}" | cut -d, -f4 )"

      [ -z "${this_address}" ] && bp::abrt "Remote address cannot be empty"
      [ -z "${this_ssh_user}" ] && bp::abrt "Remote SSH user cannot be empty"
      [ -z "${this_dest_dir}" ] && bp::abrt "Remote destination directory cannot be empty"

      echo -n "Pushing to remote ${this_address}:${this_dest_dir}: "

      # Two syncs. Root directory gets rsync WITHOUT delete option, to be safe. Second rsync command has delete option, for posts directory only.
      if ! { rsync --timeout=${RSYNC_TIMEOUT} -az -e ssh "${PUBLIC_DIR}/" "${this_ssh_user}"@"${this_address}":"${this_dest_dir}" && rsync --timeout=${RSYNC_TIMEOUT} -az -e ssh --delete "${PUBLIC_POSTS_DIR}" "${this_ssh_user}"@"${this_address}":"${this_dest_dir}" ;} ; then
        bp::abrt "There was an error pushing to ${this_address}"
      else
        bp::msg " OK"
      fi
    fi

  done

  bp::msg ""
  bp::msg "Push complete."

}

# Edits a post by ID
post::edit() {

  if no_posts; then
    bp::msg "${t_yellow}WARNING: ${t_normal}No posts found."
    exit 1
  fi

  if ! req_args $# 1; then
    bp::abrt "No post ID specified"
  fi

  local post_id="$1"

  if [ ! -d "${LOCAL_DIR}/${post_id}" ]; then
    bp::abrt "Unable to find post with ID ${post_id}"
  else
   $TEXT_EDITOR "${LOCAL_DIR}/${post_id}/content"
  fi

}

# Search for posts. Not yet implemented
post::search() {
  # Grep for post titles, or content
  :
}

# Sets post status to "publish" or "unpublish" - determines what gets generated/published
post::setstatus() {

  if no_posts; then
    bp::msg "${t_yellow}WARNING: ${t_normal}No posts found."
    exit 1
  fi

  local post_id="$1"
  local status="$2"
  
  local this_post_dir="${LOCAL_DIR}/${post_id}"

  [ ! -d "${this_post_dir}" ] && bp::abrt "Post ID ${post_id} not found"

  case ${status} in
    "publish") echo "publish" > "${this_post_dir}/status" ; echo ; echo "Post ID ${post_id} set to: publish" ;;
    "unpublish") echo "unpublish" > "${this_post_dir}/status" ; echo ; echo "Post ID ${post_id} set to: unpublish" ;;
    *) bp::abrt "Invalid post status specified: ${status}" ;;
  esac

}

# Generates "public" version of site (in preparation for publish)
post::generate() {

  if no_posts; then
    bp::msg "${t_yellow}WARNING: ${t_normal}No posts found."
    exit 1
  fi

  bp::msg ""
  bp::msg "${t_bold}Generating posts...${t_normal}"
  bp::msg ""

  # Initiate sitemap, if enabled
  if [ ${ENABLE_SITEMAP} -eq 0 ]; then
    set -u

    touch "${SITEMAP_FILE}"
    echo '<?xml version="1.0" encoding="UTF-8"?>' > "${SITEMAP_FILE}"
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' >> "${SITEMAP_FILE}"

    # Check that last character of blog URL is a "/"
    local blog_sitemap_len="${#SITEMAP_BLOG_URL}"
    local blog_sitemap_len_less=$((blog_sitemap_len - 1))
    local blog_sitemap_lastchar="${SITEMAP_BLOG_URL:${blog_sitemap_len_less}:${blog_sitemap_len}}"
    [ "${blog_sitemap_lastchar}" != "/" ] && "${SITEMAP_BLOG_URL}/"

  elif [ ${ENABLE_SITEMAP} -eq 1 ]; then
    # Assume we don't want sitemap at all, and delete it if it exists
    set -u
    [ -f "${SITEMAP_FILE}" ] && rm "${SITEMAP_FILE}"
  fi

  # Clear out existing public posts directory
  set -u
  rm -rf "${PUBLIC_POSTS_DIR}" && mkdir "${PUBLIC_POSTS_DIR}"

  # Set templates
  local template_header="$( cat "${TEMPLATES_DIR}/1-header" )"
  local template_header="${template_header//__BLOGTITLE__/${BLOG_TITLE}}"
  local template_header="${template_header//__BLOGTHEME__/${BLOG_THEME}}"

  local template_menu="$( cat "${TEMPLATES_DIR}/2-menu-post" )"

  local template_footer="$( cat "${TEMPLATES_DIR}/3-footer-post" )"


  local posts=( $( ls "${LOCAL_DIR}/" | sort -n ) )

  for post in "${posts[@]}" ; do
    echo -ne "Generating post ID: ${post}               \r"

    local this_local_dir="${LOCAL_DIR}/${post}"
    local this_status="$( cat "${this_local_dir}/status" )"

    # If post status is not published, skip
    [ "${this_status}" != "publish" ] && { echo ; echo "Skipping post ID ${post} as it is not in the 'publish' state!" ; continue ;}

    local this_content="$( cat "${this_local_dir}/content" )"

    # If word count is 0, skip
    [ ${#this_content} -eq 0 ] && { echo ; echo "Skipping post ID ${post} because there is no content!" ; continue ;}

    local this_author="$( cat "${this_local_dir}/author" )"
    local this_tags="$( cat "${this_local_dir}/tags" )"
    local this_url="$( cat "${this_local_dir}/url" )"
    local this_title="$( cat "${this_local_dir}/title" )"
    local this_checksum="$( cat "${this_local_dir}/checksum" )"
    local this_tags="$( cat "${this_local_dir}/tags" )"
    local this_categories="$( cat "${this_local_dir}/categories" )"
    local latest_content_checksum="$( openssl md5 "${this_local_dir}/content" | awk '{ print $2 }' )"

    local this_template_header="${template_header//__SUBTITLE__/${this_title}}"
    
    # Test if content is updated. If it is, update the checksum and update date
    if [ "${latest_content_checksum}" != "${this_checksum}" ]; then
      local date_now="$( date )"
      echo "${date_now}" > "${this_local_dir}/updated"
      echo "${latest_content_checksum}" > "${this_local_dir}/checksum"
    fi

    local this_last_updated="$( cat "${this_local_dir}/updated" )"

    local this_public_dir="${PUBLIC_POSTS_DIR}/${this_url}"
    local this_index_file="${this_public_dir}/index.html"

    mkdir "${this_public_dir}" || bp::abrt "Unable to create post directory ${this_public_dir}"
    touch "${this_index_file}"

    echo "${this_template_header}" > "${this_index_file}"
    echo "${template_menu}" >> "${this_index_file}"

    echo "# ${this_title}" >> "${this_index_file}"
    echo "**By:** ${this_author}. **Last updated:** ${this_last_updated}" >> "${this_index_file}"
    echo "" >> "${this_index_file}"

    if [ ${#this_categories} -gt 0 ]; then

      local this_categories_sorted="$( echo "${this_categories}" | sort | uniq | tr '\n' ',' | sed 's/,/, /g' | sed 's/, $//g' )"

      echo "**Posted in:** ${this_categories_sorted}" >> "${this_index_file}"
    fi

    echo "" >> "${this_index_file}"

    echo "${this_content}" >> "${this_index_file}"

    if [ ${#this_tags} -gt 0 ]; then

      local this_tags_sorted="$( echo "${this_tags}" | sort | uniq | tr '\n' ',' | sed 's/,/, /g' | sed 's/, $//g' )"

      echo "#### Tags" >> "${this_index_file}"
      echo "${this_tags_sorted}" >> "${this_index_file}"
    fi

    echo "${template_footer}" >> "${this_index_file}"

    [ -d "${this_local_dir}/assets" ] && cp -R "${this_local_dir}/assets" "${this_public_dir}"


    # Populate sitemap entry
    if [ ${ENABLE_SITEMAP} -eq 0 ]; then
      echo '  <url>' >> "${SITEMAP_FILE}"
      echo "    <loc>${SITEMAP_BLOG_URL}posts/${this_url}</loc>" >> "${SITEMAP_FILE}"
      echo '  </url>' >> "${SITEMAP_FILE}"
    fi

  done

  # Close sitemap tag
  if [ ${ENABLE_SITEMAP} -eq 0 ]; then
    echo '</urlset>' >> "${SITEMAP_FILE}"
  fi

  bp::msg ""

}

# Generates the index page
post::generate_index() {

  # Ensure our posts are generated. In future make this one function to avoid doubling the work done.
  post::generate

  bp::msg ""
  bp::msg "${t_bold}Generating index...${t_normal}"
  bp::msg ""

  local posts=( $( ls "${LOCAL_DIR}/" | sort -rn ) )

  # Set templates
  local template_header="$( cat "${TEMPLATES_DIR}/1-header" )"
  local template_header="${template_header//__BLOGTITLE__/${BLOG_TITLE}}"
  local template_header="${template_header//__BLOGTHEME__/${BLOG_THEME}}"
  local template_header="${template_header//__SUBTITLE__/${BLOG_SUBTITLE}}"

  local template_menu="$( cat "${TEMPLATES_DIR}/2-menu-index" )"

  local template_footer="$( cat "${TEMPLATES_DIR}/3-footer-index" )"

  touch "${PUBLIC_INDEX_FILE}"

  echo "${template_header}" > "${PUBLIC_INDEX_FILE}"

  echo "${template_menu}" >> "${PUBLIC_INDEX_FILE}"
  
  for post in "${posts[@]}" ; do

    local this_local_dir="${LOCAL_DIR}/${post}"
    local this_status="$( cat "${this_local_dir}/status" )"
 
    # If post status is not published, skip
    [ "${this_status}" != "publish" ] && continue

    local this_content_all="$( head -n5 "${this_local_dir}/content" )"

    # If word count is 0, skip
    [ ${#this_content_all} -eq 0 ] && { echo ; echo "Skipping post ID ${post} because there is no content!" ; continue ;}

    # Get content to create a snippet from. Try avoid markdown characters
    local this_content="$( head -n10 "${this_local_dir}/content" | grep -v -E -- '^#|^\[|!|\*|^`' )"

    local this_author="$( cat "${this_local_dir}/author" )"
    local this_url="$( cat "${this_local_dir}/url" )"
    local this_title="$( cat "${this_local_dir}/title" )"
    local this_full_url="posts/${this_url}"
    local this_snippet="${this_content:0:300}"
    local this_snippet="$( echo "${this_snippet}" | grep -v "^#" | tr '\n' ' ' )"
    local this_last_updated="$( cat "${this_local_dir}/updated" )"

    echo "" >> "${PUBLIC_INDEX_FILE}"
    echo "## [${this_title}](${this_full_url})" >> "${PUBLIC_INDEX_FILE}"
    echo "*By* ${this_author}. *Updated* ${this_last_updated}" >> "${PUBLIC_INDEX_FILE}"
    echo "" >> "${PUBLIC_INDEX_FILE}"
    echo "${this_snippet}...[read more](${this_full_url})" >> "${PUBLIC_INDEX_FILE}"

  done

  echo "${template_footer}" >> "${PUBLIC_INDEX_FILE}"

  cp -R "${ASSETS_DIR}" "${PUBLIC_DIR}"

  bp::msg ""

  bp::msg "${t_bold}Latest content has been generated. ${t_normal}Please run the ${t_bold}push${t_normal} command to push the latest content."

}
