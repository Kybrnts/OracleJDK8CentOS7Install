#!/bin/sh
#: Title       : OracleJDK8CentOSInstall
#: Date        : 2019-01-14
#: Author      : Kybernetes <correodelkybernetes@gmail.com>
#: Version     : 1.00
#: Description : Executable Dash shell script
#:             : Installs Oracle's JDK8 in a CentOS v7 installation from pay-
#:             : load's zip compressed tarball.
#: Options     : -h : Displays help
#:             : -u : Uninstall
#: Usage       : 1. Create a copy of this script
#:             : 2. APPEND to this script an Oracle jdk-8uXXX-linux-x64.tar.gz
#:             :    to create a self extracting executable
#:             : 3. Upload to your server and run
##
## -- Run time configuration ---------------------------------------------------
_RPLY=                                            ## Read builtin reply
_USER=$USER                                       ## Current user name
_NOWDATE=YYYY-mm-dd                               ## Current date
_JDKPRNTDIR=/usr/java                             ## All Javas container
_JDKPYLDVRS=1.8.0_XXX                             ## Payload's JDK8 version
_SHPRFLENME=/etc/profile.d/java.sh                ## Shell profile script
_SHPRFLBACK=~/${_SHPRFLENME##*/}/_${NOWDATE}.back ## Backups for above file
_PYLDLINENM=0                                     ## Payload's first line
##
## -- Required for execution ---------------------------------------------------
_CMD_SLEEP=/usr/bin/sleep _CMD_WHOAMI=/usr/bin/whoami _CMD_CAT=/bin/cat
_CMD_GREP=/bin/grep _CMD_TAIL=/usr/bin/tail _CMD_DATE=/bin/date
_CMD_MKDIR=/bin/mkdir _CMD_AWK=/bin/awk _CMD_TAR=/bin/tar
_CMD_ALTERNATIVES=/sbin/alternatives
# Check required executables availability before starting
[ -x "$_CMD_SLEEP" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_SLEEP"; exit 1; }
[ -x "$_CMD_WHOAMI" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_WHOAMI"; exit 1; }
[ -x "$_CMD_CAT" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_CAT"; exit 1; }
[ -x "$_CMD_GREP" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_GREP"; exit 1; }
[ -x "$_CMD_TAIL" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_TAIL"; exit 1; }
[ -x "$_CMD_DATE" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_DATE"; exit 1; }
[ -x "$_CMD_MKDIR" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_MKDIR"; exit 1; }
[ -x "$_CMD_AWK" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_AWK"; exit 1; }
[ -x "$_CMD_TAR" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_TAR"; exit 1; }
[ -x "$_CMD_ALTERNATIVES" ] ||
    { printf "${0##*/}: %s not found\n" "$_CMD_ALTERNATIVES"; exit 1; }
# Create alias to force use specific path within functions, while keeping syntax
# short. It will expand on func. declaration NOT on invocation. But DON'T put it
# inside "if" or any other construct command list: it could render it useless!!
alias sleep="$_CMD_SLEEP" whoami="$_CMD_WHOAMI" cat="$_CMD_CAT"\
      grep="$_CMD_GREP" tail="$_CMD_TAIL" date="$_CMD_DATE" mkdir="$_CMD_MKDIR"\
      awk="$_CMD_AWK" tar="$_CMD_TAR" alternatives="$_CMD_ALTERNATIVES"
# Force applications to use the default language for output
export LC_ALL=C
##
## Function declarations -------------------------------------------------------
stdmsg() { #@ DESCRIPTION: Print messages to STDOUT
           #@ USAGE: stdmsg [ MSG .. ]
    [ "${1+X}" = X ] && printf -- "%s\n" "$@"
}
errmsg() { #@ DESCRIPTION: Print messages to STDERR prefixed by an error stamp
           #@ USAGE: stderr [ MSG .. ]
    stdmsg ${1+"Error! $@"} >&2
}
wrnmsg() { #@ DESCRIPTION: Print Warning messages to STDOUT
           #@ USAGE wrnmsg [ MSG .. ]
    stdmsg ${1+"WARNING: $@"}
}
setUser() { #@ DESCRIPTION: Sets global _USER w/current user name.
            #@ USAGE: setUser
    local user                                           ## Name local storage
    if ! user=$(whoami 2>/dev/null); then                ## Try to get name
        printf "Error: Failed to get current user\n" >&2 ## Fail if not possible
        return 1                                         ## Return w/>0 status
    fi                                                   ## Got user name?
    _USER=$user                                          ## Yes so, Set global
}
setNowDate() { #@ DESCRIPTION: Used to set global _NOWDATE value w/today's date
               #@              YYYY-mm-dd format.
               #@ USAGE: setNowDate
    # Local variables ("local" must be function's first statement)
    local nowd      ## Now date storage
    # Try set date using date cmd, if date fails use fixed string as value
    nowd="$(date +%Y-%m-%d 2>/dev/null)" || nowd=YYYY-mm-dd
    _NOWDATE=$nowd  ## Set global value
}
setPyLdLineNm() { #@ DESCRIPTION: Sets global _PYLDLINENM with this file's first
                  #@              line of payload.
                  #@ USAGE: setPyLdLineNm
    # Local variables ("local" must be function's first statement)
    local lnum                                              ## Local line number
    lnum="$(grep -anm1 '[_]PAYLOAD_BELOW_' $0 2>/dev/null)" ## Try get number
    case $? in
        2)                                                  ## Read file failed?
            errmsg "Failed to read script"                  ## Print error
            return 2 ;;                                     ## Set status & done
        1)                                                  ## No matches found
            errmsg "No payload line read"                   ## Print error
            return 1 ;;                                     ## Set status & done
    esac                             ## Now lnum is prefixed w/number
    _PYLDLINENM=$((${lnum%%:*} + 1)) ## Extract & increase number, then set glob
}
setJdkPyldVers() { #@ DESCRIPTION: Sets global _JDKPYLDVRS with payload's JDK8
                   #@              version name.
                   #@ USAGE: usage setJdkPyldVers
    # Local variables ("local" must be function's first statement)
    local vers r                 ## JDK8 version and STDIN lines counter
    r=0                          ## Initialize read lines counter
    while IFS= read -r _RPLY; do ## Read whole lines until EOF
        r=$((r + 1))             ## Increase read lines counter
        if [ $r -gt 1 ]; then    ## Allow only one line from STDIN
            errmsg "Too many JDKs in payload"
            return 1             ## Finish w/error if more than one line read
        fi
        vers=$_RPLY              ## Store read version
    done <<EOF
$({ tail -n +$_PYLDLINENM "$0" |     ## Get payload reading $0 after tagged line
        tar -tvzf -; } 2>/dev/null | ## Accept Oracle's JDK8 compressed tarball
      awk \
'/^d.*jdk1.8.0_[0-9]{1,3}/{      ## Get only matching directory entries from tar
    gsub(/\/.*/,"", $6); v[$6]++ ## Filter only unique parent directory names
}
END{ for(x in v) print x         ## Send to STDOUT found parent directories
}')
EOF
    if [ $r -eq 0 -o X"$vers" = X ]; then  ## Require one nonempty line from
       errmsg "No JDKs found in payload"   ## input, or finish with errors
       return 1
    fi
    _JDKPYLDVRS=$vers                      ## Set global runtime conf. parameter
}
setShPrflBack() { #@ DESCRIPTION: Sets shell profile backup filename.
                  #@ USAGE setShPrflBack
    local bknme                    ## Local backup file name storage
    bkname=${_SHPRFLENME:-java.sh} ## Set a default value
    # Set global value using date for the backup
    _SHPRFLBACK=~/${bkname##*/}_${_NOWDATE:-YYYY-MM-DD}.back
}
ynPrmpt() { #@ DESCRIPTION: Prompt user to enter Yes
            #@ USAGE: ynPrmpt PROMPT
    printf "%s? (Yes|No)> " "$1"  ## Show $1 question string w/yes or no prompt
    IFS= read _RPLY               ## Read answer from STDIN
    case $_RPLY in                ## Test reply content
        [Yy][Ee][Ss]) return 0 ;; ## Return success when answer matches yes
        *) return 1 ;;            ## Fail otherwise
    esac
}
uninstallJdk8() { #@ DESCRIPTION: Removes Oracle JDK8 installation directory
                  #@              and all its content
                  #@ USAGE: uninstallJdk8
    local errs noempt                      ## Inst. errors and empty input flags
    noerrs=true                            ## Initialize flags
    # Delete all files from installation path in coprocess and print its output
    # line by line in a single line that refresh itself
    while IFS= read -r _RPLY; do           ## Read whole current line
        [ X"$_RPLY" = Xprintf ] ||         ## Reset cursor's pos. and println
            printf "\033[K\033[s%s\033[u" "$_RPLY"
        sleep 0.01                         ## Wait some time before next
    done <<EOF
    $(rm -rvf "$_JDKPRNTDIR/$_JDKPYLDVRS" 2>/dev/null)
EOF
    if [ -e "$_JDKPRNTDIR/$_JDKPYLDVRS" ]; then             ## If dir still ex-
        errmsg "Failed to remove $_JDKPRNTDIR/$_JDKPYLDVRS" ## sits, something
        noerrs=false                                        ## whent wrong
    fi
    rm -vf "$_SHPRFLENME"                      ## Now remove shell profile
    if [ -e "$_SHPRFLENME" ]; then             ## Check if it still exists
        errmsg "Failed to remove $_SHPRFLENME" ## If so, something went wrong
        noerrs=false
    fi
    $noerrs                                    ## Return w/errors if needed
}
installJdk8() { #@ DESCRIPTION: Installs Oracle's JdK8 from payload
                #@ USAGE: installJdk8
    # Decompress & untar all files to installation path in coprocess, and print
    # output line by line in a single self refreshing one
    while IFS= read -r _RPLY; do ## Red whole current line
        case $_RPLY in           ## Check line
            STATUS:\ *[0-9])     ## Matches an error upon untar coproc. command
                errmsg "Failed to extract payload to $_JDKPRNTDIR"
                return 1 ;;      ## Finish w/errors
            "") continue ;;      ## Do not print empty lines
        esac                     ## Printf resets cursor's position and println
        printf "\033[K\033[sInstalled %s\033[u" "'$_JDKPRNTDIR/$_RPLY'"
        sleep 0.01               ## Wait some time before next line
    done <<EOF
$({ tail -n +$_PYLDLINENM "$0" | 
       tar -C "$_JDKPRNTDIR" -xvzf -; } 2>/dev/null || 
  printf "STATUS: %d" $?)
EOF
    ## Coprocess starts reading $0 from payload first line onward, sending out-
    ## put to tar-unzip-extract command to specific path. If tar exit status >0
    ## it will be returned to STDOUT so it can be handled by reading while loop.
    printf "\n"                  ## Avoid re-write the last line
}
catcp() { #@ DESCRIPTION: Copy $1 filename in $2 filename using cat.
          #@ USAGE: catcp FILENAME FILENAME
    local out
    if ! out=$({ cat "$1" >"$2"; } 2>&1); then
        errmsg "Failed to copy ${1##*/} file"
        printf "$out\n"
        return 1
    fi
}
installShProfile() { #@ DESCRIPTION: Installs shell profile w/environment provi-
                     #@              ded by new JDK installation. Typically this
                     #@              it will set your JAVA_HOME.
                     #@ USAGE: installShProfile
    local out             ## Write command output container
    # Try to write to $_SHPRFLENME shell profile saving attempt's output
    out=$({ cat >"$_SHPRFLENME" <<EOF
##
## Add JAVA_HOME to environment (preserve any previously set value)
## Replace assignment's LHS w/desired java home's full path.
JAVA_HOME=\${JAVA_HOME:-$_JDKPRNTDIR/$_JDKPYLDVRS}
## Export to all subshells
export JAVA_HOME
EOF
          } 2>&1)
    if [ $? -ne 0 ]; then ## if write failed, finish w/errors
        errmsg "Failed to update ${_SHPRFLENME##*/} file"
        printf "$out\n"   ## Display write command's  error
        return 1
    fi
}
remvJavaAlt() { #@ DESCRIPTION: Removes the $1 JDK program alternative upon $2
                #@              path, using the "alternatives" program.
                #@ USAGE remvJavaAlt '[ BIN ]' '[ PATH ]'
    if ! alternatives --remove $1 "$2"; then         ## Try to remove alt.
        errmsg "Failed to remove alternative for $1" ## Display error on failure
        return 1                                     ## Notify calling env.
    fi
}
instJavaAlt() { #@ DESCRIPTION: Installs an alternative for $1 JDK program on $2
                #@              path with $3 priority, using "alternatives".
                #@ USAGE: instJavaAlt '[ BIN ]' '[ PATH ]' [ PRIORITY ]
    # Try to install the alternative or finish w/errors
    if ! alternatives --install /usr/bin/"$1" "$1" "$2" ${3:-100}; then
        errmsg "Failed to install alternative for $1"
        return 1
    fi
}
dsplyHelp() { #@ DESCRIPTION: Display help message when run in help mode.
              #@ USAGE: dsplyHelp
    cat <<EOF
${0##*/} - Install JDK8 in an Atos NOCUY Centos Installation
USAGE
* Install mode   : ${0##*/}
* Uninstall mode : ${0##*/} -[U|u]
* Help mode      : ${0##*/} -[H|h]

OPTIONS
* -U : Remove JDK8 installation;
* -u : Synonym of -U;
* -h : Display this help message and exit.

STATUS
Exit status will be 0 when all operations completed successfully. Otherwise 1.
Status >1 is used for syntax or input/output errors.

EOF
    exit 0
}
##
## -- Main ---------------------------------------------------------------------
main() {
    # Local variables ("local" must be function's first statement)
    local uinm hlpm opt noinsterrs alt ## Mode flags, option errors flag, etc
    uinm=false hlpm=false              ## Initialize mode flags
    while getopts :UuHh opt; do        ## While we still have an option in args
        case $opt in                   ## Check option case
            [Uu])                      ## Uninstall mode selected?
                if $uinm; then         ## If already selected finish w/errors
                    errmsg "\"$opt\" option already used"
                    return 2           ## (Allow uninstall option only once)
                fi
                uinm=true ;;           ## Else set uninstall mode flag to true
            [Hh])                      ## Help mode selected?
                if $hlpm; then         ## If already selected finish w/errors
                    errmsg "\"$opt\" option already used"
                    return 2           ## (Allow help option only once)
                fi
                hlpm=true ;;           ## Else set help mode flag to true
            \?)                        ## Invalid option selected?
                errmsg "Invalid option \"-$OPTARG\""
                return 2 ;;            ## Finish w/errors
        esac
    done
    shift $(($OPTIND - 1))        ## Shift already parsed arguments (opts)
    if [ $# -ne 0 ]; then         ## If additional non option args are present
        errmsg "Invalid argument" ## Finish w/errors
        return 2                  ## (No no-option args allowed)
    fi
    # Check for help mode selected (Help mode has priority over other modes)
    $hlpm && dsplyHelp            ## Display help
    # Load runtime configuration -----------------------------------------------
    stdmsg "Loading runtime conf.." ## Notify user
    sleep 1                         ## Allow some time to read messages
    setUser || return 1             ## Get current user name into global
    setNowDate                      ## Get current date into global
    setPyLdLineNm || return 1       ## Get payload first line number into global
    setJdkPyldVers || return 1      ## Get payload's JDK8 version into global
    setShPrflBack                   ## Set shell profile backup filename
    stdmsg "Done."                  ## Runtime load finished successfully
    # Check user ---------------------------------------------------------------
    stdmsg "Checking user.."        ## Notify user
    sleep 1                         ## Allow some time to read messages
    case $_USER in                  ## Check matching user name
        root) ;;                    ## If root, then OK..
        *)                          ## Other users are not allowed hence, finish
            errmsg "$_USER is not allowed to continue"\
                   "Use \"sudo\", or log in as root and try again."
            return 1 ;;             ## With errors
    esac
    stdmsg "Done."                  ## User check finished successfully
    if $uinm; then # Uninstall mode --------------------------------------------
        noinsterr=true              ## Reset errors flag
        # Check installation dir. existence before doing anything
        if [ ! -d "$_JDKPRNTDIR/$_JDKPYLDVRS" ]; then
            errmsg "JDK8 installation not found" ## If not found, display error
            stdmsg "Nothing to do"               ## But finish without errors
            return 0
        else                                     ## If found, proceed
            # Prompt user to proceed to uninstall JDK8
            if ynPrmpt "Remove $_JDKPRNTDIR/$_JDKPYLDVRS and all its content"
            then
                stdmsg "Uninstalling JDK8.."     ## If "yes continue" notify usr
                sleep 1                          ## Allow some time to read
                if ! uninstallJdk8; then         ## Try to remove installation
                    errmsg "Failed to uninstall" ## Show error if unable to.
                    noinsterr=false              ## Now, we have some errors
                fi
                stdmsg "Done."                   ## JDK8 uninstall finished
            else
                stdmsg "Cancelled"               ## If "No", do not uninstall
            fi                                   ## And let user know
            # Prompt user to proceed w/JDK common progs. alternatives removal
            if ynPrmpt "Remove alternatives for common programs"; then
                stdmsg "Removing alternatives.." ## If "yes continue" notify usr
                sleep 1                          ## Allow some time to read
                for alt in jar java javac javaws keytool; do ## For each prog..
                    stdmsg "Removing for program $alt"       ## Tell user
                    sleep 0.5                                ## Allow to read
                    # Remove current prog alternative
                    remvJavaAlt $alt "$_JDKPRNTDIR/$_JDKPYLDVRS/bin/$alt" ||
                        noinsterr=false
                done
                stdmsg "Done"                    ## Alternatives rm completed
            else
                stdmsg "Cancelled"               ## Alternatives rm cancelled
            fi
        fi
        $noinsterr ## Finish w/errors if flag indicates that something failed
    else           # Install mode ----------------------------------------------
                   # This workflow is insane, needs improvement/optimization
        noinsterrs=false ## Initialize errors flag
        # Check javas container
        stdmsg "Checking java installation path.."
        sleep 1
        # Check and create all javas container
        if [ ! -d "$_JDKPRNTDIR" ]; then   ## If container do not exists
            if [ -e "$_JDKPRNTDIR" ]; then ## But a file w/same name exists
                errmsg "File $_JDKPRNTDIR already exists"
                return 1                   ## Finish w/errors
            else                           ## Otherwise proceed w/installation
                stdmsg "Java installation path does not exits"
                if ! ynPrmpt "Would you like to create it"; then ## Prompt user
                    stdmsg "Cancelled"                           ## End if "NO"
                    return 0                                     ## w/no errors
                else                                     ## Continue if "Yes"
                    stdmsg "Creating $_JDKPRNTDIR dir.." ## Create all javas
                    mkdir -pm 755 "$_JDKPRNTDIR"         ## Container
                    if [ ! -d "$_JDKPRNTDIR" ]; then     ## Check afterwards
                        errmsg "Failed to create installation path"
                        return 1                         ## Finish w/errors
                    else                                 ## If failed to create
                        stdmsg "Created."
                    fi
                fi
            fi
        fi
        stdmsg "Done."
        # Try to install JDK8
        stdmsg "Installing JDK8.."                  ## Notify user
        sleep 1                                     ## Allow some time
        if [ -e "$_JDKPRNTDIR/$_JDKPYLDVRS" ]; then ## Check previous install
            wrnmsg "Found previous installation of $_JDKPYLDVRS"
            # If previous installation found, prompt user to re-install
            if ynPrmpt "Would you like to re-install it"; then
                if ! installJdk8; then ## If "yes" try to install
                    noinsterrs=false   ## Set flag accordingly if install fails
                    stdmsg "Failed"    ## Report failure to user
                else                   ## Re-install succeeded
                    stdmsg "Done"      ## Notify user
                fi
            else                       ## If "No" cancel do not re-install
                stdmsg "Cancelled"
            fi
            # If no previous installation found
        elif ! installJdk8; then ## Proceed to install
            noinsterrs=false     ## Set flag accordingly if install fails
            stdmsg "Failed."     ## Report failure to user
        else                     ## Install succeeded
            stdmsg "Done."       ## Notify user
        fi
        # Try to install new shell profile script
        stdmsg "Installing shell profile ${_SHPRFLENME##*/}.." ## Notify user
        sleep 1                                                ## Allow to read
        if [ -e "$_SHPRFLENME" ]; then                ## If prfle already exists
            wrnmsg "Profile ${_SHPRFLENME##*/} found" ## Warn user and prompt
            if ! ynPrmpt "Would you like to create backup"; then
                stdmsg "Cancelled."                   ## If "No" cancel install
            else                                      ## If "Yes"
                stdmsg "Creating $_SHPRFLBACK backup.."
                if [ -e "$_SHPRFLBACK" ]; then        ## Check if backup exists
                    wrnmsg "Backup already exists"    ## Warn/prmpt to overwrite
                    if ! ynPrmpt "Do you want to overwrite it"; then
                        stdmsg "Overwrite cancelled." ## If "No" don't overwrite
                    else                              ## If yes, proceed
                        stdmsg "Overwritting backup.."
                        sleep 1
                        # Try to create the backup copy of shell profile
                        if ! catcp "$_SHPRFLENME" "$_SHPRFLBACK"; then
                            noinsterrs=false           ## Copy fails?, set flag
                            stdmsg "Overwrite failed." ## & notify user
                        else                           ## Back-up copy made
                            stdmsg "Overwrite done."
                        fi
                        stdmsg "Backup done."
                    fi
                # If profile backup doesn't exist, do not prompt, and create it
                elif ! catcp "$_SHPRFLENME" "$_SHPRFLBACK"; then
                    noinsterrs=false        ## Copy fails?, set flag
                    stdmsg "Backup failed." ## and notify user
                else                        ## Back-up copy made
                    stdmsg "Backup Done."
                fi
            fi
            wrnmsg "Profile ${_SHPRFLENME##*/} found"
            # Since shell profile was found, also prompt to re-install it
            if ! ynPrmpt "Would you like to re-install it"; then
                stdmsg "Cancelled"               ## If "No", don't
            else                                 ## If "Yes", try to reinstall
                stdmsg "Re-installing profile.."
                if ! installShProfile; then      ## If profile re-install fails
                    noinsterrs=false             ## Set flag accordingly
                    stdmsg "Re-install Failed."  ## Notify user
                else                             ## Profile re-install succeeded
                    stdmsg "Re-install Done."
                fi
            fi
        # No previously installed shell profile found, so proceed to install
        elif ! installShProfile; then ## If installation fails
            noinsterrs=false          ## Set flag accordingly
            stdmsg "Failed."          ## Notify user
        fi                            ## profile install succeeded
        stdmsg "Done."
        $noinsterr
        # Prompt user to proceed w/JDK common progs. alternatives installation
        if ynPrmpt "Install alternatives for common programs"; then
            stdmsg "Installing alternatives.."           ## If "yes", notify usr
            sleep 1                                      ## Allow some time
            for alt in jar java javac javaws keytool; do ## For each prog
                stdmsg "Alternative for program $alt"    ## Tell user about it
                sleep 0.5                                ## Allow some time
                # Install current prog alternative w/a priority of 150
                instJavaAlt $alt "$_JDKPRNTDIR/$_JDKPYLDVRS/bin/$alt" 150 ||
                    noinsterr=false
            done
        fi
        stdmsg "Done" ## Installation finished
        $noinsterr    ## Finish w/flag's exit status
    fi
}
# Aliases no longer needed
unalias sleep whoami cat grep tail date mkdir awk tar alternatives
##
## -- Run! ---------------------------------------------------------------------
main ${1+"$@"}
exit ## Prevent payload execution
##
## %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PAYLOAD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_PAYLOAD_BELOW_
