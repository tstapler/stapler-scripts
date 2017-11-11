#!/usr/bin/env bash

set -o nounset                              # Treat unset variables as an error

__ScriptVersion="0.0.1"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
usage ()
{
  echo "Usage :  $0 [options] [ZIP_GLOB]
  Unarchive a zipfile full of pdfs into the current directory

    Options:
    -h|help       Display this message
    -v|version    Display script version"

}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":hv" opt
do
  case $opt in

  h|help     )  usage; exit 0   ;;

  v|version  )  echo "$0 -- Version $__ScriptVersion"; exit 0   ;;

  * )  echo -e "\n  Option does not exist : $OPTARG\n"
      usage; exit 1   ;;

  esac    # --- end of case ---
done
shift $(($OPTIND-1))

GLOB="${1:-CPRE}"
TEMP_FOLDER=temp


# Unzip and flatten zipfile

echo "Inflating notes in zips"

# Unzip and flatten zipfile
find . -maxdepth 1 -iname \*$GLOB\*.zip \
  -exec unzip -jn {} -d $TEMP_FOLDER \; \
  -exec rm -f {} \; 

echo "OCRing Notes without text"

# OCR Files without orc
find $TEMP_FOLDER -maxdepth 1 -iname \*$GLOB\*.pdf |  while read TEMP_FILE; do

PERM_FILE=$(basename "$TEMP_FILE") 

if [ ! -f PERM_FILE ]; then
  if  pdf_has_ocr "$TEMP_FILE"; then
    NEW_FILE=$(sed "s/.pdf/_ocr.pdf/" <<< "$TEMP_FILE")
    git annex unannex "$TEMP_FILE"
    pypdfocr "$TEMP_FILE"
    mv "$TEMP_FOLDER/$NEW_FILE" "$PERM_FILE"
  else
    mv "$TEMP_FILE" "$PERM_FILE"
  fi
fi
done
  
echo "Adding notes to git annex"

# Add notes that aren't in git annex
find . -maxdepth 1 -type f -name \*$GLOB\*.pdf | xargs -r git annex add

rm -rf $TEMP_FOLDER
