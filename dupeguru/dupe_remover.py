#!/usr/bin/python3

import sys

dupeSearchList = ["/storage/Common/bedroom", "/storage/Common/laptop", "/storage/Common/Recovered"]

# This script reads a csv file (output by DupeGuru)
# It reads line by line, parsing the first value (the dupe number)
# then searches for other lines with that same number
# It will then sort those lines according to what you'd like to remove
# If it matches the regex, then it will go to the bottom of the list (for easy selection) in DupeGuru


def dupeNumberFromLine(line):
    if len(line) == 0:
        return -1
    try:
        return int(line.split(',')[0])
    except:
        return -1

def checkLineIsDupe(line):
    match = False
    for dupeStr in dupeSearchList:
        if dupeStr in line.split(',')[2]:
            return True
    return False


def insertIntoList(lines, line):
    dupe = checkLineIsDupe(line)
    if dupe:
        lines.append(line)
    else:
        lines.insert(0, line)


def dupesHasDefaultMaster(lines):
    return lines[0].split(',')[2] not in dupeSearchList



def printLines(lines, output):
    if len(lines) != 0 and not dupesHasDefaultMaster(lines):
        output.write("No default master file found")
    #print(lines)
    for line in lines:
        output.write(line)


filename = sys.argv[1]
if not filename:
    print("No filename was provided")
    exit(1)

lines = []
lineDupeNumber = -1
currentDupeNumber = -1

parsedFile = "parsed_" + filename

outFile = open(parsedFile, "w+")

f = open(filename, "r")
for line in f:
    # convert to int (skip over invalid lines)
    lineDupeNumber = dupeNumberFromLine(line)
    if lineDupeNumber < 0:
        outFile.write(line)
        continue
    
    # if no lines, then it's the first one of at least this set
    if len(lines) == 0:
        currentDupeNumber = lineDupeNumber

    # if the line matches the currently tracked number
    # check to see if the line regex matches
    if currentDupeNumber == lineDupeNumber:
        insertIntoList(lines, line)
    else:
        printLines(lines, outFile)

        # blank the lines list
        lines = []

f.close()
# last entry since we ran out of lines
printLines(lines, outFile)
outFile.close()
