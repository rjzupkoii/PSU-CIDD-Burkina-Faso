#!/usr/bin/python3

# This script kind of recovers the original YAML file when the \n\r was stripped out of it

def get_last_delimiter(text, offset):
    while offset != -1:
        if text[offset].isspace() or text[offset] in (']', '-'):
            return offset
        offset = offset - 1
    return -1


def get_next_delimiter(text, offset):
    while offset != len(text):
        if text[offset].isspace() or text[offset] in ('#', '-'):
            return offset - 1
        offset = offset + 1
    return offset


# Read the file in
with open("yaml.txt", "r") as file:
    text = file.read()

yaml = []
ndx = 0
while ndx != len(text):
    # Hash indicates a comment
    if text[ndx] == '#':
        isComment = True

        # Append a new line if this isn't the very first character
        if ndx != 0:
            yaml.append('\n')

    # A colon indicates a name-value pair
    if text[ndx] == ':':
        isComment = False

        # Scan backwards for the last delimiter
        index = get_last_delimiter(text, ndx)

        # Begin processing the block
        if text[index] == '-':
            yaml.insert(len(yaml) - (ndx - index - 2), '\n')
        else:
            yaml.insert(len(yaml) - (ndx - index - 1), '\n')

        # Scan forward for the next delimiter after the expected space
        index = get_next_delimiter(text, ndx + 2)

        while ndx != (index - 1):
            yaml.append(text[ndx])
            ndx = ndx + 1

    # A dash indicates a block if preceded and followed by a space, and not in a comment
    if not isComment and (text[ndx] == '-' and text[ndx - 1].isspace() and text[ndx + 1].isspace()):
        yaml.append('\n')

    # Otherwise just append the character
    yaml.append(text[ndx])

    # Update the index
    ndx = ndx + 1

yaml = ''.join([str(char) for char in yaml])
with open("yaml.yml", "w") as file:
    file.write(yaml)


