#!/bin/sh
# Maven Wrapper Script

# Verbose logging for debugging purposes
[ "${MVNW_VERBOSE-}" != debug ] || set -x

# OS specific support for Windows
native_path() { printf %s\\n "$1"; }

case "$(uname)" in
  CYGWIN* | MINGW*)
    # If JAVA_HOME is set, convert it to Unix style for compatibility
    [ -z "${JAVA_HOME-}" ] || JAVA_HOME="$(cygpath --unix "$JAVA_HOME")"
    native_path() { cygpath --path --windows "$1"; }
    ;;
esac

# Set the Java executable paths: JAVACMD and JAVACCMD
set_java_home() {
  # Check if JAVA_HOME is set
  if [ -n "${JAVA_HOME-}" ]; then
    if [ -x "$JAVA_HOME/jre/sh/java" ]; then
      # For IBM's JDK on AIX
      JAVACMD="$JAVA_HOME/jre/sh/java"
      JAVACCMD="$JAVA_HOME/jre/sh/javac"
    else
      JAVACMD="$JAVA_HOME/bin/java"
      JAVACCMD="$JAVA_HOME/bin/javac"
      # Ensure that the executables exist
      if [ ! -x "$JAVACMD" ] || [ ! -x "$JAVACCMD" ]; then
        echo "JAVA_HOME is not configured correctly. Either \$JAVA_HOME/bin/java or \$JAVA_HOME/bin/javac do not exist." >&2
        return 1
      fi
    fi
  else
    JAVACMD="$(command -v java)" || :
    JAVACCMD="$(command -v javac)" || :
    
    # Ensure java and javac are available in PATH
    if [ ! -x "${JAVACMD-}" ] || [ ! -x "${JAVACCMD-}" ]; then
      echo "java/javac commands are not found in PATH, and JAVA_HOME is not set." >&2
      return 1
    fi
  fi
}

# Hash a string like Java's String::hashCode
hash_string() {
  str="${1:-}" h=0
  while [ -n "$str" ]; do
    char="${str%"${str#?}"}"
    h=$(((h * 31 + $(LC_CTYPE=C printf %d "'$char")) % 4294967296))
    str="${str#?}"
  done
  printf %x\\n $h
}

# Verbose logging (disabled by default)
verbose() { :; }
[ "${MVNW_VERBOSE-}" != true ] || verbose() { printf %s\\n "${1-}"; }

# Terminate the script with an error message
die() {
  printf %s\\n "$1" >&2
  exit 1
}

# Trim whitespace (for cleanup purposes)
trim() {
  # MWRAPPER-139: Remove all whitespace characters (spaces, tabs, newlines)
  printf "%s" "${1}" | tr -d '[:space:]'
}

# Parse the distribution URL and SHA-256 sum from the properties file
while IFS="=" read -r key value; do
  case "${key-}" in
    distributionUrl) distributionUrl=$(trim "${value-}") ;;
    distributionSha256Sum) distributionSha256Sum=$(trim "${value-}") ;;
  esac
done <"${0%/*}/.mvn/wrapper/maven-wrapper.properties"

# Ensure distributionUrl is available
[ -n "${distributionUrl-}" ] || die "Cannot read distributionUrl property in ${0%/*}/.mvn/wrapper/maven-wrapper.properties"

# Detect the platform for Maven distribution (Windows, macOS, Linux, etc.)
case "${distributionUrl##*/}" in
  maven-mvnd-*bin.*)
    MVN_CMD=mvnd.sh _MVNW_REPO_PATTERN=/maven/mvnd/
    case "${PROCESSOR_ARCHITECTURE-}${PROCESSOR_ARCHITEW6432-}:$(uname -a)" in
      *AMD64:CYGWIN* | *AMD64:MINGW*) distributionPlatform=windows-amd64 ;;
      :Darwin*x86_64) distributionPlatform=darwin-amd64 ;;
      :Darwin*arm64) distributionPlatform=darwin-aarch64 ;;
      :Linux*x86_64*) distributionPlatform=linux-amd64 ;;
      *)
        echo "Cannot detect platform for mvnd on $(uname)-$(uname -m), using default linux-amd64" >&2
        distributionPlatform=linux-amd64
        ;;
    esac
    distributionUrl="${distributionUrl%-bin.*}-$distributionPlatform.zip"
    ;;
  maven-mvnd-*) MVN_CMD=mvnd.sh _MVNW_REPO_PATTERN=/maven/mvnd/ ;;
  *) MVN_CMD="mvn${0##*/mvnw}" _MVNW_REPO_PATTERN=/org/apache/maven/ ;;
esac

# Determine MAVEN_HOME and download location
distributionUrlName="${distributionUrl##*/}"
distributionUrlNameMain="${distributionUrlName%.*}"
distributionUrlNameMain="${distributionUrlNameMain%-bin}"
MAVEN_USER_HOME="${MAVEN_USER_HOME:-${HOME}/.m2}"
MAVEN_HOME="${MAVEN_USER_HOME}/wrapper/dists/${distributionUrlNameMain-}/$(hash_string "$distributionUrl")"

# Execute Maven with the given arguments
exec_maven() {
  unset MVNW_VERBOSE MVNW_USERNAME MVNW_PASSWORD MVNW_REPOURL || :
  exec "$MAVEN_HOME/bin/$MVN_CMD" "$@" || die "Cannot execute $MAVEN_HOME/bin/$MVN_CMD"
}

# If MAVEN_HOME already exists, execute Maven
if [ -d "$MAVEN_HOME" ]; then
  verbose "Found existing MAVEN_HOME at $MAVEN_HOME"
  exec_maven "$@"
fi

# Ensure distributionUrl is valid (must end with -bin.zip or maven-mvnd-*.zip)
case "${distributionUrl-}" in
  *?-bin.zip | *?maven-mvnd-?*-?*.zip) ;;
  *) die "Invalid distributionUrl format. Must match *-bin.zip or maven-mvnd-*.zip, but found '${distributionUrl-}'" ;;
esac

# Prepare a temporary directory for downloading Maven
if TMP_DOWNLOAD_DIR="$(mktemp -d)" && [ -d "$TMP_DOWNLOAD_DIR" ]; then
  clean() { rm -rf -- "$TMP_DOWNLOAD_DIR"; }
  trap clean HUP INT TERM EXIT
else
  die "Cannot create temporary directory"
fi

mkdir -p -- "${MAVEN_HOME%/*}"

# Download Maven distribution
verbose "Downloading Maven from: $distributionUrl"
verbose "Saving to: $TMP_DOWNLOAD_DIR/$distributionUrlName"

# Select format: .zip or .tar.gz
if ! command -v unzip >/dev/null; then
  distributionUrl="${distributionUrl%.zip}.tar.gz"
  distributionUrlName="${distributionUrl##*/}"
fi

# Set quiet options for wget/curl
__MVNW_QUIET_WGET=--quiet __MVNW_QUIET_CURL=--silent __MVNW_QUIET_UNZIP=-q __MVNW_QUIET_TAR=''

# Use wget or curl to download Maven distribution
if [ -z "${MVNW_USERNAME-}" ] && command -v wget >/dev/null; then
  verbose "Found wget, using wget"
  wget ${__MVNW_QUIET_WGET:+"$__MVNW_QUIET_WGET"} "$distributionUrl" -O "$TMP_DOWNLOAD_DIR/$distributionUrlName" || die "Failed to fetch $distributionUrl using wget"
elif [ -z "${MVNW_USERNAME-}" ] && command -v curl >/dev/null; then
  verbose "Found curl, using curl"
  curl ${__MVNW_QUIET_CURL:+"$__MVNW_QUIET_CURL"} -f -L -o "$TMP_DOWNLOAD_DIR/$distributionUrlName" "$distributionUrl" || die "Failed to fetch $distributionUrl using curl"
else
  die "No valid download method (wget or curl) available"
fi

# Validate SHA-256 checksum if provided
if [ -n "${distributionSha256Sum-}" ]; then
  distributionSha256Result=false
  if command -v sha256sum >/dev/null; then
    if echo "$distributionSha256Sum  $TMP_DOWNLOAD_DIR/$distributionUrlName" | sha256sum -c >/dev/null 2>&1; then
      distributionSha256Result=true
    fi
  elif command -v shasum >/dev/null; then
    if echo "$distributionSha256Sum  $TMP_DOWNLOAD_DIR/$distributionUrlName" | shasum -a 256 -c >/dev/null 2>&1; then
      distributionSha256Result=true
    fi
  else
    echo "Checksum validation is not supported. Please install 'sha256sum' or 'shasum'." >&2
    exit 1
  fi
  if [ $distributionSha256Result = false ]; then
    echo "Error: SHA-256 validation failed for the Maven distribution." >&2
    exit 1
  fi
fi

# Unzip or untar the downloaded Maven distribution
if command -v unzip >/dev/null; then
  unzip ${__MVNW_QUIET_UNZIP:+"$__MVNW_QUIET_UNZIP"} "$TMP_DOWNLOAD_DIR/$distributionUrlName" -d "$TMP_DOWNLOAD_DIR" || die "Failed to unzip Maven distribution"
else
  tar xzf${__MVNW_QUIET_TAR:+"$__MVNW_QUIET_TAR"} "$TMP_DOWNLOAD_DIR/$distributionUrlName" -C "$TMP_DOWNLOAD_DIR" || die "Failed to untar Maven distribution"
fi

# Move the downloaded Maven distribution to MAVEN_HOME
mv -- "$TMP_DOWNLOAD_DIR/$distributionUrlNameMain" "$MAVEN_HOME" || die "Failed to move Maven distribution to $MAVEN_HOME"

# Clean up temporary files
clean || :

# Execute Maven with the provided arguments
exec_maven "$@"
