module pap.extensions.yaml;

import dyaml;

/++
 + Returns the value of the node as a string map.
 +/
public string[string] asStringMap(Node node)
{
    string[string] map;
    foreach (pair; node.mapping)
    {
        map[pair.key.as!string] = pair.value.as!string;
    }

    return map;
}

/++
 + Returns the value of the node as a string array.
 +/
public string[] asStringArray(Node node)
{
    string[] array;
    foreach (Node element; node)
    {
        array ~= element.as!string;
    }

    return array;
}
