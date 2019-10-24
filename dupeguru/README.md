This script can be used to de-dupe your files when the ordering found by DupeGuru is "incorrect". You can set a list of "secondary" directories and they will appear at the end of the list, this way your chosen (as in, undefined) location will appear first and will not be deleted in DupeGuru.

To execute:
python3 dupe_remover.py < path to dupe file.csv >

The output will be directed to <parsed_ path to dupe file.csv>

Unfortunately DupeGuru cannot read CSV files so we'll need to manually delete the files:

cat <parsed_ path to dupe file.csv> | awk '{split($0,a,","); print a[3] a[2]}'
