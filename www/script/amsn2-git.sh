#######################################################################
# This script allows users who don't have a clue about git, and don't #
# need/want to, to keep following aMSN2 development.                  #
#                                                                     #
# authors:                                                            #
# Alexander Nestorov <alexandernst@gmail.com>                         #
# Boris Faure <billiob@users.sourceforge.net>                         #
#                                                                     #
# license:                                                            #
# GNU GPLv3 - http://www.gnu.org/licenses/gpl-3.0.html                #
#######################################################################

#######################################################################
# Global vars                                                         #
#######################################################################
REPOSITORY_URL="https://github.com/amsn/amsn2.git"
SCRIPT_URL="http://www.amsn-project.net/script/amsn2-git.sh"
VERSION=4
TEMPFILE="/tmp/$(basename $0).$RANDOM.txt"
MYSELF=$(basename $0)
WHEREAMI=`dirname $(readlink -f $0)`
AMSN2DIR=$WHEREAMI"/amsn2-git"
#######################################################################
# End global vars                                                     #
#######################################################################

#######################################################################
# checkfor() will check if app is installed.                          #
#######################################################################
checkfor()
{
  type -P $1 &>/dev/null || 
  { 
    echo "I require $1 but it's not installed.  Aborting." >&2; exit 1;
  }
}
#######################################################################
# End checkfor()                                                      #
#######################################################################

#######################################################################
# selfupdate() will update this script.                               #
#######################################################################
selfupdate()
{
  #Check for w perms
  if [ ! -w $0 ]; then
    echo "No writable permissions. Aborting update..."
    return 1
  fi
  echo -n "Retrieving latest version... "
  #Download
  wget -t 1 -T 5 -q -O $TEMPFILE $SCRIPT_URL
  #Check script version
  IFS="="
  set -- $(cat $TEMPFILE | egrep "^VERSION=")
  LATEST_VERSION=$1
  #Update if necessary.
  if expr "$LATEST_VERSION" "<=" "$VERSION" > /dev/null; then
    rm -f $TEMPFILE
    echo "Already updated!"
    return 2
  fi
  echo -n "Updating to version $LATEST_VERSION... "
  cd $WHEREAMI
  chmod a+x $TEMPFILE
  mv $TEMPFILE $MYSELF
  cd - > /dev/null
  echo "Done!"
  return 0
}
#######################################################################
# End selfupdate()                                                    #
#######################################################################

#######################################################################
# Main part                                                           #
#######################################################################
echo "Checking for updates..."
selfupdate
echo "Checking for needed components..."
checkfor git
checkfor python
#checkfor more things
while true; do
  echo "All good."
  echo "What would you like to do?"
  echo "[1] I'd like to install/upgrade if already installed my aMSN2."
  echo "[2] I'd like to make some work on aMSN2."
  echo "[3] Run aMSN2."
  echo "[4] Exit this script."
  read answer
  case "$answer" in
    1)
      #Check if we have already cloned amsn2
      if [ -d "$AMSN2DIR" ]; then #update amsn2 from git
        cd "$AMSN2DIR"
        git remote update
        git reset --hard origin/master
        git submodule update
        cd -
      else #Clone with read only or with read and write perms.
        if [ ! -z "$1" ]; then
          $REPOSITORY_URL=$(echo $REPOSITORY_URL | sed -e "s/\/amsn\//\/$1\//")
          $REPOSITORY_URL=$(echo $REPOSITORY_URL | sed -e "s/\/https\//\/git\//")
        fi
        git clone "$REPOSITORY_URL" "$AMSN2DIR"
        cd "$AMSN2DIR"
        git submodule update --init
        cd -
      fi
      ;;
    2)
      while true; do
        echo "What would you like to do?"
        echo "[1] Add a branch."
        echo "[2] Remove a branch."
        echo "[3] Show branches."
        echo "[4] Switch to a branch."
        echo "[5] Fetch and merge a branch."
        echo "[6] Show current status."
        echo "[7] Add files/folders for a commit."
        echo "[8] Make a commit."
        echo "[9] Go back to main menu."
        read answer
        case "$answer" in
        1) #add a branch to local amsn2 git branch
          echo "Type the name of the branch."
          read branch
          $REPOSITORY_URL=$(echo $REPOSITORY_URL | sed -e "s/\/amsn\//\/$branch\//")
          cd "$AMSN2DIR"
            git remote add "$1" "$REPOSITORY_URL"
          cd -
          ;;
        2) #remove a branch from local amsn2 git branch
          echo "Type the name of the branch."
          read branch  
          cd "$AMSN2DIR"
          git remote rm "$branch"
          cd -
          ;;
        3) #show amsn2 git branches
          cd "$AMSN2DIR"
          git branch -a
          cd -
          ;;
        4) #switch to some branch
          echo "Type the name of the branch."
          read branch
          cd "$AMSN2DIR"
          git branch "$branch"
          cd -
          ;;
        5) #fetch and merge a branch
          echo "Type the name of the branch."
          read branch
          cd "$AMSN2DIR"
          git remote update
          git reset --hard "$branch"
          cd -
          ;;
        6) #show changed files
          cd "$AMSN2DIR"
          git status
          cd -
          ;;
        7) #add files/folders to commit
          echo "Type the name/path of the file/folder you want to add."
          read path
          cd "$AMSN2DIR"
          git add "$path"
          cd -
          ;;
        8) #commit changes
          echo "Type the commit message."
          read msg
          echo "Type the name of the branch."
          read branch
          cd "$AMSN2DIR"
          git commit -m "$msg"
          git push "git@github.com:$branch/amsn2.git"
          cd -
          ;;
        9)
          break
          ;;
        *)
          echo "Valid answers are 1 to 9."
          ;;
        esac
      done
      ;;
    3)
      cd "$AMSN2DIR"
      export python_bin=`which python2`
      echo "Select one of the available front ends."
      env $python_bin $AMSN2DIR/amsn2.py -l
      read answer
      env $python_bin $AMSN2DIR/amsn2.py -f $answer
      ;;
    4)
      exit 0
      ;;
    *)
      echo "Valid answers are 1 to 4."
      ;;
  esac
done